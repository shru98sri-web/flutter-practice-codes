import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // NOTE: Before executing, download your setup infrastructure configuration options
  // from the Firebase Console and initialize the native bindings here:
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    const MaterialApp(home: LiveRadarApp(), debugShowCheckedModeBanner: false),
  );
}

// ==========================================
// 1. CLOUD TELEMETRY DATA MODELS
// ==========================================

class RadarTarget {
  final String id;
  final double
  distanceRatio; // Normalized metric translation (0.0 to 1.0) relative to maximum ceiling limits
  final double
  angleInRadians; // Geodesic bearing converted to canvas spatial coordinate index

  RadarTarget({
    required this.id,
    required this.distanceRatio,
    required this.angleInRadians,
  });
}

// ==========================================
// 2. STATE MANAGEMENT (PRODUCTION BLOC SYSTEM)
// ==========================================

abstract class RadarEvent {}

class ConnectToCloudRadar extends RadarEvent {
  final String currentUserId;
  ConnectToCloudRadar(this.currentUserId);
}

class SyncCloudData extends RadarEvent {
  final Position userPosition;
  final List<DocumentSnapshot> cloudDocs;
  SyncCloudData(this.userPosition, this.cloudDocs);
}

class CloudRadarError extends RadarEvent {
  final String message;
  CloudRadarError(this.message);
}

abstract class RadarState {}

class RadarInitial extends RadarState {}

class RadarConnecting extends RadarState {}

class RadarStreamingActive extends RadarState {
  final Position myPosition;
  final List<RadarTarget> liveTargets;

  RadarStreamingActive({required this.myPosition, required this.liveTargets});
}

class RadarStreamFailure extends RadarState {
  final String error;
  RadarStreamFailure(this.error);
}

class CloudRadarBloc extends Bloc<RadarEvent, RadarState> {
  StreamSubscription<Position>? _gpsSubscription;
  StreamSubscription<QuerySnapshot>? _firestoreSubscription;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final double trackingRangeMeters =
      500.0; // 500m geofence perimeter sweep limit

  CloudRadarBloc() : super(RadarInitial()) {
    on<ConnectToCloudRadar>(_onConnectToCloud);
    on<SyncCloudData>(_onSyncCloudData);
    on<CloudRadarError>(
      (event, emit) => emit(RadarStreamFailure(event.message)),
    );
  }

  Future<void> _onConnectToCloud(
    ConnectToCloudRadar event,
    Emitter<RadarState> emit,
  ) async {
    emit(RadarConnecting());
    try {
      // 1. Hardware Manifest and Security Verification Check
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return add(
            CloudRadarError(
              "Security clearance rejected: Device location access is required.",
            ),
          );
        }
      }

      // 2. Transmit Link Creation: Sample local hardware and execute push uplink pipeline
      _gpsSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 3,
            ),
          ).listen(
            (Position position) {
              // Write active telemetry positioning array payload parameters back onto remote node collection
              _firestore
                  .collection('users_radar')
                  .doc(event.currentUserId)
                  .set({
                    'userId': event.currentUserId,
                    'latitude': position.latitude,
                    'longitude': position.longitude,
                    'lastUpdated': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));

              // 3. Receive Link Creation: Establish structural hot reactive subscription stream to capture network matrix snapshot queries
              _firestoreSubscription?.cancel();
              _firestoreSubscription = _firestore
                  .collection('users_radar')
                  .snapshots()
                  .listen(
                    (QuerySnapshot snapshot) {
                      // Forward cloud synchronization collection blocks payload directly into processing loop pipeline
                      add(SyncCloudData(position, snapshot.docs));
                    },
                    onError: (err) => add(
                      CloudRadarError("Remote network handshake failure: $err"),
                    ),
                  );
            },
            onError: (err) => add(
              CloudRadarError("GPS Telemetry receiver tracking crash: $err"),
            ),
          );
    } catch (e) {
      add(
        CloudRadarError("Pipeline initial initialization failure vector: $e"),
      );
    }
  }

  void _onSyncCloudData(SyncCloudData event, Emitter<RadarState> emit) {
    List<RadarTarget> mappedTargets = [];

    for (var doc in event.cloudDocs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null || data['userId'] == doc.id)
        continue; // Filter loop context execution to skip self-rendering matrix nodes

      double targetLat = (data['latitude'] as num).toDouble();
      double targetLng = (data['longitude'] as num).toDouble();

      // Geodesic Vector Tracking Distance calculation loops using Haversine models
      double distance = Geolocator.distanceBetween(
        event.userPosition.latitude,
        event.userPosition.longitude,
        targetLat,
        targetLng,
      );

      // Validate perimeter bounds parameters context
      if (distance <= trackingRangeMeters) {
        double ratio = distance / trackingRangeMeters;
        double bearing = Geolocator.bearingBetween(
          event.userPosition.latitude,
          event.userPosition.longitude,
          targetLat,
          targetLng,
        );
        double radians = (bearing - 90) * (math.pi / 180);

        mappedTargets.add(
          RadarTarget(
            id: data['userId'],
            distanceRatio: ratio,
            angleInRadians: radians,
          ),
        );
      }
    }

    emit(
      RadarStreamingActive(
        myPosition: event.userPosition,
        liveTargets: mappedTargets,
      ),
    );
  }

  @override
  Future<void> close() {
    _gpsSubscription?.cancel();
    _firestoreSubscription?.cancel();
    return super.close();
  }
}

