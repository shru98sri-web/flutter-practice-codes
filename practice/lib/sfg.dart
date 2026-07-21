import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  runApp(const SFGApp());
}

class SFGApp extends StatelessWidget {
  const SFGApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SFG Visualization',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
      ),
      home: const SFGAnimationScreen(),
    );
  }
}

class SFGAnimationScreen extends StatefulWidget {
  const SFGAnimationScreen({super.key});

  @override
  State<SFGAnimationScreen> createState() => _SFGAnimationScreenState();
}

class _SFGAnimationScreenState extends State<SFGAnimationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _omega1 = 1.0;
  double _omega2 = 2.0;

  @override
  void initState() {
    super.initState();
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
    double omegaSum = _omega1 + _omega2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sum Frequency Generation (SFG)'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: SFGWavePainter(
                      omega1: _omega1,
                      omega2: _omega2,
                      omegaSum: omegaSum,
                      phase: _controller.value * 2 * math.pi,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSlider(
                    label: 'ω₁',
                    value: _omega1,
                    min: 0.5,
                    max: 5.0,
                    color: Colors.cyan,
                    onChanged: (val) => setState(() => _omega1 = val),
                  ),
                  const SizedBox(height: 10),
                  _buildSlider(
                    label: 'ω₂',
                    value: _omega2,
                    min: 0.5,
                    max: 5.0,
                    color: Colors.orange,
                    onChanged: (val) => setState(() => _omega2 = val),
                  ),
                  const Divider(color: Colors.white24, height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'ω_sum (ω₁ + ω₂): ',
                        style: TextStyle(fontSize: 18, color: Colors.white70),
                      ),
                      Text(
                        omegaSum.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.purpleAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            activeColor: color,
            inactiveColor: color.withOpacity(0.2),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 45,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              value.toStringAsFixed(1),
              style: const TextStyle(fontSize: 16, fontFamily: 'monospace'),
            ),
          ),
        ),
      ],
    );
  }
}

class SFGWavePainter extends CustomPainter {
  final double omega1;
  final double omega2;
  final double omegaSum;
  final double phase;

  SFGWavePainter({
    required this.omega1,
    required this.omega2,
    required this.omegaSum,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final double sectionHeight = size.height / 3;

    // १. पहिली लाट (Wave 1 - ω₁)
    paint.color = Colors.cyan;
    _drawWave(canvas, size, sectionHeight * 0.5, omega1, paint);
    _drawLabel(canvas, "Input ω₁", 20, sectionHeight * 0.5 - 30, Colors.cyan);

    // २. दुसरी लाट (Wave 2 - ω₂)
    paint.color = Colors.orange;
    _drawWave(canvas, size, sectionHeight * 1.5, omega2, paint);
    _drawLabel(canvas, "Input ω₂", 20, sectionHeight * 1.5 - 30, Colors.orange);

    // ३. एकत्रित बेरीज लाट (Sum Wave - ω_sum)
    paint.color = Colors.purpleAccent;
    _drawWave(canvas, size, sectionHeight * 2.5, omegaSum, paint);
    _drawLabel(
      canvas,
      "Output ω_sum",
      20,
      sectionHeight * 2.5 - 30,
      Colors.purpleAccent,
    );
  }

  void _drawWave(
    Canvas canvas,
    Size size,
    double yOffset,
    double frequency,
    Paint paint,
  ) {
    final path = Path();
    final double amplitude = size.height / 10;

    path.moveTo(0, yOffset);

    for (double x = 0; x <= size.width; x++) {
      // k (वेव्ह नंबर) आणि फेजच्या सहाय्याने अचूक सिग्नल्स तयार करणे
      double angle = (x * frequency * 0.04) - phase;
      double y = yOffset + math.sin(angle) * amplitude;
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  void _drawLabel(Canvas canvas, String text, double x, double y, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant SFGWavePainter oldDelegate) {
    return oldDelegate.omega1 != omega1 ||
        oldDelegate.omega2 != omega2 ||
        oldDelegate.omegaSum != omegaSum ||
        oldDelegate.phase != phase;
  }
}
