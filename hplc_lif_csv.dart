import 'dart:math';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

void main() {
  runApp(const HplcLifApp());
}

class HplcLifApp extends StatelessWidget {
  const HplcLifApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HPLC-LIF Simulator',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const SimulatorScreen(),
    );
  }
}

// Data point representation for HPLC signal matching
class ChromatogramPoint {
  final double time; // X-axis (minutes)
  final double intensity; // Y-axis (Fluorescence intensity in mV)

  ChromatogramPoint(this.time, this.intensity);
}

// Model representing a single chemical compound (Peak)
class Analyte {
  final String name;
  double baseRetentionTime; // Ideal retention time at 50% Organic Solvent
  double peakWidth; // Column efficiency factor
  double fluorescenceYield; // Response factor for LIF detector

  Analyte({
    required this.name,
    required this.baseRetentionTime,
    required this.peakWidth,
    required this.fluorescenceYield,
  });
}

class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  // Global Simulation Parameters
  double _flowRate = 1.0; // mL/min
  double _initialOrganic = 20.0; // Starting % B (e.g., Acetonitrile)
  double _finalOrganic = 80.0; // Ending % B
  double _gradientDuration = 8.0; // Duration of gradient ramp (min)
  double _noiseLevel = 0.5; // LIF baseline noise scalar

  // Hardcoded compound mixture setup
  final List<Analyte> _mixture = [
    Analyte(
      name: "Compound A (Early)",
      baseRetentionTime: 3.0,
      peakWidth: 0.12,
      fluorescenceYield: 45.0,
    ),
    Analyte(
      name: "Compound B (Mid)",
      baseRetentionTime: 5.5,
      peakWidth: 0.18,
      fluorescenceYield: 85.0,
    ),
    Analyte(
      name: "Compound C (Late)",
      baseRetentionTime: 7.8,
      peakWidth: 0.25,
      fluorescenceYield: 60.0,
    ),
  ];

  List<ChromatogramPoint> _generatedData = [];
  bool _isSimulating = false;

  @override
  void initState() {
    super.initState();
    _runSimulationEngine();
  }

  // Engine mimicking interactive separation column logic
  void _runSimulationEngine() {
    setState(() => _isSimulating = true);

    List<ChromatogramPoint> calculatedPoints = [];
    final random = Random();
    const double totalRunTime = 10.0;
    const double timeStep = 0.01;

    for (double t = 0.0; t <= totalRunTime; t += timeStep) {
      double totalIntensity = 0.0;

      // Determine current Organic composition % at timestamp (t)
      double currentOrganic = _initialOrganic;
      if (t <= _gradientDuration && _gradientDuration > 0) {
        currentOrganic =
            _initialOrganic +
            ((_finalOrganic - _initialOrganic) * (t / _gradientDuration));
      } else {
        currentOrganic = _finalOrganic;
      }

      // Linear velocity correction based on mobile phase configuration
      double velocityFactor = _flowRate * (1.0 + (currentOrganic / 100.0));

      for (var analyte in _mixture) {
        // Adjust retention center mathematically via current elution power
        double dynamicRt = analyte.baseRetentionTime / (velocityFactor * 0.85);

        // Gaussian Distribution Function execution
        double exponent =
            -pow(t - dynamicRt, 2) / (2 * pow(analyte.peakWidth, 2));
        double peakSignal = analyte.fluorescenceYield * exp(exponent);

        totalIntensity += peakSignal;
      }

      // Simulate specific LIF High-Sensitivity baseline noise floor
      double baselineNoise = (random.nextDouble() - 0.5) * _noiseLevel;
      double finalSignal = max(
        0.0,
        totalIntensity + baselineNoise + 2.0,
      ); // Baseline offset

      calculatedPoints.add(ChromatogramPoint(t, finalSignal));
    }

    setState(() {
      _generatedData = calculatedPoints;
      _isSimulating = false;
    });
  }

  // Cross-Platform CSV Downloader
  Future<void> _exportChromatogramToCSV() async {
    if (_generatedData.isEmpty) return;

    List<List<dynamic>> csvMatrix = [
      ["HPLC-LIF Simulator Export Data"],
      ["Flow Rate (mL/min)", _flowRate],
      ["Initial Organic %", _initialOrganic],
      ["Final Organic %", _finalOrganic],
      ["Gradient Time (min)", _gradientDuration],
      [], // Spacer
      ["Retention Time (min)", "Fluorescence Intensity (mV)"],
    ];

    for (var point in _generatedData) {
      csvMatrix.add([
        point.time.toStringAsFixed(2),
        point.intensity.toStringAsFixed(4),
      ]);
    }

    String csvString = const ListToCsvConverter().convert(csvMatrix);

    if (kIsWeb) {
      // Browser Download Protocol
      final blob = html.Blob([csvString], 'text/csv', 'native');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "hplc_lif_chromatogram.csv")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Native File Systems Protocol (Windows, macOS, Linux, iOS, Android)
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Chromatogram Data CSV',
        fileName: 'hplc_lif_chromatogram.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: Uint8List.fromList(csvString.codeUnits),
      );

      if (outputFile != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File saved securely to: $outputFile')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactive HPLC-LIF Data Simulator'),
        backgroundColor: Colors.teal.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runSimulationEngine,
            tooltip: 'Re-run Math Engine',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 900;
          return Flex(
            direction: isWide ? Axis.horizontal : Axis.vertical,
            children: [
              // Controller System Sidebar
              Expanded(
                flex: isWide ? 1 : 0,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    color: const Color(0xFF1E1E1E),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'System Configuration',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.teal),
                          ),
                          const Divider(),
                          _buildSliderSetting(
                            label: 'Flow Rate (mL/min)',
                            value: _flowRate,
                            min: 0.2,
                            max: 3.0,
                            divisions: 28,
                            onChanged: (v) => setState(() => _flowRate = v),
                          ),
                          _buildSliderSetting(
                            label: 'Initial Organic Solvent (%)',
                            value: _initialOrganic,
                            min: 5.0,
                            max: 95.0,
                            divisions: 18,
                            onChanged: (v) =>
                                setState(() => _initialOrganic = v),
                          ),
                          _buildSliderSetting(
                            label: 'Final Organic Solvent (%)',
                            value: _finalOrganic,
                            min: 5.0,
                            max: 95.0,
                            divisions: 18,
                            onChanged: (v) => setState(() => _finalOrganic = v),
                          ),
                          _buildSliderSetting(
                            label: 'Gradient Duration (min)',
                            value: _gradientDuration,
                            min: 1.0,
                            max: 10.0,
                            divisions: 9,
                            onChanged: (v) =>
                                setState(() => _gradientDuration = v),
                          ),
                          _buildSliderSetting(
                            label: 'LIF Detector Noise Floor',
                            value: _noiseLevel,
                            min: 0.0,
                            max: 2.0,
                            divisions: 20,
                            onChanged: (v) => setState(() => _noiseLevel = v),
                          ),
                          const SizedBox(height: 24),
                          // ElevatedButton.icon(
                          //   onPressed: _runSimulationEngine,
                          //   icon: const Icon(Icons.science),
                          //   label: const Text('Calculate Separation'),
                          //   style: ElevatedButton.styleFrom(
                          //     backgroundColor: Colors.teal,
                          //     minimumSize: const Size.fromHeight(45),
                          //   ),
                          // ),
                          // const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _isSimulating
                                ? null
                                : _exportChromatogramToCSV,
                            icon: const Icon(Icons.download),
                            label: const Text('Download CSV Data'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey.shade700,
                              minimumSize: const Size.fromHeight(45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ), // Main Data Visualizer Panel
              Expanded(
                flex: isWide ? 2 : 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    color: const Color(0xFF1E1E1E),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
                      child: _isSimulating
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.teal,
                              ),
                            )
                          : LineChart(
                              LineChartData(
                                minX: 0,
                                maxX: 10,
                                minY: 0,
                                maxY: 100,
                                gridData: const FlGridData(
                                  show: true,
                                  drawVerticalLine: true,
                                ),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    axisNameWidget: const Text(
                                      'Retention Time (minutes)',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 1,
                                      reservedSize: 22,
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    axisNameWidget: const Text(
                                      'Fluorescence Response (mV)',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 20,
                                      reservedSize: 35,
                                    ),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(color: Colors.white24),
                                ),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _generatedData
                                        .map((p) => FlSpot(p.time, p.intensity))
                                        .toList(),
                                    isCurved: true,
                                    barWidth: 2,
                                    color: Colors.tealAccent,
                                    dotData: const FlDotData(show: false),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliderSetting({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
              Text(
                value.toStringAsFixed(1),
                style: const TextStyle(color: Colors.tealAccent),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: Colors.teal,
            inactiveColor: Colors.white12,
            onChanged: (val) {
              onChanged(val);
              _runSimulationEngine(); // Dynamic recalculation loop on slider adjustment
            },
          ),
        ],
      ),
    );
  }
}
