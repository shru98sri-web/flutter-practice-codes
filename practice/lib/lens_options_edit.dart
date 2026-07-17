import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const RayTracingScreen(),
    );
  }
}

// Model class to define Lens properties
class Lens {
  final double x; // X coordinate position on screen
  final double radius; // Curvature radius (+ve for Convex, -ve for Concave)
  final double height; // Physical height of the lens
  final double refIndex; // Refractive Index (e.g., Glass = 1.5)

  Lens({
    required this.x,
    required this.radius,
    required this.height,
    required this.refIndex,
  });
}

class RayTracingScreen extends StatefulWidget {
  const RayTracingScreen({super.key});

  @override
  State<RayTracingScreen> createState() => _RayTracingScreenState();
}

class _RayTracingScreenState extends State<RayTracingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Track the currently active lens layout option
  String _selectedPreset = '4-Lens Combo';

  @override
  void initState() {
    super.initState();
    // Controls the oscillating angle of incoming light rays
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

  // Generates presets dynamically based on screen width dimensions
  List<Lens> _getLenses(double screenWidth) {
    switch (_selectedPreset) {
      case 'Convex Only':
        return [
          Lens(x: screenWidth * 0.5, radius: 140, height: 180, refIndex: 1.55),
        ];
      case 'Concave Only':
        return [
          Lens(x: screenWidth * 0.5, radius: -120, height: 160, refIndex: 1.60),
        ];
      case 'Telescope Setup':
        return [
          Lens(x: screenWidth * 0.3, radius: 150, height: 180, refIndex: 1.50),
          Lens(x: screenWidth * 0.7, radius: 80, height: 100, refIndex: 1.65),
        ];
      case '4-Lens Combo':
      default:
        return [
          Lens(x: screenWidth * 0.25, radius: 150, height: 160, refIndex: 1.52),
          Lens(
            x: screenWidth * 0.45,
            radius: -120,
            height: 140,
            refIndex: 1.65,
          ),
          Lens(x: screenWidth * 0.65, radius: 180, height: 150, refIndex: 1.50),
          Lens(x: screenWidth * 0.85, radius: 100, height: 120, refIndex: 1.70),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final List<Lens> activeLenses = _getLenses(screenWidth);

    return Scaffold(
      backgroundColor: const Color(
        0xFF0F172A,
      ), // Tailwinds Slate-900 background
      appBar: AppBar(
        title: const Text("Ray Tracing & Optics Simulator"),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 4,
      ),
      body: Stack(
        children: [
          // 1. Core Ray Tracing Canvas Animation
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: RayTracerPainter(
                    progress: _controller.value,
                    lenses: activeLenses,
                  ),
                );
              },
            ),
          ),

          // 2. Overlay Menu for Selection
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildPresetChip('4-Lens Combo'),
                      const SizedBox(width: 8),
                      _buildPresetChip('Convex Only'),
                      const SizedBox(width: 8),
                      _buildPresetChip('Concave Only'),
                      const SizedBox(width: 8),
                      _buildPresetChip('Telescope Setup'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Builder for Selection Choice Chips
  Widget _buildPresetChip(String label) {
    final bool isSelected = _selectedPreset == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.cyan.withOpacity(0.3),
      checkmarkColor: Colors.cyan,
      labelStyle: TextStyle(
        color: isSelected ? Colors.cyan : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.transparent,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _selectedPreset = label;
          });
        }
      },
    );
  }
}

class RayTracerPainter extends CustomPainter {
  final double progress;
  final List<Lens> lenses;

  RayTracerPainter({required this.progress, required this.lenses});

  @override
  void paint(Canvas canvas, Size size) {
    final double centerY = size.height / 2;

    final lensPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final lensBorderPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw active lenses on screen
    for (var lens in lenses) {
      Path path = Path();
      if (lens.radius > 0) {
        // Precise double convex geometry drawing
        path.moveTo(lens.x - 12, centerY - lens.height / 2);
        path.arcToPoint(
          Offset(lens.x + 12, centerY + lens.height / 2),
          radius: Radius.circular(lens.radius),
          clockwise: true,
        );
        path.arcToPoint(
          Offset(lens.x - 12, centerY - lens.height / 2),
          radius: Radius.circular(lens.radius),
          clockwise: true,
        );
      } else {
        // High fidelity neat concave geometry drawing
        double halfH = lens.height / 2;
        double thickness = 22;
        double rad = lens.radius.abs();

        path.moveTo(lens.x - thickness, centerY - halfH);
        path.lineTo(lens.x + thickness, centerY - halfH);
        path.arcToPoint(
          Offset(lens.x + thickness, centerY + halfH),
          radius: Radius.circular(rad),
          clockwise: false,
        );
        path.lineTo(lens.x - thickness, centerY + halfH);
        path.arcToPoint(
          Offset(lens.x - thickness, centerY - halfH),
          radius: Radius.circular(rad),
          clockwise: false,
        );
      }
      canvas.drawPath(path, lensPaint);
      canvas.drawPath(path, lensBorderPaint);
    }

    // Generate and calculate physics path for 80 Light Rays
    final int rayCount = 80;
    final rayPaint = Paint()
      ..color = Colors.amber.withOpacity(0.35)
      ..strokeWidth = 1.0;

    // Cyclic wave math to oscillate incoming ray directions smoothly
    double angleOffset = math.sin(progress * 2 * math.pi) * 0.07;

    for (int i = 0; i < rayCount; i++) {
      double startY = centerY - 120 + (240 / (rayCount - 1)) * i;
      double currentX = 0;
      double currentY = startY;

      double dirX = math.cos(angleOffset);
      double dirY = math.sin(angleOffset);

      List<Offset> rayPoints = [Offset(currentX, currentY)];
      double currentRefIndex = 1.0; // Air Refractive Index = 1.0

      // Sort lenses left-to-right along the X-axis for progressive calculation
      var sortedLenses = List<Lens>.from(lenses)
        ..sort((a, b) => a.x.compareTo(b.x));

      for (var lens in sortedLenses) {
        if (currentX < lens.x) {
          double stepX = lens.x - currentX;
          double stepY = (dirY / dirX) * stepX;

          currentX = lens.x;
          currentY += stepY;

          // Check if the ray strikes inside the lens vertical boundary limits
          if ((currentY - centerY).abs() < lens.height / 2) {
            // Approximated optical surface normal vector calculation
            double normalAngle = 0;
            if (lens.radius > 0) {
              normalAngle = (currentY - centerY) / lens.radius;
            } else {
              normalAngle = -(currentY - centerY) / lens.radius.abs();
            }

            // Implement Snell's Law vector refraction computation
            double incidentAngle = math.atan2(dirY, dirX) - normalAngle;
            double refractedAngle = math.asin(
              (currentRefIndex / lens.refIndex) * math.sin(incidentAngle),
            );

            if (!refractedAngle.isNaN) {
              double finalAngle = refractedAngle + normalAngle;
              dirX = math.cos(finalAngle);
              dirY = math.sin(finalAngle);
            }
          }
          rayPoints.add(Offset(currentX, currentY));
        }
      }

      // Project final calculated light paths cleanly off-screen
      double endX = size.width;
      double endY = currentY + (dirY / dirX) * (endX - currentX);
      rayPoints.add(Offset(endX, endY));

      // Paint lines across ray trajectory points on canvas
      for (int j = 0; j < rayPoints.length - 1; j++) {
        canvas.drawLine(rayPoints[j], rayPoints[j + 1], rayPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant RayTracerPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.lenses != lenses;
  }
}
