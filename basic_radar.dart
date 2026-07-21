import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(home: RadarScreen(), debugShowCheckedModeBanner: false),
  );
}

class RadarScreen extends StatefulWidget {
  const RadarScreen({super.key});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Animation controller for continuous 360-degree rotation (looping)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
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
          'Radar Signal Imaging',
          style: TextStyle(color: Colors.greenAccent),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              // Passes the current rotating angle to the painter
              painter: RadarPainter(_controller.value * 2 * math.pi),
              child: const SizedBox(width: 300, height: 300),
            );
          },
        ),
      ),
    );
  }
}

// Custom Painter class responsible for rendering the radar grid and signal sweep
class RadarPainter extends CustomPainter {
  final double sweepAngle;
  RadarPainter(this.sweepAngle);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2);

    // 1. Drawing the Background Grid Design
    final gridPaint = Paint()
      ..color = Colors.green.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw three concentric grid circles
    canvas.drawCircle(center, radius, gridPaint);
    canvas.drawCircle(center, radius * 0.66, gridPaint);
    canvas.drawCircle(center, radius * 0.33, gridPaint);

    // Draw Crosshair Lines (X and Y Axis)
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

    // 2. Drawing the Rotating Sweep (Sweeping Gradient)
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0.0,
        endAngle: 2 * math.pi,
        colors: [
          Colors.green.withOpacity(
            0.8,
          ), // Bright leading edge of the radar signal
          Colors.green.withOpacity(0.0), // Fading tail
        ],
        stops: const [
          0.0,
          0.25,
        ], // Controls the width/spread of the signal trail
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    // Rotate the canvas dynamically based on the current animation angle
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(sweepAngle);
    canvas.translate(-center.dx, -center.dy);

    // Render the radar sweep effect
    canvas.drawCircle(center, radius, sweepPaint);
    canvas.restore();

    // 3. Drawing the Center Core Point (Origin Dot)
    final centerDotPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, centerDotPaint);
  }

  @override
  bool shouldRepaint(covariant RadarPainter oldDelegate) {
    // Ensures the canvas repaints smoothly on every animation tick
    return oldDelegate.sweepAngle != sweepAngle;
  }
}
