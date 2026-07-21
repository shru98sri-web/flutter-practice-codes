import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(
    const MaterialApp(home: RadarAppGrid(), debugShowCheckedModeBanner: false),
  );
}

// ==========================================
// 1. DATA MODELS
// ==========================================

/// Source Geographic target structural contract representing absolute real-world data points
class GeoTarget {
  final String id;
  final double latitude;
  final double longitude;

  GeoTarget({
    required this.id,
    required this.latitude,
    required this.longitude,
  });
}

/// Transformed target optimized strictly for local UI Canvas Polar space mapping
class RadarTarget {
  final String id;
  final double
  distanceRatio; // Scale factor from center point (Normalized 0.0 to 1.0)
  final double angleInRadians; // Radial vector projection index (0 to 2*pi)

  RadarTarget({
    required this.id,
    required this.distanceRatio,
    required this.angleInRadians,
  });
}

// ==========================================
// 2. STATE MANAGEMENT (BLOC ARCHITECTURE)
// ==========================================

// Events
abstract class RadarEvent {}

class StartRadarTracking extends RadarEvent {}

class UpdateUserLocation extends RadarEvent {
  final Position position;
  UpdateUserLocation(this.position);
}

class RadarTrackingError extends RadarEvent {
  final String message;
  RadarTrackingError(this.message);
}

// States
abstract class RadarState {}

class RadarInitial extends RadarState {}

class RadarLoading extends RadarState {}

class RadarTracked extends RadarState {
  final Position userPosition;
  final List<RadarTarget>
  radarTargets; // Fully computed coordinate telemetry payload

  RadarTracked({required this.userPosition, required this.radarTargets});
}

class RadarFailure extends RadarState {
  final String errorMessage;
  RadarFailure(this.errorMessage);
}

// Business Logic Component (BLoC Engine)
class RadarBloc extends Bloc<RadarEvent, RadarState> {
  StreamSubscription<Position>? _gpsStreamSubscription;

  // Simulated static reference points near Chennai, India context
  // Adjust these to coordinates within 500 meters of your physical test region
  final List<GeoTarget> _mockStaticTargets = [
    GeoTarget(id: "Target_Alpha", latitude: 13.0835, longitude: 80.2710),
    GeoTarget(id: "Target_Bravo", latitude: 13.0810, longitude: 80.2745),
    GeoTarget(id: "Target_Charlie", latitude: 13.0860, longitude: 80.2730),
  ];

  // Maximum physical target visibility tracking ceiling perimeter boundary (500 Meters)
  final double maxRadarRangeInMeters = 500.0;

  RadarBloc() : super(RadarInitial()) {
    on<StartRadarTracking>(_onStartTracking);
    on<UpdateUserLocation>(_onUpdateLocation);
    on<RadarTrackingError>(_onHandleError);
  }

  Future<void> _onStartTracking(
    StartRadarTracking event,
    Emitter<RadarState> emit,
  ) async {
    emit(RadarLoading());
    try {
      // Validate device hardware availability and explicit runtime manifest authorizations
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled)
        return emit(
          RadarFailure("Hardware failure: Please enable device GPS Services."),
        );

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return emit(
            RadarFailure(
              "Security verification rejected: Location permission denied.",
            ),
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return emit(
          RadarFailure(
            "Security Lock: Permission permanently denied. Alter settings manually.",
          ),
        );
      }

      // Initialize persistent pipeline processing sub-link at maximum precision parameters
      _gpsStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter:
                  2, // Emits downstream updates only when the user crosses a 2-meter delta
            ),
          ).listen(
            (Position position) => add(UpdateUserLocation(position)),
            onError: (error) => add(RadarTrackingError(error.toString())),
          );
    } catch (e) {
      emit(RadarFailure("Pipeline initiation initialization crash: $e"));
    }
  }

  void _onUpdateLocation(UpdateUserLocation event, Emitter<RadarState> emit) {
    final userPos = event.position;
    List<RadarTarget> convertedTargets = [];

    for (var geoTarget in _mockStaticTargets) {
      // Calculate real-world geodesic distance using the Haversine formula internally
      double distanceInMeters = Geolocator.distanceBetween(
        userPos.latitude,
        userPos.longitude,
        geoTarget.latitude,
        geoTarget.longitude,
      );

      // Filter out assets positioned beyond the tracking boundary scope limits
      if (distanceInMeters <= maxRadarRangeInMeters) {
        // Normalize linear scale parameter into custom canvas sizing ratios
        double distanceRatio = distanceInMeters / maxRadarRangeInMeters;

        // Calculate heading relative to true north between coordinates
        double bearing = Geolocator.bearingBetween(
          userPos.latitude,
          userPos.longitude,
          geoTarget.latitude,
          geoTarget.longitude,
        );

        // Map compass bearings (-180 to 180) to Cartesian radians matching standard UI custom layouts
        double angleInRadians = (bearing - 90) * (math.pi / 180);

        convertedTargets.add(
          RadarTarget(
            id: geoTarget.id,
            distanceRatio: distanceRatio,
            angleInRadians: angleInRadians,
          ),
        );
      }
    }

    emit(RadarTracked(userPosition: userPos, radarTargets: convertedTargets));
  }

  void _onHandleError(RadarTrackingError event, Emitter<RadarState> emit) {
    emit(RadarFailure(event.message));
  }

  @override
  Future<void> close() {
    _gpsStreamSubscription
        ?.cancel(); // Terminate sub-channel to mitigate memory leak vectors
    return super.close();
  }
}

