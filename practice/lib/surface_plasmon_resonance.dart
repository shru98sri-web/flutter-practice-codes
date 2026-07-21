import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  runApp(const SPRSimulatorApp());
}

class SPRSimulatorApp extends StatelessWidget {
  const SPRSimulatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SPR Output Simulator',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      home: const SPRSimulatorScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SPRSimulatorScreen extends StatefulWidget {
  const SPRSimulatorScreen({super.key});

  @override
  State<SPRSimulatorScreen> createState() => _SPRSimulatorScreenState();
}

class _SPRSimulatorScreenState extends State<SPRSimulatorScreen> {
  // बदलता येणारे SPR पॅरामीटर्स (State variables)
  double _resonanceAngle = 64.5; // अंश (Degrees) मध्ये रेझोनन्स अँगल
  double _goldThickness = 50.0; // नॅनोमीटर (nm) मध्ये सोन्याचा थर
  double _wavelength = 633.0; // नॅनोमीटर (nm) मध्ये लेझर वेव्हलेंथ

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Surface Plasmon Resonance (SPR)'),
        centerTitle: true,
        backgroundColor: Colors.teal.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // १. रिअल-टाइम ग्राफ आणि आउटपुट डिस्प्ले
            Expanded(
              flex: 4,
              child: Card(
                elevation: 4,
                color: Colors.grey.shade900,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CustomPaint(
                    painter: SPRCurvePainter(
                      resonanceAngle: _resonanceAngle,
                      thickness: _goldThickness,
                      wavelength: _wavelength,
                    ),
                    child: Container(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // २. स्लाईडर्स आणि कंट्रोल पॅनल
            Expanded(
              flex: 5,
              child: Card(
                color: Colors.grey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: ListView(
                    children: [
                      const Text(
                        'Simulation Parameters',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.tealAccent,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Divider(color: Colors.teal),

                      // स्लाईडर १: रेझोनन्स अँगल
                      _buildSliderRow(
                        label: 'Resonance Angle',
                        value: _resonanceAngle,
                        min: 55.0,
                        max: 75.0,
                        unit: '°',
                        onChanged: (val) {
                          setState(() => _resonanceAngle = val);
                        },
                      ),

                      // स्लाईडर २: फिल्म थिकनेस
                      _buildSliderRow(
                        label: 'Gold Layer Thickness',
                        value: _goldThickness,
                        min: 30.0,
                        max: 70.0,
                        unit: ' nm',
                        onChanged: (val) {
                          setState(() => _goldThickness = val);
                        },
                      ),

                      // स्लाईडर ३: वेव्हलेंथ
                      _buildSliderRow(
                        label: 'Laser Wavelength',
                        value: _wavelength,
                        min: 500.0,
                        max: 800.0,
                        unit: ' nm',
                        onChanged: (val) {
                          setState(() => _wavelength = val);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // स्लाईडर UI बनवणारे कॉमन व्हिजेट
  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${value.toStringAsFixed(1)}$unit',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.amberAccent,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: 100,
            activeColor: Colors.tealAccent,
            inactiveColor: Colors.teal.shade900,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ३. SPR रेफ्लेक्टिव्हिटी कर्व ड्रॉ करण्यासाठी Custom Painter क्लास
class SPRCurvePainter extends CustomPainter {
  final double resonanceAngle;
  final double thickness;
  final double wavelength;

  SPRCurvePainter({
    required this.resonanceAngle,
    required this.thickness,
    required this.wavelength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = Colors.tealAccent
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final paintGrid = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1.0;

    final paintText = TextPainter(textDirection: TextDirection.ltr);

    // ग्रिड लाइन्स आणि अक्षांची आखणी (Grid & Axis layout)
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      paintGrid,
    );
    canvas.drawLine(Offset(0, 0), Offset(0, size.height), paintGrid);

    final path = Path();
    bool first = true;

    // एक्स-अक्ष ५०° ते ८०° दर्शवतो
    double startAngle = 50.0;
    double endAngle = 80.0;

    // मॅथेमॅटिकल मॉडेलिंगद्वारे SPR कर्व्ह तयार करणे
    for (double x = 0; x <= size.width; x++) {
      // ग्राफच्या X-पिक्सेलचे अंशात (angle) रुपांतर
      double angle = startAngle + (x / size.width) * (endAngle - startAngle);

      // गणितीय मॉडेल: जाडी (thickness) आणि वेव्हलेंथ (wavelength) नुसार कर्वची रुंदी ठरते
      double dipWidth =
          1.5 +
          ((thickness - 50.0).abs() * 0.05) +
          ((wavelength - 633.0).abs() * 0.003);
      double dipDepth = 0.85 - ((thickness - 50.0).abs() * 0.015);
      if (dipDepth < 0.1) dipDepth = 0.1;

      // गॉस्सियन फंक्शन वापरून डिप (Dip) तयार करणे
      num exponent = -math.pow((angle - resonanceAngle) / dipWidth, 2);

      // २. math.exp() ऐवजी math.pow(math.e, exponent) चा वापर केला आहे
      double reflectivity = 1.0 - (dipDepth * math.pow(math.e, exponent));

      // वाय-पिक्सेलचे ग्राफच्या उंचीनुसार मॅपिंग
      double y = size.height * (1.0 - reflectivity);

      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }

    // स्क्रीनवर कर्व ड्रॉ करणे
    canvas.drawPath(path, paintLine);

    // ग्राफवर माहिती लिहिणे
    paintText.text = TextSpan(
      text:
          'SPR Dip: ${resonanceAngle.toStringAsFixed(2)}°\nReflectivity Curve',
      style: const TextStyle(color: Colors.white70, fontSize: 12),
    );
    paintText.layout();
    paintText.paint(canvas, const Offset(10, 10));
  }

  @override
  bool shouldRepaint(covariant SPRCurvePainter oldDelegate) {
    return oldDelegate.resonanceAngle != resonanceAngle ||
        oldDelegate.thickness != thickness ||
        oldDelegate.wavelength != wavelength;
  }
}
