import 'dart:math' as math;

import 'package:flutter/material.dart';

enum FiberType { singleMode, multimodeStep, multimodeGraded }

void main() {
  runApp(Fiber());
}

class Fiber extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(home: AdvancedFiberVisualizer());
  }
}

class AdvancedFiberVisualizer extends StatefulWidget {
  const AdvancedFiberVisualizer({Key? key}) : super(key: key);

  @override
  _AdvancedFiberVisualizerState createState() =>
      _AdvancedFiberVisualizerState();
}

class _AdvancedFiberVisualizerState extends State<AdvancedFiberVisualizer> {
  FiberType _selectedType = FiberType.singleMode;
  double _coreMicrons = 9.0;

  // Fiber Optic Physics Properties (Constants)
  final double n1 = 1.465; // Core Refractive Index
  final double n2 = 1.460; // Cladding Refractive Index
  final double wavelengthNm = 1550.0; // Standard Telecom Wavelength (nm)
  final double speedOfLight = 299792458; // Vacuum Speed of Light (m/s)

  void _onTypeChanged(FiberType? type) {
    if (type == null) return;
    setState(() {
      _selectedType = type;
      if (type == FiberType.singleMode) {
        _coreMicrons = 8.2; // Standard single-mode core diameter
      } else {
        _coreMicrons = 50.0; // Standard multi-mode core diameter
      }
    });
  }

  // Calculates light wave speed inside the physical core media
  double get calculateVelocity {
    return speedOfLight / n1;
  }

  // Calculates the active Normalized Frequency metric
  double get calculateVNumber {
    double radiusMeters =
        (_coreMicrons / 2) * 1e-6; // Converts µm radius to meters
    double wavelengthMeters =
        wavelengthNm * 1e-9; // Converts nm wavelength to meters

    // Numerical Aperture Formula: NA = sqrt(n1^2 - n2^2)
    double numericalAperture = math.sqrt((n1 * n1) - (n2 * n2));

    // V-Number Formula: V = (2 * pi * a * NA) / lambda
    return (2 * math.pi * radiusMeters * numericalAperture) / wavelengthMeters;
  }

