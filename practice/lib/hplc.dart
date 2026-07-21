import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HplcApp());
}

class HplcApp extends StatelessWidget {
  const HplcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HPLC Chromatogram Simulator',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F111A),
      ),
      home: const HplcSimulationPage(),
    );
  }
}

class HplcSimulationPage extends StatefulWidget {
  const HplcSimulationPage({super.key});

  @override
  State<HplcSimulationPage> createState() => _HplcSimulationPageState();
}

class _HplcSimulationPageState extends State<HplcSimulationPage> {
  // HPLC Parameters (नियंत्रण चल)
  double _flowRate = 1.0; // Flow rate (mL/min)
  double _injectionVolume = 20.0; // Injection Volume (µL)
  bool _isRunning = true;

  // Mock Compound Data: [Retention Time Factor, Peak Height, Base Width, Name, Color]
  final List<Map<String, dynamic>> _compounds = [
    {
      'rtFactor': 2.0,
      'height': 180.0,
      'width': 0.15,
      'name': 'Uracil (Void)',
      'color': Colors.grey,
    },
    {
      'rtFactor': 4.5,
      'height': 450.0,
      'width': 0.25,
      'name': 'Phenol',
      'color': Colors.orangeAccent,
    },
    {
      'rtFactor': 6.2,
      'height': 300.0,
      'width': 0.32,
      'name': 'Acetophenone',
      'color': Colors.cyanAccent,
    },
    {
      'rtFactor': 8.8,
      'height': 600.0,
      'width': 0.40,
      'name': 'Toluene',
      'color': Colors.lightGreenAccent,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HPLC Spectrum Chromatogram Simulator'),
        backgroundColor: const Color(0xFF171A26),
      ),
      body: Column(
        children: [
          // Chromatogram Interactive Canvas Area
          Expanded(
            flex: 6,
            child: Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF05070B),
                border: Border.all(color: Colors.white10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomPaint(
                size: Size.infinite,
                painter: HplcChromatogramPainter(
                  flowRate: _flowRate,
                  injectionVolume: _injectionVolume,
                  compounds: _compounds,
                ),
              ),
            ),
          ),

          // Control Dashboard Panel
          Expanded(
            flex: 3,
            child: Container(
              color: const Color(0xFF171A26),
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  // Slider 1: Flow Rate
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Flow Rate: ${_flowRate.toStringAsFixed(2)} mL/min',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.cyanAccent,
                          ),
                        ),
                        const Text(
                          'Higher flow rate reduces retention time (shifts left).',
                          style: TextStyle(fontSize: 11, color: Colors.white54),
                        ),
                        Slider(
                          value: _flowRate,
                          min: 0.5,
                          max: 2.5,
                          divisions: 20,
                          activeColor: Colors.cyanAccent,
                          onChanged: (val) => setState(() => _flowRate = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  // Slider 2: Injection Volume
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Injection Volume: ${_injectionVolume.toStringAsFixed(1)} µL',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.purpleAccent,
                          ),
                        ),
                        const Text(
                          'Higher volume increases peak area and signal intensity.',
                          style: TextStyle(fontSize: 11, color: Colors.white54),
                        ),
                        Slider(
                          value: _injectionVolume,
                          min: 5.0,
                          max: 50.0,
                          divisions: 45,
                          activeColor: Colors.purpleAccent,
                          onChanged: (val) =>
                              setState(() => _injectionVolume = val),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HplcChromatogramPainter extends CustomPainter {
  final double flowRate;
  final double injectionVolume;
  final List<Map<String, dynamic>> compounds;

  HplcChromatogramPainter({
    required this.flowRate,
    required this.injectionVolume,
    required this.compounds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paddingLeft = 60.0;
    final paddingBottom = 40.0;
    final graphWidth = size.width - paddingLeft - 20.0;
    final graphHeight = size.height - paddingBottom - 20.0;

    final origin = Offset(paddingLeft, size.height - paddingBottom);

    // 1. Grid Axes Layout
    final axisPaint = Paint()
      ..color = Colors.white30
      ..strokeWidth = 1.5;

    // X Axis (Retention Time) & Y Axis (Intensity mAU)
    canvas.drawLine(
      origin,
      Offset(size.width - 20, size.height - paddingBottom),
      axisPaint,
    );
    canvas.drawLine(origin, Offset(paddingLeft, 20), axisPaint);

    // Grid Background Markers
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1.0;

    const int xDivisions = 10;
    const double maxMinutes = 12.0;

    for (int i = 1; i <= xDivisions; i++) {
      double xPos = origin.dx + (graphWidth * (i / xDivisions));
      canvas.drawLine(Offset(xPos, origin.dy), Offset(xPos, 20), gridPaint);

      // X Labels (Minutes)
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${(maxMinutes * (i / xDivisions)).toStringAsFixed(1)} min',
          style: const TextStyle(fontSize: 10, color: Colors.white70),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(xPos - (textPainter.width / 2), origin.dy + 8),
      );
    }

    // Y Axis Labels (mAU - milli-Absorbance Units)
    const int yDivisions = 5;
    const double maxAbsorbance = 1000.0;
    for (int i = 0; i <= yDivisions; i++) {
      double yPos = origin.dy - (graphHeight * (i / yDivisions));
      canvas.drawLine(
        Offset(origin.dx, yPos),
        Offset(size.width - 20, yPos),
        gridPaint,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${(maxAbsorbance * (i / yDivisions)).toInt()}',
          style: const TextStyle(fontSize: 10, color: Colors.white70),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(
          origin.dx - textPainter.width - 8,
          yPos - (textPainter.height / 2),
        ),
      );
    }

    // 2. Continuous HPLC Signal Curve Construction
    final path = Path();
    path.moveTo(origin.dx, origin.dy);

    final double volScaling =
        injectionVolume / 20.0; // Normalization scaling anchor

    // Loop through every pixel column to map out spectrum
    for (double pixelX = 0; pixelX <= graphWidth; pixelX++) {
      // Map current horizontal position to chromatography runtime value
      double currentTime = (pixelX / graphWidth) * maxMinutes;
      double totalAbsorbance = 0.0;

      for (var compound in compounds) {
        // Chemical Peak Math Modeling
        // Flow rate inversely scales retention time: t_R = factory / flow
        double retentionTime = compound['rtFactor'] / flowRate;
        double baseHeight = compound['height'] * volScaling;
        double width = compound['width'] as double;

        // Exponential modified peak deviation component (Tail Factor)
        double deltaT = currentTime - retentionTime;

        // Gaussian peak execution equation
        double gaussianIntensity =
            baseHeight *
            math.exp(-math.pow(deltaT, 2) / (2 * math.pow(width, 2)));

        // Realistic chromatographic tailing profile skew
        if (deltaT > 0) {
          gaussianIntensity *= math.exp(-deltaT * 0.4);
        }

        totalAbsorbance += gaussianIntensity;
      }

      // Add baseline signal matrix noise jitter (Detector optical fluctuations)
      double baselineNoise =
          1.5 * math.sin(currentTime * 50) * math.cos(currentTime * 12);
      totalAbsorbance += baselineNoise;

      // Translate output data domain points straight onto physical graphics canvas
      double graphY =
          origin.dy - ((totalAbsorbance / maxAbsorbance) * graphHeight);
      graphY = graphY.clamp(20.0, origin.dy); // Keep within safety limits

      path.lineTo(origin.dx + pixelX, graphY);
    }

    final spectrumPaint = Paint()
      ..color = Colors.lightBlueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(path, spectrumPaint);

    // 3. Peak Chemical Legends Label Marking
    for (var compound in compounds) {
      double retentionTime = compound['rtFactor'] / flowRate;
      if (retentionTime > maxMinutes) continue;

      double labelX = origin.dx + ((retentionTime / maxMinutes) * graphWidth);
      double baseHeight = compound['height'] * volScaling;
      double labelY =
          origin.dy - ((baseHeight / maxAbsorbance) * graphHeight) - 25;
      final labelPainter = TextPainter(
        text: TextSpan(
          text: compound['name'],
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: compound['color'],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      if (labelY > 30 && labelX < size.width - 50) {
        labelPainter.paint(
          canvas,
          Offset(labelX - (labelPainter.width / 2), labelY),
        );
        // Indicator Pin
        canvas.drawLine(
          Offset(labelX, labelY + labelPainter.height + 2),
          Offset(labelX, labelY + labelPainter.height + 10),
          Paint()
            ..color = compound['color']
            ..strokeWidth = 1.0,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant HplcChromatogramPainter oldDelegate) {
    return oldDelegate.flowRate != flowRate ||
        oldDelegate.injectionVolume != injectionVolume;
  }
}
