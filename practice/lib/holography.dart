import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: HolographySimulator()));

class HolographySimulator extends StatefulWidget {
  const HolographySimulator({super.key});

  @override
  State<HolographySimulator> createState() => _HolographySimulatorState();
}

class _HolographySimulatorState extends State<HolographySimulator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool isRecordingMode = true;

  @override
  void initState() {
    super.initState();
    // Loop the animation continuously to simulate dynamic wave propagation
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
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        title: const Text('Holography Lab: Spectrum Simulator'),
        backgroundColor: const Color(0xFF161F33),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildModeSelector(),
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: HolographyPainter(
                    animationValue: _controller.value,
                    isRecording: isRecordingMode,
                  ),
                  child: Container(),
                );
              },
            ),
          ),
          _buildControlPanel(),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ChoiceChip(
            label: const Text('1. Recording Phase'),
            selected: isRecordingMode,
            selectedColor: Colors.cyan.withOpacity(0.3),
            labelStyle: TextStyle(
              color: isRecordingMode ? Colors.cyan : Colors.grey,
            ),
            onSelected: (val) => setState(() => isRecordingMode = true),
          ),
          const SizedBox(width: 16),
          ChoiceChip(
            label: const Text('2. Reconstruction Phase'),
            selected: !isRecordingMode,
            selectedColor: Colors.purple.withOpacity(0.3),
            labelStyle: TextStyle(
              color: !isRecordingMode ? Colors.purpleAccent : Colors.grey,
            ),
            onSelected: (val) => setState(() => isRecordingMode = false),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      color: const Color(0xFF161F33),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isRecordingMode
                  ? 'Recording Mechanics:'
                  : 'Reconstruction Mechanics:',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isRecordingMode
                  ? '• Reference laser beam intersects with the scattered Object beam.\n• Micro-interference patterns (spatial spectrum fringes) are captured on the film plane.'
                  : '• The recorded holographic plane is illuminated by the Reference beam alone.\n• The spatial spectrum acts as a diffraction grating, reconstructing the Virtual 3D Image.',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HolographyPainter extends CustomPainter {
  final double animationValue;
  final bool isRecording;

  HolographyPainter({required this.animationValue, required this.isRecording});

  @override
  void paint(Canvas canvas, Size size) {
    final double midY = size.height * 0.45;
    final double filmX = size.width * 0.55;
    final double objectX = size.width * 0.15;
    final double laserX = size.width * 0.15;
    final double laserY = size.height * 0.15;

    // Paint definition utilities
    final Paint beamPaint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final Paint componentPaint = Paint()
      ..color = Colors.white70
      ..style = PaintingStyle.fill;

    // 1. Draw Optical Components Base Layout
    _drawComponentCard(
      canvas,
      Offset(laserX, laserY),
      "Laser Source",
      componentPaint,
    );
    _drawComponentCard(
      canvas,
      Offset(objectX, midY),
      "Target Object",
      componentPaint,
    );
    _drawComponentPlate(
      canvas,
      Offset(filmX, midY - 60),
      Offset(filmX, midY + 60),
      "Holo-Media Plane",
      Colors.amber,
    );

    // 2. Execute Animation Phases Based on User State
    if (isRecording) {
      _paintRecordingPhase(
        canvas,
        size,
        beamPaint,
        laserX,
        laserY,
        objectX,
        midY,
        filmX,
        animationValue,
      );
    } else {
      _paintReconstructionPhase(
        canvas,
        size,
        beamPaint,
        laserX,
        laserY,
        filmX,
        midY,
        animationValue,
      );
    }
  }

  void _paintRecordingPhase(
    Canvas canvas,
    Size size,
    Paint paint,
    double lx,
    double ly,
    double ox,
    double oy,
    double fx,
    double t,
  ) {
    // Reference Beam Matrix (Laser Source directly hitting Holo Media Plate)
    paint.color = Colors.cyan.withOpacity(0.6);
    _drawSineWaveLine(
      canvas,
      Offset(lx + 40, ly),
      Offset(fx, oy - 30),
      t,
      paint,
      25.0,
    );

    // Illumination Beam hitting target Object
    paint.color = Colors.blueAccent.withOpacity(0.4);
    _drawSineWaveLine(
      canvas,
      Offset(lx, ly + 15),
      Offset(ox, oy - 20),
      t,
      paint,
      20.0,
    );

    // Object Beam Matrix scattered from target toward Holo Media Plate
    paint.color = Colors.greenAccent.withOpacity(0.6);
    _drawSineWaveLine(
      canvas,
      Offset(ox + 40, oy),
      Offset(fx, oy + 20),
      t,
      paint,
      15.0,
    );

    // Intersecting Fringe Spectrum Simulation (Fringes building up on Media Plate)
    final Paint fringePaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(
        0.3 + (0.4 * math.sin(t * math.pi * 2).abs()),
      )
      ..strokeWidth = 4.0;

    for (int i = 0; i < 12; i++) {
      double yOffset = (oy - 50) + (i * 9.0);
      canvas.drawLine(
        Offset(fx, yOffset),
        Offset(fx + 6, yOffset + 4),
        fringePaint,
      );
    }
  }

  void _paintReconstructionPhase(
    Canvas canvas,
    Size size,
    Paint paint,
    double lx,
    double ly,
    double fx,
    double oy,
    double t,
  ) {
    // Reference Reconstruction Laser Beam incoming onto the processed medium
    paint.color = Colors.purpleAccent.withOpacity(0.7);
    _drawSineWaveLine(
      canvas,
      Offset(lx + 40, ly),
      Offset(fx, oy - 30),
      t,
      paint,
      25.0,
    );

    // Real-time Spatial Frequency Spectrum Diffraction Simulation escaping through back plate
    final double outputStartX = fx + 4;
    final RandomSpec = math.sin(t * math.pi * 2);

    // Simulating diffracted spectrum orders (First-order real image beam pathways)
    paint.color = Colors.redAccent.withOpacity(0.5);
    _drawSineWaveLine(
      canvas,
      Offset(outputStartX, oy - 20),
      Offset(size.width * 0.9, oy - 70 + (RandomSpec * 5)),
      t,
      paint,
      18.0,
    );

    paint.color = Colors.indigoAccent.withOpacity(0.5);
    _drawSineWaveLine(
      canvas,
      Offset(outputStartX, oy + 20),
      Offset(size.width * 0.9, oy + 70 + (RandomSpec * 5)),
      t,
      paint,
      22.0,
    );

    // Rendered Virtual 3D Reconstructed Wavefront Target Object Box
    final Paint objectGhostPaint = Paint()
      ..color = Colors.purple.withOpacity(
        0.25 + (0.15 * math.sin(t * math.pi * 4)),
      )
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.85, oy),
          width: 55,
          height: 55,
        ),
        const Radius.circular(8),
      ),
      objectGhostPaint,
    );

    _drawText(
      canvas,
      Offset(size.width * 0.85 - 24, oy - 6),
      "3D Image",
      Colors.purpleAccent,
      11,
    );
  }

  void _drawSineWaveLine(
    Canvas canvas,
    Offset start,
    Offset end,
    double t,
    Paint paint,
    double spatialWavelength,
  ) {
    final Path path = Path();
    path.moveTo(start.dx, start.dy);

    double distance = math.sqrt(
      math.pow(end.dx - start.dx, 2) + math.pow(end.dy - start.dy, 2),
    );
    int steps = (distance / 2)
        .castToDoubleOrInt(); // Iterative precision stepping
    if (steps < 10) steps = 10;

    for (int i = 0; i <= steps; i++) {
      double fraction = i / steps;
      // Interpolate along linear path matrix
      double x = start.dx + (end.dx - start.dx) * fraction;
      double y = start.dy + (end.dy - start.dy) * fraction;

      // Compute perpendicular offset shift using sinusoidal function
      double angle =
          (fraction * (distance / spatialWavelength) * 2 * math.pi) -
          (t * 2 * math.pi);
      double waveOffset = math.sin(angle) * 6.0;

      // Apply simple normal transformation components manually
      double nx = -(end.dy - start.dy) / distance;
      double ny = (end.dx - start.dx) / distance;

      path.lineTo(x + nx * waveOffset, y + ny * waveOffset);
    }
    canvas.drawPath(path, paint);
  }

  void _drawComponentCard(
    Canvas canvas,
    Offset center,
    String label,
    Paint paint,
  ) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 85, height: 40),
        const Radius.circular(6),
      ),
      paint..color = const Color(0xFF24344F),
    );
    _drawText(
      canvas,
      Offset(center.dx - 36, center.dy - 6),
      label,
      Colors.white,
      11,
    );
  }

  void _drawComponentPlate(
    Canvas canvas,
    Offset top,
    Offset bottom,
    String label,
    Color color,
  ) {
    final Paint linePaint = Paint()
      ..color = color
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(top, bottom, linePaint);
    _drawText(canvas, Offset(top.dx - 45, top.dy - 18), label, color, 11);
  }

  void _drawText(
    Canvas canvas,
    Offset offset,
    String text,
    Color color,
    double size,
  ) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant HolographyPainter oldDelegate) => true;
}

extension on num {
  int castToDoubleOrInt() => toInt();
}
