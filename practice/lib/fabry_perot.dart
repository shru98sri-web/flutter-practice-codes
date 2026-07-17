import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: UltraSmoothFPI()));

class UltraSmoothFPI extends StatefulWidget {
  const UltraSmoothFPI({super.key});

  @override
  State<UltraSmoothFPI> createState() => _UltraSmoothFPIState();
}

class _UltraSmoothFPIState extends State<UltraSmoothFPI> {
  ui.FragmentShader? shader;
  bool hasError = false;

  double R = 0.85; // Reflectance
  double d = 5000; // Cavity spacing (nm)
  double lambda = 632.8; // Wavelength (nm)
  double focalLength =
      1200; // फोकल लेंथ कमी केली जेणेकरून रिंग्स स्क्रीनवर स्पष्ट दिसतील

  @override
  void initState() {
    super.initState();
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'shaders/interferometer.frag',
      );
      setState(() {
        shader = program.fragmentShader();
      });
    } catch (e) {
      setState(() {
        hasError = true;
      });
      debugPrint("Shader Loading Error: $e");
    }
  }

  double calculateFinesse(double r) {
    return (math.pi * math.sqrt(r)) / (1.0 - r);
  }

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return const Scaffold(
        body: Center(
          child: Text('Shader initialization failed.Check pubspec.yaml specs'),
        ),
      );
    }
    if (shader == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    double currentFinesse = calculateFinesse(R);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('FPI Ultra-Smooth Simulator')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blueGrey[900],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  'Reflectance: ${R.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  'Finesse (ℱ): ${currentFinesse.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: CustomPaint(
              painter: ShaderFringePainter(
                shader: shader!,
                R: R,
                d: d,
                lambda: lambda,
                f: focalLength,
              ),
              child: Container(),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              children: [
                Text(
                  "Reflectance (R): ${R.toStringAsFixed(2)}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Slider(
                  value: R,
                  min: 0.50,
                  max: 0.95,
                  onChanged: (val) => setState(() => R = val),
                ),
                const SizedBox(height: 10),
                Text(
                  "Cavity Spacing (d): ${d.toStringAsFixed(0)} nm",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Slider(
                  value: d,
                  min: 2000,
                  max: 8000,
                  onChanged: (val) => setState(() => d = val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ShaderFringePainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double R, d, lambda, f;

  ShaderFringePainter({
    required this.shader,
    required this.R,
    required this.d,
    required this.lambda,
    required this.f,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // तंतोतंत इंडेक्स मॅचिंग (0 ते 5)
    shader.setFloat(0, size.width); // uWidth
    shader.setFloat(1, size.height); // uHeight
    shader.setFloat(2, R); // uR
    shader.setFloat(3, d); // uD
    shader.setFloat(4, lambda); // uLambda
    shader.setFloat(5, f); // uFocalLength

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant ShaderFringePainter oldDelegate) => true;
}
