import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MarangoniEffectScreen(),
    ),
  );
}

class MarangoniEffectScreen extends StatefulWidget {
  const MarangoniEffectScreen({super.key});

  @override
  State<MarangoniEffectScreen> createState() => _MarangoniEffectScreenState();
}

class _MarangoniEffectScreenState extends State<MarangoniEffectScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Controls the speed and loop of the surface wave/flow
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: const Size(350, 350),
              painter: MarangoniPainter(_controller.value),
            );
          },
        ),
      ),
    );
  }
}

class MarangoniPainter extends CustomPainter {
  final double animationValue;

  MarangoniPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.cyanAccent, Colors.blueAccent, Colors.purple],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final Path path = Path();
    final double waveLength = size.width / 2;
    final double waveHeight = 20.0;

    // Starting point
    path.moveTo(0, size.height);

    // Generating the flowing/fluttering wave path
    for (double i = 0; i <= size.width; i++) {
      // The Marangoni effect equation component (sine wave shifted by time)
      double y =
          size.height / 2 +
          sin((i / waveLength) + (animationValue * 2 * pi)) * waveHeight;
      path.lineTo(i, y);
    }

    // Connect the path to form a filled "liquid" container
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Clip to a circle to simulate a liquid drop or confined space
    final Path clipPath = Path()
      ..addOval(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.clipPath(clipPath);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant MarangoniPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
