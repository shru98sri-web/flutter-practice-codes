import 'dart:math';

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const LaserPatternScreen(),
    );
  }
}

class LaserPatternScreen extends StatefulWidget {
  const LaserPatternScreen({super.key});

  @override
  State<LaserPatternScreen> createState() => _LaserPatternScreenState();
}

class _LaserPatternScreenState extends State<LaserPatternScreen> {
  // Parameters controlling the structured light pattern
  double rings = 3.0; // Radial frequency (n)
  double petals = 8.0; // Angular/Azimuthal frequency (m)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Structured Light Pattern Generator'),
        backgroundColor: Colors.grey[900],
      ),
      body: Column(
        children: [
          // Visualizer Area
          Expanded(
            child: Center(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: CustomPaint(
                  painter: LaserPatternPainter(rings: rings, petals: petals),
                ),
              ),
            ),
          ),

          // Sliders Control Panel
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Radial Rings Slider
                  Row(
                    children: [
                      const SizedBox(width: 80, child: Text('Rings (n):')),
                      Expanded(
                        child: Slider(
                          value: rings,
                          min: 0.0,
                          max: 10.0,
                          divisions: 10,
                          activeColor: Colors.red,
                          label: rings.round().toString(),
                          onChanged: (val) => setState(() => rings = val),
                        ),
                      ),
                      Text(
                        rings.round().toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Angular Petals Slider
                  Row(
                    children: [
                      const SizedBox(width: 80, child: Text('Petals (m):')),
                      Expanded(
                        child: Slider(
                          value: petals,
                          min: 0.0,
                          max: 24.0,
                          divisions: 24,
                          activeColor: Colors.redAccent,
                          label: petals.round().toString(),
                          onChanged: (val) => setState(() => petals = val),
                        ),
                      ),
                      Text(
                        petals.round().toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter that uses math functions to render the optical interference looks
class LaserPatternPainter extends CustomPainter {
  final double rings;
  final double petals;

  LaserPatternPainter({required this.rings, required this.petals});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) / 2 * 0.9;

    final paint = Paint()..style = PaintingStyle.fill;

    // Scan pixels to calculate laser mode wave function intensities
    // Step size balances performance and rendering fidelity
    const double step = 2.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        // Convert to coordinate system relative to container center
        double dx = x - center.dx;
        double dy = y - center.dy;
        double r = sqrt(dx * dx + dy * dy);

        // Normalize radius between 0.0 and 1.0
        double normalizedR = r / maxRadius;
        if (normalizedR > 1.0) continue;

        // Calculate angular position (theta)
        double theta = atan2(dy, dx);

        // 1. Radial component (simulates Laguerre-Gaussian or Bessel modes)
        double radialWave = sin(rings * pi * normalizedR);

        // 2. Azimuthal component (Creates the starburst / petal shapes)
        double angularWave = cos(petals * theta);

        // Combined intensity envelope with Gaussian decay at borders
        double intensity = (radialWave * angularWave).abs();
        double edgeDecay = exp(-2 * normalizedR * normalizedR);
        double finalAlpha = intensity * edgeDecay;

        // Map intensity directly to the opacity of the laser red color
        paint.color = Colors.red.withOpacity(finalAlpha.clamp(0.0, 1.0));

        // Render intensity calculation block
        canvas.drawRect(Rect.fromLTWH(x, y, step, step), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant LaserPatternPainter oldDelegate) {
    return oldDelegate.rings != rings || oldDelegate.petals != petals;
  }
}
