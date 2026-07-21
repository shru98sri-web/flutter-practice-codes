import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() => runApp(
  const MaterialApp(
    home: HolographySpectrumLab(),
    debugShowCheckedModeBanner: false,
  ),
);

class HolographySpectrumLab extends StatefulWidget {
  const HolographySpectrumLab({super.key});

  @override
  State<HolographySpectrumLab> createState() => _HolographySpectrumLabState();
}

class _HolographySpectrumLabState extends State<HolographySpectrumLab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isRecordingMode = true;
  double _laserWavelength = 532.0; // Default: Green Laser (nm)

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getLaserColor(double wavelength) {
    if (wavelength >= 380 && wavelength < 450) return Colors.deepPurple;
    if (wavelength >= 450 && wavelength < 495) return Colors.blue;
    if (wavelength >= 495 && wavelength < 570) return Colors.green;
    if (wavelength >= 570 && wavelength < 590) return Colors.yellow;
    if (wavelength >= 590 && wavelength < 620) return Colors.orange;
    if (wavelength >= 620 && wavelength <= 750) return Colors.red;
    return Colors.cyan;
  }

  @override
  Widget build(BuildContext context) {
    Color currentLaserColor = _getLaserColor(_laserWavelength);

    return Scaffold(
      backgroundColor: const Color(0xFF080B11),
      appBar: AppBar(
        title: const Text(
          'Holography Spectrum Lab',
          style: TextStyle(fontSize: 18, color: Colors.white70),
        ),
        backgroundColor: const Color(0xFF101622),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Phase Selection
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRecordingMode
                          ? const Color(0xFF1E293B)
                          : const Color(0xFF0F172A),
                      side: BorderSide(
                        color: _isRecordingMode
                            ? currentLaserColor
                            : Colors.transparent,
                      ),
                    ),
                    onPressed: () => setState(() => _isRecordingMode = true),
                    child: const Text(
                      '1. Recording Phase',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_isRecordingMode
                          ? const Color(0xFF1E293B)
                          : const Color(0xFF0F172A),
                      side: BorderSide(
                        color: !_isRecordingMode
                            ? currentLaserColor
                            : Colors.transparent,
                      ),
                    ),
                    onPressed: () => setState(() => _isRecordingMode = false),
                    child: const Text(
                      '2. Reconstruction',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Core Animation Canvas
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D131F),
                borderRadius: BorderRadius.circular(12),
                border: BorderBorder.all(color: const Color(0xFF1E293B)),
              ),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: HolographySpectrumPainter(
                      animationValue: _controller.value,
                      isRecording: _isRecordingMode,
                      laserColor: currentLaserColor,
                      wavelength: _laserWavelength,
                    ),
                    child: Container(),
                  );
                },
              ),
            ),
          ),

          // Variable Spectrum Control Engine
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF101622),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Laser Wavelength Spectrum:',
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      '${_laserWavelength.toInt()} nm',
                      style: TextStyle(
                        color: currentLaserColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _laserWavelength,
                  min: 400,
                  max: 700,
                  activeColor: currentLaserColor,
                  inactiveColor: Colors.white10,
                  onChanged: (val) => setState(() => _laserWavelength = val),
                ),
                const SizedBox(height: 8),
                Text(
                  _isRecordingMode
                      ? 'Interference Matrix: Object & Reference beams superimpose to record physical fringe micro-patterns on the photographic emulsion.'
                      : 'Diffraction Spectrum: The reference beam passes through the processed spatial grating slits, reconstructing the original 3D wavefront.',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BorderBorder {
  static Border all({required Color color}) => Border.all(color: color);
}

class HolographySpectrumPainter extends CustomPainter {
  final double animationValue;
  final bool isRecording;
  final Color laserColor;
  final double wavelength;

  HolographySpectrumPainter({
    required this.animationValue,
    required this.isRecording,
    required this.laserColor,
    required this.wavelength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double midY = size.height * 0.5;
    final double sourceX = size.width * 0.15;
    final double sourceY = size.height * 0.2;
    final double objectX = size.width * 0.25;
    final double objectY = size.height * 0.7;
    final double plateX = size.width * 0.75;

    final Paint beamPaint = Paint()
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final Paint nodePaint = Paint()..style = PaintingStyle.fill;

    // 1. Static Optical Setup Components ड्रॉ करणे
    _drawComponent(
      canvas,
      Offset(sourceX, sourceY),
      "Laser Source",
      Colors.blueGrey,
    );
    _drawPlate(
      canvas,
      Offset(plateX, midY - 80),
      Offset(plateX, midY + 80),
      "Holo-Plate",
    );

    // Wavelength नुसार फ्रिक्वेन्सी रुंदी (Period) ठरवणे
    double dynamicPeriod = (wavelength / 700) * 30.0;

    if (isRecording) {
      // Target Object ड्रॉ करणे
      _drawComponent(canvas, Offset(objectX, objectY), "Object", Colors.amber);

      // Reference Beam (Source -> Plate)
      beamPaint.color = laserColor.withOpacity(0.7);
      _drawWave(
        canvas,
        Offset(sourceX + 35, sourceY),
        Offset(plateX, midY - 40),
        animationValue,
        beamPaint,
        dynamicPeriod,
      );

      // Object Illumination Beam (Source -> Object)
      beamPaint.color = laserColor.withOpacity(0.4);
      _drawWave(
        canvas,
        Offset(sourceX, sourceY + 15),
        Offset(objectX - 10, objectY - 15),
        animationValue,
        beamPaint,
        dynamicPeriod,
      );

      // Scattered Object Beam (Object -> Plate)
      beamPaint.color = Colors.tealAccent.withOpacity(0.6);
      _drawWave(
        canvas,
        Offset(objectX + 35, objectY),
        Offset(plateX, midY + 40),
        animationValue,
        beamPaint,
        dynamicPeriod + 5,
      );

      // Plate वर होणारे इंटरफेरन्स फ्रिंजेस (Interference Fringes)
      final Paint fringePaint = Paint()..strokeWidth = 3.0;
      for (int i = 0; i < 20; i++) {
        double yPos = (midY - 70) + (i * 7);
        double intensity = math
            .sin((i * 0.9) - (animationValue * math.pi * 2))
            .abs();
        fringePaint.color = laserColor.withOpacity(intensity);
        canvas.drawLine(
          Offset(plateX - 2, yPos),
          Offset(plateX + 4, yPos),
          fringePaint,
        );
      }
    } else {
      // Reconstruction Phase
      // Reconstructing Reference Beam (Source -> Plate)
      beamPaint.color = laserColor.withOpacity(0.7);
      _drawWave(
        canvas,
        Offset(sourceX + 35, sourceY),
        Offset(plateX, midY - 40),
        animationValue,
        beamPaint,
        dynamicPeriod,
      );

      // Diffracted Waves (+1, 0, -1 Spectrum Orders)
      beamPaint.color = laserColor.withOpacity(0.5);
      _drawWave(
        canvas,
        Offset(plateX + 4, midY - 40),
        Offset(size.width * 0.95, midY - 70),
        animationValue,
        beamPaint,
        dynamicPeriod,
      );
      _drawWave(
        canvas,
        Offset(plateX + 4, midY - 40),
        Offset(size.width * 0.95, midY),
        animationValue,
        beamPaint,
        dynamicPeriod,
      );
      _drawWave(
        canvas,
        Offset(plateX + 4, midY - 40),
        Offset(size.width * 0.95, midY + 70),
        animationValue,
        beamPaint,
        dynamicPeriod,
      );

      // Floating Virtual 3D Reconstructed Wavefront Object (3D Image)
      final double ghostOpacity =
          0.25 + (0.15 * math.sin(animationValue * math.pi * 2));
      nodePaint.color = Colors.cyan.withOpacity(ghostOpacity);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width * 0.5, midY + 40),
            width: 60,
            height: 40,
          ),
          const Radius.circular(6),
        ),
        nodePaint,
      );
      _drawText(
        canvas,
        Offset(size.width * 0.5 - 24, midY + 33),
        "3D Image",
        Colors.cyanAccent,
        10,
      );

      // Converging wavefront logic (मागील तुटलेला भाग येथे नीट जोडला आहे)
      beamPaint.color = Colors.cyan.withOpacity(0.4);
      _drawWave(
        canvas,
        Offset(plateX + 4, midY + 40),
        Offset(size.width * 0.5, midY + 40),
        animationValue,
        beamPaint,
        dynamicPeriod,
      );
    }
  }

  // गहाळ (Missing) असलेले लाटांचे गणितीय फंक्शन (_drawWave)
  void _drawWave(
    Canvas canvas,
    Offset start,
    Offset end,
    double t,
    Paint paint,
    double wavelengthSpace,
  ) {
    final Path path = Path();
    path.moveTo(start.dx, start.dy);

    double dx = end.dx - start.dx;
    double dy = end.dy - start.dy;
    double distance = math.sqrt(dx * dx + dy * dy);

    int sections = (distance / 3).toInt();
    if (sections < 10) sections = 10;

    for (int i = 0; i <= sections; i++) {
      double pct = i / sections;
      double x = start.dx + dx * pct;
      double y = start.dy + dy * pct;

      double waveAngle =
          (pct * (distance / wavelengthSpace) * 2 * math.pi) -
          (t * 2 * math.pi);
      double offset = math.sin(waveAngle) * 5.0;

      double nx = -dy / distance;
      double ny = dx / distance;

      path.lineTo(x + nx * offset, y + ny * offset);
    }
    canvas.drawPath(path, paint);
  }

  void _drawComponent(Canvas canvas, Offset center, String text, Color color) {
    final Paint paint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    final Paint strokePaint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 80, height: 35),
        const Radius.circular(6),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 80, height: 35),
        const Radius.circular(6),
      ),
      strokePaint,
    );
    _drawText(
      canvas,
      Offset(center.dx - 28, center.dy - 6),
      text,
      const Color(0xEEEEEEEE),
      11,
    );
  }

  void _drawPlate(Canvas canvas, Offset top, Offset bottom, String text) {
    final Paint paint = Paint()
      ..color = Colors.tealAccent.withOpacity(0.8)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(top, bottom, paint);
    _drawText(
      canvas,
      Offset(top.dx - 25, top.dy - 16),
      text,
      Colors.tealAccent,
      11,
    );
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
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant HolographySpectrumPainter oldDelegate) => true;
}
