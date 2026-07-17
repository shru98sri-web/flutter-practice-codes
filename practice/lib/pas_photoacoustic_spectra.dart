import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PhotoacousticApp());
}

class PhotoacousticApp extends StatelessWidget {
  const PhotoacousticApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PAS Diffraction Simulator',
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
  double _laserIntensity = 2.5; // Laser Power Intensity (W/cm²)
  double _gasPressure = 1.0; // Gas Chamber Pressure (Atm)
  double _modulationFreq = 40.0; // Light Modulation Frequency (Hz)

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
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
      appBar: AppBar(
        title: const Text('PAS Thermal & Diffraction Simulator'),
        backgroundColor: const Color(0xFF141726),
        elevation: 4,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 800;

          Widget controls = Container(
            color: const Color(0xFF141726),
            padding: const EdgeInsets.all(24.0),
            child: ListView(
              children: [
                const Text(
                  'PAS Controls',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent,
                  ),
                ),
                const Divider(color: Colors.white24, height: 24),

                // 1. Laser Power Slider
                Text(
                  'Laser Power (I₀): ${_laserIntensity.toStringAsFixed(1)} W/cm²',
                  style: const TextStyle(fontSize: 14),
                ),
                Slider(
                  value: _laserIntensity,
                  min: 0.5,
                  max: 5.0,
                  divisions: 45,
                  activeColor: Colors.redAccent,
                  onChanged: (val) => setState(() => _laserIntensity = val),
                ),

                // 2. Chamber Gas Pressure Slider
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

                // 3. Modulation Frequency Slider
                Text(
                  'Modulation Frequency (f): ${_modulationFreq.toStringAsFixed(0)} Hz',
                  style: const TextStyle(fontSize: 14),
                ),
                Slider(
                  value: _modulationFreq,
                  min: 10.0,
                  max: 200.0,
                  divisions: 19,
                  activeColor: Colors.greenAccent,
                  onChanged: (val) => setState(() => _modulationFreq = val),
                ),

                const SizedBox(height: 20),
                const Card(
                  color: Color(0xFF1E2238),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Physics Insight:\n'
                      'Laser light absorption causes periodic heating (Thermal Gradients) and acoustic waves. '
                      'This resulting thermal lensing skews the optical pathway of a probe beam, generating a circular Fraunhofer diffraction fringe pattern on the screen.',
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
              // 1. Diffraction Pattern Visualizer Screen
              Expanded(
                flex: 5,
                child: Container(
                  margin: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.3),
                    ),
                  ),
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return CustomPaint(
                        size: Size.infinite,
                        painter: PasDiffractionPainter(
                          laserIntensity: _laserIntensity,
                          gasPressure: _gasPressure,
                          frequency: _modulationFreq,
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

class PasDiffractionPainter extends CustomPainter {
  final double laserIntensity;
  final double gasPressure;
  final double frequency;
  final double phase;

  PasDiffractionPainter({
    required this.laserIntensity,
    required this.gasPressure,
    required this.frequency,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.45);
    final maxRadius = math.min(size.width, size.height) * 0.4;

    // Calculate Photoacoustic Signal Amplitude (Acoustic Amplitude ∝ I₀ * P / √f)
    double acousticAmplitude =
        (laserIntensity * gasPressure) / math.sqrt(frequency);

    // 1. Render Circular Diffraction Rings (Airy Disk Profile)
    const int totalRings = 6;
    for (int i = 0; i < totalRings; i++) {
      double ringBaseRadius = (i == 0) ? 5.0 : (i * 35.0) + 15.0;

      // Thermal expansion factor altering fringe boundaries dynamically based on acoustic waves
      double thermalShift =
          acousticAmplitude * 6.0 * math.sin(phase - (i * 0.8));
      double dynamicRadius = ringBaseRadius + (i > 0 ? thermalShift : 0);

      if (dynamicRadius <= 0 || dynamicRadius > maxRadius) continue;

      // Intensity distribution computation via Fraunhofer Diffraction Sinc math approximations
      double intensity = (i == 0)
          ? 1.0
          : math.pow(math.sin(i * math.pi / 2) / (i * math.pi / 2), 2).abs() *
                0.8;

      // Dynamic modulation phase mapping
      double currentOpacity = (intensity * (0.7 + 0.3 * math.sin(phase))).clamp(
        0.0,
        1.0,
      );

      final ringPaint = Paint()
        ..style = (i == 0) ? PaintingStyle.fill : PaintingStyle.stroke
        ..color = Colors.redAccent.withOpacity(currentOpacity)
        ..strokeWidth = (i == 0) ? 0 : 4.0 - (i * 0.4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, (i == 0) ? 6 : 1.5);

      if (i == 0) {
        // Central Maxima (Airy Disk)
        canvas.drawCircle(center, 12.0 + acousticAmplitude * 2, ringPaint);
      } else {
        // Secondary Maxima Fringes
        canvas.drawCircle(center, dynamicRadius, ringPaint);
      }
    }

    // 2. Continuous Cross-Sectional Intensity Curve Graph
    final graphOriginY = size.height - 40.0;
    final graphHeight = 60.0;
    final path = Path();

    path.moveTo(20.0, graphOriginY);

    for (double x = 20.0; x < size.width - 20.0; x++) {
      double distanceToCenter = (x - center.dx).abs();

      // Calculate intensity using Sinc Function Formula: sinc(θ) = sin(θ)/θ
      double k = 0.08; // Wave vector scale profile anchor
      double angle = distanceToCenter * k;
      double intensityCurve = 0.0;

      if (angle == 0) {
        intensityCurve = 1.0;
      } else {
        intensityCurve = math.sin(angle) / angle;
      }

      // Scale dynamic height based on photoacoustic sound fluctuations
      double displayIntensity =
          math.pow(intensityCurve, 2) * (graphHeight + acousticAmplitude * 4);
      double graphY =
          graphOriginY - displayIntensity.clamp(0.0, graphHeight + 20);

      if (x == 20.0) {
        path.moveTo(x, graphY);
      } else {
        path.lineTo(x, graphY);
      }
    }

    final linePaint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(path, linePaint);

    // Graph Horizontal Baseline Axis
    canvas.drawLine(
      Offset(20.0, graphOriginY),
      Offset(size.width - 20.0, graphOriginY),
      Paint()
        ..color = Colors.white24
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(covariant PasDiffractionPainter oldDelegate) {
    return oldDelegate.laserIntensity != laserIntensity ||
        oldDelegate.gasPressure != gasPressure ||
        oldDelegate.frequency != frequency ||
        oldDelegate.phase != phase;
  }
}
