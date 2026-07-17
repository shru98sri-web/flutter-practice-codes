import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

void main() {
  runApp(const AdvancedLaserApp());
}

class AdvancedLaserApp extends StatelessWidget {
  const AdvancedLaserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(primaryColor: Colors.blueAccent),
      home: const LaserWorkspace(),
    );
  }
}

class LaserWorkspace extends StatefulWidget {
  const LaserWorkspace({super.key});

  @override
  State<LaserWorkspace> createState() => _LaserWorkspaceState();
}

class _LaserWorkspaceState extends State<LaserWorkspace> {
  // Configurable Parameters
  int _m = 0;
  int _n = 0;
  double _beamRadius = 45.0; // w0 parameter
  Color _laserColor = Colors.red;

  final List<Map<String, dynamic>> _temModes = [
    {'name': 'TEM 00', 'm': 0, 'n': 0},
    {'name': 'TEM 01', 'm': 0, 'n': 1},
    {'name': 'TEM 10', 'm': 1, 'n': 0},
    {'name': 'TEM 11', 'm': 1, 'n': 1},
    {'name': 'TEM 20', 'm': 2, 'n': 0},
    {'name': 'TEM 22', 'm': 2, 'n': 2},
    {'name': 'TEM 33', 'm': 3, 'n': 3},
  ];

  final List<Map<String, dynamic>> _wavelengths = [
    {'name': 'UV (375nm)', 'color': Colors.deepPurple},
    {'name': 'Blue (450nm)', 'color': Colors.blue},
    {'name': 'Green (532nm)', 'color': Colors.green},
    {'name': 'Red (650nm)', 'color': Colors.red},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laser Transverse Mode Simulator'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              // High-Performance Visualizer Viewport
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _laserColor.withOpacity(0.5)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: FutureBuilder<ui.Image>(
                        future: _generateModeImage(
                          _m,
                          _n,
                          _beamRadius,
                          _laserColor,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasData) {
                            return CustomPaint(
                              painter: TexturePainter(snapshot.data!),
                              child: const SizedBox.expand(),
                            );
                          }
                          return const Center(child: Text('Rendering Error'));
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // Settings Control Panel
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: ListView(
                    children: [
                      // Beam Radius Slider
                      Text(
                        'Beam Radius Size (w₀): ${_beamRadius.toStringAsFixed(1)} px',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Slider(
                        value: _beamRadius,
                        min: 20.0,
                        max: 80.0,
                        activeColor: _laserColor,
                        onChanged: (val) => setState(() => _beamRadius = val),
                      ),
                      const Divider(height: 24),

                      // Wavelength Color Picker
                      const Text(
                        'Wavelength Color Profile',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _wavelengths.map((w) {
                          final isSel = _laserColor == w['color'];
                          return ChoiceChip(
                            label: Text(w['name']),
                            selected: isSel,
                            selectedColor: w['color'],
                            onSelected: (selected) {
                              if (selected)
                                setState(() => _laserColor = w['color']);
                            },
                          );
                        }).toList(),
                      ),
                      const Divider(height: 24),

                      // Spatial Mode List Selector
                      const Text(
                        'Select Higher-Order TEM Mode',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _temModes.map((mode) {
                          final isSel = _m == mode['m'] && _n == mode['n'];
                          return ChoiceChip(
                            label: Text(mode['name']),
                            selected: isSel,
                            selectedColor: _laserColor.withOpacity(0.3),
                            side: BorderSide(
                              color: isSel ? _laserColor : Colors.grey,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _m = mode['m'];
                                  _n = mode['n'];
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Fast mathematical rendering via low-level byte arrays
  Future<ui.Image> _generateModeImage(
    int m,
    int n,
    double w0,
    Color laserColor,
  ) {
    final Completer<ui.Image> completer = Completer();
    const int width = 300;
    const int height = 300;

    // 4 channels (RGBA) per pixel
    final Uint8List pixels = Uint8List(width * height * 4);
    const double centerX = width / 2;
    const double centerY = height / 2;

    int pixelIndex = 0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final double xNorm = (x - centerX) / w0;
        final double yNorm = (y - centerY) / w0;

        final double hX = _hermite(m, xNorm * math.sqrt(2));
        final double hY = _hermite(n, yNorm * math.sqrt(2));
        final double gaussian = math.exp(-(xNorm * xNorm + yNorm * yNorm));

        final double amplitude = hX * hY * gaussian;
        double intensity = amplitude * amplitude;

        // Mathematical scaling factor corrections based on order levels
        if (m == 1) intensity /= 2.0;
        if (n == 1) intensity /= 2.0;
        if (m == 2) intensity /= 8.0;
        if (n == 2) intensity /= 8.0;
        if (m == 3) intensity /= 48.0;
        if (n == 3) intensity /= 48.0;

        final double finalIntensity = intensity.clamp(0.0, 1.0);

        // Map intensity scale dynamically directly into raw RGBA bytes memory array
        pixels[pixelIndex] = (laserColor.red * finalIntensity).toInt(); // R
        pixels[pixelIndex + 1] = (laserColor.green * finalIntensity)
            .toInt(); // G
        pixels[pixelIndex + 2] = (laserColor.blue * finalIntensity)
            .toInt(); // B
        pixels[pixelIndex + 3] = (finalIntensity * 255).toInt(); // A

        pixelIndex += 4;
      }
    }

    ui.decodeImageFromPixels(
      pixels,
      width,
      height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );

    return completer.future;
  }

  double _hermite(int order, double x) {
    if (order == 0) return 1.0;
    if (order == 1) return 2.0 * x;
    if (order == 2) return 4.0 * x * x - 2.0;
    if (order == 3) return 8.0 * x * x * x - 12.0 * x;
    return 1.0;
  }
}

// Draws the pre-computed pixel matrix straight to canvas smoothly
class TexturePainter extends CustomPainter {
  final ui.Image image;
  TexturePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()..filterQuality = ui.FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant TexturePainter oldDelegate) =>
      oldDelegate.image != image;
}