// ==========================================
// 3. USER INTERFACE LAYER
// ==========================================

class RadarAppGrid extends StatelessWidget {
  const RadarAppGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RadarBloc()..add(StartRadarTracking()),
      child: const RadarScreen(),
    );
  }
}

class RadarScreen extends StatefulWidget {
  const RadarScreen({super.key});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _sweepController;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Live GPS Radar Pipeline',
          style: TextStyle(color: Colors.greenAccent, fontSize: 18),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: BlocBuilder<RadarBloc, RadarState>(
        builder: (context, state) {
          if (state is RadarLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            );
          } else if (state is RadarFailure) {
            return Center(
              child: Text(
                state.errorMessage,
                style: const TextStyle(color: Colors.redAccent, fontSize: 16),
              ),
            );
          } else if (state is RadarTracked) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Display Canvas Window Panel Component
                Center(
                  child: AnimatedBuilder(
                    animation: _sweepController,
                    builder: (context, child) {
                      double currentSweep =
                          _sweepController.value * 2 * math.pi;
                      return CustomPaint(
                        painter: TelemetryRadarPainter(
                          sweepAngle: currentSweep,
                          detectedTargets: state.radarTargets,
                        ),
                        child: const SizedBox(width: 320, height: 320),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
                // Live Telemetry Readout Widget
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.05),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Origin Center Vector Reference:",
                        style: TextStyle(
                          color: Colors.greenAccent.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        "Lat: ${state.userPosition.latitude.toStringAsFixed(5)} | Long: ${state.userPosition.longitude.toStringAsFixed(5)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const Divider(color: Colors.green, thickness: 0.3),
                      Text(
                        "Active Tracked Matrix Nodes: ${state.radarTargets.length}",
                        style: const TextStyle(color: Colors.greenAccent),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          return const Center(
            child: Text(
              "Acquiring initial satellite fix...",
              style: TextStyle(color: Colors.white),
            ),
          );
        },
      ),
    );
  }
}

// ================================================== // 4. RENDERING GRAPHICS LAYER (CUSTOM PAINTER) // =========================================
class TelemetryRadarPainter extends CustomPainter {
  final double sweepAngle;
  final List detectedTargets;
  TelemetryRadarPainter({
    required this.sweepAngle,
    required this.detectedTargets,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2);
    // Concentric Calibration Rings Layout configuration
    final gridPaint = Paint()
      ..color = Colors.green.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius, gridPaint);
    canvas.drawCircle(center, radius * 0.66, gridPaint);
    canvas.drawCircle(center, radius * 0.33, gridPaint);
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      gridPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      gridPaint,
    ); // Draw Live Telemetry Array Nodes
    for (var target in detectedTargets) {
      // Polar to Cartesian Space Matrix Transformation conversion formulas
      double targetX =
          center.dx +
          (radius * target.distanceRatio) * math.cos(target.angleInRadians);
      double targetY =
          center.dy +
          (radius * target.distanceRatio) * math.sin(target.angleInRadians);
      Offset targetOffset = Offset(
        targetX,
        targetY,
      ); // Scan beam relative distance difference validation configuration
      double angleDiff = (sweepAngle - target.angleInRadians) % (2 * math.pi);
      if (angleDiff < 0) angleDiff += 2 * math.pi;
      double opacity = 0.0;
      if (angleDiff < math.pi / 2) {
        opacity = 1.0 - (angleDiff / (math.pi / 2));
        // 90-degree quadrant phosphorescence fall-off decay curve
      }
      if (opacity > 0.05) {
        // Render target outer glow bloom element
        canvas.drawCircle(
          targetOffset,
          12,
          Paint()..color = Colors.redAccent.withOpacity(opacity * 0.3),
        );
        // Render target central registration node core dot
        canvas.drawCircle(
          targetOffset,
          5,
          Paint()..color = Colors.redAccent.withOpacity(opacity),
        );
      }
    }
    // Rotating Sweep Laser Shading Matrix Execution
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        colors: [Colors.green.withOpacity(0.5), Colors.green.withOpacity(0.0)],
        stops: const [0.0, 0.25],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(sweepAngle);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawCircle(center, radius, sweepPaint);
    canvas.restore();
    // Host position initialization pin point
    canvas.drawCircle(center, 5, Paint()..color = Colors.greenAccent);
  }

  @override
  bool shouldRepaint(covariant TelemetryRadarPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle ||
        oldDelegate.detectedTargets != detectedTargets;
  }
}
