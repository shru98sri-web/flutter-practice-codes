import 'dart:convert';
import 'dart:math';

import 'package:csv/csv.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// universal_html चा वापर केल्याने कोड वेब आणि मोबाईल दोन्हीवर विना-एरर चालतो
import 'package:universal_html/html.dart' as html;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LibsGraphApp());
}

class LibsGraphApp extends StatelessWidget {
  const LibsGraphApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LIBS Universal App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const LibsGraphPage(),
    );
  }
}

class LibsGraphPage extends StatefulWidget {
  const LibsGraphPage({super.key});

  @override
  State<LibsGraphPage> createState() => _LibsGraphPageState();
}

class _LibsGraphPageState extends State<LibsGraphPage> {
  double _maxWavelength = 800.0;
  double _peakIntensityMultiplier = 1.0;
  String _savedStatus = "No file downloaded yet in this session";

  List<FlSpot> _spectralData = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSavedAnchors();
  }

  // लोकल स्टोरेजमधून स्लायडर पोझिशन लोड करणे
  Future<void> _loadSavedAnchors() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _maxWavelength = prefs.getDouble('max_wavelength') ?? 800.0;
      _peakIntensityMultiplier = prefs.getDouble('intensity_multiplier') ?? 1.0;
    });
    _generateLibsData();
  }

  // स्लायडर पोझिशन सेव्ह करणे
  Future<void> _saveSliderData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('max_wavelength', _maxWavelength);
    await prefs.setDouble('intensity_multiplier', _peakIntensityMultiplier);
  }

  // स्लायडरनुसार ग्राफ डेटा तयार करणे
  void _generateLibsData() {
    List<FlSpot> spots = [];
    for (
      double wavelength = 200;
      wavelength <= _maxWavelength;
      wavelength += 2
    ) {
      double baselineNoise = Random().nextDouble() * 5;
      double intensity = baselineNoise;

      if ((wavelength - 324).abs() < 15) {
        intensity +=
            80 * _peakIntensityMultiplier * exp(-pow(wavelength - 324, 2) / 20);
      }
      if ((wavelength - 589).abs() < 15) {
        intensity +=
            150 *
            _peakIntensityMultiplier *
            exp(-pow(wavelength - 589, 2) / 15);
      }

      spots.add(FlSpot(wavelength, intensity));
    }
    setState(() {
      _spectralData = spots;
    });
  }

  // HTML WebElement Anchor (<a>) वापरून CSV डाउनलोड करणे
  void _downloadCsvViaHtmlAnchor() {
    if (_spectralData.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // १. CSV डेटा मॅट्रिक्स तयार करा
      List<List<dynamic>> csvData = [
        <String>["Wavelength (nm)", "Intensity (a.u.)"],
      ];

      for (var spot in _spectralData) {
        csvData.add([spot.x, spot.y]);
      }

      // २. डेटाचे CSV स्ट्रिंग आणि बाइट्समध्ये रुपांतर करा
      String csvString = const ListToCsvConverter().convert(csvData);
      final bytes = utf8.encode(csvString);

      // ३. HTML मधील 'Blob' (Binary Large Object) ऑब्जेक्ट तयार करा
      final blob = html.Blob([bytes], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);

      // ४. व्हर्च्युअल HTML <a> (अँकर एलिमेंट) तयार करा
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = 'libs_data_${DateTime.now().millisecondsSinceEpoch}.csv';

      // ५. अँकरला डॉक्युमेंटमध्ये जोडून त्यावर क्लिक इव्हेंट ट्रिगर करा
      html.document.body?.children.add(anchor);
      anchor.click(); // यामुळे फाईल थेट डाउनलोड होईल

      // ६. कचरा साफ करा (Cleanup)
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);

      setState(() {
        _savedStatus = "File successfully generated and pushed to Downloads!";
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CSV Download Triggered via HTML Anchor!'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _savedStatus = "Error: $e";
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HTML Anchor Exporter'),
        backgroundColor: Colors.deepOrange.withOpacity(0.2),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ग्राफ विभाग
            Expanded(
              flex: 4,
              child: _spectralData.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : LineChart(_buildChartData()),
            ),
            const SizedBox(height: 15),

            // स्लायडर्स पॅनेल
            Card(
              color: Colors.deepOrange.shade50,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Text(
                      'Max Wavelength Anchor: ${_maxWavelength.toStringAsFixed(0)} nm',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                    Slider(
                      value: _maxWavelength,
                      min: 400.0,
                      max: 900.0,
                      divisions: 10,
                      activeColor: Colors.deepOrange,
                      label: _maxWavelength.toStringAsFixed(0),
                      onChanged: (value) {
                        setState(() {
                          _maxWavelength = value;
                          _generateLibsData();
                        });
                        _saveSliderData();
                      },
                    ),

                    Text(
                      'Peak Intensity Anchor: ${_peakIntensityMultiplier.toStringAsFixed(1)}x',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                    Slider(
                      value: _peakIntensityMultiplier,
                      min: 0.5,
                      max: 2.5,
                      divisions: 4,
                      activeColor: Colors.deepOrange,
                      label: '${_peakIntensityMultiplier.toStringAsFixed(1)}x',
                      onChanged: (value) {
                        setState(() {
                          _peakIntensityMultiplier = value;
                          _generateLibsData();
                        });
                        _saveSliderData();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            // नवीन HTML डाउनलोड बटन
            Center(
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _downloadCsvViaHtmlAnchor,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.html),
                label: const Text('Download CSV via Web Anchor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // डाऊनलोड स्टेटस ट्रॅकर
            const Text(
              'Download Status:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _savedStatus,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _buildChartData() {
    return LineChartData(
      gridData: const FlGridData(show: true),
      titlesData: const FlTitlesData(
        show: true,
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      minX: 200,
      maxX: _maxWavelength,
      minY: 0,
      maxY: 400,
      lineBarsData: [
        LineChartBarData(
          spots: _spectralData,
          isCurved: true,
          color: Colors.deepOrange,
          barWidth: 2,
          dotData: const FlDotData(show: false),
        ),
      ],
    );
  }
}
