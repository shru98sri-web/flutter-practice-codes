import 'package:flutter/material.dart';

void main() => runApp(const BernoulliApp());

class BernoulliApp extends StatelessWidget {
  const BernoulliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const BernoulliSimulation(),
    );
  }
}

class BernoulliSimulation extends StatefulWidget {
  const BernoulliSimulation({super.key});

  @override
  State<BernoulliSimulation> createState() => _BernoulliSimulationState();
}

class _BernoulliSimulationState extends State<BernoulliSimulation> {
  // Configurable flow velocity at the inlet (Point 1)
  double v1 = 2.0; // m/s
  final double p1 = 200000; // Const pressure at inlet (200 kPa)
  final double rho = 1000; // Density of water (1000 kg/m³)

  @override
  Widget build(BuildContext context) {
    // Pipe Areas (Fixed geometry for demonstration)
    const double a1 = 0.1;
    const double a2 = 0.04; // Narrow constriction (Point 2)

    // Continuity Equation: A1 * V1 = A2 * V2 -> V2 = (A1 / A2) * V1
    double v2 = (a1 / a2) * v1;

    // Bernoulli's Equation: P1 + 0.5*rho*v1² = P2 + 0.5*rho*v2²
    // P2 = P1 + 0.5 * rho * (v1² - v2²)
    double p2 = p1 + 0.5 * rho * ((v1 * v1) - (v2 * v2));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bernoulli's Theorem Simulator"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Equation Header Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                // Using simple notation clear for all screen sizes
                child: Center(
                  child: Text(
                    "P₁ + ½ρv₁² = P₂ + ½ρv₂²",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[300],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Visual Animation Panel
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: CustomPaint(
                  painter: PipePainter(v1: v1, v2: v2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Live Metrics Panel
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricColumn(
                  "Wide Section (1)",
                  v1,
                  p1,
                  Colors.greenAccent,
                ),
                _buildMetricColumn(
                  "Narrow Section (2)",
                  v2,
                  p2,
                  Colors.orangeAccent,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Flow Rate Interactive Control Slider
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Column(
                  children: [
                    Text(
                      "Adjust Inlet Velocity (v₁): ${v1.toStringAsFixed(1)} m/s",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: v1,
                      min: 0.5,
                      max: 4.5,
                      divisions: 40,
                      activeColor: Colors.blueAccent,
                      onChanged: (val) {
                        setState(() {
                          v1 = val;
                        });
                      },
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

  Widget _buildMetricColumn(
    String title,
    double velocity,
    double pressure,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Text("Velocity: ${velocity.toStringAsFixed(2)} m/s"),
        Text("Pressure: ${(pressure / 1000).toStringAsFixed(1)} kPa"),
      ],
    );
  }
}

class PipePainter extends CustomPainter {
  final double v1;
  final double v2;

  PipePainter({required this.v1, required this.v2});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final midY = h / 2;

    // Define geometric profile vectors of the Venturi tube
    final pipePath = Path()
      ..moveTo(0, midY - 60)
      ..lineTo(w * 0.3, midY - 60)
      ..cubicTo(w * 0.45, midY - 60, w * 0.45, midY - 25, w * 0.55, midY - 25)
      ..lineTo(w * 0.7, midY - 25)
      ..cubicTo(w * 0.8, midY - 25, w * 0.8, midY - 60, w * 0.95, midY - 60)
      ..lineTo(w, midY - 60)
      ..lineTo(w, midY + 60)
      ..lineTo(w * 0.95, midY + 60)
      ..cubicTo(w * 0.8, midY + 60, w * 0.8, midY + 25, w * 0.7, midY + 25)
      ..lineTo(w * 0.55, midY + 25)
      ..cubicTo(w * 0.45, midY + 25, w * 0.45, midY + 60, w * 0.3, midY + 60)
      ..lineTo(0, midY + 60)
      ..close();

    // Fill fluid background (Opacity represents relative visual density)
    final fluidPaint = Paint()
      ..color = Colors.blue.withAlpha(50)
      ..style = PaintingStyle.fill;
    canvas.drawPath(pipePath, fluidPaint);

    // Draw Pipe Structural Contours
    final borderPaint = Paint()
      ..color = Colors.white70
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawPath(pipePath, borderPaint);

    // Draw dynamic flow streamline vectors inside the fluid
    final linePaint = Paint()
      ..color = Colors.cyanAccent.withAlpha(180)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Generate reference vector lines mapping fluid compression layout
    for (var offset in [-35.0, 0.0, 35.0]) {
      final streamPath = Path()
        ..moveTo(0, midY + offset)
        ..lineTo(w * 0.3, midY + offset)
        ..cubicTo(
          w * 0.45,
          midY + offset,
          w * 0.45,
          midY + (offset * 0.41),
          w * 0.55,
          midY + (offset * 0.41),
        )
        ..lineTo(w * 0.7, midY + (offset * 0.41))
        ..cubicTo(
          w * 0.8,
          midY + (offset * 0.41),
          w * 0.8,
          midY + offset,
          w * 0.95,
          midY + offset,
        )
        ..lineTo(w, midY + offset);
      canvas.drawPath(streamPath, linePaint);
    }

    // Annotation Tags (1 and 2 tracking targets)
    _drawMarker(canvas, Offset(w * 0.2, midY), "P₁, v₁", Colors.greenAccent);
    _drawMarker(canvas, Offset(w * 0.62, midY), "P₂, v₂", Colors.orangeAccent);
  }

  void _drawMarker(Canvas canvas, Offset pos, String text, Color color) {
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 5, circlePaint);

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - 28));
  }

  @override
  bool shouldRepaint(covariant PipePainter oldDelegate) => oldDelegate.v1 != v1;
}
