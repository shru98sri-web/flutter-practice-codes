import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PhotoacousticAdvancedApp());
}

class PhotoacousticAdvancedApp extends StatelessWidget {
  const PhotoacousticAdvancedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Advanced PAS Simulator',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0D17),
      ),
      home: const PasSimulationPage(),
    );
  }
}

class PasSimulationPage extends StatefulWidget {
  const PasSimulationPage({super.key});

  @override
  State<PasSimulationPage> createState() => _PasSimulationPageState();
}

class _PasSimulationPageState extends State<PasSimulationPage>
    with SingleTickerProviderStateMixin {
  // Control Variables
  double _laserIntensity = 2.5; // Laser Power (W/cm²)
  double _gasPressure = 1.0; // Chamber Gas Pressure (atm)
  double _modulationFreq = 40.0; // Chopper/Modulation Frequency (Hz)
  double _wavelength = 532.0; // Laser Wavelength (nm)

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

  // Converts Nanometer Wavelength to concrete RGB Color space profiles
  Color _nmToColor(double wavelength) {
    if (wavelength >= 380 && wavelength < 440) {
      return Colors.purpleAccent;
    } else if (wavelength >= 440 && wavelength < 490) {
      return Colors.blueAccent;
    } else if (wavelength >= 490 && wavelength < 510) {
      return Colors.cyanAccent;
    } else if (wavelength >= 510 && wavelength < 580) {
      return Colors.greenAccent;
    } else if (wavelength >= 580 && wavelength < 645) {
      return Colors.orangeAccent;
    } else if (wavelength >= 645 && wavelength <= 750) {
      return Colors.redAccent;
    }
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    Color activeLaserColor = _nmToColor(_wavelength);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PAS Multi-Graph & Laser Simulator'),
        backgroundColor: const Color(0xFF141726),
        elevation: 4,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 900;

          Widget controls = Container(
            color: const Color(0xFF141726),
            padding: const EdgeInsets.all(24.0),
            child: ListView(
              children: [
                const Text(
                  'Simulation Control Center',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent,
                  ),
                ),
                const Divider(color: Colors.white24, height: 24),

                // 1. Wavelength Control Slider
                Text(
                  'Laser Wavelength (λ): ${_wavelength.toStringAsFixed(0)} nm',
                  style: TextStyle(
                    fontSize: 14,
                    color: activeLaserColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Slider(
                  value: _wavelength,
                  min: 380.0,
                  max: 750.0,
                  divisions: 37,
                  activeColor: activeLaserColor,
                  onChanged: (val) => setState(() => _wavelength = val),
                ),

                // 2. Laser Power Slider
                Text(
                  'Laser Power (I₀): ${_laserIntensity.toStringAsFixed(1)} W/cm²',
                  style: const TextStyle(fontSize: 14),
                ),
                Slider(
                  value: _laserIntensity,
                  min: 0.5,
                  max: 5.0,
                  divisions: 45,
                  activeColor: Colors.white70,
                  onChanged: (val) => setState(() => _laserIntensity = val),
                ),

                // 3. Chamber Gas Pressure Slider
                Text(
                  'Gas Pressure (P): ${_gasPressure.toStringAsFixed(2)} atm',
                  style: const TextStyle(fontSize: 14),
                ),
                Slider(
                  value: _gasPressure,
                  min: 0.2,
                  max: 3.0,
                  divisions: 28,
                  activeColor: Colors.blueAccent,
                  onChanged: (val) => setState(() => _gasPressure = val),
                ),

                // 4. Modulation Frequency Slider
                Text(
                  'Modulation Frequency (f): ${_modulationFreq.toStringAsFixed(0)} Hz',
                  style: const TextStyle(fontSize: 14),
                ),
                Slider(
                  value: _modulationFreq,
                  min: 10.0,
                  max: 200.0,
                  divisions: 19,
                  activeColor: Colors.purpleAccent,
                  onChanged: (val) => setState(() => _modulationFreq = val),
                ),

                const SizedBox(height: 16),
                const Card(
                  color: Color(0xFF1E2238),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Physics Metrics Added:\n'
                      '• Wavelength alters the diffraction fringe width directly via Huygens principles (R ∝ λ).\n'
                      '• The Sound Wave Overlay displays live micro-volt microphone feedback generated by thermal volume expansions.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );

          Widget content = Column(
            children: [
              // Combined Visualizer Screen Canvas Block
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: activeLaserColor.withOpacity(0.3),
                    ),
                  ),
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return CustomPaint(
                        size: Size.infinite,
                        painter: PasAdvancedVisualizerPainter(
                          laserIntensity: _laserIntensity,
                          gasPressure: _gasPressure,
                          frequency: _modulationFreq,
                          wavelength: _wavelength,
                          laserColor: activeLaserColor,
                          phase: _controller.value * 2 * math.pi,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );

          return isWide
              ? Row(
                  children: [
                    Expanded(flex: 6, child: content),
                    Expanded(flex: 4, child: controls),
                  ],
                )
              : Column(
                  children: [
                    Expanded(flex: 6, child: content),
                    Expanded(flex: 4, child: controls),
                  ],
                );
        },
      ),
    );
  }
}

class PasAdvancedVisualizerPainter extends CustomPainter {
  final double laserIntensity;
  final double gasPressure;
  final double frequency;
  final double wavelength;
  final Color laserColor;
  final double phase;

  PasAdvancedVisualizerPainter({
    required this.laserIntensity,
    required this.gasPressure,
    required this.frequency,
    required this.wavelength,
    required this.laserColor,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.35);
    final maxRadius = math.min(size.width, size.height) * 0.35;

    // Photoacoustic acoustic signal calculation (Amplitude ∝ I₀ * P / √f)
    double acousticAmplitude =
        (laserIntensity * gasPressure) / math.sqrt(frequency);

    // Physical optics adjustment: Wavelength shifts diffraction geometry width
    double wavelengthScaling = wavelength / 550.0;

    // ==========================================
    // 1. RENDER FRAUNHOFER DIFFRACTION PATTERN
    // ==========================================
    const int totalRings = 6;
    for (int i = 0; i < totalRings; i++) {
      double ringBaseRadius = (i == 0)
          ? 5.0
          : ((i * 32.0) + 12.0) * wavelengthScaling;

      // Dynamic thermal oscillation driving localized expansion
      double thermalShift =
          acousticAmplitude * 5.0 * math.sin(phase - (i * 0.7));
      double dynamicRadius = ringBaseRadius + (i > 0 ? thermalShift : 0);

      if (dynamicRadius <= 0 || dynamicRadius > maxRadius) continue;

      // Sinc Function-based structural power drop-off
      double intensity = (i == 0)
          ? 1.0
          : math.pow(math.sin(i * math.pi / 2) / (i * math.pi / 2), 2).abs() *
                0.75;

      double currentOpacity = (intensity * (0.65 + 0.35 * math.sin(phase)))
          .clamp(0.0, 1.0);

      final ringPaint = Paint()
        ..style = (i == 0) ? PaintingStyle.fill : PaintingStyle.stroke
        ..color = laserColor.withOpacity(currentOpacity)
        ..strokeWidth = (i == 0) ? 0 : 4.5 - (i * 0.4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, (i == 0) ? 7 : 1.2);

      if (i == 0) {
        canvas.drawCircle(center, 10.0 + acousticAmplitude * 2.5, ringPaint);
      } else {
        canvas.drawCircle(center, dynamicRadius, ringPaint);
      }
    }

    // ==========================================
    // 2. LOWER REGION DUAL GRAPH TRACKS
    // ==========================================
    final bottomSectionHeight = size.height * 0.3;
    final graphWidth = (size.width - 60.0) / 2;

    final optGraphOrigin = Offset(20.0, size.height - 30.0);
    final acoGraphOrigin = Offset(size.width / 2 + 10.0, size.height - 30.0);
    final maxGraphHeight = bottomSectionHeight - 40.0;
    // Draw Background Grid Separation Box Outlines
    final gridOutlinePaint = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(
      Rect.fromLTWH(
        optGraphOrigin.dx,
        optGraphOrigin.dy - maxGraphHeight,
        graphWidth,
        maxGraphHeight,
      ),
      gridOutlinePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        acoGraphOrigin.dx,
        acoGraphOrigin.dy - maxGraphHeight,
        graphWidth,
        maxGraphHeight,
      ),
      gridOutlinePaint,
    );
    final optPath = Path();
    final acoPath = Path();
    // Loop through sub-grid widths to chart analytical paths
    for (double i = 0; i <= graphWidth; i++) {
      double pct = i / graphWidth;
      // --- Left Graph: Continuous Intensity Cross-Section ---
      double distFromCenter = (pct - 0.5).abs() * graphWidth;
      double k = 0.1 / wavelengthScaling;
      double angle = distFromCenter * k;
      double sincValue = (angle == 0) ? 1.0 : math.sin(angle) / angle;

      // १. आधी ग्राफचे मार्जिन आणि आकारमान (Dimensions) निश्चित करा
      final double paddingLeft = 50.0;
      final double paddingBottom = 40.0;

      // उपलब्ध स्क्रीन साईझनुसार रुंदी (Width) आणि उंची (Height) परिभाषित करा
      final double optGraphWidth = size.width - paddingLeft - 20.0;
      final double optGraphHeight =
          (size.height * 0.3); // स्क्रीनचा खालचा ३०% भाग ग्राफसाठी

      // ग्राफचा आरंभ बिंदू (Origin Point)
      final Offset optGraphOrigin = Offset(
        paddingLeft,
        size.height - paddingBottom,
      );

      // २. आता तुमचा मुख्य लूप सुरु होईल (यात आता कोणतीही एरर येणार नाही)
      final Path optPath = Path();

      for (double i = 0; i <= optGraphWidth; i++) {
        // ऑप्टिकल इंटेंसिटी (Sinc Function) चे गणित
        double distanceToCenter = (i - (optGraphWidth / 2)).abs();
        double k = 0.08;
        double angle = distanceToCenter * k;
        double intensityCurve = (angle == 0) ? 1.0 : math.sin(angle) / angle;

        // 'optY' व्हेरिएबल अचूकपणे डिक्लेअर केले आहे
        double displayIntensity =
            math.pow(intensityCurve, 2) * (optGraphHeight * 0.8);
        double optY = optGraphOrigin.dy - displayIntensity;

        // पाथ रेखाटणे
        if (i == 0) {
          optPath.moveTo(optGraphOrigin.dx + i, optY);
        } else {
          optPath.lineTo(optGraphOrigin.dx + i, optY);
        }
      }

      // ३. शेवटी कॅनव्हासवर आलेख पेंट करा
      final Paint linePaint = Paint()
        ..color = Colors.cyanAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawPath(optPath, linePaint);
      // --- Right Graph: Acoustic Waves Microphone Signal Overlay --
      // Models sound compression/rarefaction cycles: Wave speed based on frequency config
      double timeVariable = pct * 4 * math.pi;
      double waveMath =
          math.sin(timeVariable * (frequency / 40.0) - phase) *
          math.cos(timeVariable * 0.5) *
          (acousticAmplitude * 12.0);
      double acoY =
          (acoGraphOrigin.dy - (maxGraphHeight / 2)) -
          waveMath.clamp(-maxGraphHeight / 2, maxGraphHeight / 2);
      if (i == 0)
        acoPath.moveTo(acoGraphOrigin.dx + i, acoY);
      else
        acoPath.lineTo(acoGraphOrigin.dx + i, acoY);
    }
    // Render Optical Intensity Line Profile
    canvas.drawPath(
      optPath,
      Paint()
        ..color = laserColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    // Render Microphone Acoustic Wave Line Profile
    canvas.drawPath(
      acoPath,
      Paint()
        ..color = Colors.cyanAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    ); // ==========================================// 3. GRAPH TEXT LABELS RENDERING// ==========================================
    _drawLabel(
      canvas,
      "Optical Line Profile (Sinc²)",
      Offset(optGraphOrigin.dx + 6, optGraphOrigin.dy - maxGraphHeight + 6),
    );
    _drawLabel(
      canvas,
      "Microphone Acoustic Signal (µV)",
      Offset(acoGraphOrigin.dx + 6, acoGraphOrigin.dy - maxGraphHeight + 6),
    );
  }

  void _drawLabel(Canvas canvas, String text, Offset offset) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 10, color: Colors.white54),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant PasAdvancedVisualizerPainter oldDelegate) {
    return oldDelegate.laserIntensity != laserIntensity ||
        oldDelegate.gasPressure != gasPressure ||
        oldDelegate.frequency != frequency ||
        oldDelegate.wavelength != wavelength ||
        oldDelegate.phase != phase;
  }
}
