import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(child: MarangoniSimulationApp()),
      ),
    ),
  );
}

class MarangoniSimulationApp extends StatefulWidget {
  const MarangoniSimulationApp({super.key});

  @override
  State<MarangoniSimulationApp> createState() => _MarangoniSimulationAppState();
}

class _MarangoniSimulationAppState extends State<MarangoniSimulationApp>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _marangoniNumber = 100.0;
  String _currentMode =
      'a'; // Modes correspond to 'a', 'b', and 'c' from the image

  @override
  void initState() {
    super.initState();
    // Continuous loop for moving streamline tracer points and plume fluctuations
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- Header Section ---
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Marangoni Flow Profile Simulation',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Simulating surface tension gradients & thermal plumes',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        // --- Regime Selectors (Image Columns) ---
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildModeButton('a', 'Regime (a) Low-Re Symmetric'),
            const SizedBox(width: 8),
            _buildModeButton('b', 'Regime (b) Unstable Wake'),
            const SizedBox(width: 8),
            _buildModeButton('c', 'Regime (c) Extended Jet'),
          ],
        ),

        // --- Render Canvas Viewport ---
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: DropletFlowPainter(
                      time: _controller.value,
                      marangoniNumber: _marangoniNumber,
                      mode: _currentMode,
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // --- Control Panels ---
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Marangoni Number (Ma): ${_marangoniNumber.toInt()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _controller.isAnimating ? Icons.pause : Icons.play_arrow,
                    ),
                    onPressed: () {
                      if (_controller.isAnimating) {
                        _controller.stop();
                      } else {
                        _controller.repeat();
                      }
                      setState(() {});
                    },
                  ),
                ],
              ),
              Slider(
                value: _marangoniNumber,
                min: 10.0,
                max: 250.0,
                divisions: 24,
                activeColor: Colors.blueAccent,
                label: _marangoniNumber.toInt().toString(),
                onChanged: (value) {
                  setState(() {
                    _marangoniNumber = value;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModeButton(String modeKey, String label) {
    final isSelected = _currentMode == modeKey;
    return ChoiceChip(
      label: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
      selected: isSelected,
      selectedColor: Colors.blueAccent,
      backgroundColor: Colors.grey[200],
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _currentMode = modeKey;
          });
        }
      },
    );
  }
}

// ==========================================
// ERROR-FREE CUSTOM PAINTER IMPLEMENTATION
// ==========================================

class DropletFlowPainter extends CustomPainter {
  final double time;
  final double marangoniNumber;
  final String mode;

  DropletFlowPainter({
    required this.time,
    required this.marangoniNumber,
    required this.mode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.45);
    final dropletRadius = min(size.width, size.height) * 0.22;

    _paintHeatmapBackground(canvas, size, center, dropletRadius);
    _paintFlowStreamlines(canvas, size, center, dropletRadius);
    _paintDropletInterface(canvas, center, dropletRadius);
  }

  void _paintHeatmapBackground(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
  ) {
    final paint = Paint()..style = PaintingStyle.fill;
    const double resolution =
        5.0; // Balances smoothness and rendering frame rates

    for (double x = 0; x < size.width; x += resolution) {
      for (double y = 0; y < size.height; y += resolution) {
        final currentPos = Offset(x, y);
        final vectorToCenter = currentPos - center;
        final distance = vectorToCenter.distance;
        final angle = atan2(vectorToCenter.dy, vectorToCenter.dx);

        double scalarValue = 0.0;

        if (distance <= radius) {
          double normalizedR = distance / radius;
          double coreFlow = sin(normalizedR * pi) * sin(angle * 2).abs();
          scalarValue = coreFlow * (marangoniNumber * 0.4);
        } else {
          double normalizedR = distance / radius;

          if (mode == 'a') {
            scalarValue =
                (30 / normalizedR) +
                (marangoniNumber * 0.15) *
                    exp(-pow(normalizedR - 1.1, 2)) *
                    pow(sin(angle * 2), 2);
          } else if (mode == 'b') {
            double wakeWobble = sin(time * 2 * pi + normalizedR * 2) * 0.2;
            double plume = exp(
              -pow(angle - (-pi / 2 + wakeWobble), 2) * (normalizedR * 1.5),
            );
            scalarValue =
                (20 / normalizedR) +
                (marangoniNumber * 0.4) *
                    plume /
                    (1.0 + (normalizedR - 1) * 0.5);
          } else {
            double sharpPlume = exp(
              -pow(angle - (-pi / 2), 2) * (normalizedR * 2.5),
            );
            scalarValue =
                (15 / normalizedR) + (marangoniNumber * 0.6) * sharpPlume;
          }
        }

        double normFactor = (scalarValue / 120.0).clamp(0.0, 1.0);
        paint.color = _getFluidJetColor(normFactor);

        canvas.drawRect(Rect.fromLTWH(x, y, resolution, resolution), paint);
      }
    }
  }

