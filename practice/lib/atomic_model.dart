import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  runApp(const AnimatedAtomApp());
}

class AnimatedAtomApp extends StatelessWidget {
  const AnimatedAtomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const AtomSliderPage(),
    );
  }
}

class AtomSliderPage extends StatefulWidget {
  const AtomSliderPage({super.key});

  @override
  State<AtomSliderPage> createState() => _AtomSliderPageState();
}

class _AtomSliderPageState extends State<AtomSliderPage>
    with SingleTickerProviderStateMixin {
  double _currentAtomicNumber = 6.0; // डिफॉल्ट कार्बन (Z=6)
  late AnimationController _animationController;

  // घटकांचा डेटाबेस (नाव आणि इलेक्ट्रॉन शेल कॉन्फिगरेशन Bohr model नुसार)
  final Map<int, Map<String, dynamic>> _elementDatabase = {
    1: {
      'symbol': 'H',
      'name': 'Hydrogen',
      'shells': [1],
    },
    2: {
      'symbol': 'He',
      'name': 'Helium',
      'shells': [2],
    },
    3: {
      'symbol': 'Li',
      'name': 'Lithium',
      'shells': [2, 1],
    },
    4: {
      'symbol': 'Be',
      'name': 'Beryllium',
      'shells': [2, 2],
    },
    6: {
      'symbol': 'C',
      'name': 'Carbon',
      'shells': [2, 4],
    },
    8: {
      'symbol': 'O',
      'name': 'Oxygen',
      'shells': [2, 6],
    },
    10: {
      'symbol': 'Ne',
      'name': 'Neon',
      'shells': [2, 8],
    },
    11: {
      'symbol': 'Na',
      'name': 'Sodium',
      'shells': [2, 8, 1],
    },
    14: {
      'symbol': 'Si',
      'name': 'Silicon',
      'shells': [2, 8, 4],
    },
    18: {
      'symbol': 'Ar',
      'name': 'Argon',
      'shells': [2, 8, 8],
    },
    26: {
      'symbol': 'Fe',
      'name': 'Iron',
      'shells': [2, 8, 14, 2],
    },
    79: {
      'symbol': 'Au',
      'name': 'Gold',
      'shells': [2, 8, 18, 32, 18, 1],
    },
    118: {
      'symbol': 'Og',
      'name': 'Oganesson',
      'shells': [2, 8, 18, 32, 32, 18, 8],
    },
  };

  @override
  void initState() {
    // इलेक्ट्रॉन फिरण्यासाठी अविरत चालणारे ॲनिमेशन (Continuous Animation)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // डेटाबेसमध्ये नसलेल्या अणूंसाठी शेल्स कॅल्क्युलेट करणारे अल्गोरिदम
  List<int> _getShellConfiguration(int z) {
    if (_elementDatabase.containsKey(z)) {
      return _elementDatabase[z]!['shells'];
    }
    // मॅक्सिमम क्षमता Bohr नियमानुसार: 2, 8, 18, 32...
    List<int> shells = [];
    int remaining = z;
    List<int> maxCapacities = [2, 8, 18, 32, 32, 18, 8];
    for (int capacity in maxCapacities) {
      if (remaining <= 0) break;
      if (remaining <= capacity) {
        shells.add(remaining);
        remaining = 0;
      } else {
        shells.add(capacity);
        remaining -= capacity;
      }
    }
    return shells;
  }

  String _getElementName(int z) => _elementDatabase[z]?['name'] ?? 'Element $z';
  String _getElementSymbol(int z) => _elementDatabase[z]?['symbol'] ?? 'El';

  @override
  Widget build(BuildContext context) {
    int intZ = _currentAtomicNumber.round();
    List<int> shells = _getShellConfiguration(intZ);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Animated Atomic Diagram'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // १. अणू माहिती मजकूर
            Text(
              '${_getElementName(intZ)} (${_getElementSymbol(intZ)})',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.cyanAccent,
              ),
            ),
            Text(
              'Atomic Number (Z) = $intZ | Electron Shells: ${shells.toString()}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // २. मुख्य ॲनिमेटेड अणू आकृती (Visual Anchor)
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(300, 300),
                      painter: AtomPainter(
                        shells: shells,
                        rotationValue: _animationController.value,
                        symbol: _getElementSymbol(intZ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ३. कंट्रोल करण्यासाठी स्लाइडर
            const Text('Slide to change Atomic Number (1-118)'),
            Slider(
              value: _currentAtomicNumber,
              min: 1,
              max: 118,
              divisions: 117,
              label: intZ.toString(),
              activeColor: Colors.cyanAccent,
              onChanged: (double value) {
                setState(() {
                  _currentAtomicNumber = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ४. कस्टम पेंटर - जो अणूची कक्षा (Orbits) आणि फिरणारे इलेक्ट्रॉन्स ड्रॉ करतो
class AtomPainter extends CustomPainter {
  final List<int> shells;
  final double rotationValue;
  final String symbol;

  AtomPainter({
    required this.shells,
    required this.rotationValue,
    required this.symbol,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // न्यूक्लियस (Nucleus Paint)
    final nucleusPaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 18, nucleusPaint);

    // केंद्रस्थानी रासायनिक संज्ञा लिहिणे (Symbol text in Nucleus)
    final textPainter = TextPainter(
      text: TextSpan(
        text: symbol,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );

    // कक्षा (Orbits Paint)
    final orbitPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // इलेक्ट्रॉन (Electron Paint)
    final electronPaint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.fill;

    // प्रत्येक शेल आणि त्यातील इलेक्ट्रॉन ड्रॉ करणे
    for (int i = 0; i < shells.length; i++) {
      double radius = 40.0 + (i * 22); // प्रत्येक कक्षेमधील अंतर
      int electronCount = shells[i];

      // कक्षा वर्तुळ काढणे (Draw Orbit Ring)
      canvas.drawCircle(center, radius, orbitPaint);

      // या कक्षेतील सर्व इलेक्ट्रॉन्स विशिष्ट कोनात फिरवणे (Place & Rotate Electrons)
      for (int j = 0; j < electronCount; j++) {
        // वर्तुळातील प्रत्येक इलेक्ट्रॉनमधील कोनाचे अंतर (Spacing Angle)
        double baseAngle = (j * 2 * math.pi) / electronCount;

        // वेगवेगळ्या कक्षेतील इलेक्ट्रॉन वेगवेगळ्या गतीने फिरवण्यासाठी (Dynamic Speed)
        double currentAngle =
            baseAngle + (rotationValue * 2 * math.pi * (1.0 / (i + 1)));

        // त्रिकोणमितीनुसार X आणि Y कोऑर्डिनेट्स शोधणे
        double electronX = center.dx + radius * math.cos(currentAngle);
        double electronY = center.dy + radius * math.sin(currentAngle);

        // इलेक्ट्रॉन ड्रॉ करणे (Draw Electron Dot)
        canvas.drawCircle(Offset(electronX, electronY), 4.5, electronPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant AtomPainter oldDelegate) => true;
}