// ==========================================
// 3. USER INTERFACE TREE COMPONENT
// ==========================================

class LiveRadarApp extends StatelessWidget {
  const LiveRadarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Configuration simulation token representing local authorization user ID
      create: (context) =>
          CloudRadarBloc()..add(ConnectToCloudRadar("User_Me")),
      child: const CloudRadarScreen(),
    );
  }
}

class CloudRadarScreen extends StatefulWidget {
  const CloudRadarScreen({super.key});

  @override
  State<CloudRadarScreen> createState() => _CloudRadarScreenState();
}

class _CloudRadarScreenState extends State<CloudRadarScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _sweep;

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Live Server Sync Radar',
          style: TextStyle(color: Colors.greenAccent, fontSize: 16),
        ),
        backgroundColor: Colors.black,
      ),
      body: BlocBuilder<CloudRadarBloc, RadarState>(
        builder: (context, state) {
          if (state is RadarConnecting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            );
          } else if (state is RadarStreamFailure) {
            return Center(
              child: Text(
                state.error,
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          } else if (state is RadarStreamingActive) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: AnimatedBuilder(
                    animation: _sweep,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: ServerRadarPainter(
                          sweepAngle: _sweep.value * 2 * math.pi,
                          detectedTargets: state.liveTargets,
                        ),
                        child: const SizedBox(width: 300, height: 300),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  "Active Network Nodes Inside Boundary: ${state.liveTargets.length}",
                  style: const TextStyle(color: Colors.greenAccent),
                ),
              ],
            );
          }
          return const Center(
            child: Text(
              "Binding network channel parameters...",
              style: TextStyle(color: Colors.grey),
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// 4. GRAPHICS TELEMETRY RENDER PANEL (CUSTOM PAINTER)
// ==========================================

class ServerRadarPainter extends CustomPainter {
  final double sweepAngle;
  final List<RadarTarget> detectedTargets;

  ServerRadarPainter({required this.sweepAngle, required this.detectedTargets});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2);

    final linePaint = Paint()
      ..color = Colors.green.withOpacity(0.2)
      ..style = PaintingStyle.stroke;

    // Draw Calibration Structural Wireframes
    canvas.drawCircle(center, radius, linePaint);
    canvas.drawCircle(center, radius * 0.5, linePaint);
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      linePaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      linePaint,
    );
    // Dynamic Live Cloud Node Plotting Engine
    for (var target in detectedTargets) {
      double targetX =
          center.dx +
          (radius * target.distanceRatio) * math.cos(target.angleInRadians);
      double targetY =
          center.dy +
          (radius * target.distanceRatio) * math.sin(target.angleInRadians);
      double angleDiff = (sweepAngle - target.angleInRadians) % (2 * math.pi);
      if (angleDiff < 0) angleDiff += 2 * math.pi;
      double opacity = 0.0;
      if (angleDiff < math.pi / 2) {
        opacity = 1.0 - (angleDiff / (math.pi / 2));
      }
      if (opacity > 0.05) {
        // Cyan Accent variant signaling verified remote external server nodes
        canvas.drawCircle(
          Offset(targetX, targetY),
          10,
          Paint()..color = Colors.cyanAccent.withOpacity(opacity * 0.3),
        );
        canvas.drawCircle(
          Offset(targetX, targetY),
          4,
          Paint()..color = Colors.cyanAccent.withOpacity(opacity),
        );
      }
    }
    // Sweeping Laser Core Beam configuration
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        colors: [Colors.green.withOpacity(0.4), Colors.green.withOpacity(0.0)],
        stops: const [0.0, 0.2],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(sweepAngle);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawCircle(center, radius, sweepPaint);
    canvas.restore();
    canvas.drawCircle(center, 4, Paint()..color = Colors.greenAccent);
  }

  @override
  bool shouldRepaint(covariant ServerRadarPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle ||
        oldDelegate.detectedTargets != detectedTargets;
  }
}
