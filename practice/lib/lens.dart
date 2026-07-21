import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

// void main() {
//   runApp(const RayTracingApp());
// }

class RayTracingApp extends StatelessWidget {
  const RayTracingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Advanced Optics Simulation',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.cyanAccent,
      ),
      home: const RayTracerScreen(),
    );
  }
}

class RayTracerScreen extends StatefulWidget {
  const RayTracerScreen({super.key});

  @override
  State<RayTracerScreen> createState() => _RayTracerScreenState();
}

class _RayTracerScreenState extends State<RayTracerScreen> {
  // Lens Parameters
  bool _isConvex = true;
  double _refractiveIndex = 1.50; // Crown glass default
  double _radius1 = 120.0; // Radius of surface 1 (front)
  double _radius2 = 120.0; // Radius of surface 2 (back)

  // Object Parameters
  double _objectDistance = 220.0;
  double _objectHeight = 60.0;

  @override
  Widget build(BuildContext context) {
    // 1. Lens Maker's Equation implementation using standard sign conventions
    // Convex (Bi-convex): R1 is positive, R2 is negative.
    // Concave (Bi-concave): R1 is negative, R2 is positive.
    final double r1Signed = _isConvex ? _radius1 : -_radius1;
    final double r2Signed = _isConvex ? -_radius2 : _radius2;

    // 1/f = (n - 1) * (1/R1 - 1/R2)
    final double lensPower =
        (_refractiveIndex - 1.0) * ((1.0 / r1Signed) - (1.0 / r2Signed));

    // Absolute calculated focal length
    final double calculatedFocalLength = lensPower != 0
        ? (1.0 / lensPower).abs()
        : double.infinity;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Optics Simulation: Lens Maker\'s Equation'),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFF0A0A0A),
              child: CustomPaint(
                size: Size.infinite,
                painter: AdvancedLensPainter(
                  objectDistance: _objectDistance,
                  objectHeight: _objectHeight,
                  focalLength: calculatedFocalLength,
                  isConvex: _isConvex,
                  radius1: _radius1,
                  radius2: _radius2,
                  refractiveIndex: _refractiveIndex,
                ),
              ),
            ),
          ),
          _buildControlPanel(calculatedFocalLength),
        ],
      ),
    );
  }

  Widget _buildControlPanel(double currentFocal) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1E1E1E),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: Lens Type and Real-time Focal Length Output
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text("Concave", style: TextStyle(fontSize: 16)),
                    Switch(
                      value: _isConvex,
                      activeColor: Colors.cyanAccent,
                      onChanged: (val) => setState(() => _isConvex = val),
                    ),
                    const Text(
                      "Convex",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  "Calculated Focal Length (f): ${currentFocal.toStringAsFixed(1)}px",
                  style: const TextStyle(
                    color: Colors.yellowAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.grey),

            // Row 2: Refractive Index Slider
            _buildSliderRow(
              label: "Refractive Index (n)",
              value: _refractiveIndex,
              min: 1.1,
              max: 2.4,
              // Air to Diamond boundary
              displayValue: _refractiveIndex.toStringAsFixed(2),
              onChanged: (val) => setState(() => _refractiveIndex = val),
            ),

            // Row 3: Radius of Curvature Slider
            _buildSliderRow(
              label: "Surface Radii (R1 & R2)",
              value: _radius1,
              // Mirroring R1 and R2 for a symmetric lens
              min: 60.0,
              max: 250.0,
              displayValue: "${_radius1.toStringAsFixed(0)}px",
              onChanged: (val) => setState(() {
                _radius1 = val;
                _radius2 = val;
              }),
            ),

            // Row 4: Object Distance Slider
            _buildSliderRow(
              label: "Object Distance (u)",
              value: _objectDistance,
              min: 30.0,
              max: 400.0,
              displayValue: "${_objectDistance.toStringAsFixed(0)}px",
              onChanged: (val) => setState(() => _objectDistance = val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ),
        Expanded(
          flex: 5,
          child: Slider(
            value: value,
            min: min,
            max: max,
            activeColor: Colors.cyan,
            inactiveColor: Colors.grey[800],
            onChanged: onChanged,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            displayValue,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontFamily: 'monospace',
              color: Colors.cyanAccent,
            ),
          ),
        ),
      ],
    );
  }
}

