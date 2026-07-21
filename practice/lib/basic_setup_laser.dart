import 'package:flutter/material.dart';

void main() {
  runApp(const LaserExperimentApp());
}

class LaserExperimentApp extends StatelessWidget {
  const LaserExperimentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const LaserExperimentPage(),
    );
  }
}

class LaserExperimentPage extends StatefulWidget {
  const LaserExperimentPage({super.key});

  @override
  State<LaserExperimentPage> createState() => _LaserExperimentPageState();
}

class _LaserExperimentPageState extends State<LaserExperimentPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isLaserOn = true;

  @override
  void initState() {
    super.initState();
    // लेझर बीम पल्सिंग (pulsing) इफेक्टसाठी ॲनिमेशन
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Breadboard Laser Experiment'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Laser Diode Circuit Setup',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Interactive 2D schematic on a breadboard canvas',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // १. मुख्य ॲनिमेटेड ब्रेडबोर्ड कॅनव्हास (Visual Anchor)
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(360, 400),
                      painter: BreadboardLaserPainter(
                        animationValue: _animationController.value,
                        isLaserOn: _isLaserOn,
                      ),
                    );
                  },
                ),
              ),
            ),

            // २. लेझर चालू/बंद करण्याचा कंट्रोल स्विच
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Power Supply: ', style: TextStyle(fontSize: 16)),
                Switch(
                  value: _isLaserOn,
                  activeColor: Colors.redAccent,
                  onChanged: (value) {
                    setState(() {
                      _isLaserOn = value;
                    });
                  },
                ),
                Text(
                  _isLaserOn ? "ON" : "OFF",
                  style: TextStyle(
                    color: _isLaserOn ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ३. कस्टम पेंटर - जो ब्रेडबोर्ड आणि संपूर्ण सर्किट घटकांना ड्राॅ करतो
class BreadboardLaserPainter extends CustomPainter {
  final double animationValue;
  final bool isLaserOn;

  BreadboardLaserPainter({
    required this.animationValue,
    required this.isLaserOn,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // अ. ब्रेडबोर्ड बॅकग्राउंड ड्राॅ करणे (White Breadboard Body)
    final breadboardPaint = Paint()
      ..color = const Color(0xFFF0F0F0)
      ..style = PaintingStyle.fill;

    final RRect breadboardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(10, 10, size.width - 20, size.height - 20),
      const Radius.circular(15),
    );
    canvas.drawRRect(breadboardRect, breadboardPaint);

    // ब. ब्रेडबोर्डवरील होल्स (Pin Holes Matrix) ड्राॅ करणे
    final holePaint = Paint()..color = Colors.black, style = PaintingStyle.fill;

    for (int row = 0; row < 25; row++) {
      for (int col = 0; col < 10; col++) {
        double x =
            40.0 +
            (col * 15.0) +
            (col >= 5 ? 30.0 : 0); // मध्यभागी गॅप ठेवण्यासाठी
        double y = 40.0 + (row * 13.0);
        canvas.drawCircle(Offset(x, y), 2.0, holePaint);
      }
    }

    // क. पॉवरलाईन्स (Red and Blue Rails)
    final redRail = Paint()
      ..color = Colors.red
      ..strokeWidth = 2;
    final blueRail = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2;
    canvas.drawLine(
      const Offset(25, 35),
      Offset(25, size.height - 35),
      redRail,
    );
    canvas.drawLine(
      const Offset(25, 35),
      Offset(size.width - 25, size.height - 35),
      blueRail,
    );

    // ड. सर्किट कॉम्पोनंट्स: रेझिस्टर (Resistor)
    final componentPaint = Paint()
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // रेझिस्टरच्या वायरी (Connecting Leads)
    componentPaint.color = Colors.grey;
    canvas.drawLine(
      const Offset(40, 100),
      const Offset(100, 100),
      componentPaint,
    );
    // रेझिस्टर बॉडी
    final resistorBody = Paint()
      ..color = const Color(0xFFD2B48C)
      ..style = PaintingStyle.fill;
    canvas.drawRect(const Rect.fromLTWH(55, 93, 30, 14), resistorBody);
    // रेझिस्टर कलर बँड्स (Color Bands)
    final bandPaint = Paint()..style = PaintingStyle.fill;
    bandPaint.color = Colors.brown;
    canvas.drawRect(const Rect.fromLTWH(60, 93, 4, 14), bandPaint);
    bandPaint.color = Colors.black;
    canvas.drawRect(const Rect.fromLTWH(68, 93, 4, 14), bandPaint);
    bandPaint.color = Colors.red;
    canvas.drawRect(const Rect.fromLTWH(76, 93, 4, 14), bandPaint);

    // इ. लेझर डायोड मॉड्यूल (Laser Diode Module)
    final laserModulePaint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      const Rect.fromLTWH(70, 180, 50, 30),
      laserModulePaint,
    ); // मुख्य ब्रास बॉडी

    // लेझर लेन्स कॅप (Front Lens)
    final lensCapPaint = Paint()
      ..color = Colors.yellow.shade700
      ..style = PaintingStyle.fill;
    canvas.drawRect(const Rect.fromLTWH(85, 210, 20, 10), lensCapPaint);

    // फ. पॉवर जंपर वायरी (Jumper Wires)
    final wirePaint = Paint()
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    wirePaint.color = Colors.red; // पॉवर रेल ते रेझिस्टर
    canvas.drawLine(const Offset(25, 100), const Offset(40, 100), wirePaint);

    wirePaint.color = Colors.green; // रेझिस्टर ते लेझर इनपुट
    canvas.drawLine(const Offset(100, 100), const Offset(95, 180), wirePaint);

    wirePaint.color = Colors.black; // लेझर ग्राउंड ते निळा रेल
    canvas.drawLine(const Offset(115, 180), const Offset(115, 150), wirePaint);
    canvas.drawLine(
      const Offset(115, 150),
      Offset(size.width - 25, 150),
      wirePaint,
    );

    // ग. ॲनिमेटेड लेझर बीम (Animated Laser Beam Emission)
    if (isLaserOn) {
      // बीमचा प्रकाश बदलण्यासाठी अ‍ॅनिमेशन व्हॅल्यूचा वापर (Pulsing Glow Effect)
      double beamWidth = 2.0 + (animationValue * 3.0);
      double glowAlpha = 50 + (animationValue * 150);

      // बाहेरील ग्लो इफेक्ट (Outer Glow)
      final laserGlow = Paint()
        ..color = Colors.red.withAlpha(glowAlpha.round())
        ..strokeWidth = beamWidth * 3
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        const Offset(95, 220),
        Offset(95, size.height - 40),
        laserGlow,
      );

      // आतील मुख्य तीव्र प्रकाश (Core Beam)
      final laserCore = Paint()
        ..color = Colors.white
        ..strokeWidth = beamWidth
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        const Offset(95, 220),
        Offset(95, size.height - 40),
        laserCore,
      );

      // लेझर डॉट/टार्गेट (Target Dot on the floor)
      final targetDot = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(95, size.height - 40),
        6 + (animationValue * 4),
        targetDot,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BreadboardLaserPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isLaserOn != isLaserOn;
  }
}
