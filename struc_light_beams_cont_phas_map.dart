import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
  runApp(const StructuredLightApp());
}

class StructuredLightApp extends StatelessWidget {
  const StructuredLightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const ContourPhaseMappingScreen(),
    );
  }
}

class ContourPhaseMappingScreen extends StatefulWidget {
  const ContourPhaseMappingScreen({super.key});

  @override
  State<ContourPhaseMappingScreen> createState() => _ContourPhaseMappingScreenState();
}

class _ContourPhaseMappingScreenState extends State<ContourPhaseMappingScreen> {
  double _phaseShift = 0.0; // रेडियन्समध्ये फेज शिफ्ट (0 ते 2*Pi)
  double _frequency = 0.05; // फ्रिक्वेन्सी (Fringe density)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Structured Light: Phase Mapping'),
        backgroundColor: Colors.grey[900],
      ),
      body: Column(
        children: [
          // फेज मॅपिंग सिम्युलेशन एरिया
          Expanded(
            child: Center(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black,
                child: CustomPaint(
                  painter: FringePatternPainter(
                    phase: _phaseShift,
                    frequency: _frequency,
                  ),
                ),
              ),
            ),
          ),
          // कंट्रोल्स (Phase & Frequency Sliders)
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[900],
            child: Column(
              children: [
                Text(
                  'Phase Shift: ${(_phaseShift / math.pi).toStringAsFixed(2)} π',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                Slider(
                  value: _phaseShift,
                  min: 0.0,
                  max: 2 * math.pi,
                  onChanged: (value) {
                    setState(() {
                      _phaseShift = value;
                    });
                  },
                ),
                Text(
                  'Fringe Frequency: ${_frequency.toStringAsFixed(3)}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                Slider(
                  value: _frequency,
                  min: 0.01,
                  max: 0.2,
                  onChanged: (value) {
                    setState(() {
                      _frequency = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// कस्टम पेंटर - जो रिअल-टाइम लाईट बीम पॅटर्न ड्रॉ करतो
class FringePatternPainter extends CustomPainter {
  final double phase;
  final double frequency;

  FringePatternPainter({required this.phase, required this.frequency});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;

    // संपूर्ण स्क्रीनवर वर्टिकल लाईन्स (Fringes) ड्रॉ करणे
    for (double x = 0; x < size.width; x += 1.0) {
      // कॉन्टूर इफेक्ट देण्यासाठी मध्यभागी काल्पनिक ३D वस्तू (Sphere/Bump) सिम्युलेट केली आहे
      double centerY = size.height / 2;
      double centerX = size.width / 2;
      double radius = 120.0;

      // प्रत्येक पिक्सेलवर ३D वस्तूमुळे होणारा फेज बदल (Contour Distortion)
      double contourDistortion = 0.0;

      for (double y = 0; y < size.height; y += 4.0) {
        double distance = math.sqrt(math.pow(x - centerX, 2) + math.pow(y - centerY, 2));

        if (distance < radius) {
          // ३D गोलाकार वस्तूमुळे प्रकाशाच्या रेषेत होणारा वक्राकार बदल (Phase Modulation)
          contourDistortion = math.cos((distance / radius) * (math.pi / 2)) * 15.0;
        } else {
          contourDistortion = 0.0;
        }

        // गणितीय सूत्र: Intensity = I0 * (1 + cos(2 * pi * f * x + phase + distortion))
        double intensity = (math.cos((x + contourDistortion) * frequency + phase) + 1.0) / 2.0;

        // मोनोक्रोमॅटिक (स्ट्रक्चर्ड) ग्रे-स्केल किंवा ग्रीन लाईट बीम सेट करणे
        int colorValue = (intensity * 255).toInt();
        paint.color = Color.fromARGB(255, 0, colorValue, 0); // ग्रीन बीम इफेक्ट

        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant FringePatternPainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.frequency != frequency;
  }
}
