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
      home: const PsiWavelengthScreen(),
    );
  }
}

class PsiWavelengthScreen extends StatefulWidget {
  const PsiWavelengthScreen({super.key});

  @override
  State<PsiWavelengthScreen> createState() => _PsiWavelengthScreenState();
}

class _PsiWavelengthScreenState extends State<PsiWavelengthScreen> {
  // स्लाईडर्सचे नियंत्रित व्हेरिएबल्स
  double _currentWavelength = 550.0; // नॅनोमीटर (nm) मध्ये सुरुवातीची तरंगलांबी
  double _amplitudeShift = 45.0; // कर्व्हची उंची नियंत्रित करण्यासाठी बेस Psi

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Psi (Ψ) vs Wavelength (λ)'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // १. रिअल-टाइम माहिती कार्ड
            Card(
              color: Colors.blueGrey[900],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Selected Wavelength: ${_currentWavelength.toStringAsFixed(0)} nm',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Graph represents thin-film interference simulation',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // २. ग्राफ डिस्प्ले क्षेत्र (Graph Area)
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomPaint(
                  painter: PsiWavelengthPainter(
                    selectedWavelength: _currentWavelength,
                    amplitudeShift: _amplitudeShift,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // ३. कंट्रोल स्लाईडर्स (Sliders)
            const Text(
              'Control Wavelength (λ)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                const Text('300 nm'),
                Expanded(
                  child: Slider(
                    value: _currentWavelength,
                    min: 300.0,
                    max: 800.0,
                    divisions: 100,
                    activeColor: Colors.redAccent,
                    onChanged: (value) {
                      setState(() {
                        _currentWavelength = value;
                      });
                    },
                  ),
                ),
                const Text('800 nm'),
              ],
            ),
            const SizedBox(height: 10),

            const Text(
              'Base Psi Control (Film Thickness Modifier)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                const Text('10°'),
                Expanded(
                  child: Slider(
                    value: _amplitudeShift,
                    min: 10.0,
                    max: 80.0,
                    activeColor: Colors.tealAccent,
                    onChanged: (value) {
                      setState(() {
                        _amplitudeShift = value;
                      });
                    },
                  ),
                ),
                const Text('80°'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ग्राफ काढणारा पेंटर क्लास (Custom Painter for Plotting)
class PsiWavelengthPainter extends CustomPainter {
  final double selectedWavelength;
  final double amplitudeShift;

  PsiWavelengthPainter({
    required this.selectedWavelength,
    required this.amplitudeShift,
  });

  // मॅथेमॅटिकल मॉडेल: तरंगलांबीनुसार Psi ची किंमत बदलणे (Thin-film oscillation formula)
  double calculatePsiForWavelength(double wavelength) {
    // चित्रपट आणि काचेच्या थरामुळे निर्माण होणारे काल्पनिक दोलन (Oscillation)
    double frequencyFactor = 2 * math.pi * 1500 / wavelength;
    double oscillation = math.sin(frequencyFactor);

    // Psi चे मूल्य 0 ते 90 अंशांच्या दरम्यान मर्यादित ठेवणे
    return amplitudeShift + (15.0 * oscillation);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey[800]!
      ..strokeWidth = 0.5;
    final curvePaint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final linePaint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 1.5;
    final dotPaint = Paint()
      ..color = Colors.yellowAccent
      ..style = PaintingStyle.fill;

    // १. ग्रिड लाईन्स रेखाटणे (Grid Lines)
    for (int i = 1; i < 5; i++) {
      double y = size.height * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      double x = size.width * (i / 5);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // २. संपुर्ण कर्व्ह (Curve Plotting) रेखाटणे - 300nm ते 800nm
    final path = Path();
    bool isFirst = true;

    for (double screenX = 0; screenX <= size.width; screenX += 2) {
      // स्क्रीन X च्या रेषेला प्रत्यक्ष तरंगलांबीमध्ये (300 to 800 nm) मॅप करणे
      double currentWavelengthX =
          300.0 + (screenX / size.width) * (800.0 - 300.0);
      double psiYValue = calculatePsiForWavelength(currentWavelengthX);

      // प्रत्यक्ष गणितीय Y मूल्याला स्क्रीनच्या Y को-ऑर्डिनेटमध्ये बदलणे (0° ते 90° वरून स्क्रीन हाईटमध्ये)
      double screenY = size.height - (psiYValue / 90.0) * size.height;

      if (isFirst) {
        path.moveTo(screenX, screenY);
        isFirst = false;
      } else {
        path.lineTo(screenX, screenY);
      }
    }
    canvas.drawPath(path, curvePaint);

    // ३. सध्या निवडलेल्या तरंगलांबीचा लाल उभा रेषा (Selected Wavelength Indicator)
    double selectedX =
        ((selectedWavelength - 300.0) / (800.0 - 300.0)) * size.width;
    canvas.drawLine(
      Offset(selectedX, 0),
      Offset(selectedX, size.height),
      linePaint,
    );

    // ४. निवडलेल्या बिंदूवर हायलाईट डॉट देणे (Intersection Point)
    double selectedPsiY = calculatePsiForWavelength(selectedWavelength);
    double selectedScreenY = size.height - (selectedPsiY / 90.0) * size.height;
    canvas.drawCircle(Offset(selectedX, selectedScreenY), 6.0, dotPaint);

    // ५. अक्षांची नावे (Labels)
    const textStyle = TextStyle(color: Colors.white60, fontSize: 11);
    _drawText(canvas, "90° (Ψ)", const Offset(5, 5), textStyle);
    _drawText(canvas, "0° (Ψ)", Offset(5, size.height - 15), textStyle);
    _drawText(canvas, "300 nm", Offset(5, size.height - 15), textStyle);
    _drawText(
      canvas,
      "800 nm",
      Offset(size.width - 45, size.height - 15),
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
  bool shouldRepaint(covariant PsiWavelengthPainter oldDelegate) {
    return oldDelegate.selectedWavelength != selectedWavelength ||
        oldDelegate.amplitudeShift != amplitudeShift;
  }
}