  @override
  Widget build(BuildContext context) {
    double minMicrons = _selectedType == FiberType.singleMode ? 4.0 : 50.0;
    double maxMicrons = _selectedType == FiberType.singleMode ? 11.0 : 100.0;

    double velocity = calculateVelocity;
    double vNumber = calculateVNumber;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Optical Fiber Visualizer & Calculator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fiber Mode Selector Toggles
            const Text(
              'Select Fiber Type:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Center(
              child: SegmentedButton<FiberType>(
                segments: const [
                  ButtonSegment(
                    value: FiberType.singleMode,
                    label: Text('Single-Mode'),
                  ),
                  ButtonSegment(
                    value: FiberType.multimodeStep,
                    label: Text('MM Step-Idx'),
                  ),
                  ButtonSegment(
                    value: FiberType.multimodeGraded,
                    label: Text('MM Graded-Idx'),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (Set<FiberType> selection) {
                  _onTypeChanged(selection.first);
                },
              ),
            ),
            const SizedBox(height: 25),

            // Fiber Interactive Layout (Custom Paint Canvas)
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomPaint(
                painter: FiberCanvasPainter(
                  coreMicrons: _coreMicrons,
                  fiberType: _selectedType,
                  maxMicrons: maxMicrons,
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Dimension Slider Interface
            Text(
              'Core Diameter: ${_coreMicrons.toStringAsFixed(1)} µm',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: MicronSliderThumb(microns: _coreMicrons),
                activeTrackColor: Colors.blueAccent,
                inactiveTrackColor: Colors.grey.shade300,
              ),
              child: Slider(
                value: _coreMicrons,
                min: minMicrons,
                max: maxMicrons,
                onChanged: (value) {
                  setState(() {
                    _coreMicrons = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 25),

            // Live Physics Analytical Calculation Dashboard Panel
            const Text(
              'Live Calculation Analysis:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildResultRow('Core Refractive Index (n1)', '$n1'),
                    const Divider(),
                    _buildResultRow('Cladding Refractive Index (n2)', '$n2'),
                    const Divider(),
                    _buildResultRow(
                      'Operating Wavelength (λ)',
                      '${wavelengthNm.toStringAsFixed(0)} nm',
                    ),
                    const Divider(),
                    // Velocity Metrics Row
                    _buildResultRow(
                      'Velocity in Core (v)',
                      '${(velocity / 1000000).toStringAsFixed(2)} × 10⁶ m/s\n(~${((velocity / speedOfLight) * 100).toStringAsFixed(0)}% of c)',
                    ),
                    const Divider(),
                    // Normalized V-Number Parameter Row
                    _buildResultRow(
                      'Normalized Frequency (V-Number)',
                      vNumber.toStringAsFixed(3),
                      textColor: vNumber < 2.405
                          ? Colors.green
                          : Colors.redAccent,
                    ),
                    const SizedBox(height: 10),
                    // Adaptive Context-Aware Warning Box
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: vNumber < 2.405
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        vNumber < 2.405
                            ? '✅ Single-Mode Condition Met (V < 2.405): The fiber structure strictly supports only a single bound mode propagation.'
                            : '⚠️ Multimode Propagation Region (V ≥ 2.405): Core thickness allows multiple light ray reflection pathways (modes).',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: vNumber < 2.405
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.black87, fontSize: 14),
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Slider Handle Element Wrapper
class MicronSliderThumb extends SliderComponentShape {
  final double microns;
  const MicronSliderThumb({required this.microns});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(45, 30);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    final paint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.fill;

    final rRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 52, height: 26),
      const Radius.circular(6),
    );
    canvas.drawRRect(rRect, paint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(rRect, borderPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: '${microns.toStringAsFixed(1)}µm',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: textDirection,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        center.dx - (textPainter.width / 2),
        center.dy - (textPainter.height / 2),
      ),
    );
  }
}

// Canvas Core/Cladding Structural Layout Renderer
class FiberCanvasPainter extends CustomPainter {
  final double coreMicrons;
  final FiberType fiberType;
  final double maxMicrons;

  FiberCanvasPainter({
    required this.coreMicrons,
    required this.fiberType,
    required this.maxMicrons,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double midY = size.height / 2;
    final double maxCoreHeight = size.height * 0.7;
    final double coreHeight = (coreMicrons / maxMicrons) * maxCoreHeight;

    // Background Cladding boundary construction
    final claddingPaint = Paint()..color = Colors.blueGrey.withOpacity(0.2);
    canvas.drawRect(
      Rect.fromLTWH(0, midY - (maxCoreHeight / 2), size.width, maxCoreHeight),
      claddingPaint,
    );

    // Inner Core geometry definitions
    final Rect coreRect = Rect.fromLTWH(
      0,
      midY - (coreHeight / 2),
      size.width,
      coreHeight,
    );
    final corePaint = Paint();

    if (fiberType == FiberType.multimodeGraded) {
      corePaint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.blue.withOpacity(0.1),
          Colors.cyan,
          Colors.blue.withOpacity(0.1),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(coreRect);
    } else if (fiberType == FiberType.singleMode) {
      corePaint.color = Colors.amberAccent.withOpacity(0.8);
    } else {
      corePaint.color = Colors.lightBlueAccent.withOpacity(0.6);
    }

    canvas.drawRect(coreRect, corePaint);

    // Dynamic wave reflection plotting paths
    final rayPaint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final rayPath = Path()..moveTo(0, midY);

    if (fiberType == FiberType.singleMode) {
      rayPath.lineTo(size.width, midY);
    } else if (fiberType == FiberType.multimodeStep) {
      double step = size.width / 4;
      double halfCore = coreHeight / 2 - 2;
      rayPath.lineTo(step * 1, midY - halfCore);
      rayPath.lineTo(step * 2, midY + halfCore);
      rayPath.lineTo(step * 3, midY - halfCore);
      rayPath.lineTo(size.width, midY);
    } else if (fiberType == FiberType.multimodeGraded) {
      double step = size.width / 4;
      double halfCore = coreHeight / 2 - 4;
      rayPath.cubicTo(
        step * 0.5,
        midY - halfCore,
        step * 0.5,
        midY - halfCore,
        step * 1,
        midY - halfCore,
      );
      rayPath.cubicTo(
        step * 1.5,
        midY - halfCore,
        step * 1.5,
        midY + halfCore,
        step * 2,
        midY + halfCore,
      );
      rayPath.cubicTo(
        step * 2.5,
        midY + halfCore,
        step * 2.5,
        midY - halfCore,
        step * 3,
        midY - halfCore,
      );
      rayPath.cubicTo(
        step * 3.5,
        midY - halfCore,
        step * 3.5,
        midY,
        size.width,
        midY,
      );
    }

    canvas.drawPath(rayPath, rayPaint);
  } // Cleanly closes the paint method

  @override
  bool shouldRepaint(covariant FiberCanvasPainter oldDelegate) {
    return oldDelegate.coreMicrons != coreMicrons ||
        oldDelegate.fiberType != fiberType;
  }
}
