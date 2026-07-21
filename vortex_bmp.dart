import 'dart:html'
    as html; // Standard web DOM library for input and anchor tags
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

void main() => runApp(const VortexAiryWebApp());

class VortexAiryWebApp extends StatelessWidget {
  const VortexAiryWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const VortexAiryWorkspace(),
    );
  }
}

class VortexAiryWorkspace extends StatefulWidget {
  const VortexAiryWorkspace({super.key});

  @override
  State<VortexAiryWorkspace> createState() => _VortexAiryWorkspaceState();
}

class _VortexAiryWorkspaceState extends State<VortexAiryWorkspace> {
  // Configurable Parameters for Beam Profile Creation
  double cubicScale = 4.0; // Airy acceleration factor (alpha)
  double topologicalCharge = 3.0; // Vortex orbital twist factor (l)
  String uploadStatusText = "No external file loaded";

  /// TRIGGER 1: HTML Input element workflow to upload files into memory
  void _uploadFileViaWebAnchor() {
    final html.InputElement uploadInput = html.InputElement(type: 'file')
      ..accept = '.bmp,.png,.jpg,.bin';

    uploadInput.onChange.listen((event) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final html.File file = files.first;
        final html.FileReader reader = html.FileReader();

        reader.onLoadEnd.listen((loadEvent) {
          final Object? fileData = reader.result;
          if (fileData is List<int>) {
            setState(() {
              // fileData contains the raw bytes from the uploaded file
              uploadStatusText =
                  "Successfully loaded: ${file.name} (${fileData.length} bytes)";
            });
          }
        });
        reader.readAsArrayBuffer(file);
      }
    });
    uploadInput.click(); // Open system dialog
  }

  /// TRIGGER 2: HTML Anchor element workflow to download the generated 8-bit SLM file
  void _downloadSlmBmpViaWebAnchor() {
    const int resolution = 512; // Native SLM Grid Target Dimensions

    // Generate the raw 8-bit grayscale uncompressed array sequence
    final Uint8List bmpBytes = SlmBmpEngine.build8BitGrayscaleBmp(
      width: resolution,
      height: resolution,
      cubicScale: cubicScale,
      charge: topologicalCharge,
    );

    // Turn byte payload into a browser accessible binary blob data stream
    final blob = html.Blob([bmpBytes], 'image/bmp');
    final String dataUrl = html.Url.createObjectUrlFromBlob(blob);

    // Anchor creation loop mapping download parameters natively to your browser tab
    final html.AnchorElement anchor = html.AnchorElement(href: dataUrl)
      ..setAttribute(
        "download",
        "slm_mask_alpha${cubicScale.toStringAsFixed(1)}_l${topologicalCharge.round()}.bmp",
      )
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click(); // Fire native save dialogue window

    // Memory Clean Up Lifecycle
    anchor.remove();
    html.Url.revokeObjectUrl(dataUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Vortex Airy Beam Web Station'),
        backgroundColor: Colors.grey.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file, color: Colors.blueAccent),
            tooltip: 'Upload File (HTML Input)',
            onPressed: _uploadFileViaWebAnchor,
          ),
          IconButton(
            icon: const Icon(
              Icons.download_for_offline,
              color: Colors.greenAccent,
            ),
            tooltip: 'Download SLM Mask (HTML Anchor)',
            onPressed: _downloadSlmBmpViaWebAnchor,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // Informative web action bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.blueGrey.withOpacity(0.15),
            child: Text(
              uploadStatusText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            ),
          ),

          // Simulation Render Core Area
          Expanded(
            child: Center(
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.red.withOpacity(0.2),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: CustomPaint(
                  painter: VortexAiryPainter(
                    cubicScale: cubicScale,
                    charge: topologicalCharge,
                  ),
                ),
              ),
            ),
          ),

          // Slider Matrix Control Panel
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            color: Colors.grey.shade900,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 150,
                        child: Text('Airy Acceleration (α):'),
                      ),
                      Expanded(
                        child: Slider(
                          value: cubicScale,
                          min: 0.0,
                          max: 10.0,
                          divisions: 20,
                          activeColor: Colors.red,
                          onChanged: (val) => setState(() => cubicScale = val),
                        ),
                      ),
                      Text(cubicScale.toStringAsFixed(1)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const SizedBox(
                        width: 150,
                        child: Text('Vortex Charge (l):'),
                      ),
                      Expanded(
                        child: Slider(
                          value: topologicalCharge,
                          min: 0.0,
                          max: 8.0,
                          divisions: 8,
                          activeColor: Colors.orangeAccent,
                          onChanged: (val) =>
                              setState(() => topologicalCharge = val),
                        ),
                      ),
                      Text(topologicalCharge.round().toString()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simulation Renderer Painter
class VortexAiryPainter extends CustomPainter {
  final double cubicScale;
  final double charge;

  VortexAiryPainter({required this.cubicScale, required this.charge});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) / 2;
    final paint = Paint()..style = PaintingStyle.fill;
    const double step = 2.0;

    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        double dx = (x - center.dx) / maxRadius;
        double dy = (y - center.dy) / maxRadius;
        double r = sqrt(dx * dx + dy * dy);

        if (r > 1.1) continue;

        double theta = atan2(dy, dx);
        double airyField =
            cos(cubicScale * pi * (dx * dx * dx)) +
            cos(cubicScale * pi * (dy * dy * dy));
        double vortexField = sin(charge * theta);
        double intensity = (airyField * vortexField).abs();

        double coreBoundary = 0.06 * charge;
        if (r < coreBoundary && charge > 0) {
          intensity *= (r / coreBoundary);
        }

        double beamDecay = exp(-1.5 * (dx * dx + dy * dy));
        paint.color = Colors.red.withOpacity(
          (intensity * beamDecay).clamp(0.0, 1.0),
        );
        canvas.drawRect(Rect.fromLTWH(x, y, step, step), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant VortexAiryPainter oldDelegate) =>
      oldDelegate.cubicScale != cubicScale || oldDelegate.charge != charge;
}

/// Binary engine converting live mathematical parameters to uncompressed 8-bit BMP arrays
class SlmBmpEngine {
  static Uint8List build8BitGrayscaleBmp({
    required int width,
    required int height,
    required double cubicScale,
    required double charge,
  }) {
    int rowSize = ((width + 3) ~/ 4) * 4;
    int pixelDataSize = rowSize * height;
    const int headerOffset = 54 + (256 * 4); // 54 byte headers + 1024 byte LUT
    int totalSize = headerOffset + pixelDataSize;

    final bytes = Uint8List(totalSize);
    final bd = ByteData.view(bytes.buffer);

    // Standard 14 Byte BMP Meta Header Block
    bytes[0] = 0x42;
    bytes[1] = 0x4D; // "BM"
    bd.setUint32(2, totalSize, Endian.little);
    bd.setUint32(10, headerOffset, Endian.little);

    // Standard 40 Byte DIB Header Information
    bd.setUint32(14, 40, Endian.little);
    bd.setInt32(18, width, Endian.little);
    bd.setInt32(22, height, Endian.little);
    bd.setUint16(26, 1, Endian.little);
    bd.setUint16(28, 8, Endian.little); // Target pixel bit depth configuration
    bd.setUint32(34, pixelDataSize, Endian.little);
    bd.setUint32(46, 256, Endian.little);

    // Generate 1024-byte Grayscale color palette LUT mappings
    for (int i = 0; i < 256; i++) {
      int baseIdx = 54 + (i * 4);
      bytes[baseIdx] = i; // Blue component channel
      bytes[baseIdx + 1] = i; // Green component channel
      bytes[baseIdx + 2] = i; // Red component channel
    }

    // Populate data body rows
    double centerX = width / 2;
    double centerY = height / 2;
    double maxRadius = min(width, height) / 2;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        double dx = (x - centerX) / maxRadius;
        double dy = (y - centerY) / maxRadius;
        double r = sqrt(dx * dx + dy * dy);
        double wrappedPhase = 0.0;
        if (r <= 1.1) {
          double theta = atan2(dy, dx);
          double rawPhase =
              (cubicScale * pi * (dx * dx * dx)) +
              (cubicScale * pi * (dy * dy * dy)) +
              (charge * theta);
          wrappedPhase = rawPhase % (2 * pi);
          if (wrappedPhase < 0) wrappedPhase += (2 * pi);
        }
        int indexVal = ((wrappedPhase / (2 * pi)) * 255).round().clamp(0, 255);
        bytes[headerOffset + (y * rowSize) + x] = indexVal;
      }
    }
    return bytes;
  }
}