  void _paintFlowStreamlines(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
  ) {
    final linePaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final particlePaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    int linesCount = mode == 'c' ? 45 : 35;
    for (int i = 0; i < linesCount; i++) {
      double startX = (size.width / linesCount) * i;
      Offset currentPoint = Offset(startX, size.height);
      final path = Path()..moveTo(currentPoint.dx, currentPoint.dy);

      for (int step = 0; step < 120; step++) {
        Offset vec = _getVelocityVectorAt(currentPoint, center, radius);
        currentPoint = Offset(
          currentPoint.dx + vec.dx * 3.5,
          currentPoint.dy + vec.dy * 3.5,
        );

        if (currentPoint.dy < 0 ||
            currentPoint.dx < 0 ||
            currentPoint.dx > size.width)
          break;
        path.lineTo(currentPoint.dx, currentPoint.dy);

        if ((step + (time * 40).toInt()) % 30 == 0) {
          canvas.drawCircle(currentPoint, 1.3, particlePaint);
        }
      }
      canvas.drawPath(path, linePaint);
    }

    final internalVortexPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (double rFactor = 0.3; rFactor < 0.9; rFactor += 0.25) {
      double r = radius * rFactor;
      canvas.drawOval(
        Rect.fromCenter(
          center: center - Offset(radius * 0.35, 0),
          width: r,
          height: r * 1.3,
        ),
        internalVortexPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: center + Offset(radius * 0.35, 0),
          width: r,
          height: r * 1.3,
        ),
        internalVortexPaint,
      );
    }
  }

  Offset _getVelocityVectorAt(Offset pos, Offset center, double radius) {
    final diff = pos - center;
    final d = diff.distance;

    double dx = 0.0;
    double dy = -1.2;

    if (d > radius) {
      double angle = atan2(diff.dy, diff.dx);
      num influenceFactor = pow(radius / d, 3);
      dx = sin(angle) * cos(angle) * influenceFactor * 1.5;
      dy =
          -1.0 +
          (pow(cos(angle), 2) - pow(sin(angle), 2)) * influenceFactor * 0.8;

      if (diff.dy < 0) {
        double plumePull = (marangoniNumber / 150.0) * (radius / d);
        if (mode == 'b') {
          dx += sin(time * 2 * pi + d * 0.05) * 0.3;
        }
        dy -= plumePull;
      }
    }
    return Offset(dx, dy);
  }

  void _paintDropletInterface(Canvas canvas, Offset center, double radius) {
    final boundaryPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius, boundaryPaint);

    const int segments = 72;
    const double segmentAngle = (2 * pi) / segments;
    final segmentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5;

    for (int i = 0; i < segments; i++) {
      double startAngle = i * segmentAngle;
      double checkAngle = startAngle - pi / 2;

      double localStress =
          sin(checkAngle * 2).abs() * (marangoniNumber / 220.0);
      segmentPaint.color = _getFluidJetColor(localStress.clamp(0.0, 1.0));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        false,
        segmentPaint,
      );
    }
  }

  Color _getFluidJetColor(double value) {
    if (value < 0.15) {
      return Colors.blue[900]!.withOpacity(0.85);
    } else if (value < 0.4) {
      double t = (value - 0.15) / 0.25;
      return Color.lerp(
        Colors.blue[900],
        Colors.cyan[600],
        t,
      )!.withOpacity(0.9);
    } else if (value < 0.7) {
      double t = (value - 0.4) / 0.3;
      return Color.lerp(
        Colors.cyan[600],
        Colors.yellow[600],
        t,
      )!.withOpacity(0.9);
    } else {
      double t = (value - 0.7) / 0.3;
      return Color.lerp(
        Colors.yellow[600],
        Colors.red[900],
        t,
      )!.withOpacity(0.95);
    }
  }

  @override
  bool shouldRepaint(covariant DropletFlowPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.marangoniNumber != marangoniNumber ||
        oldDelegate.mode != mode;
  }
}
