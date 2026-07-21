import 'dart:convert';
import 'dart:html' as html;
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';

void main() {
  // FACTORY 1: Register the Upload CSV Anchor element
  ui_web.platformViewRegistry.registerViewFactory('csv-upload-anchor', (
    int viewId,
  ) {
    final html.AnchorElement anchor = html.AnchorElement(href: '#')
      ..id = 'native-csv-uploader'
      ..text = '📁 Upload CSV Config'
      ..style.display = 'flex'
      ..style.alignItems = 'center'
      ..style.justifyContent = 'center'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.color = '#00E676'
      ..style.fontFamily = 'monospace'
      ..style.fontWeight = 'bold'
      ..style.textDecoration = 'none'
      ..style.fontSize = '13px'
      ..style.cursor = 'pointer';

    final html.InputElement hiddenInput = html.InputElement(type: 'file')
      ..accept = '.csv'
      ..style.display = 'none';

    anchor.onClick.listen((e) {
      e.preventDefault();
      hiddenInput.click();
    });

    hiddenInput.onChange.listen((e) {
      final files = hiddenInput.files;
      if (files != null && files.isNotEmpty) {
        final html.File file = files.first;
        final html.FileReader reader = html.FileReader();

        reader.onLoadEnd.listen((loadEvent) {
          final Object? fileContent = reader.result;
          if (fileContent is String) {
            final customEvent = html.CustomEvent(
              'csvDataDispatched',
              detail: {'name': file.name, 'content': fileContent},
            );
            html.window.dispatchEvent(customEvent);
          }
        });
        reader.readAsText(file);
      }
    });

    anchor.append(hiddenInput);
    return anchor;
  });

  // FACTORY 2: Register the Combined Download Archive ZIP Anchor element
  ui_web.platformViewRegistry.registerViewFactory('zip-download-anchor', (
    int viewId,
  ) {
    final html.AnchorElement anchor = html.AnchorElement(href: '#')
      ..id = 'native-zip-downloader'
      ..text = '📦 Download BMP + CSV Bundle (.zip)'
      ..style.display = 'flex'
      ..style.alignItems = 'center'
      ..style.justifyContent = 'center'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.color =
          '#FFD700' // Gold Accent for premium bundle action
      ..style.fontFamily = 'monospace'
      ..style.fontWeight = 'bold'
      ..style.textDecoration = 'none'
      ..style.fontSize = '13px'
      ..style.cursor = 'pointer';

    anchor.onClick.listen((e) {
      e.preventDefault();
      final customEvent = html.CustomEvent('zipDownloadRequested');
      html.window.dispatchEvent(customEvent);
    });

    return anchor;
  });

  runApp(const VortexAiryCsvApp());
}

class VortexAiryCsvApp extends StatelessWidget {
  const VortexAiryCsvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const CsvWorkspaceScreen(),
    );
  }
}

class CsvWorkspaceScreen extends StatefulWidget {
  const CsvWorkspaceScreen({super.key});

  @override
  State<CsvWorkspaceScreen> createState() => _CsvWorkspaceScreenState();
}

class _CsvWorkspaceScreenState extends State<CsvWorkspaceScreen> {
  double cubicScale = 4.0;
  double topologicalCharge = 3.0;
  String workflowStatusText =
      "Modify configurations via sliders or sync layout using anchors below.";

  @override
  void initState() {
    super.initState();

    // Listen for file imports
    html.window.on['csvDataDispatched'].listen((html.Event event) {
      if (event is html.CustomEvent && event.detail != null) {
        final Map data = event.detail as Map;
        _parseAndApplyCsv(data['content'] ?? '', data['name'] ?? 'Unknown');
      }
    });

    // Listen for bundle zip exports
    html.window.on['zipDownloadRequested'].listen((html.Event event) {
      _generateAndDownloadZipBundle();
    });
  }

  /// Packages both the generated 8-bit BMP phase mask and configuration CSV into a unified ZIP archive
  void _generateAndDownloadZipBundle() {
    try {
      final Archive archive = Archive();
      final String baseFileName =
          "vortex_airy_alpha${cubicScale.toStringAsFixed(1)}_l${topologicalCharge.round()}";

      // 1. Generate & append the parameters CSV file text stream payload
      final String csvString =
          "alpha,${cubicScale.toStringAsFixed(2)}\ncharge,${topologicalCharge.round()}\n";
      final List<int> csvBytes = utf8.encode(csvString);

      archive.addFile(
        ArchiveFile(
          '$baseFileName.csv',
          csvBytes.length,
          Uint8List.fromList(csvBytes),
        ),
      );

      // 2. Generate & append the raw uncompressed 8-bit grayscale SLM BMP image
      final Uint8List bmpBytes = SlmBmpEngine.build8BitGrayscaleBmp(
        width: 512,
        height: 512,
        cubicScale: cubicScale,
        charge: topologicalCharge,
      );

      archive.addFile(
        ArchiveFile('$baseFileName.bmp', bmpBytes.length, bmpBytes),
      );

      // 3. Compress encoder file packing sequence execution
      final dynamic encodedData = ZipEncoder().encode(archive);
      if (encodedData == null)
        throw Exception("Failed to encode ZIP payload matrix.");

      // Explicitly enforce cast to Uint8List array structure to fulfill type bounds
      final Uint8List zipBytes = encodedData is Uint8List
          ? encodedData
          : Uint8List.fromList(encodedData as List<int>);

      // 4. Stream data to local disk volume via binary object blob URL mappings
      // Notice the updated reference array: [zipBytes]
      final blob = html.Blob([zipBytes], 'application/zip');
      final String url = html.Url.createObjectUrlFromBlob(blob);

      final html.AnchorElement hiddenZipAnchor = html.AnchorElement(href: url)
        ..setAttribute("download", "$baseFileName.zip")
        ..style.display = 'none';

      html.document.body?.children.add(hiddenZipAnchor);
      hiddenZipAnchor.click();

      hiddenZipAnchor.remove();
      html.Url.revokeObjectUrl(url);

      setState(() {
        workflowStatusText =
            "Successfully compiled! Downloaded bundle package archive: $baseFileName.zip";
      });
    } catch (e) {
      setState(() {
        workflowStatusText = "Archiving transmission error: ${e.toString()}";
      });
    }
  }

