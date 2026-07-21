import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(home: RadarScreen(), debugShowCheckedModeBanner: false),
  );
}

// Data Model for targets detected on the radar
class RadarTarget {
  final double distanceRatio; // Distance from center (0.0 to 1.0)
  final double angleInRadians; // Angular direction in radians (0 to 2*pi)
  final double size; // Visual size of the target dot

  RadarTarget({
    required this.distanceRatio,
    required this.angleInRadians,
    this.size = 5.0,
  });
}

class RadarScreen extends StatefulWidget {
  const RadarScreen({super.key});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Simulated list of target objects detected at specific locations
  final List<RadarTarget> targets = [
    RadarTarget(distanceRatio: 0.4, angleInRadians: math.pi / 4), // 45 degrees
    RadarTarget(distanceRatio: 0.7, angleInRadians: math.pi), // 180 degrees
    RadarTarget(
      distanceRatio: 0.25,
      angleInRadians: 1.5 * math.pi,
    ), // 270 degrees
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // Speed of one complete sweep
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Dynamic Radar Mapping',
          style: TextStyle(color: Colors.greenAccent),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            double currentSweep = _controller.value * 2 * math.pi;

            return CustomPaint(
              painter: RadarPainter(
                sweepAngle: currentSweep,
                detectedTargets: targets,
              ),
              child: const SizedBox(width: 320, height: 320),
            );
          },
        ),
      ),
    );
  }
}

class RadarPainter extends CustomPainter {
  final double sweepAngle;
  final List<RadarTarget> detectedTargets;

  RadarPainter({required this.sweepAngle, required this.detectedTargets});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2);

    // 1. Draw Background Radar Grid
    final gridPaint = Paint()
      ..color = Colors.green.withOpacity(0.2)
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
    );

    // 2. Map and Render Target Dots
    for (var target in detectedTargets) {
      // Convert polar coordinates to Cartesian (X, Y) canvas coordinates
      double targetX =
          center.dx +
          (radius * target.distanceRatio) * math.cos(target.angleInRadians);
      double targetY =
          center.dy +
          (radius * target.distanceRatio) * math.sin(target.angleInRadians);
      Offset targetOffset = Offset(targetX, targetY);

      // Calculate angular distance between the sweep line and the target object
      double angleDiff = (sweepAngle - target.angleInRadians) % (2 * math.pi);
      if (angleDiff < 0) angleDiff += 2 * math.pi;

      // Calculate fade visibility based on trailing distance of the sweep line
      double opacity = 0.0;
      if (angleDiff < math.pi / 2) {
        opacity =
            1.0 -
            (angleDiff /
                (math.pi / 2)); // Smooth fade within a 90-degree quadrant arc
      }

      // Draw the target only if it should be visible
      if (opacity > 0.05) {
        // Soft outer radar glow effect
        final targetGlow = Paint()
          ..color = Colors.redAccent.withOpacity(opacity * 0.4)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(targetOffset, target.size * 2.5, targetGlow);

        // Solid inner core target blip
        final targetCore = Paint()
          ..color = Colors.redAccent.withOpacity(opacity)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(targetOffset, target.size, targetCore);
      }
    }

    // 3. Draw The Rotating Sweep Shader
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0.0,
        endAngle: 2 * math.pi,
        colors: [Colors.green.withOpacity(0.6), Colors.green.withOpacity(0.0)],
        stops: const [0.0, 0.2],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(sweepAngle);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawCircle(center, radius, sweepPaint);
    canvas.restore();

    // 4. Center Core Pinpoint
    final centerDotPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, centerDotPaint);
  }

  @override
  bool shouldRepaint(covariant RadarPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle ||
        oldDelegate.detectedTargets != detectedTargets;
  }
}
