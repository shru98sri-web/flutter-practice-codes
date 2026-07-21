import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(title: const Text('DCS Optical Setup Layout')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: AspectRatio(
              aspectRatio:
                  2.1, // इमेजच्या लांबी-रुंदीच्या प्रमाणात (Layout Ratio)
              child: DCSSetupWidget(),
            ),
          ),
        ),
      ),
    );
  }
}

class DCSSetupWidget extends StatelessWidget {
  const DCSSetupWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // १. मुख्य डायग्राम रेखाटण्यासाठी CustomPaint
        Positioned.fill(child: CustomPaint(painter: OpticalSetupPainter())),
        // २. डायग्राममधील महत्त्वाचे मजकूर (Labels) योग्य ठिकाणी प्लेस करण्यासाठी Positioned Widgets
        const Positioned(top: 40, left: 140, child: SetupLabel('Master Comb')),
        const Positioned(
          bottom: 50,
          left: 120,
          child: SetupLabel('Slave Comb'),
        ),
        const Positioned(
          top: 10,
          left: 280,
          child: SetupLabel('Lens1 + PPLN1'),
        ),
        const Positioned(top: 10, left: 540, child: SetupLabel('AOM')),
        const Positioned(top: 10, left: 660, child: SetupLabel('Rb Cell')),
        const Positioned(top: 10, left: 880, child: SetupLabel('Grating')),
        const Positioned(
          top: 140,
          left: 330,
          child: SetupLabel('Retroreflector & Delay'),
        ),
        const Positioned(
          bottom: 20,
          right: 230,
          child: SetupLabel('Monitor / 3D Data'),
        ),
      ],
    );
  }
}

// लेबल डिझाईन करण्यासाठी छोटा साहाय्यक विजेट
class SetupLabel extends StatelessWidget {
  final String text;
  const SetupLabel(this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade700, width: 0.5),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: Colors.white70),
      ),
    );
  }
}

