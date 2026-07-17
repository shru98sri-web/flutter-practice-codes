import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v64;

// void main() {
//   runApp(const OpticsRayTracerApp());
// }

class OpticsRayTracerApp extends StatelessWidget {
  const OpticsRayTracerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Convex & Concave Ray Tracer',
      theme: ThemeData.dark(), // सायंटिफिक लुकसाठी डार्क थीम
      home: const OpticsWorkbenchHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class OpticsWorkbenchHome extends StatefulWidget {
  const OpticsWorkbenchHome({super.key});

  @override
  State<OpticsWorkbenchHome> createState() => _OpticsWorkbenchHomeState();
}

class _OpticsWorkbenchHomeState extends State<OpticsWorkbenchHome> {
  // लेन्सचे बदलता येणारे गुणधर्म (Parameters)
  double convexRadius = 120.0; // बहिर्वक्र लेन्सची वक्रता त्रिज्या
  double concaveRadius = -120.0; // अंतर्वक्र लेन्सची वक्रता त्रिज्या (Negative)
  double refractiveIndex = 1.517; // काचेचा अपवर्तनांक (N-BK7 Glass)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Convex & Concave Vector Ray Tracer'),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: Column(
        children: [
          // १. ऑप्टिकल सिमुलेटर स्क्रीन
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.black,
              width: double.infinity,
              height: double.infinity,
              child: CustomPaint(
                painter: AdvancedOpticsPainter(
                  convexR: convexRadius,
                  concaveR: concaveRadius,
                  nGlass: refractiveIndex,
                ),
              ),
            ),
          ),

