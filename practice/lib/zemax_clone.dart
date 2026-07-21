import 'package:flutter/material.dart';

// void main() {
//   runApp(const ZemaxCloneApp());
//}

class ZemaxCloneApp extends StatelessWidget {
  const ZemaxCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: OpticalSimulatorHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class OpticalSimulatorHome extends StatefulWidget {
  const OpticalSimulatorHome({super.key});

  @override
  State<OpticalSimulatorHome> createState() => _OpticalSimulatorHomeState();
}

class _OpticalSimulatorHomeState extends State<OpticalSimulatorHome> {
  // Lens properties simulating Zemax Lens Data Editor parameters
  double focalLength = 150.0;
  double lensThickness = 30.0;
  double refractiveIndex = 1.517; // Index of Refraction (Standard N-BK7 Glass)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zemax Optics Simulator Clone'),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          // Optical Workbench Workspace Area
          Expanded(
            child: Container(
              color: Colors.black, // Dark lab layout mode
              width: double.infinity,
              height: double.infinity,
              child: CustomPaint(
                painter: OpticsPainter(
                  focalLength: focalLength,
                  lensThickness: lensThickness,
                  nLens: refractiveIndex,
                ),
              ),
            ),
          ),
          // Configuration Panel (Control Matrix UI)
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.blueGrey[900],
            child: Column(
              children: [
                Text(
                  'Lens parameters (Refractive Index: $refractiveIndex)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    const Text(
                      'Focal Length (f): ',
                      style: TextStyle(color: Colors.white),
                    ),
                    Expanded(
                      child: Slider(
                        value: focalLength,
                        min: 50.0,
                        max: 300.0,
                        activeColor: Colors.indigoAccent,
                        onChanged: (val) => setState(() => focalLength = val),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter parsing vectors and drawing light ray traces
class OpticsPainter extends CustomPainter {
  final double focalLength;
  final double lensThickness;
  final double nLens;

  OpticsPainter({
    required this.focalLength,
    required this.lensThickness,
    required this.nLens,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Draw Optical Axis (System Center Line)
    final axisPaint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      axisPaint,
    );

    // 2. Draw Geometric Convex Lens Body
    final lensPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.25)
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    final lensPath = Path();
    lensPath.moveTo(center.dx - lensThickness / 2, center.dy - 80);

    // Front Surface Curvature
    lensPath.quadraticBezierTo(
      center.dx - lensThickness,
      center.dy,
      center.dx - lensThickness / 2,
      center.dy + 80,
    );
    // Back Surface Curvature
    lensPath.lineTo(center.dx + lensThickness / 2, center.dy + 80);
    lensPath.quadraticBezierTo(
      center.dx + lensThickness,
      center.dy,
      center.dx + lensThickness / 2,
      center.dy - 80,
    );
    lensPath.close();
    canvas.drawPath(lensPath, lensPaint);

    // 3. Mathematical Ray Tracing Engine Simulation Loop
    final rayPaint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Simulate 5 incoming parallel ray vectors
    for (int i = -2; i <= 2; i++) {
      double yOffset = i * 30.0;
      if (yOffset == 0)
        continue; // Principal ray passing through optical center travels straight

      // Seg 1: Source point to front lens interface intersection
      final start = Offset(0, center.dy + yOffset);
      final hitLensInput = Offset(
        center.dx - lensThickness / 2,
        center.dy + yOffset,
      );
      canvas.drawLine(start, hitLensInput, rayPaint);

      // Seg 2: Internal transmission propagation within lens medium
      final hitLensOutput = Offset(
        center.dx + lensThickness / 2,
        center.dy + (yOffset * 0.9),
      );
      canvas.drawLine(hitLensInput, hitLensOutput, rayPaint);

      // Seg 3: Refraction divergence passing from lens back to focal node point
      final focusPoint = Offset(center.dx + focalLength, center.dy);
      canvas.drawLine(hitLensOutput, focusPoint, rayPaint);

      // Seg 4: Post-focal length vector propagation path mapping
      final endX = size.width;
      final endY =
          center.dy -
          ((endX - focusPoint.dx) *
              (hitLensOutput.dy - center.dy) /
              (focusPoint.dx - hitLensOutput.dx));
      canvas.drawLine(focusPoint, Offset(endX, endY), rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant OpticsPainter oldDelegate) {
    return oldDelegate.focalLength != focalLength ||
        oldDelegate.lensThickness != lensThickness ||
        oldDelegate.nLens != nLens;
  }
}
