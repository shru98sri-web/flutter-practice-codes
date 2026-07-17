import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ZeemanApp());
}

class ZeemanApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zeeman Effect Simulator',
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black54),
      home: ZeemanSimulationPage(),
    );
  }
}

class ZeemanSimulationPage extends StatefulWidget {
  @override
  _ZeemanSimulationPageState createState() => _ZeemanSimulationPageState();
}

class _ZeemanSimulationPageState extends State<ZeemanSimulationPage>
    with SingleTickerProviderStateMixin {
  double _bField = 0.0; // Magnetic field strength (Tesla)
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zeeman Splitting Simulation')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  margin: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: ZeemanPainter(_bField, _animation.value),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text(
                  'Magnetic Field (B): ${_bField.toStringAsFixed(2)} T',
                  style: const TextStyle(fontSize: 18),
                ),
                Slider(
                  value: _bField,
                  min: 0.0,
                  max: 5.0,
                  divisions: 50,
                  label: '${_bField.toStringAsFixed(1)} T',
                  onChanged: (value) => setState(() => _bField = value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ZeemanPainter extends CustomPainter {
  final double bField;
  final double pulseValue;

  ZeemanPainter(this.bField, this.pulseValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Background glow
    final glowPaint = Paint()
      ..color = Colors.blue.withOpacity(0.05 * bField)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawRect(Offset.zero & size, glowPaint);

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Constants for Bohr magneton & frequency shift
    const baseFreq = 200.0;
    final shift = 25.0 * bField;

    // The Central Unshifted Line (\pi transition)
    _drawSpectralLine(
      canvas,
      centerX,
      centerY,
      baseFreq,
      Colors.white,
      pulseValue,
    );

    // If B > 0, we draw the split lines (\sigma transitions)
    if (bField > 0) {
      // Left shifted line (m = -1)
      _drawSpectralLine(
        canvas,
        centerX - shift,
        centerY,
        baseFreq - shift,
        Colors.blueAccent,
        pulseValue,
      );
      // Right shifted line (m = +1)
      _drawSpectralLine(
        canvas,
        centerX + shift,
        centerY,
        baseFreq + shift,
        Colors.redAccent,
        pulseValue,
      );

      // Draw connection lines
      final path = Path()
        ..moveTo(centerX, centerY - 20)
        ..quadraticBezierTo(
          centerX - shift / 2,
          centerY - 60,
          centerX - shift,
          centerY - 80,
        )
        ..moveTo(centerX, centerY - 20)
        ..quadraticBezierTo(
          centerX + shift / 2,
          centerY - 60,
          centerX + shift,
          centerY - 80,
        );
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white24
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _drawSpectralLine(
    Canvas canvas,
    double x,
    double y,
    double intensity,
    Color color,
    double pulse,
  ) {
    final paint = Paint()
      ..color = color.withOpacity(0.5 + (0.5 * pulse))
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // Draw the main spectral peak line
    canvas.drawLine(Offset(x, y - 50), Offset(x, y + 50), paint);

    // Draw emission halo
    final haloPaint = Paint()
      ..color = color.withOpacity(0.2 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawLine(Offset(x, y - 60), Offset(x, y + 60), haloPaint);
  }

  @override
  bool shouldRepaint(covariant ZeemanPainter oldDelegate) {
    return oldDelegate.bField != bField || oldDelegate.pulseValue != pulseValue;
  }
}