class AdvancedLensPainter extends CustomPainter {
  final double objectDistance;
  final double objectHeight;
  final double focalLength;
  final bool isConvex;
  final double radius1;
  final double radius2;
  final double refractiveIndex;

  AdvancedLensPainter({
    required this.objectDistance,
    required this.objectHeight,
    required this.focalLength,
    required this.isConvex,
    required this.radius1,
    required this.radius2,
    required this.refractiveIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    void _drawExtendedRay(
      Canvas canvas,
      Offset start,
      Offset via,
      double maxExtent,
      Paint paint,
    ) {
      final double dx = via.dx - start.dx;
      final double dy = via.dy - start.dy;
      if (dx == 0) return;
      final double slope = dy / dx;
      final Offset endPoint = dx > 0
          ? Offset(maxExtent, via.dy + slope * (maxExtent - via.dx))
          : Offset(0, via.dy + slope * (0 - via.dx));
      canvas.drawLine(start, endPoint, paint);
    }

    void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
      const double dashWidth = 4.0;
      const double dashSpace = 4.0;
      final double dx = p2.dx - p1.dx;
      final double dy = p2.dy - p1.dy;
      final double distance = sqrt(dx * dx + dy * dy);
      final double maxDashes = distance / (dashWidth + dashSpace);
      double currentDist = 0.0;
      for (int i = 0; i < maxDashes; i++) {
        final double t1 = currentDist / distance;
        currentDist += dashWidth;
        final double t2 = currentDist / distance;
        canvas.drawLine(
          Offset(p1.dx + dx * t1, p1.dy + dy * t1),
          Offset(p1.dx + dx * t2, p1.dy + dy * t2),
          paint,
        );
        currentDist += dashSpace;
      }
    }

    void _drawArrowHead(Canvas canvas, Offset start, Offset end, Color color) {
      final double dx = end.dx - start.dx;
      final double dy = end.dy - start.dy;
      final double angle = atan2(dy, dx);
      const double arrowSize = 8.0;
      final Path path = Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo(
          end.dx - arrowSize * cos(angle - pi / 6),
          end.dy - arrowSize * sin(angle - pi / 6),
        )
        ..lineTo(
          end.dx - arrowSize * cos(angle + pi / 6),
          end.dy - arrowSize * sin(angle + pi / 6),
        )
        ..close();
      final Paint paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, paint);
    }

