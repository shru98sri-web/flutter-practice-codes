import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  runApp(const SpeckleApp());
}

class SpeckleApp extends StatelessWidget {
  const SpeckleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme:
          ThemeData.dark(), // सायंटिफिक डेटा पाहण्यासाठी डार्क थीम उत्तम दिसते
      home: const InterferometrySliderPage(),
    );
  }
}

class InterferometrySliderPage extends StatefulWidget {
  const InterferometrySliderPage({super.key});

  @override
  State<InterferometrySliderPage> createState() =>
      _InterferometrySliderPageState();
}

class _InterferometrySliderPageState extends State<InterferometrySliderPage> {
  // स्लायडरद्वारे नियंत्रित होणारे व्हेरिएबल्स
  double _frequency = 0.1;
  double _noiseLevel = 0.2;

  final int _matrixSize = 120; // ग्रिडचा आकार (120x120 पिक्सल्स)

  // फ्रिंज पॅटर्न जनरेट करणारा मॅथेमॅटिकल फंक्शन (Mock Optical Output)
  List<List<double>> _generateInterferogram(double freq, double noise) {
    final random = math.Random();
    return List.generate(_matrixSize, (r) {
      return List.generate(_matrixSize, (c) {
        // वर्तुळाकार इंटरफेरन्स पॅटर्नचे सूत्र (Concentric Fringe Rings)
        double distance = math.sqrt(
          math.pow(r - _matrixSize / 2, 2) + math.pow(c - _matrixSize / 2, 2),
        );
        double pattern = (math.sin(distance * freq) + 1) / 2.0;

        // वास्तविक स्पेकल इफेक्ट दाखवण्यासाठी थोडा रँडम नॉइज (Noise) जोडणे
        double randomNoise = random.nextDouble() * noise;

        // मूल्य 0.0 ते 1.0 च्या दरम्यान मर्यादित ठेवणे
        return (pattern + randomNoise).clamp(0.0, 1.0);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final fringeData = _generateInterferogram(_frequency, _noiseLevel);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Speckle Interferometry Simulator'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // १. मुख्य इंटरफेरोग्राम डिस्प्ले एरिया
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                    child: CustomPaint(
                      painter: SpeckleFringePainter(fringeData: fringeData),
                      child: Container(),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // २. फ्रिक्वेन्सी कंट्रोल स्लायडर (Fringe Frequency)
            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Text(
                      'Fringe Frequency: ${_frequency.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: _frequency,
                      min: 0.05,
                      max: 0.5,
                      divisions: 45,
                      activeColor: Colors.cyanAccent,
                      onChanged: (newValue) {
                        setState(() {
                          _frequency = newValue;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ३. नॉइज कंट्रोल स्लायडर (Speckle Noise)
            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Text(
                      'Speckle Noise Level: ${(_noiseLevel * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: _noiseLevel,
                      min: 0.0,
                      max: 0.6,
                      divisions: 6,
                      activeColor: Colors.amberAccent,
                      onChanged: (newValue) {
                        setState(() {
                          _noiseLevel = newValue;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ४. कस्टम पेंटर - जो डेटाला स्क्रीनवर ड्रॉ करतो
class SpeckleFringePainter extends CustomPainter {
  final List<List<double>> fringeData;

  SpeckleFringePainter({required this.fringeData});

  @override
  void paint(Canvas canvas, Size size) {
    if (fringeData.isEmpty) return;

    final rows = fringeData.length;
    final cols = fringeData[0].length;

    final cellWidth = size.width / cols;
    final cellHeight = size.height / rows;

    final paint = Paint()..style = PaintingStyle.fill;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final intensity = fringeData[r][c];

        // मोनोक्रोम (Grayscale) इंटरफेरोमेट्री आउटपुटसाठी सावली सेट करणे
        // (तुम्ही हवं असल्यास रंगासाठी HSVColor चा वापर करू शकता)
        final int greyValue = (intensity * 255).toInt();
        paint.color = Color.fromARGB(255, greyValue, greyValue, greyValue);

        canvas.drawRect(
          Rect.fromLTWH(
            c * cellWidth,
            r * cellHeight,
            cellWidth + 0.5, // गॅप्स टाळण्यासाठी थोडे एक्स्ट्रा पॅडिंग
            cellHeight + 0.5,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant SpeckleFringePainter oldDelegate) {
    // जेव्हा नवीन डेटा जनरेट होईल तेव्हाच पेंटर री-ड्रॉ होईल
    return oldDelegate.fringeData != fringeData;
  }
}