// ३. Custom Painter क्लास - जो लेझर लाईन्स आणि ब्लॉक शेप्स ड्रॉ करतो
class OpticalSetupPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // रंगांचे ब्रशेस (Paints) तयार करणे
    final laserPaint = Paint()
      ..color = Colors.redAccent.withOpacity(0.9)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final referenceLaserPaint = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final blockPaint = Paint()
      ..color = Colors.blueGrey.shade800
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final mirrorPaint = Paint()
      ..color = Colors.amberAccent
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    // -------------------------------------------------------------
    // अ) लेझर पाथ्स आणि ऑप्टिकल लाईन्स रेखाटणे (Laser Beams)
    // -------------------------------------------------------------

    // १. मास्टर कॉम्ब मधून निघणारा मुख्य वरील लेझर बीम
    final Path topLaserPath = Path()
      ..moveTo(w * 0.22, h * 0.25) // Master comb मधून बाहेर
      ..lineTo(w * 0.82, h * 0.25) // सरळ BS (Beam Splitter) पर्यंत
      ..lineTo(w * 0.82, h * 0.80) // खाली PBS3 कडे वळणारा बीम
      ..lineTo(w * 0.92, h * 0.80);
    canvas.drawPath(topLaserPath, laserPaint);

    // २. स्लेव्ह कॉम्ब मधून निघणारा खालील लेझर बीम
    final Path bottomLaserPath = Path()
      ..moveTo(w * 0.22, h * 0.70) // Slave comb मधून बाहेर
      ..lineTo(w * 0.82, h * 0.70); // सरळ मुख्य आरशापर्यंत (Mirror)
    canvas.drawPath(bottomLaserPath, laserPaint..color = Colors.red.shade700);

    // ३. डिले लाईन आणि रेट्रोरिफ्लेक्टरचा अंतर्गत बीम पाथ (Retroreflector Delay Path)
    final Path delayBeamPath = Path()
      ..moveTo(w * 0.48, h * 0.25) // PBS1 मधून कट होऊन खाली
      ..lineTo(w * 0.48, h * 0.40) // Mirror1 कडे
      ..lineTo(w * 0.32, h * 0.40) // Retroreflector कडे आत
      ..lineTo(w * 0.32, h * 0.48) // Retroreflector मधून बाहेर
      ..lineTo(w * 0.58, h * 0.48) // Mirror2 कडे
      ..lineTo(w * 0.58, h * 0.25); // PBS2 मध्ये परत मिक्स होतो
    canvas.drawPath(delayBeamPath, referenceLaserPaint);

    // ४. शेवटचा डिटेक्टर फायबर पाथ (Monitor connection)
    final Path monitorCablePath = Path()
      ..moveTo(w * 0.92, h * 0.80)
      ..cubicTo(w * 0.95, h * 0.90, w * 0.80, h * 0.95, w * 0.75, h * 0.85);
    canvas.drawPath(
      monitorCablePath,
      Paint()
        ..color = Colors.grey
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // -------------------------------------------------------------
    // ब) फिजिकल ब्लॉक्स आणि कंपोनेंट्स ड्रॉ करणे (Optical Components)
    // -------------------------------------------------------------

    // १. मास्टर कॉम्ब ब्लॉक (Master Comb Box)
    Rect masterComb = Rect.fromLTWH(w * 0.10, h * 0.15, w * 0.12, h * 0.18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(masterComb, const Radius.circular(8)),
      blockPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(masterComb, const Radius.circular(8)),
      borderPaint,
    );

    // २. स्लेव्ह कॉम्ब ब्लॉक (Slave Comb Box)
    Rect slaveComb = Rect.fromLTWH(w * 0.10, h * 0.60, w * 0.12, h * 0.18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(slaveComb, const Radius.circular(8)),
      blockPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(slaveComb, const Radius.circular(8)),
      borderPaint,
    );

    // ३. CW लेझर लिंकिंग ब्लॉक (Center CW Laser)
    Rect cwLaser = Rect.fromLTWH(w * 0.13, h * 0.40, w * 0.06, h * 0.12);
    canvas.drawRect(cwLaser, blockPaint..color = Colors.orange.shade900);
    canvas.drawRect(cwLaser, borderPaint);

    // ४. PPLN क्रिस्टल्स आणि लेन्स (लहान आयताकृती ब्लॉक्स)
    canvas.drawRect(
      Rect.fromLTWH(w * 0.26, h * 0.20, w * 0.04, h * 0.10),
      blockPaint..color = Colors.cyan.shade700,
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.26, h * 0.65, w * 0.04, h * 0.10),
      blockPaint,
    );

    // ५. AOM (Acousto-Optic Modulator) मध्यवर्ती ब्लॉक
    Rect aomBlock = Rect.fromLTWH(w * 0.52, h * 0.18, w * 0.05, h * 0.14);
    canvas.drawRect(aomBlock, blockPaint..color = Colors.deepOrange.shade800);
    canvas.drawRect(aomBlock, borderPaint);

    // ६. रुबिडियम सेल (Rb Cell Gas Chamber)
    Rect rbCell = Rect.fromLTWH(w * 0.64, h * 0.18, w * 0.08, h * 0.14);
    canvas.drawRect(rbCell, blockPaint..color = Colors.blueGrey.shade900);
    canvas.drawRect(rbCell, borderPaint..color = Colors.redAccent);

    // ७. आरसे (Yellow Reflective Mirrors)
    canvas.drawLine(
      Offset(w * 0.46, h * 0.38),
      Offset(w * 0.50, h * 0.42),
      mirrorPaint,
    ); // Mirror 1
    canvas.drawLine(
      Offset(w * 0.56, h * 0.46),
      Offset(w * 0.60, h * 0.50),
      mirrorPaint,
    ); // Mirror 2
    canvas.drawLine(
      Offset(w * 0.80, h * 0.72),
      Offset(w * 0.84, h * 0.68),
      mirrorPaint,
    ); // Bottom turning mirror

    // ८. मॉनिटर आकृती (Screen Boundary)
    Rect screen = Rect.fromLTWH(w * 0.66, h * 0.75, w * 0.14, h * 0.20);
    canvas.drawRect(screen, blockPaint..color = Colors.black);
    canvas.drawRect(screen, borderPaint..color = Colors.blueAccent);
  }

  @override
  bool shouldRepaint(covariant OpticalSetupPainter oldDelegate) => false;
}