    // 1. Draw Axis Lines
    final axisPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      axisPaint,
    );

    // 2. Draw Physics Realistic Lens Geometry Layout
    final lensPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    final lensOutlinePaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final Path lensPath = Path();
    const double lensThickness = 24.0;
    const double lensHeight = 220.0;

    if (isConvex) {
      // Draw Bi-Convex Path
      lensPath.moveTo(center.dx, center.dy - lensHeight / 2);
      lensPath.quadraticBezierTo(
        center.dx + lensThickness,
        center.dy,
        center.dx,
        center.dy + lensHeight / 2,
      );
      lensPath.quadraticBezierTo(
        center.dx - lensThickness,
        center.dy,
        center.dx,
        center.dy - lensHeight / 2,
      );
    } else {
      // Draw Bi-Concave Path
      lensPath.moveTo(center.dx - lensThickness, center.dy - lensHeight / 2);
      lensPath.lineTo(center.dx + lensThickness, center.dy - lensHeight / 2);
      lensPath.quadraticBezierTo(
        center.dx + 4,
        center.dy,
        center.dx + lensThickness,
        center.dy + lensHeight / 2,
      );
      lensPath.lineTo(center.dx - lensThickness, center.dy + lensHeight / 2);
      lensPath.quadraticBezierTo(
        center.dx - 4,
        center.dy,
        center.dx - lensThickness,
        center.dy - lensHeight / 2,
      );
    }
    canvas.drawPath(lensPath, lensPaint);
    canvas.drawPath(lensPath, lensOutlinePaint);

    // 3. Focal Points Rendering (F and 2F on both sides)
    final double f = focalLength;
    final fPoints = [
      Offset(center.dx - f, center.dy), // F1 (Left)
      Offset(center.dx + f, center.dy), // F2 (Right)
      Offset(center.dx - 2 * f, center.dy), // 2F1 (Left)
      Offset(center.dx + 2 * f, center.dy), // 2F2 (Right)
    ];

    final focusPaint = Paint()
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < fPoints.length; i++) {
      focusPaint.color = i < 2 ? Colors.redAccent : Colors.orangeAccent;
      canvas.drawPoints(PointMode.points, [fPoints[i]], focusPaint);
    }

    // 4. Draw Object (Green Arrow)
    final double objX = center.dx - objectDistance;
    final Offset objTop = Offset(objX, center.dy - objectHeight);
    final paintObj = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 3.5;
    canvas.drawLine(Offset(objX, center.dy), objTop, paintObj);
    _drawArrowHead(canvas, Offset(objX, center.dy), objTop, Colors.greenAccent);

    // 5. Compute Mathematical Image Coordinates (Thin Lens Formula)
    // Sign conventions: Object distance (u) is always negative in vector geometry calculations.
    final double u = -objectDistance;
    final double signedF = isConvex ? f : -f;

    // 1/v = 1/f + 1/u
    final double invV = (1.0 / signedF) + (1.0 / u);
    final double v = invV.abs() > 0.0001 ? 1.0 / invV : 99999.0;
    final double magnification = u != 0 ? v / u : 1.0;
    final double imgHeight = objectHeight * magnification;
    final double imgX = center.dx + v;
    final Offset imgTop = Offset(imgX, center.dy + imgHeight);

    // Draw Formed Image Structure (Orange Arrow)
    final paintImg = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = 3.5
      ..style = PaintingStyle
          .stroke; // Check if the image falls inside screen boundaries
    if (imgX.isFinite && imgX.abs() < 5000) {
      // If virtual image, draw it dashed to represent physics convention
      if (v < 0) {
        _drawDashedLine(canvas, Offset(imgX, center.dy), imgTop, paintImg);
      } else {
        canvas.drawLine(Offset(imgX, center.dy), imgTop, paintImg);
      }
      _drawArrowHead(
        canvas,
        Offset(imgX, center.dy),
        imgTop,
        Colors.orangeAccent,
      );
    }
    // 6. Draw Ray Tracing Vectors
    final ray1Paint = Paint()
      ..color = Colors.yellowAccent.withOpacity(0.8)
      ..strokeWidth = 1.8;
    final ray2Paint = Paint()
      ..color = Colors.pinkAccent.withOpacity(0.8)
      ..strokeWidth = 1.8;
    final virtualRayPaint = Paint()
      ..color = Colors.white54
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final Offset lensCenterTop = Offset(center.dx, objTop.dy);
    // --- RAY 1: Parallel to Principal Axis ---
    canvas.drawLine(objTop, lensCenterTop, ray1Paint);
    if (isConvex) {
      // Bends through real focal point F2 (Right)
      final Offset dir = Offset(center.dx + f, center.dy);
      _drawExtendedRay(canvas, lensCenterTop, dir, size.width, ray1Paint);
    } else {
      // Diverges away from virtual focus point F1 (Left side)
      final Offset virtualFocusLeft = Offset(center.dx - f, center.dy);
      _drawExtendedRay(
        canvas,
        lensCenterTop,
        lensCenterTop + (lensCenterTop - virtualFocusLeft),
        size.width,
        ray1Paint,
      );
      // Virtual trace back projection line
      // _drawDashedLine(canvas, lensCenterTop, virtualFocusLeft, virtualRayPaint);}
      // --- RAY 2: Center Optical Node Ray ---
      final Offset centerNode = Offset(center.dx, center.dy);
      _drawExtendedRay(canvas, objTop, centerNode, size.width, ray2Paint);
      // --- Virtual Intersections Construction ---//
      //If the image is virtual (v < 0), project back tracing lines to the image peak point
      if (v < 0 && imgTop.dx.isFinite) {
        _drawDashedLine(canvas, lensCenterTop, imgTop, virtualRayPaint);
        _drawDashedLine(canvas, centerNode, imgTop, virtualRayPaint);
      }
    }

    @override
    shouldRepaint(AdvancedLensPainter oldDelegate) {
      return oldDelegate.objectDistance != objectDistance ||
          oldDelegate.objectHeight != objectHeight ||
          oldDelegate.focalLength != focalLength ||
          oldDelegate.isConvex != isConvex ||
          oldDelegate.radius1 != radius1 ||
          oldDelegate.radius2 != radius2 ||
          oldDelegate.refractiveIndex != refractiveIndex;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // TODO: implement shouldRepaint
    return true;
  }
}
