import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() => runApp(const InterstellarPlasmaApp());

class InterstellarPlasmaApp extends StatelessWidget {
  const InterstellarPlasmaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const PlasmaSimulationScreen(),
    );
  }
}

class PlasmaSimulationScreen extends StatefulWidget {
  const PlasmaSimulationScreen({super.key});
  @override
  State<PlasmaSimulationScreen> createState() => _PlasmaSimulationScreenState();
}

class _PlasmaSimulationScreenState extends State<PlasmaSimulationScreen>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  late List<BlackHoleBody> _blackHoles;
  final List<Offset> _stars = [];
  final List<PlasmaParticle> _particles = [];

  double _gyroX = 0.0;
  double _gyroY = 0.0;
  bool _isMerged = false;

  @override
  void initState() {
    super.initState();
    _generateStars();
    _resetSimulation();

    gyroscopeEvents.listen((GyroscopeEvent event) {
      setState(() {
        _gyroX = (_gyroX + event.y * 1.5).clamp(-30.0, 30.0);
        _gyroY = (_gyroY + event.x * 1.5).clamp(-30.0, 30.0);
      });
    });

    _ticker = createTicker((elapsed) {
      setState(() {
        _updateSimulation();
      });
    });
    _ticker.start();
  }

  void _generateStars() {
    final rand = Random();
    _stars.clear();
    for (int i = 0; i < 150; i++) {
      _stars.add(Offset(rand.nextDouble() * 600, rand.nextDouble() * 1000));
    }
  }

  void _resetSimulation() {
    _isMerged = false;
    _particles.clear();

    // १. दोन मुख्य ब्लॅक होल्स तयार करणे
    _blackHoles = [
      BlackHoleBody(
        id: 1,
        mass: 4000,
        position: const Offset(160, 420),
        velocity: const Offset(2.8, -8.5),
        color: Colors.deepOrangeAccent,
      ),
      BlackHoleBody(
        id: 2,
        mass: 5000,
        position: const Offset(440, 460),
        velocity: const Offset(-2.8, 7.0),
        color: Colors.amberAccent,
      ),
    ];

    // २. दोन्ही ब्लॅक होल्सभोवती फिरणारे प्लाझ्मा पार्टिकल्स तयार करणे (Accretion Disk Particles)
    final rand = Random();
    for (var bh in _blackHoles) {
      int particleCount = bh.id == 1 ? 500 : 600;
      for (int i = 0; i < particleCount; i++) {
        double r = bh.radius * 1.3 + rand.nextDouble() * (bh.radius * 2.2);
        double angle = rand.nextDouble() * pi * 2;
        _particles.add(
          PlasmaParticle(
            blackHoleId: bh.id,
            orbitRadius: r,
            currentAngle: angle,
            // केप्लेरियन गती: जवळचे कण वेगाने फिरतात (v ∝ 1/√r)
            speed: (8.0 / sqrt(r)) * (0.8 + rand.nextDouble() * 0.4),
            size: 1.0 + rand.nextDouble() * 2.0,
            brightness: 0.3 + rand.nextDouble() * 0.7,
          ),
        );
      }
    }
  }

  void _updateSimulation() {
    if (_isMerged) {
      // विलीनीकरणानंतरच्या सिंगल ब्लॅक होलभोवती पार्टिकल्स फिरवणे
      var bh = _blackHoles.first;
      for (var p in _particles) {
        p.blackHoleId = bh.id;
        p.currentAngle += p.speed * 0.3;
      }
      return;
    }

    var bh1 = _blackHoles[0];
    var bh2 = _blackHoles[1];
    Offset direction = bh2.position - bh1.position;
    double distance = direction.distance;

    // कोलिजन डिटेक्शन (Collision & Merger)
    if (distance <= (bh1.radius + bh2.radius)) {
      _isMerged = true;
      double totalMass = bh1.mass + bh2.mass;
      Offset finalVel =
          (bh1.velocity * bh1.mass + bh2.velocity * bh2.mass) / totalMass;
      Offset finalPos =
          (bh1.position * bh1.mass + bh2.position * bh2.mass) / totalMass;

      _blackHoles = [
        BlackHoleBody(
          id: 3,
          mass: totalMass,
          position: finalPos,
          velocity: finalVel,
          color: Colors.purpleAccent,
        ),
      ];
      return;
    }

    // गुरुत्वाकर्षण आणि ऑर्बिटल डीके फिजिक्स
    double force = (140.0 * bh1.mass * bh2.mass) / (distance * distance);
    Offset gForce = (direction / distance) * force;
    Offset decay = (bh2.velocity - bh1.velocity) * 0.38;

    bh1.velocity += (gForce + decay) / bh1.mass;
    bh1.position += bh1.velocity * 0.15;

    bh2.velocity += (-gForce - decay) / bh2.mass;
    bh2.position += bh2.velocity * 0.15;

    // पार्टिकल्सचे पोझिशन अपडेट करणे (दुसऱ्या ब्लॅक होलच्या प्रभावामुळे कणांचे विस्कळीत होणे)
    for (var p in _particles) {
      p.currentAngle += p.speed * 0.3;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Blackhole Simulator')),
      backgroundColor: const Color(0xFF000003),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: ParticleInterstellarPainter(
                blackHoles: _blackHoles,
                stars: _stars,
                particles: _particles,
                gyroX: _gyroX,
                gyroY: _gyroY,
              ),
            ),
          ),
          Positioned(
            top: 50,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white10,
              onPressed: _resetSimulation,
              child: const Icon(Icons.refresh, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class BlackHoleBody {
  final int id;
  double mass;
  Offset position;
  Offset velocity;
  Color color;

  double get radius => sqrt(mass) * 0.72;
  BlackHoleBody({
    required this.id,
    required this.mass,
    required this.position,
    required this.velocity,
    required this.color,
  });
}

class PlasmaParticle {
  int blackHoleId;
  double orbitRadius;
  double currentAngle;
  double speed;
  double size;
  double brightness;

  PlasmaParticle({
    required this.blackHoleId,
    required this.orbitRadius,
    required this.currentAngle,
    required this.speed,
    required this.size,
    required this.brightness,
  });
}

class ParticleInterstellarPainter extends CustomPainter {
  final List<BlackHoleBody> blackHoles;
  final List<Offset> stars;
  final List<PlasmaParticle> particles;
  final double gyroX;
  final double gyroY;

  ParticleInterstellarPainter({
    required this.blackHoles,
    required this.stars,
    required this.particles,
    required this.gyroX,
    required this.gyroY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(gyroX, gyroY);

    // १. बॅकग्राउंड स्टार्स (Lensed Stars)
    final starPaint = Paint()..color = Colors.white.withOpacity(0.7);
    for (var star in stars) {
      Offset pos = Offset(star.dx % size.width, star.dy % size.height);
      canvas.drawCircle(_applyLensing(pos), 1.1, starPaint);
    }

    // २. प्लाझ्मा पार्टिकल डिस्कचे ३D रेंडरिंग (Warped Particle Disk)
    for (var bh in blackHoles) {
      // या विशिष्ट ब्लॅक होलशी संबंधित असलेले कण वेगळे करणे
      final bhParticles = particles
          .where((p) => p.blackHoleId == bh.id || blackHoles.length == 1)
          .toList();

      // अ) मुख्य आडवी डिस्क (Flat Equatorial Ring)
      _renderParticleDisk(canvas, bh, bhParticles, scaleY: 0.22);

      // ब) पाठीमागील वाकलेली वरची कडी (Gravitationally Warped Upper Halo)
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, size.width, bh.position.dy));
      _renderParticleDisk(
        canvas,
        bh,
        bhParticles,
        scaleY: 0.85,
        opacityMod: 0.6,
      );
      canvas.restore();

      // क) पाठीमागील वाकलेली खालची कडी (Gravitationally Warped Lower Halo)
      canvas.save();
      canvas.clipRect(
        Rect.fromLTWH(0, bh.position.dy, size.width, size.height),
      );
      _renderParticleDisk(
        canvas,
        bh,
        bhParticles,
        scaleY: 0.85,
        opacityMod: 0.6,
      );
      canvas.restore();

      // ड) आतील उजळ फोटॉन रिंग (Inner Photon Ring)
      final photonPaint = Paint()
        ..color = bh.color.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(bh.position, bh.radius * 1.12, photonPaint);

      // इ) सिंगुलरिटी शॅडो (The Absolute Black Shadow)
      final shadowPaint = Paint()..color = Colors.black;
      canvas.drawCircle(bh.position, bh.radius, shadowPaint);
    }

    canvas.restore();
  }

  // पार्टिकल्सना ३D मॅट्रिक्सवर प्रोजेक्ट करून काढणारे फंक्शन
  void _renderParticleDisk(
    Canvas canvas,
    BlackHoleBody bh,
    List<PlasmaParticle> pList, {
    required double scaleY,
    double opacityMod = 1.0,
  }) {
    final pPaint = Paint()..style = PaintingStyle.fill;

    for (var p in pList) {
      // कणांचे २D पोलार कोऑर्डिनेट्सवरून कार्टेशियन कोऑर्डिनेट्समध्ये रूपांतर
      double rawX = p.orbitRadius * cos(p.currentAngle);
      double rawY =
          p.orbitRadius * sin(p.currentAngle) * scaleY; // ३D वाकवण्याचा इफेक्ट

      Offset particlePos = bh.position + Offset(rawX, rawY);

      // पार्टिकलच्या रंगात विविधता (कोअरमध्ये पांढरा-उजळ, कडेला नारिंगी)
      double t = (p.orbitRadius - bh.radius * 1.3) / (bh.radius * 2.2);
      Color pColor = Color.lerp(Colors.white, bh.color, t.clamp(0.0, 1.0))!;

      pPaint.color = pColor.withOpacity(p.brightness * opacityMod);

      // कणांचा आकार अंतराप्रमाणे बदलतो
      canvas.drawCircle(particlePos, p.size, pPaint);
    }
  }

  // आयन्स्टाईन लाइट डिस्टॉर्शन
  Offset _applyLensing(Offset point) {
    Offset shifted = point;
    for (var bh in blackHoles) {
      Offset diff = point - bh.position;
      double dist = diff.distance;
      if (dist < bh.radius) {
        shifted = bh.position;
      } else {
        double strength = (bh.radius * bh.radius * 1.8) / dist;
        shifted += diff * (strength / dist);
      }
    }
    return shifted;
  }

  @override
  bool shouldRepaint(covariant ParticleInterstellarPainter oldDelegate) => true;
}