  void _parseAndApplyCsv(String rawText, String fileName) {
    try {
      final List<String> lines = const LineSplitter().convert(rawText);
      if (lines.isEmpty)
        throw Exception(
          "The uploaded CSV file contains no matrix definitions.",
        );

      double? importedAlpha;
      double? importedL;

      for (String line in lines) {
        if (line.trim().isEmpty) continue;
        List<String> columns = line.split(',');

        for (int i = 0; i < columns.length - 1; i++) {
          String key = columns[i].trim().toLowerCase();
          String value = columns[i + 1].trim();

          if (key.contains('alpha') || key.contains('scale')) {
            importedAlpha = double.tryParse(value);
          }
          if (key.contains('charge') || key == 'l') {
            importedL = double.tryParse(value);
          }
        }
      }

      setState(() {
        if (importedAlpha != null) cubicScale = importedAlpha!.clamp(0.0, 10.0);
        if (importedL != null) topologicalCharge = importedL!.clamp(0.0, 8.0);
        workflowStatusText =
            "Processed: $fileName | Extracted -> α: ${cubicScale.toStringAsFixed(1)}, l: ${topologicalCharge.round()}";
      });
    } catch (e) {
      setState(() {
        workflowStatusText =
            "Error handling CSV profile data streams: ${e.toString()}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Structured Light Unified Workspace'),
        backgroundColor: Colors.grey.shade900,
      ),
      body: Column(
        children: [
          // Live status window tracker
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            color: Colors.blueGrey.withOpacity(0.12),
            child: Text(
              workflowStatusText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.amberAccent,
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            ),
          ),

          // Beam simulation rendering space
          Expanded(
            child: Center(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
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

          // Interactive Web Element Anchors Dock Panel
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                // Anchor 1: Upload Layout Block
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.greenAccent.withOpacity(0.4),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade900,
                    ),
                    child: const HtmlElementView(viewType: 'csv-upload-anchor'),
                  ),
                ),
                const SizedBox(width: 16),
                // Anchor 2: Dynamic Bundle Zip Download Block
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.amber.withOpacity(0.4),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade900,
                    ),
                    child: const HtmlElementView(
                      viewType: 'zip-download-anchor',
                    ),
                  ),
                ),
              ],
            ),
          ), // Fallback fine-tuning slider controls
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 24.0,
            ),
            color: Colors.grey.shade900,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 140,
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const SizedBox(
                        width: 140,
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
        double intensity =
            ((cos(cubicScale * pi * (dx * dx * dx)) +
                        cos(cubicScale * pi * (dy * dy * dy))) *
                    sin(charge * theta))
                .abs();
        double coreBoundary = 0.06 * charge;
        if (r < coreBoundary && charge > 0) intensity *= (r / coreBoundary);
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

class SlmBmpEngine {
  static Uint8List build8BitGrayscaleBmp({
    required int width,
    required int height,
    required double cubicScale,
    required double charge,
  }) {
    int rowSize = ((width + 3) ~/ 4) * 4;
    int pixelDataSize = rowSize * height;
    const int headerOffset = 54 + (256 * 4);
    int totalSize = headerOffset + pixelDataSize;
    final bytes = Uint8List(totalSize);
    final bd = ByteData.view(bytes.buffer);
    bytes[0] = 0x42;
    bytes[1] = 0x4D;
    bd.setUint32(2, totalSize, Endian.little);
    bd.setUint32(10, headerOffset, Endian.little);
    bd.setUint32(14, 40, Endian.little);
    bd.setInt32(18, width, Endian.little);
    bd.setInt32(22, height, Endian.little);
    bd.setUint16(26, 1, Endian.little);
    bd.setUint16(28, 8, Endian.little);
    bd.setUint32(34, pixelDataSize, Endian.little);
    bd.setUint32(46, 256, Endian.little);
    for (int i = 0; i < 256; i++) {
      int baseIdx = 54 + (i * 4);
      bytes[baseIdx] = i;
      bytes[baseIdx + 1] = i;
      bytes[baseIdx + 2] = i;
    }
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
