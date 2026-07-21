import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() {
  runApp(const BlackHoleSimulationApp());
}

class BlackHoleSimulationApp extends StatelessWidget {
  const BlackHoleSimulationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const SimulationScreen(),
    );
  }
}

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  late List<BlackHole> _blackHoles;
  final List<Offset> _mergedTrajectory = [];
  bool _isMerged = false;

  // भौतिकशास्त्राचे स्थिरांक (Physics Constants)
  final double G = 150.0; // गुरुत्वाकर्षण स्थिरांक
  final double timeStep = 0.15; // वेळेचा वेग (dt)

  @override
  void initState() {
    super.initState();
    _resetSimulation();

    // प्रत्येक फ्रेम अपडेट करण्यासाठी Ticker वापरला आहे
    _ticker = createTicker((elapsed) {
      setState(() {
        _updatePhysics();
      });
    });
    _ticker.start();
  }

  void _resetSimulation() {
    _isMerged = false;
    _mergedTrajectory.clear();

    // दोन सुरुवातीचे ब्लॅक होल्स (वस्तुमान, स्थान आणि वेग)
    _blackHoles = [
      BlackHole(
        mass: 1200,
        position: const Offset(150, 300),
        //(0,0)
        velocity: const Offset(5, -18),
        color: Colors.yellow,
      ),
      BlackHole(
        mass: 1800,
        position: const Offset(450, 350),
        //(100,150)
        velocity: const Offset(-5, 15),
        color: Colors.yellow,
      ),
    ];
  }

  void _updatePhysics() {
    if (_isMerged) return;

    var bh1 = _blackHoles[0];
    var bh2 = _blackHoles[1];

    // अंतर आणि दिशा मोजणे
    Offset direction = bh2.position - bh1.position;
    double distance = direction.distance;

    // जेव्हा दोन ब्लॅक होल एकमेकांच्या इव्हेंट होरायझन (Event Horizon) मध्ये येतात तेव्हा विलीनीकरण होते
    if (distance <= (bh1.radius + bh2.radius)) {
      _isMerged = true;

      // संवेग संवर्धन नियम (Conservation of Momentum): m1*v1 + m2*v2 = (m1+m2)*v_final
      double totalMass = bh1.mass + bh2.mass;
      Offset finalVelocity =
          (bh1.velocity * bh1.mass + bh2.velocity * bh2.mass) / totalMass;
      Offset finalPosition =
          (bh1.position * bh1.mass + bh2.position * bh2.mass) / totalMass;

      _blackHoles = [
        BlackHole(
          mass: totalMass,
          position: finalPosition,
          velocity: finalVelocity,
          color: Colors.purpleAccent,
        ),
      ];
      return;
    }

    // न्यूटनचा गुरुत्वाकर्षण नियम: F = (G * m1 * m2) / r^2
    double forceMagnitude = (G * bh1.mass * bh2.mass) / (distance * distance);
    Offset forceDirection = direction / distance;
    Offset gravitationalForce = forceDirection * forceMagnitude;

    // ऑर्बिटल डीके (Orbital Decay) - ऊर्जा गमावून जवळ येण्यासाठी काल्पनिक स्पेस फ्रिक्शन
    Offset decayForce = (bh2.velocity - bh1.velocity) * 0.25;

    // त्वरण मोजणे (Acceleration = Force / Mass)
    Offset acc1 = (gravitationalForce + decayForce) / bh1.mass;
    Offset acc2 = (-gravitationalForce - decayForce) / bh2.mass;

    // वेग आणि स्थान अपडेट करणे (Euler Integration)
    bh1.velocity += acc1 * timeStep;
    bh1.position += bh1.velocity * timeStep;
    bh1.updateTrajectory();

    bh2.velocity += acc2 * timeStep;
    bh2.position += bh2.velocity * timeStep;
    bh2.updateTrajectory();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Black Hole Collision'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetSimulation,
          ),
        ],
      ),
      body: CustomPaint(
        painter: SpacePainter(blackHoles: _blackHoles, isMerged: _isMerged),
        child: Container(),
      ),
    );
  }
}

class BlackHole {
  double mass;
  Offset position;
  Offset velocity;
  Color color;
  List<Offset> trajectory = [];

  // वस्तुमानावर आधारित त्रिज्या (Radius proportional to mass)
  double get radius => sqrt(mass) * 0.8;

  BlackHole({
    required this.mass,
    required this.position,
    required this.velocity,
    required this.color,
  });

  void updateTrajectory() {
    trajectory.add(position);
    if (trajectory.length > 80) {
      trajectory.removeAt(0); // जुना ट्रॅक डिलीट करणे
    }
  }
}

class SpacePainter extends CustomPainter {
  final List<BlackHole> blackHoles;
  final bool isMerged;

  SpacePainter({required this.blackHoles, required this.isMerged});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. बॅकग्राउंड स्टार्स ग्रॅविटेशनल लेन्सिंग इफेक्ट दाखवण्यासाठी (काल्पनिक वर्तुळे)
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < size.width; i += 60) {
      for (int j = 0; j < size.height; j += 60) {
        canvas.drawCircle(Offset(i.toDouble(), j.toDouble()), 1, bgPaint);
      }
    }

    // 2. ऑर्बिटल ट्रॅक किंवा पाथ (Orbit Trails) काढणे
    for (var bh in blackHoles) {
      final trailPaint = Paint()
        ..color = bh.color.withOpacity(0.3)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      final path = Path();
      if (bh.trajectory.isNotEmpty) {
        path.moveTo(bh.trajectory.first.dx, bh.trajectory.first.dy);
        for (var point in bh.trajectory) {
          path.lineTo(point.dx, point.dy); // Helper / direct access
        }
      }

      // सोप्या पद्धतीसाठी डायरेक्ट लाईन्स ड्रॉ करणे:
      for (int i = 0; i < bh.trajectory.length - 1; i++) {
        canvas.drawLine(bh.trajectory[i], bh.trajectory[i + 1], trailPaint);
      }

      // 3. ॲक्रेशन डिस्क (Accretion Disk) आणि इव्हेंट होरायझन काढणे
      // बाह्य प्रकाश वलय (Accretion Disk)
      final glowPaint = Paint()
        ..color = bh.color.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
      canvas.drawCircle(bh.position, bh.radius * 2.8, glowPaint);

      final diskPaint = Paint()
        ..color = bh.color.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(bh.position, bh.radius * 1.8, diskPaint);

      // मुख्य ब्लॅक होल सिंगुलरिटी (Event Horizon)
      final singularityPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill;
      canvas.drawCircle(bh.position, bh.radius, singularityPaint);

      // बॉर्डर आउटलाईन
      final borderPaint = Paint()
        ..color = bh.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(bh.position, bh.radius, borderPaint);
    }

    // 4. विलीनीकरणानंतरचा शॉकवेव्ह इफेक्ट (Gravitational Waves Burst)
    if (isMerged && blackHoles.length == 1) {
      final wavePaint = Paint()
        ..color = Colors.purpleAccent.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(
        blackHoles[0].position,
        blackHoles[0].radius * 2.0,
        wavePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SpacePainter oldDelegate) => true;
}
