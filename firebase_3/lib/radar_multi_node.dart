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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    const MaterialApp(home: LiveRadarApp(), debugShowCheckedModeBanner: false),
  );
}

// ==========================================
// 1. ADVANCED TELEMETRY DATA MODELS
// ==========================================

class RadarTarget {
  final String id;
  final String nodeName;
  final double distanceRatio;
  final double angleInRadians;
  final double actualDistance;
  final String signalStrength;

  RadarTarget({
    required this.id,
    required this.nodeName,
    required this.distanceRatio,
    required this.angleInRadians,
    required this.actualDistance,
    required this.signalStrength,
  });
}

// ==========================================
// 2. BLOC STATE MANAGEMENT WITH SIMULATOR
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

  // Tracking range increased to 5000 meters (5 km) to discover more distant nodes
  final double trackingRangeMeters = 5000.0;

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
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return add(
            CloudRadarError("Location access permission is required."),
          );
        }
      }

      _gpsSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 2,
            ),
          ).listen(
            (Position position) {
              // 1. Update own master telemetry array data back onto the remote node collection
              _firestore
                  .collection('users_radar')
                  .doc(event.currentUserId)
                  .set({
                    'userId': event.currentUserId,
                    'nodeName': 'HQ Master Control',
                    'latitude': position.latitude,
                    'longitude': position.longitude,
                    'lastUpdated': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));

              // 2. Mock node injector system (Simulates 5 custom tactical nodes around your current position)
              _injectMockSurroundingNodes(position);

              // 3. Establish reactive subscription stream to download all network matrix node documents
              _firestoreSubscription?.cancel();
              _firestoreSubscription = _firestore
                  .collection('users_radar')
                  .snapshots()
                  .listen(
                    (QuerySnapshot snapshot) =>
                        add(SyncCloudData(position, snapshot.docs)),
                    onError: (err) => add(
                      CloudRadarError("Remote network sync failure: $err"),
                    ),
                  );
            },
            onError: (err) =>
                add(CloudRadarError("GPS Telemetry signal dropped: $err")),
          );
    } catch (e) {
      add(
        CloudRadarError("Radar hardware pipeline initialization failure: $e"),
      );
    }
  }

  void _onSyncCloudData(SyncCloudData event, Emitter<RadarState> emit) {
    List<RadarTarget> mappedTargets = [];

    for (var doc in event.cloudDocs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null || data['userId'] == null || data['userId'] == "User_Me")
        continue;

      double targetLat = (data['latitude'] as num).toDouble();
      double targetLng = (data['longitude'] as num).toDouble();

      // Geodesic Vector Tracking Distance calculation via Haversine model
      double distance = Geolocator.distanceBetween(
        event.userPosition.latitude,
        event.userPosition.longitude,
        targetLat,
        targetLng,
      );

      // Verify geofence perimeter sweep limit parameters
      if (distance <= trackingRangeMeters) {
        double ratio = distance / trackingRangeMeters;
        double bearing = Geolocator.bearingBetween(
          event.userPosition.latitude,
          event.userPosition.longitude,
          targetLat,
          targetLng,
        );
        double radians = (bearing - 90) * (math.pi / 180);

        // Signal strength calculation derived from target proximity bounds
        String signal = distance < 1500
            ? "STRONG"
            : (distance < 3500 ? "STABLE" : "WEAK");

        mappedTargets.add(
          RadarTarget(
            id: doc.id,
            nodeName: data['nodeName'] ?? 'Unknown Drone Node',
            distanceRatio: ratio,
            angleInRadians: radians,
            actualDistance: distance,
            signalStrength: signal,
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

  // Telemetry Engine Matrix Injector: Populates 5 artificial nodes within 5km of your active GPS coordinate
  void _injectMockSurroundingNodes(Position pos) {
    final List<Map<String, dynamic>> mockOffsets = [
      {
        'id': 'node_alpha',
        'name': 'Alpha Recon Drone',
        'lat': 0.015,
        'lng': 0.008,
      },
      {
        'id': 'node_bravo',
        'name': 'Bravo Interceptor',
        'lat': -0.022,
        'lng': 0.019,
      },
      {
        'id': 'node_charlie',
        'name': 'Charlie Support Truck',
        'lat': 0.009,
        'lng': -0.025,
      },
      {
        'id': 'node_delta',
        'name': 'Delta Outpost Base',
        'lat': -0.011,
        'lng': -0.012,
      },
      {
        'id': 'node_echo',
        'name': 'Echo Patrol Squad',
        'lat': 0.031,
        'lng': -0.002,
      },
    ];

    for (var mock in mockOffsets) {
      _firestore.collection('users_radar').doc(mock['id']).set({
        'userId': mock['id'],
        'nodeName': mock['name'],
        'latitude': pos.latitude + mock['lat'],
        'longitude': pos.longitude + mock['lng'],
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  @override
  Future<void> close() {
    _gpsSubscription?.cancel();
    _firestoreSubscription?.cancel();
    return super.close();
  }
}

// ==========================================
// 3. UI TREE WITH BACKGROUND MAP GRAPHICS
// ==========================================

class LiveRadarApp extends StatelessWidget {
  const LiveRadarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
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
  late AnimationController _radarSweep;

  @override
  void initState() {
    super.initState();
    _radarSweep = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _radarSweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030A05),
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
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (state is RadarStreamingActive) {
            return SafeArea(
              child: Column(
                children: [
                  // Top Control Center Telemetry Header Panel
                  _buildControlHeader(state),

                  // Main Core Radar Sweep and Map Canvas Layout
                  Expanded(
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // १. बॅकग्राउंड व्हर्च्युअल मॅप ग्रिड लेयर
                          Positioned.fill(
                            child: Opacity(
                              opacity: 0.15,
                              child: Container(
                                decoration: const BoxDecoration(
                                  image: DecorationImage(
                                    image: NetworkImage('https://unsplash.com'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // २. रडार पेंटर लेयर (Sweep Engine)
                          AnimatedBuilder(
                            animation: _radarSweep,
                            builder: (context, child) {
                              return CustomPaint(
                                size: const Size(360, 360),
                                painter: AdvancedRadarPainter(
                                  sweepAngle: _radarSweep.value * 2 * math.pi,
                                  targets: state.liveTargets,
                                ),
                              );
                            },
                          ),
                        ], // Stack ची मुले (Children) इथे व्यवस्थित बंद झाली आहेत
                      ),
                    ),
                  ), // Expanded इथे व्यवस्थित बंद झाला आहे
                  // ३. बॉटम पॅनेल: मल्टिपल नोड्सची सविस्तर यादी (हा भाग आता एररशिवाय चालेल)
                  _buildTargetNodeList(state.liveTargets),
                ],
              ),
            );
          }
          return const Center(
            child: Text(
              "Acquiring Satellite Telemetry Link...",
              style: TextStyle(color: Colors.grey),
            ),
          );
        },
      ),
    );
  }

  Widget _buildControlHeader(RadarStreamingActive state) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.black.withOpacity(0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "TACTICAL CLOUD RADAR",
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                "HQ GPS: ${state.myPosition.latitude.toStringAsFixed(4)}, ${state.myPosition.longitude.toStringAsFixed(4)}",
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.greenAccent),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  "LIVE NODES: ${state.liveTargets.length}",
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetNodeList(List targets) {
    return Container(
      height: 180,
      color: Colors.black.withOpacity(0.8),
      child: targets.isEmpty
          ? const Center(
              child: Text(
                "No Active Tracking Nodes in Sector Range",
                style: TextStyle(color: Colors.white24),
              ),
            )
          : ListView.builder(
              itemCount: targets.length,
              itemBuilder: (context, index) {
                final node = targets[index];
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A140E),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.hub_outlined,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    title: Text(
                      node.nodeName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "Distance: ${(node.actualDistance).toStringAsFixed(0)}m | Signal: ${node.signalStrength}",
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                    trailing: Text(
                      "${(node.distanceRatio * 100).toStringAsFixed(0)}% Range",
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ================================================= // 4. MAP GRID & RADAR CUSTOM PAINTER // =================================================
class AdvancedRadarPainter extends CustomPainter {
  final double sweepAngle;
  final List targets;
  AdvancedRadarPainter({required this.sweepAngle, required this.targets});
  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double maxRadius = size.width / 2;
    final gridPaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    // Tactical Coordinate Map Grid Overlay (Horizontal and Vertical vector metrics)
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        Paint()..color = Colors.greenAccent.withOpacity(0.05),
      );
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        Paint()..color = Colors.greenAccent.withOpacity(0.05),
      );
    }
    // 4 Concentric Radar Ring Ranges
    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, maxRadius * (i / 4), gridPaint);
    }
    // 360-Degree Sweep Effect (Gradient Shading Engine)
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [Colors.greenAccent.withOpacity(0.35), Colors.transparent],
        stops: const [0.0, 0.3],
        transform: GradientRotation(sweepAngle),
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));
    canvas.drawCircle(center, maxRadius, sweepPaint);
    // Multi-Node Spatial Tracking Matrix Rendering
    for (var target in targets) {
      double targetRadius = target.distanceRatio * maxRadius;
      double x = center.dx + targetRadius * math.cos(target.angleInRadians);
      double y =
          center.dy +
          targetRadius *
              math.sin(target.angleInRadians); // Core Target Node Blip
      canvas.drawCircle(Offset(x, y), 5.0, Paint()..color = Colors.redAccent);
      // Node Pulse Peripheral Waveform Vector Rings
      canvas.drawCircle(
        Offset(x, y),
        12.0,
        Paint()
          ..color = Colors.redAccent.withOpacity(0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
  }

  @override
  bool shouldRepaint(covariant AdvancedRadarPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle ||
        oldDelegate.targets != targets;
  }
}
