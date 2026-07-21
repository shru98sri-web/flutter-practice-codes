import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LagrangianSimulationApp(),
    ),
  );
}

class LagrangianSimulationApp extends StatefulWidget {
  const LagrangianSimulationApp({super.key});

  @override
  State<LagrangianSimulationApp> createState() =>
      _LagrangianSimulationAppState();
}

class _LagrangianSimulationAppState extends State<LagrangianSimulationApp>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;

  // बदलणारे भौतिकशास्त्राचे गुणधर्म (Adjustable Physics Parameters via Sliders)
  double g = 9.81; // गुरुत्वाकर्षण (Gravity)
  double l1 = 110.0; // पहिल्या दांडीची लांबी (Length 1)
  double l2 = 110.0; // दुसऱ्या दांडीची लांबी (Length 2)
  double m1 = 10.0; // पहिल्या गोळ्याचे वजन (Mass 1)
  double m2 = 10.0; // दुसऱ्या गोळ्याचे वजन (Mass 2)

  // स्थिती दर्शक कोन (State Variables)
  double theta1 = pi / 2;
  double theta2 = pi / 2;
  double omega1 = 0.0;
  double omega2 = 0.0;

  // मार्गाचा माग ठेवण्यासाठी यादी (Trace path array)
  List<Offset> pathTrace = [];

  @override
  void initState() {
    super.initState();
    // प्रत्येक फ्रेमला भौतिकशास्त्राची गती मोजण्यासाठी Ticker
    _ticker = createTicker((Duration elapsed) {
      _updatePhysics();
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // लॅग्रेंजियन समीकरणांमधून मिळालेली प्रवेग (Acceleration) सूत्रे
  void _updatePhysics() {
    const double dt = 0.15; // वेळेचा लहान भाग (Time step)
    double delta = theta1 - theta2;

    // Euler-Lagrange समीकरणांवरून काढलेले मुख्य प्रवेग सूत्र
    double num1 =
        -g * (2 * m1 + m2) * sin(theta1) -
        m2 * g * sin(theta1 - 2 * theta2) -
        2 *
            sin(delta) *
            m2 *
            (omega2 * omega2 * l2 + omega1 * omega1 * l1 * cos(delta));
    double den1 = l1 * (2 * m1 + m2 - m2 * cos(2 * theta1 - 2 * theta2));
    double alpha1 = num1 / den1;

    double num2 =
        2 *
        sin(delta) *
        (omega1 * omega1 * l1 * (m1 + m2) +
            g * (m1 + m2) * cos(theta1) +
            omega2 * omega2 * l2 * m2 * cos(delta));
    double den2 = l2 * (2 * m1 + m2 - m2 * cos(2 * theta1 - 2 * theta2));
    double alpha2 = num2 / den2;

    setState(() {
      // कोनीय गती आणि कोन अपडेट करणे
      omega1 += alpha1 * dt;
      omega2 += alpha2 * dt;
      theta1 += omega1 * dt;
      theta2 += omega2 * dt;

      // हवेचा रोध (Damping factor)
      omega1 *= 0.999;
      omega2 *= 0.999;
    });
  }

  void _resetSimulation() {
    setState(() {
      theta1 = pi / 2;
      theta2 = pi / 2;
      omega1 = 0.0;
      omega2 = 0.0;
      pathTrace.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111424),
      appBar: AppBar(
        title: const Text(
          'Lagrangian Double Pendulum',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1A1F38),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _resetSimulation,
          ),
        ],
      ),
      body: Column(
        children: [
          // १. लंबक फिरण्याचे मुख्य कॅनव्हास (Simulation Viewport)
          Expanded(
            flex: 3,
            child: ClipRect(
              child: CustomPaint(
                size: Size.infinite,
                painter: PendulumPainter(
                  theta1: theta1,
                  theta2: theta2,
                  l1: l1,
                  l2: l2,
                  m1: m1,
                  m2: m2,
                  pathTrace: pathTrace,
                ),
              ),
            ),
          ),

          // २. स्लायडर्स नियंत्रण पॅनेल (Control Sliders Panel)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1F38),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSliderRow(
                    'Length 1 (L1)',
                    l1,
                    40.0,
                    160.0,
                    (val) => setState(() => l1 = val),
                  ),
                  _buildSliderRow(
                    'Length 2 (L2)',
                    l2,
                    40.0,
                    160.0,
                    (val) => setState(() => l2 = val),
                  ),
                  _buildSliderRow(
                    'Mass 1 (M1)',
                    m1,
                    2.0,
                    30.0,
                    (val) => setState(() => m1 = val),
                  ),
                  _buildSliderRow(
                    'Mass 2 (M2)',
                    m2,
                    2.0,
                    30.0,
                    (val) => setState(() => m2 = val),
                  ),
                  _buildSliderRow(
                    'Gravity (g)',
                    g,
                    1.0,
                    25.0,
                    (val) => setState(() => g = val),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // स्लायडर डिझाईन तयार करणारे हेल्पवर फंक्शन
  Widget _buildSliderRow(
    String label,
    double currentVal,
    double minVal,
    double maxVal,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: currentVal,
                min: minVal,
                max: maxVal,
                activeColor: Colors.cyanAccent,
                inactiveColor: Colors.white12,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 45,
            child: Text(
              currentVal.toStringAsFixed(1),
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class PendulumPainter extends CustomPainter {
  final double theta1;
  final double theta2;
  final double l1;
  final double l2;
  final double m1;
  final double m2;
  final List<Offset> pathTrace;

  PendulumPainter({
    required this.theta1,
    required this.theta2,
    required this.l1,
    required this.l2,
    required this.m1,
    required this.m2,
    required this.pathTrace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // स्क्रीनच्या मध्यभागी मुख्य अँकर पॉईंट ठेवणे
    final Offset origin = Offset(size.width / 2, size.height * 0.35);

    // पहिल्या बॉबची स्थिती (Cartesian Coordinates of Bob 1)
    double x1 = origin.dx + l1 * sin(theta1);
    double y1 = origin.dy + l1 * cos(theta1);
    Offset bob1 = Offset(x1, y1);

    // दुसऱ्या बॉबची स्थिती (Cartesian Coordinates of Bob 2)
    double x2 = x1 + l2 * sin(theta2);
    double y2 = y1 + l2 * cos(theta2);
    Offset bob2 = Offset(x2, y2);

    // मार्गाचा ट्रॅक मर्यादित ठेवणे जेणेकरून मेमरीवर ताण येणार नाही
    if (pathTrace.length > 200) {
      pathTrace.removeAt(0);
    }
    pathTrace.add(bob2);

    // १. मागचा निळा ट्रॅक पेंट करणे (Draw Trace Path)
    final pathPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.35)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    if (pathTrace.isNotEmpty) {
      path.moveTo(pathTrace.first.dx, pathTrace.first.dy);
      for (var point in pathTrace) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, pathPaint);
    }

    // २. रिकामा सपोर्ट / दांड्या पेंट करणे (Draw Rods)
    final rodPaint = Paint()
      ..color = Colors.white60
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(origin, bob1, rodPaint);
    canvas.drawLine(bob1, bob2, rodPaint);

    // ३. बॉब्स पेंट करणे (गोळ्याचा आकार वजनानुसार (Mass) लहान-मोठा होईल)
    final bob1Paint = Paint()..color = Colors.orangeAccent;
    final bob2Paint = Paint()..color = Colors.cyanAccent;
    final centerAnchorPaint = Paint()..color = Colors.white;

    // वजनाच्या प्रमाणात त्रिज्या ठरवणे (Radius dynamically scales with Mass)
    double r1 = 4 + (m1 * 0.6);
    double r2 = 4 + (m2 * 0.6);

    canvas.drawCircle(origin, 5, centerAnchorPaint); // मुख्य अक्ष
    canvas.drawCircle(bob1, r1, bob1Paint); // पहिला गोळा
    canvas.drawCircle(bob2, r2, bob2Paint); // दुसरा गोळा
  }

  @override
  bool shouldRepaint(covariant PendulumPainter oldDelegate) {
    return oldDelegate.theta1 != theta1 ||
        oldDelegate.theta2 != theta2 ||
        oldDelegate.l1 != l1 ||
        oldDelegate.l2 != l2 ||
        oldDelegate.m1 != m1 ||
        oldDelegate.m2 != m2;
  }
}
