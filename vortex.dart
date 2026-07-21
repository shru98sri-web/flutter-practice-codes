import 'dart:math';

import 'package:flutter/material.dart';

void main() => runApp(const VortexAiryApp());

class VortexAiryApp extends StatelessWidget {
  const VortexAiryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const VortexAiryScreen(),
    );
  }
}

class VortexAiryScreen extends StatefulWidget {
  const VortexAiryScreen({super.key});

  @override
  State<VortexAiryScreen> createState() => _VortexAiryScreenState();
}

class _VortexAiryScreenState extends State<VortexAiryScreen> {
  // Core physical control constants for Structured Light Wave Generation
  double cubicScale = 4.0; // Cubic phase parameter (Airy acceleration/bending)
  double topologicalCharge =
      3.0; // Topological charge 'l' (Size of vortex dark core)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Vortex Airy Beam Profile'),
        backgroundColor: Colors.grey[900],
        elevation: 0,
      ),
      body: Column(
        children: [
          // Dynamic Wave Simulation Canvas
          Expanded(
            child: Center(
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(
                    color: Colors.red.withOpacity(0.2),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.05),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: VortexAiryBeamPainter(
                    cubicScale: cubicScale,
                    charge: topologicalCharge,
                  ),
                ),
              ),
            ),
          ),

          // Control Panel Sliders
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Slider 1: Airy Bending (Cubic Scale Parameter)
                  Row(
                    children: [
                      const SizedBox(
                        width: 140,
                        child: Text('Airy Acceleration (α):'),
                      ),
                      Expanded(
                        child: Slider(
                          value: cubicScale,
                          min: 0.0,
                          max: 10.0,
                          divisions: 20,
                          activeColor: Colors.red,
                          inactiveColor: Colors.red.withOpacity(0.2),
                          onChanged: (val) => setState(() => cubicScale = val),
                        ),
                      ),
                      Text(
                        cubicScale.toStringAsFixed(1),
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Slider 2: Vortex Topological Charge (l)
                  Row(
                    children: [
                      const SizedBox(
                        width: 140,
                        child: Text('Vortex Charge (l):'),
                      ),
                      Expanded(
                        child: Slider(
                          value: topologicalCharge,
                          min: 0.0,
                          max: 8.0,
                          divisions: 8,
                          activeColor: Colors.orangeAccent,
                          inactiveColor: Colors.orangeAccent.withOpacity(0.2),
                          onChanged: (val) =>
                              setState(() => topologicalCharge = val),
                        ),
                      ),
                      Text(
                        topologicalCharge.round().toString(),
                        style: const TextStyle(fontFamily: 'monospace'),
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

/// Mathematically models and draws the field intensity of a Vortex Airy Beam.
class VortexAiryBeamPainter extends CustomPainter {
  final double cubicScale;
  final double charge;

  VortexAiryBeamPainter({required this.cubicScale, required this.charge});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) / 2;
    final paint = Paint()..style = PaintingStyle.fill;

    // Grid matrix scanning step. Balance performance vs image resolution.
    // 2.0 = sharp rendering with good performance. 1.0 = ultra-high crisp quality.
    const double step = 2.0;

    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        // Calculate coordinates relative to center (scaled from -1.0 to 1.0)
        double dx = (x - center.dx) / maxRadius;
        double dy = (y - center.dy) / maxRadius;
        double r = sqrt(dx * dx + dy * dy);

        // Clip scanning region slightly past the boundary circle to simulate field aperture
        if (r > 1.1) continue;

        // Calculate azimuthal phase angle (theta) for the optical vortex signature [1]
        double theta = atan2(dy, dx);

        // 1. Airy Component: Simulates the cubic phase modulation x³ + y³ [1]
        double airyX = cos(cubicScale * pi * (dx * dx * dx));
        double airyY = cos(cubicScale * pi * (dy * dy * dy));
        double airyField = (airyX + airyY);

        // 2. Vortex Component: Models the angular orbital angular momentum structure [1]
        double vortexField = sin(charge * theta);

        // Combined Wavefront Interference Profile [1]
        double totalField = airyField * vortexField;
        double intensity = totalField.abs();

        // 3. Central Phase Singularity: Forces a absolute zero dark core context at the absolute middle
        // Core hole expands relative to the scale of the topological charge
        double coreBoundary = 0.06 * charge;
        if (r < coreBoundary && charge > 0) {
          intensity *=
              (r / coreBoundary); // Smoothly decay toward structural zero core
        }

        // 4. Gaussian Amplitude Envelope: Restricts raw edge scaling bounds naturally
        double beamDecay = exp(-1.5 * (dx * dx + dy * dy));
        double finalAlpha = intensity * beamDecay;

        // Render intensity color mapping
        paint.color = Colors.red.withOpacity(finalAlpha.clamp(0.0, 1.0));
        canvas.drawRect(Rect.fromLTWH(x, y, step, step), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant VortexAiryBeamPainter oldDelegate) {
    return oldDelegate.cubicScale != cubicScale || oldDelegate.charge != charge;
  }
}
