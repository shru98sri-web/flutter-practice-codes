import 'dart:math';

import 'package:flutter/material.dart';

void main() => runApp(const RamanEffectApp());

class RamanEffectApp extends StatelessWidget {
  const RamanEffectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RamanSliderScreen(),
    );
  }
}

class RamanSliderScreen extends StatefulWidget {
  const RamanSliderScreen({super.key});

  @override
  State<RamanSliderScreen> createState() => _RamanSliderScreenState();
}

class _RamanSliderScreenState extends State<RamanSliderScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _shiftValue =
      0.0; // 0.0 म्हणजे Rayleigh, -1.0 म्हणजे Stokes, +1.0 म्हणजे Anti-Stokes

  @override
  void initState() {
    super.initState();
    // लहरी सतत गतिमान ठेवण्यासाठी ॲनिमेशन कंट्रोलर
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getScatteringType() {
    if (_shiftValue < -0.1) return 'Stokes Shift ';
    if (_shiftValue > 0.1) return 'Anti-Stokes Shift';
    return 'Rayleigh Scattering';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Raman Effect Simulator'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: RamanAnimatedPainter(
                    shift: _shiftValue,
                    animationValue: _controller.value,
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20.0),
            color: Colors.grey[900],
            child: Column(
              children: [
                Text(
                  _getScatteringType(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Shift Value: ${_shiftValue.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Slider(
                  value: _shiftValue,
                  min: -1.0,
                  max: 1.0,
                  activeColor: _shiftValue < 0
                      ? Colors.red
                      : (_shiftValue > 0 ? Colors.purple : Colors.blue),
                  inactiveColor: Colors.white24,
                  onChanged: (value) {
                    setState(() {
                      _shiftValue = value;
                    });
                  },
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Stokes (-1)', style: TextStyle(color: Colors.red)),
                    Text('Rayleigh (0)', style: TextStyle(color: Colors.blue)),
                    Text(
                      'Anti-Stokes (+1)',
                      style: TextStyle(color: Colors.purple),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RamanAnimatedPainter extends CustomPainter {
  final double shift;
  final double animationValue;

  RamanAnimatedPainter({required this.shift, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final phase = animationValue * 2 * pi;

    // १. इन्सिडेंट लाइट (Incident Light - नेहमी निळा आणि स्थिर वारंवारता)
    final incidentPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final incidentPath = Path();
    incidentPath.moveTo(0, center.dy);
    for (double i = 0; i < center.dx; i++) {
      // मूळ वारंवारता (Frequency) = 0.06
      incidentPath.lineTo(i, center.dy + sin(i * 0.06 - phase) * 25);
    }
    canvas.drawPath(incidentPath, incidentPaint);

    // २. रेणू / मॉलिक्युल (Scattering Molecule)
    final moleculePaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, 18, moleculePaint);
    canvas.drawCircle(
      center,
      22,
      Paint()
        ..color = Colors.white24
        ..style = PaintingStyle.stroke,
    );

    // ३. स्कॅटर्ड लाइट लॉजिक (Scattered Light)
    Color scatteredColor = Colors.blue;
    double baseFrequency = 0.06;

    if (shift < -0.1) {
      // Stokes: ऊर्जा कमी होते -> वारंवारता कमी होते (लाल रंग)
      scatteredColor = Color.lerp(Colors.blue, Colors.red, shift.abs())!;
      baseFrequency = 0.06 - (shift.abs() * 0.03);
    } else if (shift > 0.1) {
      // Anti-Stokes: ऊर्जा वाढते -> वारंवारता वाढते (जांभळा रंग)
      scatteredColor = Color.lerp(Colors.blue, Colors.purpleAccent, shift)!;
      baseFrequency = 0.06 + (shift * 0.04);
    }

    final scatteredPaint = Paint()
      ..color = scatteredColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final scatteredPath = Path();
    scatteredPath.moveTo(center.dx, center.dy);
    for (double i = center.dx; i < size.width; i++) {
      double relativeX = i - center.dx;
      scatteredPath.lineTo(
        i,
        center.dy + sin(relativeX * baseFrequency - phase) * 25,
      );
    }
    canvas.drawPath(scatteredPath, scatteredPaint);
  }

  @override
  bool shouldRepaint(covariant RamanAnimatedPainter oldDelegate) {
    return oldDelegate.shift != shift ||
        oldDelegate.animationValue != animationValue;
  }
}
