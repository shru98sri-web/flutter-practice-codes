import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ZeemanAnomalousApp());
}

class ZeemanAnomalousApp extends StatelessWidget {
  const ZeemanAnomalousApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Advanced Zeeman Effect Simulator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F111A),
        sliderTheme: const SliderThemeData(
          showValueIndicator: ShowValueIndicator.always,
        ),
      ),
      home: const ZeemanSimulationPage(),
    );
  }
}

class ZeemanSimulationPage extends StatefulWidget {
  const ZeemanSimulationPage({super.key});

  @override
  State<ZeemanSimulationPage> createState() => _ZeemanSimulationPageState();
}

class _ZeemanSimulationPageState extends State<ZeemanSimulationPage>
    with SingleTickerProviderStateMixin {
  // नियंत्रण चल (Control Variables)
  double _bField = 1.5; // Magnetic field strength (Tesla)
  double _lValue = 1.0; // Orbital Angular Momentum L
  double _sValue = 0.5; // Spin Angular Momentum S
  double _jValue = 1.5; // Total Angular Momentum J (L + S)

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
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

  // Landé g-factor ची गणना करणारे सूत्र
  double get _landeGFactor {
    if (_jValue == 0) return 0.0;
    double numerator =
        (_jValue * (_jValue + 1)) +
        (_sValue * (_sValue + 1)) -
        (_lValue * (_lValue + 1));
    double denominator = 2 * _jValue * (_jValue + 1);
    return 1.0 + (numerator / denominator);
  }

  // J मूल्याच्या आधारे शक्य असणाऱ्या Magnetic Quantum Numbers (Mj) ची यादी मिळवणे
  List<double> get _getMjValues {
    List<double> mjList = [];
    double current = -_jValue;
    // फ्लोटिंग पॉइंट एरर टाळण्यासाठी सूक्ष्म फरक (0.001) वापरला आहे
    while (current <= _jValue + 0.001) {
      mjList.add(current);
      current += 1.0;
    }
    return mjList;
  }

  @override
  Widget build(BuildContext context) {
    // J चे मूल्य L आणि S च्या मर्यादेत ठेवणे (सुरक्षितता)
    double maxJ = _lValue + _sValue;
    double minJ = (_lValue - _sValue).abs();
    if (_jValue > maxJ || _jValue < minJ) {
      _jValue = maxJ;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anomalous Zeeman & Fabry-Perot Simulator'),
        backgroundColor: const Color(0xFF171A26),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // जर स्क्रीनची रुंदी कमी असेल (मोबाईल), तर कॉलम आणि मोठ्या स्क्रीनवर (वेब/डेस्कटॉप) रो (Row) वापरणे
          bool isWide = constraints.maxWidth > 800;

          Widget controlPanel = Container(
            color: const Color(0xFF171A26),
            padding: const EdgeInsets.all(20.0),
            child: ListView(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              children: [
                const Text(
                  'Simulation Controls',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan,
                  ),
                ),
                const Divider(color: Colors.white24, height: 24),

                // Magnetic Field Slider
                Text(
                  'Magnetic Field (B): ${_bField.toStringAsFixed(2)} Tesla',
                  style: const TextStyle(fontSize: 14),
                ),
                Slider(
                  value: _bField,
                  min: 0.0,
                  max: 4.0,
                  divisions: 40,
                  activeColor: Colors.cyan,
                  onChanged: (val) => setState(() => _bField = val),
                ),

                // Orbital Angular Momentum L Slider
                Text(
                  'Orbital Angular Momentum (L): ${_lValue.toInt()}',
                  style: const TextStyle(fontSize: 14),
                ),
                Slider(
                  value: _lValue,
                  min: 0.0,
                  max: 3.0,
                  divisions: 3,
                  activeColor: Colors.amber,
                  onChanged: (val) => setState(() {
                    _lValue = val;
                    _jValue = (_lValue + _sValue);
                  }),
                ),

                // Spin Angular Momentum S Slider
                Text(
                  'Electron Spin (S): $_sValue',
                  style: const TextStyle(fontSize: 14),
                ),
                Slider(
                  value: _sValue,
                  min: 0.0,
                  max: 0.5,
                  divisions: 1, // फक्त दोनच स्टेप्स: 0.0 आणि 0.5
                  activeColor: Colors.blueAccent,
                  onChanged: (val) => setState(() {
                    _sValue = val;
                    // S बदलल्यावर J चे मूल्य सुरक्षित मर्यादेत सेट करा
                    _jValue = (_lValue - _sValue).abs();
                  }),
                ),

                // Total Angular Momentum J Slider (फक्त |L-S| आणि |L+S| दरम्यान बदलेल)
                Text(
                  'Total Angular Momentum (J): $_jValue',
                  style: const TextStyle(fontSize: 14),
                ),
                Slider(
                  value: _jValue,
                  min: (_lValue - _sValue).abs(),
                  max: _lValue + _sValue == 0
                      ? 0.1
                      : _lValue + _sValue, // 0 टाळण्यासाठी सुरक्षितता
                  divisions: _lValue + _sValue == (_lValue - _sValue).abs()
                      ? 1
                      : 1, // १ चा फरक
                  activeColor: Colors.greenAccent,
                  onChanged: (val) {
                    // क्वांटम नियमांनुसार J फक्त |L-S| किंवा L+S असू शकते
                    double minJ = (_lValue - _sValue).abs();
                    double maxJ = _lValue + _sValue;

                    setState(() {
                      // युझरने स्लाईडर हलवल्यास जवळच्या वैध क्वांटम मूल्यावर (State) उडी मारेल
                      if ((val - minJ).abs() < (val - maxJ).abs()) {
                        _jValue = minJ;
                      } else {
                        _jValue = maxJ;
                      }
                    });
                  },
                ),

                const SizedBox(height: 20),
                const ExpansionTile(
                  title: Text(
                    'Physics Insight',
                    style: TextStyle(color: Colors.cyanAccent),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Anomalous Zeeman effect occurs due to combined orbital and spin angular momentum. '
                        'The Landé g-factor modulates the energy level splitting (ΔE = g · μB · B · Mj), '
                        'which causes the Fabry-Perot concentric interference rings to split dynamically.',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );

          Widget visualizer = Column(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(
                      color: Colors.cyan.withOpacity(0.3),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return CustomPaint(
                        size: Size.infinite,
                        painter: FabryPerotPainter(
                          bField: _bField,
                          gFactor: _landeGFactor,
                          mjValues: _getMjValues,
                          phase: _controller.value * 2 * math.pi,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF171A26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        'Landé g-Factor: ${_landeGFactor.toStringAsFixed(3)}',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Total Components: ${_getMjValues.length}',
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );

          if (isWide) {
            return Row(
              children: [
                Expanded(flex: 6, child: visualizer),
                Expanded(flex: 4, child: controlPanel),
              ],
            );
          } else {
            return Column(
              children: [
                Expanded(flex: 5, child: visualizer),
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(child: controlPanel),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

class FabryPerotPainter extends CustomPainter {
  final double bField;
  final double gFactor;
  final List<double> mjValues;
  final double phase;

  FabryPerotPainter({
    required this.bField,
    required this.gFactor,
    required this.mjValues,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.45;

    // अक्षांच्या रेषा (Axis grid lines)
    final axisPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      axisPaint,
    );
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      axisPaint,
    );

    const int baseRingCount = 3;

    // मुख्य लूप: प्रत्येक बेस रिंगसाठी
    for (int r = 1; r <= baseRingCount; r++) {
      // Fabry-Perot वलयांचे मूळ अंतर (Scaled radius using sqrt for actual optical fringe behavior)
      double baseRadius = maxRadius * math.sqrt(r / baseRingCount);

      // प्रत्येक Mj सब-स्टेटनुसार रिंग स्प्लिटिंग करणे
      for (double mj in mjValues) {
        // Anomalous Zeeman Shift गणना
        double zeemanShift = bField * gFactor * mj * 8.0;
        double dynamicRadius = baseRadius + zeemanShift;

        if (dynamicRadius <= 0) continue;

        // प्रकाश तीव्रतेचे ॲनिमेशन (Fringe intensity modulation)
        double intensityFactor = 0.6 + 0.4 * math.sin(phase - (r * 2));

        // विविध क्वांटम स्टेट्सला भिन्न रंग देणे (σ+, π, σ- साठी)
        Color ringColor;
        if (mj > 0) {
          ringColor = Colors.redAccent.withOpacity(
            intensityFactor,
          ); // Red shift (σ+)
        } else if (mj < 0) {
          ringColor = Colors.blueAccent.withOpacity(
            intensityFactor,
          ); // Blue shift (σ-)
        } else {
          ringColor = Colors.greenAccent.withOpacity(
            intensityFactor,
          ); // Unshifted (π)
        }

        // वर्तुळाकार रिंग रेखाटणे
        final ringPaint = Paint()
          ..color = ringColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
        canvas.drawCircle(center, dynamicRadius, ringPaint);

        // बाहेरील फिकट प्रकाशवलय (Outer Glow effect for the rings)
        final ringGlow = Paint()
          ..color = ringColor.withOpacity(0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(center, dynamicRadius, ringGlow);
      }
    }

    // मध्यवर्ती केंद्रबिंदू (Central Spot)
    canvas.drawCircle(center, 3, Paint()..color = Colors.white54);
  }

  @override
  bool shouldRepaint(covariant FabryPerotPainter oldDelegate) {
    return oldDelegate.bField != bField ||
        oldDelegate.gFactor != gFactor ||
        oldDelegate.mjValues != mjValues ||
        oldDelegate.phase != phase;
  }
}
