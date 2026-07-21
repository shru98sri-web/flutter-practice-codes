import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() => runApp(const EllipsometryApp());

class EllipsometryApp extends StatelessWidget {
  const EllipsometryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const EllipsometryCalculatorScreen(),
    );
  }
}

class EllipsometryCalculatorScreen extends StatefulWidget {
  const EllipsometryCalculatorScreen({super.key});

  @override
  State<EllipsometryCalculatorScreen> createState() =>
      _EllipsometryCalculatorScreenState();
}

class _EllipsometryCalculatorScreenState
    extends State<EllipsometryCalculatorScreen> {
  // सुरुवातीची मूल्ये (Initial Values)
  double _psiDeg = 45.0;
  double _deltaDeg = 90.0;

  // आउटपुट गणितीय मूल्ये
  double _realRho = 0.0;
  double _imaginaryRho = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateEllipsometry();
  }

  void _calculateEllipsometry() {
    double psiRad = _psiDeg * math.pi / 180.0;
    double deltaRad = _deltaDeg * math.pi / 180.0;
    double tanPsi = math.tan(psiRad);

    setState(() {
      // ρ = tan(Ψ) * cos(Δ) + i * tan(Ψ) * sin(Δ)
      _realRho = tanPsi * math.cos(deltaRad);
      _imaginaryRho = tanPsi * math.sin(deltaRad);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ellipsometry Graph & Model'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // १. एलिप्सोमेट्री संकल्पना आकृती (Visual Diagram Block)
            const Text(
              'Ellipsometry Setup Diagram',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: CustomPaint(painter: EllipsometrySetupPainter()),
            ),
            const SizedBox(height: 20),

            // २. कॉम्प्लेक्स प्लेन आलेख (Real vs Imaginary Graph)
            const Text(
              'Complex Reflectance Plane (Graph)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.tealAccent,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomPaint(
                  painter: ComplexPlanePainter(
                    real: _realRho,
                    imaginary: _imaginaryRho,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ३. डिजिटल आउटपुट डिस्प्ले
            Card(
              color: Colors.blueGrey[900],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Center(
                  child: Text(
                    'ρ = ${_realRho.toStringAsFixed(3)} ${_imaginaryRho >= 0 ? "+" : "-"} ${_imaginaryRho.abs().toStringAsFixed(3)}i',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ४. कंट्रोल स्लाईडर्स (Sliders)
            Text('Psi (Ψ): ${_psiDeg.toStringAsFixed(1)}°'),
            Slider(
              value: _psiDeg,
              min: 0.1, // tan(0) इज झिरो, मॅथ एरर टाळण्यासाठी 0.1 ठेवलं आहे
              max: 89.9,
              activeColor: Colors.tealAccent,
              onChanged: (value) {
                _psiDeg = value;
                _calculateEllipsometry();
              },
            ),

            Text('Delta (Δ): ${_deltaDeg.toStringAsFixed(1)}°'),
            Slider(
              value: _deltaDeg,
              min: 0.0,
              max: 360.0,
              activeColor: Colors.orangeAccent,
              onChanged: (value) {
                _deltaDeg = value;
                _calculateEllipsometry();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// सेटअप डायग्राम तयार करणारा पेंटर (Ellipsometry Setup Drawing)
class EllipsometrySetupPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.7);

    // १. थिन फिल्मचा थर दाखवणे (Substrate/Film)
    final layerPaint = Paint()
      ..color = Colors.blueGrey[700]!
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTRB(20, size.height * 0.7, size.width - 20, size.height * 0.8),
      layerPaint,
    );

    final basePaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTRB(20, size.height * 0.8, size.width - 20, size.height * 0.95),
      basePaint,
    );

    // २. येणारा प्रकाश किरण (Incident Beam)
    final incidentPaint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.2),
      center,
      incidentPaint,
    );

    // ३. परावर्तित प्रकाश किरण (Reflected Beam)
    final reflectedPaint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      center,
      Offset(size.width * 0.8, size.height * 0.2),
      reflectedPaint,
    );

    // ४. मजकूर लेबल (Labels)
    const textStyle = TextStyle(color: Colors.white70, fontSize: 11);
    _drawText(
      canvas,
      "Light Source",
      Offset(size.width * 0.1, size.height * 0.1),
      textStyle,
    );
    _drawText(
      canvas,
      "Thin Film",
      Offset(size.width * 0.45, size.height * 0.62),
      textStyle,
    );
    _drawText(
      canvas,
      "Detector (ρ)",
      Offset(size.width * 0.75, size.height * 0.1),
      textStyle,
    );
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ग्राफ/आलेख तयार करणारा पेंटर (Complex Plane Graph Drawing)
class ComplexPlanePainter extends CustomPainter {
  final double real;
  final double imaginary;

  ComplexPlanePainter({required this.real, required this.imaginary});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final axisPaint = Paint()
      ..color = Colors.grey[700]!
      ..strokeWidth = 1.0;

    // १. मुख्य अक्ष रेखाटणे (X and Y Axes)
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      axisPaint,
    ); // X Axis (Real)
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      axisPaint,
    ); // Y Axis (Imaginary)

    // २. ग्रिड स्केलिंग फॅक्टर (Scaling Point for Visualization)
    double scale = 40.0;
    double targetX = center.dx + (real * scale);
    double targetY =
        center.dy -
        (imaginary *
            scale); // कॉम्प्युटर ग्राफिक्समध्ये Y खाली पॉझिटिव्ह असतो, म्हणून वजाबाकी केली

    // स्क्रीनच्या बाहेर बिंदू जाऊ नये म्हणून क्लिपिंग किंवा मर्यादा घालणे
    targetX = targetX.clamp(10.0, size.width - 10.0);
    targetY = targetY.clamp(10.0, size.height - 10.0);

    final vectorOffset = Offset(targetX, targetY);

    // ३. ओरिजिनपासून बिंदूपर्यंतची रेषा (Vector Line)
    final vectorPaint = Paint()
      ..color = Colors.yellowAccent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(center, vectorOffset, vectorPaint);

    // ४. प्रत्यक्ष आउटपुट बिंदू (The ρ Point)
    final pointPaint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(vectorOffset, 6.0, pointPaint);

    // ५. अक्षांवरील नावे (Axis Labels)
    const labelStyle = TextStyle(
      color: Colors.white60,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );
    final textPainterReal = TextPainter(
      text: const TextSpan(text: "+Real", style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainterReal.paint(canvas, Offset(size.width - 45, center.dy + 5));

    final textPainterImag = TextPainter(
      text: const TextSpan(text: "+Imag (i)", style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainterImag.paint(canvas, Offset(center.dx + 5, 5));
  }

  @override
  bool shouldRepaint(covariant ComplexPlanePainter oldDelegate) {
    return oldDelegate.real != real || oldDelegate.imaginary != imaginary;
  }
}
