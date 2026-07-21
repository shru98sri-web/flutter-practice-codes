import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const MarangoniDropletApp());
}

class MarangoniDropletApp extends StatelessWidget {
  const MarangoniDropletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const MarangoniDropletSimulation(),
    );
  }
}

class MarangoniDropletSimulation extends StatefulWidget {
  const MarangoniDropletSimulation({super.key});

  @override
  State<MarangoniDropletSimulation> createState() =>
      _MarangoniDropletSimulationState();
}

class _MarangoniDropletSimulationState extends State<MarangoniDropletSimulation>
    with SingleTickerProviderStateMixin {
  double _marangoniNumber = 80.0;
  String _currentMode = 'a'; // Mode matches (a), (b), or (c) from the image
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Droplet Marangoni Convection Instability'),
        backgroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          // Mode selectors (a, b, c) matching the figure panels
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: ['a', 'b', 'c'].map((mode) {
                bool isSelected = _currentMode == mode;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected
                          ? Colors.deepOrange
                          : Colors.grey[800],
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => setState(() => _currentMode = mode),
                    child: Text(
                      'Regime ($mode)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Simulation Canvas Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: DropletFlowPainter(
                      time: _animationController.value,
                      marangoniNumber: _marangoniNumber,
                      mode: _currentMode,
                    ),
                    child: Container(),
                  );
                },
              ),
            ),
          ),

          // Control UI Dashboard
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Thermal Gradient Force (Ma): ${_marangoniNumber.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Wake Profile: ${_getModeDescription()}',
                      style: const TextStyle(color: Colors.amber, fontSize: 13),
                    ),
                  ],
                ),
                Slider(
                  value: _marangoniNumber,
                  min: 10.0,
                  max: 200.0,
                  activeColor: Colors.deepOrangeAccent,
                  inactiveColor: Colors.grey[700],
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
      ),
    );
  }

  String _getModeDescription() {
    switch (_currentMode) {
      case 'a':
        return 'Symmetric Micro-Vortices';
      case 'b':
        return 'Unsteady Chaos Wake';
      case 'c':
        return 'Elongated Thermal Plume';
      default:
        return '';
    }
  }
}

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

    // --- STEP 1: Draw Continuous Heatmap Background Field (Row 2 of Image) ---
    _paintHeatmapBackground(canvas, size, center, dropletRadius);

    // --- STEP 2: Draw Flow Streamlines / Vector Particles (Row 1 of Image) ---
    _paintFlowStreamlines(canvas, size, center, dropletRadius);

    // --- STEP 3: Draw Droplet Boundary Interface with Shear Gradients ---
    _paintDropletInterface(canvas, center, dropletRadius);
  }

  void _paintHeatmapBackground(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
  ) {
    final paint = Paint()..style = PaintingStyle.fill;
    const double resolution = 6.0; // Grid sampling resolution

    for (double x = 0; x < size.width; x += resolution) {
      for (double y = 0; y < size.height; y += resolution) {
        final currentPos = Offset(x, y);
        final vectorToCenter = currentPos - center;
        final distance = vectorToCenter.distance;
        final angle = atan2(vectorToCenter.dy, vectorToCenter.dx);

        double scalarValue = 0.0;

        // Mathematical formulation modeling boundary-layer flow around a sphere with Marangoni stress
        if (distance <= radius) {
          // Internal droplet velocity profile (Toroidal inner core vortices)
          double normalizedR = distance / radius;
          double coreFlow = sin(normalizedR * pi) * sin(angle * 2).abs();
          scalarValue = coreFlow * (marangoniNumber * 0.4);
        } else {
          // External plume wake profiles varying by regime configuration
          double normalizedR = distance / radius;

          if (mode == 'a') {
            // Symmetrical low-Reynolds thermal shield
            scalarValue =
                (30 / normalizedR) +
                (marangoniNumber * 0.15) *
                    exp(-pow(normalizedR - 1.1, 2)) *
                    pow(sin(angle * 2), 2);
          } else if (mode == 'b') {
            // Asymmetric microturbulent plume detachment
            double wakeWobble = sin(time * 2 * pi + normalizedR * 2) * 0.2;
            double plume = exp(
              -pow(angle - (pi / 2 + wakeWobble), 2) * (normalizedR * 1.5),
            );
            scalarValue =
                (20 / normalizedR) +
                (marangoniNumber * 0.4) *
                    plume /
                    (1.0 + (normalizedR - 1) * 0.5);
          } else {
            // Highly extended continuous jet thermal column
            double sharpPlume = exp(
              -pow(angle - pi / 2, 2) * (normalizedR * 2.5),
            );
            scalarValue =
                (15 / normalizedR) + (marangoniNumber * 0.6) * sharpPlume;
          }
        }

        // Clamp values to drive palette boundaries smoothly
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
      ..color = Colors.black.withOpacity(0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final particlePaint = Paint()
      ..color = Colors.black.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    // Generate analytical streamlines by integrating vector steps
    int linesCount = mode == 'c' ? 45 : 35;
    for (int i = 0; i < linesCount; i++) {
      double startX = (size.width / linesCount) * i;
      Offset currentPoint = Offset(startX, size.height);
      final path = Path()..moveTo(currentPoint.dx, currentPoint.dy);

      // Trace streamline trajectories upstream
      for (int step = 0; step < 120; step++) {
        Offset vec = _getVelocityVectorAt(currentPoint, center, radius);
        // Step integration forward based on calculated vector speeds
        currentPoint = Offset(
          currentPoint.dx + vec.dx * 3.5,
          currentPoint.dy + vec.dy * 3.5,
        );

        if (currentPoint.dy < 0 ||
            currentPoint.dx < 0 ||
            currentPoint.dx > size.width)
          break;
        path.lineTo(currentPoint.dx, currentPoint.dy);

        // Periodically inject tracking dots along streamlines to match animation dynamics
        if ((step + (time * 20).toInt()) % 30 == 0) {
          canvas.drawCircle(currentPoint, 1.2, particlePaint);
        }
      }
      canvas.drawPath(path, linePaint);
    }

    // Explicit internal droplet circulation vortex mapping loops
    final internalVortexPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (double rFactor = 0.3; rFactor < 0.9; rFactor += 0.25) {
      double r = radius * rFactor;
      // Left Core Circulation Cell
      canvas.drawOval(
        Rect.fromCenter(
          center: center - Offset(radius * 0.4, 0),
          width: r,
          height: r * 1.4,
        ),
        internalVortexPaint,
      );
      // Right Core Circulation Cell
      canvas.drawOval(
        Rect.fromCenter(
          center: center + Offset(radius * 0.4, 0),
          width: r,
          height: r * 1.4,
        ),
        internalVortexPaint,
      );
    }
  }

  Offset _getVelocityVectorAt(Offset pos, Offset center, double radius) {
    final diff = pos - center;
    final d = diff.distance;

    // Default system flow upward velocity vector
    double dx = 0.0;
    double dy = -1.2;

    if (d > radius) {
      // Divergent displacement flow profile passing around a solid/fluid sphere barrier
      double angle = atan2(diff.dy, diff.dx);
      num influenceFactor = pow(radius / d, 3);
      dx = sin(angle) * cos(angle) * influenceFactor * 1.5;
      dy =
          -1.0 +
          (pow(cos(angle), 2) - pow(sin(angle), 2)) * influenceFactor * 0.8;

      // Inject Marangoni wake drag bending term pulling inward downstream
      if (diff.dy < 0) {
        // Plume wake region
        double plumePull = (marangoniNumber / 150.0) * (radius / d);
        if (mode == 'b') {
          dx +=
              sin(time * 2 * pi + d * 0.05) *
              0.3; // Wake fluctuation instability
        }
        dy -= plumePull;
      }
    }
    return Offset(dx, dy);
  }

  void _paintDropletInterface(Canvas canvas, Offset center, double radius) {
    // Outer boundary envelope outline
    final boundaryPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius, boundaryPaint);

    const int segments = 60;
    const double segmentAngle = (2 * pi) / segments;
    final segmentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    for (int i = 0; i < segments; i++) {
      double startAngle = i * segmentAngle;
      double checkAngle = startAngle - pi / 2;

      // Calculate local surface tension gradient stresses
      double localStress =
          sin(checkAngle * 2).abs() * (marangoniNumber / 200.0);
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

  // Jet/Infrared spectrum interpolation function mimicking Matlab/Comsol color schemes
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
