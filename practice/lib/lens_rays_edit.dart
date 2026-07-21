import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const RayTracingScreen(),
    );
  }
}

class RayTracingScreen extends StatefulWidget {
  const RayTracingScreen({super.key});

  @override
  State<RayTracingScreen> createState() => _RayTracingScreenState();
}

class _RayTracingScreenState extends State<RayTracingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // किरणांच्या हालचालीसाठी (Animation) कंट्रोलर
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
      backgroundColor: const Color(0xFF0F172A), // गडद पार्श्वभूमी (Dark Theme)
      appBar: AppBar(
        title: const Text("४ लेन्स रे ट्रेसिंग सिम्युलेशन"),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: RayTracerPainter(progress: _controller.value),
            child: Container(),
          );
        },
      ),
    );
  }
}

// लेन्सची रचना सांगणारा क्लास
class Lens {
  final double x; // स्क्रीनवरील X अक्ष (Position)
  final double radius; // लेन्सची वक्रता (Curvature Radius)
  final double height; // लेन्सची उंची
  final double refIndex; // अपवर्तनांक (Refractive Index, उदा. काचेचा १.५)

  Lens({
    required this.x,
    required this.radius,
    required this.height,
    required this.refIndex,
  });
}

class RayTracerPainter extends CustomPainter {
  final double progress;
  RayTracerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double centerY = size.height / 2;

    // १. ४ वेगवेगळ्या लेन्सची व्याख्या (Positions and Properties)
    final List<Lens> lenses = [
      Lens(
        x: size.width * 0.25,
        radius: 150,
        height: 160,
        refIndex: 1.52,
      ), // बहिर्वक्र (Convex)
      Lens(
        x: size.width * 0.45,
        radius: -120,
        height: 140,
        refIndex: 1.65,
      ), // अंतर्वक्र (Concave)
      Lens(
        x: size.width * 0.65,
        radius: 180,
        height: 150,
        refIndex: 1.50,
      ), // बहिर्वक्र (Convex)
      Lens(
        x: size.width * 0.85,
        radius: 100,
        height: 120,
        refIndex: 1.70,
      ), // तीव्र बहिर्वक्र
    ];

    // लेन्स ड्रा करण्यासाठी पेंट ऑब्जेक्ट
    final lensPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final lensBorderPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // लेन्स स्क्रीनवर रेखाटणे
    for (var lens in lenses) {
      Path path = Path();
      if (lens.radius > 0) {
        // १, ३ आणि ४ क्रमांकाची बहिर्वक्र लेन्स (Convex Lens)
        path.moveTo(lens.x - 12, centerY - lens.height / 2);
        path.arcToPoint(
          Offset(lens.x + 12, centerY + lens.height / 2),
          radius: Radius.circular(lens.radius),
          clockwise: true,
        );
        path.arcToPoint(
          Offset(lens.x - 12, centerY - lens.height / 2),
          radius: Radius.circular(lens.radius),
          clockwise: true,
        );
      } else {
        // २ क्रमांकाची सुबक अंतर्वक्र लेन्स (Neat Concave Lens)
        double halfH = lens.height / 2;
        double thickness = 22; // कडेची जाडी
        double rad = lens.radius.abs();

        // वरच्या डाव्या कोपऱ्यापासून सुरुवात
        path.moveTo(lens.x - thickness, centerY - halfH);
        // वरची सरळ रेघ
        path.lineTo(lens.x + thickness, centerY - halfH);
        // उजवी बाजू (आत वळलेली वक्र रेघ)
        path.arcToPoint(
          Offset(lens.x + thickness, centerY + halfH),
          radius: Radius.circular(rad),
          clockwise: false,
        );
        // खालची सरळ रेघ
        path.lineTo(lens.x - thickness, centerY + halfH);
        // डावी बाजू (आत वळलेली वक्र रेघ)
        path.arcToPoint(
          Offset(lens.x - thickness, centerY - halfH),
          radius: Radius.circular(rad),
          clockwise: false,
        );
      }

      // लेन्स रंगवणे आणि कडा स्पष्ट करणे
      canvas.drawPath(path, lensPaint);
      canvas.drawPath(path, lensBorderPaint);
    }
    // २. अनेक प्रकाशकिरण (Many Rays) तयार करणे आणि ट्रॅक करणे
    final int rayCount = 80; // एकूण किरणांची संख्या
    final rayPaint = Paint()
      ..color = Colors.amber.withOpacity(0.4)
      ..strokeWidth = 1.0;

    // ॲनिमेशननुसार किरणांचा मुख्य कोन बदलणे
    double angleOffset = math.sin(progress * 2 * math.pi) * 0.08;

    for (int i = 0; i < rayCount; i++) {
      // किरणांना सुरुवातीला Y अक्षावर समांतर पसरवणे
      double startY = centerY - 100 + (200 / (rayCount - 1)) * i;
      double currentX = 0;
      double currentY = startY;

      // किरणांची दिशा (Vector)
      double dirX = math.cos(angleOffset);
      double dirY = math.sin(angleOffset);

      List<Offset> rayPoints = [Offset(currentX, currentY)];
      double currentRefIndex = 1.0; // हवेचा अपवर्तनांक = १.०

      // प्रत्येक लेन्ससोबत किरणाचा संकर (Intersection) तपासणे
      for (var lens in lenses) {
        // सोप्या गणितासाठी लेन्सच्या मध्य अक्षावर (X) अपवर्तन मोजणे
        if (currentX < lens.x) {
          double stepX = lens.x - currentX;
          double stepY = (dirY / dirX) * stepX;

          currentX = lens.x;
          currentY += stepY;

          // जर किरण लेन्सच्या उंचीच्या आत असेल तरच अपवर्तन होणार
          if ((currentY - centerY).abs() < lens.height / 2) {
            // लेन्सच्या वक्रतेनुसार नॉर्मल कोन (Normal Angle) काढणे
            double normalAngle = 0;
            if (lens.radius > 0) {
              normalAngle = (currentY - centerY) / lens.radius;
            } else {
              normalAngle = -(currentY - centerY) / lens.radius.abs();
            }

            // स्नेलचा नियम (Snell's Law) वापरून नवा अपवर्तन कोन काढणे
            double incidentAngle = math.atan2(dirY, dirX) - normalAngle;
            double refractedAngle = math.asin(
              (currentRefIndex / lens.refIndex) * math.sin(incidentAngle),
            );

            if (!refractedAngle.isNaN) {
              double finalAngle = refractedAngle + normalAngle;
              dirX = math.cos(finalAngle);
              dirY = math.sin(finalAngle);
            }
          }
          rayPoints.add(Offset(currentX, currentY));
        }
      }

      // शेवटचा बिंदू स्क्रीनच्या बाहेर काढणे
      double endX = size.width;
      double endY = currentY + (dirY / dirX) * (endX - currentX);
      rayPoints.add(Offset(endX, endY));

      // किरणाचा संपूर्ण मार्ग स्क्रीनवर काढणे
      for (int j = 0; j < rayPoints.length - 1; j++) {
        canvas.drawLine(rayPoints[j], rayPoints[j + 1], rayPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant RayTracerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
