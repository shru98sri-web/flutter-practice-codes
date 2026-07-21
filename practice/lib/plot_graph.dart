import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

// void main() {
//   runApp(const OriginCsvApp());
// }

class OriginCsvApp extends StatelessWidget {
  const OriginCsvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: CsvVisualizerHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CsvVisualizerHome extends StatefulWidget {
  const CsvVisualizerHome({super.key});

  @override
  State<CsvVisualizerHome> createState() => _CsvVisualizerHomeState();
}

class _CsvVisualizerHomeState extends State<CsvVisualizerHome> {
  List<FileDataPoint> csvDataPoints = [];
  bool isLoading = false;
  String fileName = "No file selected";

  // Select CSV file and parse data
  Future<void> _pickAndParseCsv() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Open file picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        String csvString = "";
        setState(() {
          fileName = result.files.single.name;
        });

        // Condition to ensure cross-compatibility on both Web and Mobile platforms
        if (kIsWeb) {
          final bytes = result.files.single.bytes;
          if (bytes != null) {
            csvString = utf8.decode(bytes);
          }
        } else {
          final path = result.files.single.path;
          if (path != null) {
            final file = File(path);
            csvString = await file.readAsString();
          }
        }

        // Parse CSV data (skipping the first row assuming it contains headers)
        List<List<dynamic>> rows = const CsvToListConverter().convert(
          csvString,
        );
        List<FileDataPoint> points = [];

        for (int i = 1; i < rows.length; i++) {
          // Guard clause to ensure the row has at least 2 columns
          if (rows[i].length >= 2) {
            var rawX = rows[i][0];
            var rawY = rows[i][1];

            // Safely convert dynamics to doubles
            double x = rawX is num
                ? rawX.toDouble()
                : (double.tryParse(rawX.toString()) ?? 0.0);
            double y = rawY is num
                ? rawY.toDouble()
                : (double.tryParse(rawY.toString()) ?? 0.0);

            points.add(FileDataPoint(x, y));
          }
        }

        setState(() {
          csvDataPoints = points;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading file: $e')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Origin CSV Plot Importer'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // File Selector UI block
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickAndParseCsv,
                      icon: const Icon(Icons.file_open),
                      label: const Text('Choose CSV File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        fileName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Display Graph or Loading state
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.teal),
                    )
                  : csvDataPoints.isEmpty
                  ? const Center(
                      child: Text(
                        'Please upload a 2-column (.csv) file to generate a scientific plot.',
                      ),
                    )
                  : SfCartesianChart(
                      primaryXAxis: const NumericAxis(
                        title: AxisTitle(text: 'X Data'),
                      ),
                      primaryYAxis: const NumericAxis(
                        title: AxisTitle(text: 'Y Data'),
                      ),
                      title: ChartTitle(text: 'Scientific Plot for $fileName'),
                      tooltipBehavior: TooltipBehavior(enable: true),
                      series: <CartesianSeries<FileDataPoint, double>>[
                        ScatterSeries<FileDataPoint, double>(
                          dataSource: csvDataPoints,
                          xValueMapper: (FileDataPoint data, _) => data.x,
                          yValueMapper: (FileDataPoint data, _) => data.y,
                          name: 'Experimental Data',
                          markerSettings: const MarkerSettings(
                            isVisible: true,
                            height: 6,
                            width: 6,
                          ),
                        ),
                        LineSeries<FileDataPoint, double>(
                          dataSource: csvDataPoints,
                          xValueMapper: (FileDataPoint data, _) => data.x,
                          yValueMapper: (FileDataPoint data, _) => data.y,
                          name: 'Trend Line',
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class FileDataPoint {
  final double x;
  final double y;
  FileDataPoint(this.x, this.y);
}
