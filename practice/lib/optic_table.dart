import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  runApp(const OpticsLabApp());
}

class OpticsLabApp extends StatelessWidget {
  const OpticsLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme:
          ThemeData.dark(), // Dark mode matches the look of a real laser optics lab
      home: const InterferometerPage(),
    );
  }
}

class InterferometerPage extends StatefulWidget {
  const InterferometerPage({super.key});

  @override
  State<InterferometerPage> createState() => _InterferometerPageState();
}

class _InterferometerPageState extends State<InterferometerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isLaserOn = true;
  double _mirrorDistanceOffset = 0.0; // Simulated mirror micro-displacement

  @override
  void initState() {
    super.initState();
    // Continuous animation for laser beam propagation and interference patterns
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Michelson Interferometer Setup'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Optical Breadboard Grid',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.cyanAccent,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Interactive laser path splitting and phase interference',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 15),

            // 1. The Interactive Optics Table Canvas
            Expanded(
              child: Center(
                child: Card(
                  elevation: 12,
                  color: const Color(0xFF1E272C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: const BorderSide(color: Colors.grey, width: 0.5),
                  ),
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(360, 420),
                        painter: OpticsTablePainter(
                          animationValue: _animationController.value,
                          isLaserOn: _isLaserOn,
                          mirrorOffset: _mirrorDistanceOffset,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // 2. Interactive Control Panel
            Card(
              color: Colors.black87,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Laser Power Supply:',
                          style: TextStyle(fontSize: 15),
                        ),
                        Row(
                          children: [
                            Switch(
                              value: _isLaserOn,
                              activeColor: Colors.redAccent,
                              onChanged: (value) {
                                setState(() {
                                  _isLaserOn = value;
                                });
                              },
                            ),
                            Text(
                              _isLaserOn ? "ON" : "OFF",
                              style: TextStyle(
                                color: _isLaserOn ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Adjust Mirror 1 Position (Δd): ${_mirrorDistanceOffset.toStringAsFixed(2)} nm',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Slider(
                          value: _mirrorDistanceOffset,
                          min: -10.0,
                          max: 10.0,
                          activeColor: Colors.cyan,
                          inactiveColor: Colors.grey.shade800,
                          onChanged: (value) {
                            setState(() {
                              _mirrorDistanceOffset = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 3. CustomPainter that renders the components and laser paths
class OpticsTablePainter extends CustomPainter {
  final double animationValue;
  final bool isLaserOn;
  final double mirrorOffset;

  OpticsTablePainter({
    required this.animationValue,
    required this.isLaserOn,
    required this.mirrorOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // a. Draw Optics Table M6 Imperial Thread Grid Holes
    final gridPaint = Paint()
      ..color = Colors.white.withAlpha(25)
      ..style = PaintingStyle.fill;

    for (double x = 20; x < size.width; x += 25) {
      for (double y = 20; y < size.height; y += 25) {
        canvas.drawCircle(Offset(x, y), 1.5, gridPaint);
      }
    }

    // Coordinate Anchors for Components
    const Offset laserPos = Offset(40, 300);
    const Offset beamSplitterPos = Offset(180, 300);
    const Offset mirror2Pos = Offset(320, 300); // Fixed Reference Mirror
    Offset mirror1Pos = Offset(
      180,
      60 - (mirrorOffset * 0.8),
    ); // Movable Mirror (responds to slider)
    const Offset detectorPos = Offset(180, 400);

    // b. Render Components
    final compPaint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white70
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 1. Laser Source Module
    compPaint.color = Colors.blueGrey.shade800;
    canvas.drawRect(
      Rect.fromCenter(
        center: laserPos - const Offset(15, 0),
        width: 40,
        height: 26,
      ),
      compPaint,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: laserPos - const Offset(15, 0),
        width: 40,
        height: 26,
      ),
      borderPaint,
    );
    compPaint.color = Colors.amber; // Aperture output cap
    canvas.drawRect(
      Rect.fromCenter(
        center: laserPos + const Offset(5, 0),
        width: 6,
        height: 14,
      ),
      compPaint,
    );

    // 2. Beam Splitter Cube (Centered at 45 degrees)
    canvas.save();
    canvas.translate(beamSplitterPos.dx, beamSplitterPos.dy);
    canvas.rotate(math.pi / 4); // Rotate 45°
    compPaint.color = Colors.cyan.withAlpha(60);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: 30, height: 30),
      compPaint,
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: 30, height: 30),
      borderPaint,
    );
    // Draw the internal half-silvered splitting interface diagonal
    final interfacePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5;
    canvas.drawLine(
      const Offset(-15, -15),
      const Offset(15, 15),
      interfacePaint,
    );
    canvas.restore();

    // 3. Reference Mirror 2 (Right side)
    compPaint.color = Colors.grey.shade700;
    canvas.drawRect(
      Rect.fromCenter(
        center: mirror2Pos + const Offset(5, 0),
        width: 10,
        height: 40,
      ),
      compPaint,
    );
    final mirrorSurfacePaint = Paint()
      ..color = Colors.white.withAlpha(220)
      ..strokeWidth = 2;
    canvas.drawLine(
      mirror2Pos + const Offset(0, -20),
      mirror2Pos + const Offset(0, 20),
      mirrorSurfacePaint,
    );

    // 4. Movable Mirror 1 (Top side)
    compPaint.color = Colors.grey.shade700;
    canvas.drawRect(
      Rect.fromCenter(
        center: mirror1Pos - const Offset(0, 5),
        width: 40,
        height: 10,
      ),
      compPaint,
    );
    canvas.drawLine(
      mirror1Pos + const Offset(-20, 0),
      mirror1Pos + const Offset(20, 0),
      mirrorSurfacePaint,
    );

    // 5. CCD Camera / Detector Target (Bottom side)
    compPaint.color = Colors.black;
    canvas.drawRect(
      Rect.fromCenter(center: detectorPos, width: 50, height: 12),
      compPaint,
    );
    canvas.drawRect(
      Rect.fromCenter(center: detectorPos, width: 50, height: 12),
      borderPaint,
    );

    // c. Trace Laser Optics Beams (Dynamic Vector Computation)
    if (isLaserOn) {
      final Paint laserCore = Paint()
        ..color = Colors.red
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      final Paint laserGlow = Paint()
        ..color = Colors.red.withAlpha(70)
        ..strokeWidth = 6.0
        ..style = PaintingStyle.stroke;

      // Path 1: Source to Beam Splitter
      canvas.drawLine(laserPos, beamSplitterPos, laserGlow);
      canvas.drawLine(laserPos, beamSplitterPos, laserCore);

      // Path 2: Transmitted beam to Reference Mirror 2 (Right)
      canvas.drawLine(beamSplitterPos, mirror2Pos, laserGlow);
      canvas.drawLine(beamSplitterPos, mirror2Pos, laserCore);

      // Path 3: Reflected return beam from Mirror 2 back to Beam Splitter
      canvas.drawLine(mirror2Pos, beamSplitterPos, laserGlow);
      canvas.drawLine(mirror2Pos, beamSplitterPos, laserCore);

      // Path 4: Split beam going up to Movable Mirror 1
      canvas.drawLine(beamSplitterPos, mirror1Pos, laserGlow);
      canvas.drawLine(beamSplitterPos, mirror1Pos, laserCore);

      // Path 5: Return path from Mirror 1 back to Beam Splitter
      canvas.drawLine(mirror1Pos, beamSplitterPos, laserGlow);
      canvas.drawLine(mirror1Pos, beamSplitterPos, laserCore);
      // Path 6: Recombined interfering beams going down to the CCD Detector canvas.drawLine(beamSplitterPos, detectorPos, laserGlow); canvas.drawLine(beamSplitterPos, detectorPos, laserCore);
      // d. Render Fringes Projection Screen on the Detector
      // Calculate dynamic phase shifting from mirror displacement slider
      double interferenceWaveFactor = math.sin(
        (mirrorOffset * math.pi / 2) + (animationValue * 2 * math.pi),
      );
      int absoluteOpacity = ((interferenceWaveFactor + 1) * 110 + 35)
          .round()
          .clamp(0, 255);
      final Paint fringePaint = Paint()
        ..color = Colors.red.withAlpha(absoluteOpacity)
        ..style = PaintingStyle.fill;
      // Render alternate destructive and constructive interference bands
      for (int f = -3; f <= 3; f++) {
        double xOffset = detectorPos.dx + (f * 6);
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(xOffset, detectorPos.dy - 3),
            width: 3,
            height: 6,
          ),
          fringePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant OpticsTablePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isLaserOn != isLaserOn ||
        oldDelegate.mirrorOffset != mirrorOffset;
  }
}
