import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() => runApp(const PointCloudApp());

class PointCloudApp extends StatelessWidget {
  const PointCloudApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF111115),
      ),
      home: const PointCloudScreen(),
    );
  }
}

class PointCloudScreen extends StatefulWidget {
  const PointCloudScreen({super.key});

  @override
  State<PointCloudScreen> createState() => _PointCloudScreenState();
}

class _PointCloudScreenState extends State<PointCloudScreen> {
  // Viewing angles for 3D rotation manipulation
  double yaw = -0.6; // Horizontal rotation (radians)
  double pitch = 0.8; // Vertical tilt rotation (radians)
  double scale = 12.0; // Zoom multiplier factor

  // Seed dataset arrays
  List<Vector3D> groundPoints = [];
  List<List<Vector3D>> pillars = [];
  List<Vector3D> trajectory = [];

  @override
  void initState() {
    super.initState();
    _generateMockLidarData();
  }

  void _generateMockLidarData() {
    final random = math.Random(42);

    // 1. Generate sparse ground point cloud landscape
    for (int i = 0; i < 1500; i++) {
      double x = random.nextDouble() * 30 - 10; // -10 to +20
      double y = random.nextDouble() * 30 - 20; // -20 to +10
      // Slight surface noise wave
      double z = math.sin(x / 4) * math.cos(y / 4) * 0.3 - 0.5;
      groundPoints.add(Vector3D(x, y, z));
    }

    // 2. Generate systematic array of vertical forest/structural pillars
    for (double px = -6; px <= 16; px += 4) {
      for (double py = -16; py <= 6; py += 4) {
        // Skip random centers to mimic natural clearance space
        if ((px - 5).abs() < 4 && (py + 5).abs() < 4) continue;

        List<Vector3D> pillarSegments = [];
        double heightMax = 1.5 + random.nextDouble() * 1.5;
        for (double pz = -0.5; pz <= heightMax; pz += 0.15) {
          // Add micro-jitter scatter around the trunk structure
          double rX = px + (random.nextDouble() - 0.5) * 0.4;
          double rY = py + (random.nextDouble() - 0.5) * 0.4;
          pillarSegments.add(Vector3D(rX, rY, pz));
        }
        pillars.add(pillarSegments);
      }
    }

    // 3. Construct a continuous looping trajectory path tracking around the core
    for (int i = 0; i <= 120; i++) {
      double angle = (i / 120) * 2 * math.pi;
      // Define an asymmetric loop trajectory path geometry
      double x = 5.0 + 8.0 * math.cos(angle) + 2.0 * math.sin(2 * angle);
      double y = -5.0 + 7.0 * math.sin(angle);
      double z = 0.2 + 0.3 * math.sin(3 * angle);
      trajectory.add(Vector3D(x, y, z));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Interactive 3D drag surface capture region
            GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  yaw += details.delta.dx * 0.007;
                  pitch = (pitch + details.delta.dy * 0.007).clamp(
                    0.1,
                    math.pi / 2 - 0.05,
                  );
                });
              },
              child: Container(
                color: Colors.transparent,
                width: double.infinity,
                height: double.infinity,
                child: CustomPaint(
                  painter: PointCloud3DPainter(
                    yaw: yaw,
                    pitch: pitch,
                    scale: scale,
                    groundPoints: groundPoints,
                    pillars: pillars,
                    trajectory: trajectory,
                  ),
                ),
              ),
            ),

            // Floating UI Control Instructions HUD Overlay
            const Positioned(
              top: 20,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "LiDAR 3D Point Cloud Scene",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "➔ Drag viewport surface to rotate in 3D Space",
                    style: TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Vector3D {
  final double x, y, z;
  Vector3D(this.x, this.y, this.z);
}

class PointCloud3DPainter extends CustomPainter {
  final double yaw;
  final double pitch;
  final double scale;
  final List<Vector3D> groundPoints;
  final List<List<Vector3D>> pillars;
  final List<Vector3D> trajectory;

  PointCloud3DPainter({
    required this.yaw,
    required this.pitch,
    required this.scale,
    required this.groundPoints,
    required this.pillars,
    required this.trajectory,
  });

  // True mathematical 3D orthographic projection pipeline map coordinate transformation
  Offset _project(Vector3D v, Size size) {
    final double midX = size.width / 2;
    final double midY = size.height / 2 + 30;

    // Apply Yaw (Z-axis horizontal rotation)
    double cosY = math.cos(yaw);
    double sinY = math.sin(yaw);
    double x1 = v.x * cosY - v.y * sinY;
    double y1 = v.x * sinY + v.y * cosY;

    // Apply Pitch (X-axis vertical tilt view rotation)
    double cosP = math.cos(pitch);
    double sinP = math.sin(pitch);
    double xFinal = x1;
    double yFinal = y1 * cosP - v.z * sinP;

    // Scale to device pixel layout positions
    return Offset(midX + xFinal * scale, midY + yFinal * scale);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw 3D Spatial Grid Framework Matrix (Bounding Cage)
    final gridPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1.0;

    final List<double> xTicks = [-10, -5, 0, 5, 10, 15, 20];
    final List<double> yTicks = [-20, -15, -10, -5, 0, 5, 10];

    // Horizontal floor grid lines layout loop execution
    for (double x in xTicks) {
      canvas.drawLine(
        _project(Vector3D(x, -20, -1.0), size),
        _project(Vector3D(x, 10, -1.0), size),
        gridPaint,
      );
    }
    for (double y in yTicks) {
      canvas.drawLine(
        _project(Vector3D(-10, y, -1.0), size),
        _project(Vector3D(20, y, -1.0), size),
        gridPaint,
      );
    }

    // 2. Draw Sparse Background Surface Point Cloud
    final scatterPaint = Paint()..strokeWidth = 1.5;
    for (var pt in groundPoints) {
      scatterPaint.color = _getHeightColor(pt.z);
      canvas.drawCircle(_project(pt, size), 1.0, scatterPaint);
    }

    // 3. Draw Vertical Elevation Point Cloud Pillars
    final pillarPaint = Paint()..strokeWidth = 2.5;
    for (var pillar in pillars) {
      for (var node in pillar) {
        pillarPaint.color = _getHeightColor(node.z);
        canvas.drawCircle(_project(node, size), 1.5, pillarPaint);
      }
    }

    // 4. Draw Continuous Central Trajectory Loop
    final trajPaint = Paint()
      ..color = const Color(0xFFFF3B30)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final Path trajPath = Path();
    for (int i = 0; i < trajectory.length; i++) {
      Offset projPos = _project(trajectory[i], size);
      if (i == 0) {
        trajPath.moveTo(projPos.dx, projPos.dy);
      } else {
        trajPath.lineTo(projPos.dx, projPos.dy);
      }
    }
    canvas.drawPath(trajPath, trajPaint);

    // 5. Draw Axis Labels Metadata Tags (X and Y vectors anchor labels)
    _drawAxisLabel(canvas, _project(Vector3D(22, -5, -1.0), size), "X");
    _drawAxisLabel(canvas, _project(Vector3D(5, 12, -1.0), size), "Y");
    _drawAxisLabel(canvas, _project(Vector3D(-10, -20, 2.5), size), "Z");
  }

  // Dynamic scientific pseudo-color map generation loop based on height thresholds
  Color _getHeightColor(double z) {
    if (z < -0.2) return Colors.blue.withAlpha(180);
    if (z < 0.3) return Colors.cyan.withAlpha(210);
    if (z < 1.0) return Colors.greenAccent;
    if (z < 1.8) return Colors.yellowAccent;
    return Colors.redAccent;
  }

  void _drawAxisLabel(Canvas canvas, Offset pos, String label) {
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant PointCloud3DPainter oldDelegate) {
    return oldDelegate.yaw != yaw ||
        oldDelegate.pitch != pitch ||
        oldDelegate.scale != scale;
  }
}