          // २. कंट्रोल पॅनेल (Sliders)
          Container(
            color: Colors.blueGrey[900],
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSliderRow("Convex Curvature", convexRadius, 0, 1000, (
                  val,
                ) {
                  setState(() => convexRadius = val);
                }),
                _buildSliderRow("Concave Curvature ", concaveRadius, -1000, 0, (
                  val,
                ) {
                  setState(() => concaveRadius = val);
                }),
                _buildSliderRow(
                  "Glass Refractive Index (n)",
                  refractiveIndex,
                  1.0,
                  2.0,
                  (val) {
                    setState(() => refractiveIndex = val);
                  },
                  isIndex: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow(
    String title,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    bool isIndex = false,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 200,
          child: Text(
            '$title: ${value.toStringAsFixed(isIndex ? 3 : 0)}',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            activeColor: Colors.cyanAccent,
            inactiveColor: Colors.white24,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// मुख्य रे-ट्रेसिंग इंजिन (Custom Painter)
class AdvancedOpticsPainter extends CustomPainter {
  final double convexR;
  final double concaveR;
  final double nGlass;

  AdvancedOpticsPainter({
    required this.convexR,
    required this.concaveR,
    required this.nGlass,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double midY = size.height / 2;

    // १. मुख्य ऑप्टिक ॲक्सिस (सेंटर लाइन)
    final axisPaint = Paint()
      ..color = Colors.white30
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), axisPaint);

    // लेन्सच्या जागा निश्चित करणे
    double convexX = size.width * 0.3; // स्क्रीनच्या ३०% वर बहिर्वक्र लेन्स
    double concaveX = size.width * 0.6; // स्क्रीनच्या ६०% वर अंतर्वक्र लेन्स
    double lensHeight = 90.0;

    final glassPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    final edgePaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // २. बहिर्वक्र लेन्स (Convex Lens Shape) ड्रॉ करणे
    final convexPath = Path();
    convexPath.moveTo(convexX - 15, midY - lensHeight);
    convexPath.quadraticBezierTo(
      convexX + (convexR * 0.2),
      midY,
      convexX - 15,
      midY + lensHeight,
    );
    convexPath.lineTo(convexX + 15, midY + lensHeight);
    convexPath.quadraticBezierTo(
      convexX - (convexR * 0.2),
      midY,
      convexX + 15,
      midY - lensHeight,
    );
    convexPath.close();
    canvas.drawPath(convexPath, glassPaint);
    canvas.drawPath(convexPath, edgePaint);

    // ३. अंतर्वक्र लेन्स (Concave Lens Shape) ड्रॉ करणे
    final concavePath = Path();
    concavePath.moveTo(concaveX - 25, midY - lensHeight);
    concavePath.quadraticBezierTo(
      concaveX,
      midY,
      concaveX - 25,
      midY + lensHeight,
    );
    concavePath.lineTo(concaveX + 25, midY + lensHeight);
    concavePath.quadraticBezierTo(
      concaveX,
      midY,
      concaveX + 25,
      midY - lensHeight,
    );
    concavePath.close();
    canvas.drawPath(concavePath, glassPaint);
    canvas.drawPath(concavePath, edgePaint);

    // ४. प्रगत स्नेल्स लॉ वेक्टर रे-ट्रेसिंग सिमुलेशन (Ray Tracing Engine)
    final rayPaint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    // समांतर येणारे ५ प्रकाशकिरण
    for (int i = -2; i <= 2; i++) {
      if (i == 0) continue; // मध्य अक्षावरील किरण सरळ निघून जातो

      double currentY = midY + (i * 30.0);
      double currentX = 0;

      // प्रकाशाची दिशा दर्शवणारा प्राथमिक वेक्टर (Incident Vector)
      v64.Vector2 dVec = v64.Vector2(1.0, 0.0)..normalize();
      List<Offset> rayPoints = [Offset(currentX, currentY)];
      double currentN = 1.0; // हवा (Air n=1.0)

      // --- १. बहिर्वक्र लेन्समध्ये प्रवेश (Convex Entry) ---
      double hitX1 = convexX - 15;
      if (currentX < hitX1) {
        currentY += (hitX1 - currentX) * (dVec.y / dVec.x);
        currentX = hitX1;
        rayPoints.add(Offset(currentX, currentY));

        // नॉर्मल वेक्टर काढणे
        double normalY = (currentY - midY) / convexR;
        double normalX = math.sqrt(1.0 - normalY * normalY);
        v64.Vector2 normal = v64.Vector2(normalX, normalY)..normalize();
        normal.negate();

        dVec = _refract(dVec, normal, currentN, nGlass);
        currentN = nGlass;
      }

      // --- २. बहिर्वक्र लेन्समधून बाहेर (Convex Exit) ---
      double hitX2 = convexX + 15;
      currentY += (hitX2 - currentX) * (dVec.y / dVec.x);
      currentX = hitX2;
      rayPoints.add(Offset(currentX, currentY));

      double normalY2 = (currentY - midY) / -convexR;
      double normalX2 = math.sqrt(1.0 - normalY2 * normalY2);
      v64.Vector2 normal2 = v64.Vector2(normalX2, normalY2)..normalize();

      dVec = _refract(dVec, normal2, currentN, 1.0);
      currentN = 1.0;

      // --- ३. अंतर्वक्र लेन्समध्ये प्रवेश (Concave Entry) ---
      double hitX3 = concaveX - 25;
      if (currentX < hitX3) {
        currentY += (hitX3 - currentX) * (dVec.y / dVec.x);
        currentX = hitX3;
        rayPoints.add(Offset(currentX, currentY));

        double normalY3 = (currentY - midY) / concaveR;
        double normalX3 = math.sqrt(1.0 - normalY3 * normalY3);
        v64.Vector2 normal3 = v64.Vector2(normalX3, normalY3)..normalize();

        dVec = _refract(dVec, normal3, currentN, nGlass);
        currentN = nGlass;
      }

      // --- ४. अंतर्वक्र लेन्समधून बाहेर (Concave Exit) ---
      double hitX4 = concaveX + 25;
      currentY += (hitX4 - currentX) * (dVec.y / dVec.x);
      currentX = hitX4;
      rayPoints.add(Offset(currentX, currentY));

      double normalY4 = (currentY - midY) / -concaveR;
      double normalX4 = math.sqrt(1.0 - normalY4 * normalY4);
      v64.Vector2 normal4 = v64.Vector2(normalX4, normalY4)..normalize();
      normal4.negate();

      dVec = _refract(dVec, normal4, currentN, 1.0);
      currentN = 1.0;

      // स्क्रीनच्या शेवटपर्यंतचा अंतिम मार्ग
      double remainingX = size.width - currentX;
      rayPoints.add(
        Offset(size.width, currentY + (remainingX * (dVec.y / dVec.x))),
      );

      // सर्व गोळा केलेले पॉइंट्स जोडणारी रेषा काढणे
      for (int p = 0; p < rayPoints.length - 1; p++) {
        canvas.drawLine(rayPoints[p], rayPoints[p + 1], rayPaint);
      }
    }
  }

  // स्नेल्स लॉ नुसार वेक्टर रिफ्रॅक्शनचे प्रगत सूत्र (Snell's Law Vector Math)
  v64.Vector2 _refract(
    v64.Vector2 incident,
    v64.Vector2 normal,
    double n1,
    double n2,
  ) {
    double eta = n1 / n2;
    double cosTheta1 = -normal.dot(incident);
    double k = 1.0 - eta * eta * (1.0 - cosTheta1 * cosTheta1);

    if (k < 0) {
      // Total Internal Reflection (पूर्ण अंतर्गत परावर्तन) झाल्यास किरण परावर्तित (Reflect) होतो
      return incident - (normal * 2.0 * normal.dot(incident));
    }

    v64.Vector2 refracted =
        (incident * eta) + (normal * (eta * cosTheta1 - math.sqrt(k)));
    return refracted..normalize();
  }

  @override
  bool shouldRepaint(covariant AdvancedOpticsPainter oldDelegate) {
    return oldDelegate.convexR != convexR ||
        oldDelegate.concaveR != concaveR ||
        oldDelegate.nGlass != nGlass;
  }
}
