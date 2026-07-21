import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() => runApp(const ChartApp());

class ChartApp extends StatelessWidget {
  const ChartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: RangeChartContainer(),
          ),
        ),
      ),
    );
  }
}

class RangeChartContainer extends StatelessWidget {
  const RangeChartContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio:
          1.6, // Adjusted slightly to comfortably fit the wide right legend
      child: CustomPaint(painter: LidarRangeChartPainter()),
    );
  }
}

class LidarRangeChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Adjusted paddingRight to carve out dedicated space for the attenuation legend
    const double paddingLeft = 65.0;
    const double paddingRight = 180.0;
    const double paddingTop = 40.0;
    const double paddingBottom = 55.0;

    final double graphWidth = w - paddingLeft - paddingRight;
    final double graphHeight = h - paddingTop - paddingBottom;

    // Axis limits
    const double xMax = 90.0;
    const double yMax = 6.0;

    // Painting tools
    final axisPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final tickPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0;

    // 1. Draw Main Border Box
    final Rect graphRect = Rect.fromLTWH(
      paddingLeft,
      paddingTop,
      graphWidth,
      graphHeight,
    );
    canvas.drawRect(graphRect, axisPaint);

    // 2. Draw X-Axis Ticks & Labels (0 to 80)
    for (int i = 0; i <= 80; i += 20) {
      double xPos = paddingLeft + (i / xMax) * graphWidth;
      canvas.drawLine(
        Offset(xPos, paddingTop + graphHeight),
        Offset(xPos, paddingTop + graphHeight - 6),
        tickPaint,
      );
      canvas.drawLine(
        Offset(xPos, paddingTop),
        Offset(xPos, paddingTop + 6),
        tickPaint,
      );
      _drawText(
        canvas,
        Offset(xPos, paddingTop + graphHeight + 8),
        "$i",
        alignment: Alignment.topCenter,
      );
    }
    double x90 = paddingLeft + (90 / xMax) * graphWidth;
    canvas.drawLine(
      Offset(x90, paddingTop + graphHeight),
      Offset(x90, paddingTop + graphHeight - 6),
      tickPaint,
    );

    // 3. Draw Y-Axis Ticks & Labels (0 to 5)
    for (int i = 0; i <= 5; i += 1) {
      double yPos = paddingTop + graphHeight - (i / yMax) * graphHeight;
      canvas.drawLine(
        Offset(paddingLeft, yPos),
        Offset(paddingLeft + 6, yPos),
        tickPaint,
      );
      canvas.drawLine(
        Offset(paddingLeft + graphWidth, yPos),
        Offset(paddingLeft + graphWidth - 6, yPos),
        tickPaint,
      );
      _drawText(
        canvas,
        Offset(paddingLeft - 10, yPos),
        "$i",
        alignment: Alignment.centerRight,
      );
    }

    // 4. Plot the 4 Rounded Decay Curves
    final List<Map<String, dynamic>> curves = [
      {'r0': 5.6, 'color': Colors.black, 'label': '0.05 km^-1'},
      {'r0': 4.6, 'color': Colors.red, 'label': '0.15 km^-1'},
      {'r0': 3.7, 'color': Colors.green, 'label': '0.30 km^-1'},
      {'r0': 2.8, 'color': Colors.blue, 'label': '0.60 km^-1'},
    ];

    for (var curve in curves) {
      final double r0 = curve['r0'];
      final Color color = curve['color'];

      final curvePaint = Paint()
        ..color = color
        ..strokeWidth = 4.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final Path path = Path();
      bool isFirst = true;

      for (int i = 0; i <= 200; i++) {
        double deg = (i / 200) * 90.0;
        double rad = deg * (math.pi / 180.0);
        double range = r0 * math.sqrt(math.cos(rad));

        double x = paddingLeft + (deg / xMax) * graphWidth;
        double y = paddingTop + graphHeight - (range / yMax) * graphHeight;

        if (isFirst) {
          path.moveTo(x, y);
          isFirst = false;
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, curvePaint);
    }

    // 5. Draw Atmospheric Attenuation Coefficient Legend Panel
    final double legendStartX = paddingLeft + graphWidth + 25;
    double currentLegendY = paddingTop - 10;

    // Multi-line header block text rendering
    _drawText(
      canvas,
      Offset(legendStartX, currentLegendY),
      "Atmospheric",
      isBold: true,
      fontSize: 13,
      alignment: Alignment.topLeft,
    );
    currentLegendY += 16;
    _drawText(
      canvas,
      Offset(legendStartX, currentLegendY),
      "Attenuation",
      isBold: true,
      fontSize: 13,
      alignment: Alignment.topLeft,
    );
    currentLegendY += 16;
    _drawText(
      canvas,
      Offset(legendStartX, currentLegendY),
      "Coefficient",
      isBold: true,
      fontSize: 13,
      alignment: Alignment.topLeft,
    );

    currentLegendY += 28; // Space before indicator rows

    // Draw lines and matching coefficient text strings
    for (var curve in curves) {
      final Color color = curve['color'];
      final String labelText = curve['label'];

      final legendLinePaint = Paint()
        ..color = color
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round;

      // Draw color bar indicator
      canvas.drawLine(
        Offset(legendStartX, currentLegendY + 6),
        Offset(legendStartX + 25, currentLegendY + 6),
        legendLinePaint,
      );

      // Draw indicator layout label value
      _drawText(
        canvas,
        Offset(legendStartX + 35, currentLegendY),
        labelText,
        isBold: true,
        fontSize: 13,
        alignment: Alignment.topLeft,
      );

      currentLegendY += 22; // Step spacing between legend items
    }

    // 6. Draw Standard Titles
    _drawText(
      canvas,
      Offset(paddingLeft + graphWidth / 2, paddingTop + graphHeight + 32),
      "Angle of Incidence (degrees)",
      isBold: true,
      fontSize: 14,
      alignment: Alignment.topCenter,
    );

    _drawRotatedText(
      canvas,
      Offset(paddingLeft - 40, paddingTop + graphHeight / 2),
      "Maximum Range (km)",
      isBold: true,
      fontSize: 14,
    );

    _drawText(
      canvas,
      Offset(paddingLeft + graphWidth / 2, paddingTop - 25),
      "Maximum Range vs. Angle of Incidence",
      isBold: true,
      fontSize: 14,
      alignment: Alignment.topCenter,
    );
  }

  void _drawText(
    Canvas canvas,
    Offset pos,
    String text, {
    bool isBold = false,
    double fontSize = 12,
    Alignment alignment = Alignment.center,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.black,
          fontSize: fontSize,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontFamily: 'sans-serif',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    double dx = pos.dx;
    double dy = pos.dy;

    if (alignment == Alignment.topCenter) dx -= tp.width / 2;
    if (alignment == Alignment.topLeft) {
      /* keeps explicit dx/dy positioning intact */
    }
    if (alignment == Alignment.centerRight) {
      dx -= tp.width;
      dy -= tp.height / 2;
    }
    if (alignment == Alignment.center) {
      dx -= tp.width / 2;
      dy -= tp.height / 2;
    }

    tp.paint(canvas, Offset(dx, dy));
  }

  void _drawRotatedText(
    Canvas canvas,
    Offset pos,
    String text, {
    bool isBold = false,
    double fontSize = 12,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.black,
          fontSize: fontSize,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(-math.pi / 2);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
