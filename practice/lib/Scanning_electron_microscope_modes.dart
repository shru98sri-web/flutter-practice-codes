import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

void main() {
  runApp(const SemApp());
}

class SemApp extends StatelessWidget {
  const SemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.teal,
      ),
      home: const SemWorkspace(),
    );
  }
}

class SemWorkspace extends StatefulWidget {
  const SemWorkspace({super.key});

  @override
  State<SemWorkspace> createState() => _SemWorkspaceState();
}

class _SemWorkspaceState extends State<SemWorkspace> {
  // SEM मधील कॉन्फिगरेशन पॅरामिटर्स
  String _currentMode = 'Secondary Electrons (SE)';
  double _contrast = 1.0;
  double _brightness = 0.0;

  // प्रमुख SEM मोड्सची यादी
  final List<Map<String, dynamic>> _semModes = [
    {
      'name': 'Secondary Electrons (SE)',
      'description':
          'Best for topography and high-resolution surface structure mapping.',
      'type': 'SE',
    },
    {
      'name': 'Backscattered Electrons (BSE)',
      'description':
          'Highlights differences in composition and atomic number (Z-contrast).',
      'type': 'BSE',
    },
    {
      'name': 'Transmission SEM (STEM)',
      'description':
          'Detects transmitted electrons through thin samples to show internal structure.',
      'type': 'STEM',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final activeMode = _semModes.firstWhere((m) => m['name'] == _currentMode);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SEM Mode Simulator'),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // रिअल-टाइम SEM इमेज जनरेटर पॅनेल
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.teal.withOpacity(0.5)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: FutureBuilder<ui.Image>(
                    future: _generateSemImage(
                      activeMode['type'],
                      _contrast,
                      _brightness,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasData) {
                        return CustomPaint(
                          painter: SemTexturePainter(snapshot.data!),
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

          // मोडचे वर्णन (Description)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              activeMode['description'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

          // कंट्रोल्स आणि मोड्स सिलेक्शन पॅनेल
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                children: [
                  // Contrast Slider
                  Text(
                    'Contrast: ${_contrast.toStringAsFixed(1)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: _contrast,
                    min: 0.5,
                    max: 2.0,
                    activeColor: Colors.teal,
                    onChanged: (val) => setState(() => _contrast = val),
                  ),

                  // Brightness Slider
                  Text(
                    'Brightness: ${_brightness.toStringAsFixed(1)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: _brightness,
                    min: -0.5,
                    max: 0.5,
                    activeColor: Colors.teal,
                    onChanged: (val) => setState(() => _brightness = val),
                  ),
                  const Divider(height: 24),

                  // Mode Selector List
                  const Text(
                    'Select SEM Mode',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: _semModes.map((mode) {
                      final isSelected = _currentMode == mode['name'];
                      return ListTile(
                        title: Text(mode['name']),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Colors.teal)
                            : const Icon(Icons.circle_outlined),
                        selected: isSelected,
                        onTap: () {
                          setState(() {
                            _currentMode = mode['name'];
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // सिम्युलेटेड डिजिटल मायक्रोस्कोपी टेक्सचर जनरेशन (Low-level RGBA buffer)
  Future<ui.Image> _generateSemImage(
    String type,
    double contrast,
    double brightness,
  ) {
    final Completer<ui.Image> completer = Completer();
    const int width = 300;
    const int height = 300;
    final Uint8List pixels = Uint8List(width * height * 4);

    int pixelIndex = 0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        double intensity = 0.5;

        // वेगवेगळ्या मोड्सनुसार सिग्नल पॅटर्न सिम्युलेशन (SE = Edge Edge Enhancement, BSE = Composition) [1]
        if (type == 'SE') {
          // कडांवर जास्त ब्राइटनेस दाखवण्यासाठी (Edge Effect) [1]
          if ((x - 150).abs() > 100 || (y - 150).abs() > 100) {
            intensity = 0.8;
          } else {
            intensity = 0.4;
          }
        } else if (type == 'BSE') {
          // झोननुसार वेगवेगळी ग्रे-स्केल शेड (Z-contrast simulation) [1]
          intensity = (x > 150 && y > 150) ? 0.8 : 0.3;
        } else if (type == 'STEM') {
          // मधोमध हाय-ट्रांसमिशन ब्राइटनेस [2]
          double dist = ui.Offset(
            x.toDouble() - 150,
            y.toDouble() - 150,
          ).distance;
          intensity = (1.0 - (dist / 150)).clamp(0.1, 0.9);
        }

        // Contrast आणि Brightness गणिते लागू करणे
        intensity = ((intensity - 0.5) * contrast) + 0.5 + brightness;
        final int greyValue = (intensity.clamp(0.0, 1.0) * 255).toInt();

        // SEM इमेजेस या प्रामुख्याने ग्रे-स्केल (Monochrome) असतात [1]
        pixels[pixelIndex] = greyValue; // R
        pixels[pixelIndex + 1] = greyValue; // G
        pixels[pixelIndex + 2] = greyValue; // B
        pixels[pixelIndex + 3] = 255; // A (Opacity)

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
}

class SemTexturePainter extends CustomPainter {
  final ui.Image image;
  SemTexturePainter(this.image);

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
  bool shouldRepaint(covariant SemTexturePainter oldDelegate) =>
      oldDelegate.image != image;
}
