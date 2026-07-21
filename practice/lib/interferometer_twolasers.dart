import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: UltraSmoothFPI(),
    ),
  );
}

class UltraSmoothFPI extends StatefulWidget {
  const UltraSmoothFPI({super.key});

  @override
  State<UltraSmoothFPI> createState() => _UltraSmoothFPIState();
}

class _UltraSmoothFPIState extends State<UltraSmoothFPI> {
  ui.FragmentShader? shader;
  bool hasError = false;

  double R = 0.85; // Reflectance
  double d = 20000; // Cavity spacing (20 µm)
  double lambda = 632.8; // Initial: Red He-Ne Laser

  @override
  void initState() {
    super.initState();
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'shaders/interfergr.frag',
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

  double calculateCentralOrder(double spacing, double wavelength) {
    return (2 * spacing) / wavelength;
  }

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Shader initialization failed!',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    if (shader == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.red)),
      );
    }

    double currentFinesse = calculateFinesse(R);
    double centralOrder = calculateCentralOrder(d, lambda);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'FPI Multi-Wavelength Simulator',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey,
      ),
      body: Column(
        children: [
          // Analytical Data Panel
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            color: Colors.blueGrey,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      'Cavity Finesse (ℱ)',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentFinesse.toStringAsFixed(2),
                      style: const TextStyle(
                        color: Colors.pinkAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text(
                      'Central Fringe Order (m)',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      centralOrder.toStringAsFixed(3),
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // GPU Rendered Canvas
          Expanded(
            child: CustomPaint(
              painter: ShaderFringePainter(
                shader: shader!,
                R: R,
                d: d,
                lambda: lambda,
              ),
              child: Container(),
            ),
          ),

          // Engineering Controls Panel
          Container(
            color: Colors.blueGrey,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                // Laser Source Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Laser Source:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    ToggleButtons(
                      isSelected: [lambda == 632.8, lambda == 543.5],
                      onPressed: (index) {
                        setState(() {
                          lambda = index == 0 ? 632.8 : 543.5;
                        });
                      },
                      color: Colors.white60,
                      selectedColor: Colors.white,
                      fillColor: lambda == 632.8
                          ? Colors.red.withOpacity(0.5)
                          : Colors.green.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text("Red (632.8 nm)"),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text("Green (543.5 nm)"),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Reflectance (R) [Sharpness]",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      R.toStringAsFixed(2),
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: R,
                  min: 0.60,
                  max: 0.96,
                  activeColor: lambda == 632.8 ? Colors.red : Colors.green,
                  inactiveColor: Colors.grey,
                  onChanged: (val) => setState(() => R = val),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Cavity Spacing (d)",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "${(d / 1000).toStringAsFixed(3)} µm",
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: d,
                  min: 19500,
                  max: 20500,
                  activeColor: lambda == 632.8 ? Colors.red : Colors.green,
                  inactiveColor: Colors.grey,
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
  final double R, d, lambda;

  ShaderFringePainter({
    required this.shader,
    required this.R,
    required this.d,
    required this.lambda,
  });

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, R);
    shader.setFloat(3, d);
    shader.setFloat(4, lambda);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant ShaderFringePainter oldDelegate) => true;
}
