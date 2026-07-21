import 'dart:math';

import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: PotentiometerScreen()));

class PotentiometerScreen extends StatefulWidget {
  const PotentiometerScreen({super.key});

  @override
  State<PotentiometerScreen> createState() => _PotentiometerScreenState();
}

class _PotentiometerScreenState extends State<PotentiometerScreen> {
  double _value = 0.0; // Current potentiometer value (0.0 to 100.0)

  void _updateValue(Offset localPosition, Size size) {
    // Calculate the center point of the widget
    final center = Offset(size.width / 2, size.height / 2);

    // Get coordinates relative to center
    final x = localPosition.dx - center.dx;
    final y = localPosition.dy - center.dy; // standard Cartesian mapping below

    // Calculate angle in radians and convert to degrees
    double angle = atan2(y, x) * 180 / pi;

    // Shift angle so 0 degrees starts at the bottom or left matching your graph look
    angle = (angle + 90) % 360;
    if (angle < 0) angle += 360;

    // Map the 360 degree rotation to a 0-100 scale
    setState(() {
      _value = (angle / 360) * 100;
    });
  }

  @override
  Widget build(BuildContext context) {
    const double dialSize = 250.0;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: const Text('Potentiometer Graph'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display Current Value
            Text(
              '${_value.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 40,
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),

            // Interactive Potentiometer Graph
            GestureDetector(
              onPanUpdate: (details) => _updateValue(
                details.localPosition,
                const Size(dialSize, dialSize),
              ),
              onPanDown: (details) => _updateValue(
                details.localPosition,
                const Size(dialSize, dialSize),
              ),
              child: SizedBox(
                width: dialSize,
                height: dialSize,
                child: CustomPaint(
                  painter: PotentiometerPainter(value: _value),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PotentiometerPainter extends CustomPainter {
  final double value;
  PotentiometerPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);

    // 1. Draw Outer Background Track
    final trackPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0;
    canvas.drawCircle(center, radius - 10, trackPaint);

    // 2. Draw Colored Progress Arc Graph
    final progressPaint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round;

    double sweepAngle = (value / 100) * 2 * pi;
    // -pi / 2 shifts the start point to the top (12 o'clock position)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    // 3. Draw Center Rotating Knob
    final knobPaint = Paint()
      ..color = const Color(0xFF2D2D44)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 25, knobPaint);

    // 4. Draw Knob Pointer Indicator Dot
    final indicatorPaint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.fill;

    // Find the position of the dot indicator based on current angle
    double indicatorAngle = (-pi / 2) + sweepAngle;
    double dotX = center.dx + (radius - 40) * cos(indicatorAngle);
    double dotY = center.dy + (radius - 40) * sin(indicatorAngle);

    canvas.drawCircle(Offset(dotX, dotY), 7, indicatorPaint);
  }

  @override
  bool shouldRepaint(covariant PotentiometerPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
