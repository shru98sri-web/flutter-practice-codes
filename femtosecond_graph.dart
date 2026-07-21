import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;

void main() {
  runApp(const LaserGainApp());
}

class LaserGainApp extends StatelessWidget {
  const LaserGainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueGrey,
        scaffoldBackgroundColor: const Color(0xff121212),
      ),
      home: const LaserGainSimulator(),
    );
  }
}

class LaserGainSimulator extends StatefulWidget {
  const LaserGainSimulator({super.key});

  @override
  State<LaserGainSimulator> createState() => _LaserGainSimulatorState();
}

class _LaserGainSimulatorState extends State<LaserGainSimulator> {
  double _initialGain = 2.0;
  double _satFluence = 1.0;
  double _inputFWHM = 0.0;
  double _outputFWHM = 0.0;
  String _errorMessage = '';
  bool _isTypingValid = true;
  Timer? _debounceTimer;

  final TextEditingController _formulaController = TextEditingController(
    text: 'E^(-(x^2))',
  );

  List<FlSpot> _inputPulseSpots = [];
  List<FlSpot> _outputPulseSpots = [];

  @override
  void initState() {
    super.initState();
    _runSimulation();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _formulaController.dispose();
    super.dispose();
  }

  double _calculateFWHM(List<FlSpot> spots) {
    if (spots.isEmpty) return 0.0;
    double maxIntensity = spots.map((s) => s.y).reduce(math.max);
    if (maxIntensity <= 0.001) return 0.0;
    double halfMax = maxIntensity / 2.0;
    double? t1;
    double? t2;

    for (int i = 0; i < spots.length - 1; i++) {
      var current = spots[i];
      var next = spots[i + 1];
      if ((current.y <= halfMax && next.y >= halfMax) ||
          (current.y >= halfMax && next.y <= halfMax)) {
        double tInterp =
            current.x +
            (halfMax - current.y) * (next.x - current.x) / (next.y - current.y);
        if (t1 == null) {
          t1 = tInterp;
        } else {
          t2 = tInterp;
          break;
        }
      }
    }
    if (t1 != null && t2 != null) return (t2 - t1).abs();
    return 0.0;
  }

  void _runSimulation() {
    List<FlSpot> inputSpots = [];
    List<FlSpot> outputSpots = [];
    String formulaText = _formulaController.text.trim();

    if (formulaText.isEmpty) return;

    try {
      Variable x = Variable('x');
      ContextModel cm = ContextModel();
      cm.bindVariable(Variable('E'), Number(math.e));

      Expression expression = Parser().parse(formulaText);

      int steps = 100;
      double tMin = -4.0;
      double tMax = 4.0;
      double dt = (tMax - tMin) / steps;

      List<double> times = [];
      List<double> inputIntensities = [];

      for (int i = 0; i <= steps; i++) {
        double t = tMin + (i / steps) * (tMax - tMin);
        cm.bindVariable(x, Number(t));
        double inputIntensity = expression.evaluate(EvaluationType.REAL, cm);

        if (inputIntensity.isNaN ||
            inputIntensity.isInfinite ||
            inputIntensity < 0) {
          inputIntensity = 0.0;
        }
        times.add(t);
        inputIntensities.add(inputIntensity);
        inputSpots.add(FlSpot(t, inputIntensity));
      }

      double integratedFluence = 0.0;
      double storedGain0 = _initialGain;

      for (int i = 0; i <= steps; i++) {
        double iIn = inputIntensities[i];
        double currentGain =
            storedGain0 * math.exp(-integratedFluence / _satFluence);
        double outputIntensity = iIn * math.exp(currentGain);
        outputSpots.add(FlSpot(times[i], outputIntensity));

        if (i < steps) {
          double nextIn = inputIntensities[i + 1];
          integratedFluence += 0.5 * (iIn + nextIn) * dt;
        }
      }

      setState(() {
        _inputPulseSpots = inputSpots;
        _outputPulseSpots = outputSpots;
        _errorMessage = '';
        _isTypingValid = true;
        _inputFWHM = _calculateFWHM(inputSpots);
        _outputFWHM = _calculateFWHM(outputSpots);
      });
    } catch (e) {
      setState(() {
        _isTypingValid = false;
        _errorMessage = "Format Error! Use capital 'E^' (e.g., E^(-(x^2)))";
      });
    }
  }

  void _onFormulaChanged(String text) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _runSimulation();
    });
  }

  // UPGRADED: Real physical file download engine
  Future<void> _exportToCSV() async {
    if (_inputPulseSpots.isEmpty || _outputPulseSpots.isEmpty) return;

    // 1. Compile CSV Payload Data Data Data Stream Buffer
    final StringBuffer csvBuilder = StringBuffer();
    csvBuilder.writeln(
      'Time (fs),Input Intensity (a.u.),Output Intensity (a.u.)',
    );
    for (int i = 0; i < _inputPulseSpots.length; i++) {
      csvBuilder.writeln(
        '${_inputPulseSpots[i].x.toStringAsFixed(4)},'
        '${_inputPulseSpots[i].y.toStringAsFixed(4)},'
        '${_outputPulseSpots[i].y.toStringAsFixed(4)}',
      );
    }

    final String csvContent = csvBuilder.toString();

    try {
      if (kIsWeb) {
        // --- WEB ENGINE (Saves via Document Blob Layer) ---
        final bytes = utf8.encode(csvContent);
        final blob = html.Blob([bytes], 'text/csv');
        final url = html.Url.createObjectUrlFromBlob(blob);

        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", "laser_pulse_simulation_data.csv")
          ..style.display = 'none';

        html.document.body?.children.add(anchor);
        anchor.click();

        html.document.body?.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
      } else {
        // --- MOBILE / DESKTOP NATIVE OS FILE STORAGE ENGINE ---
        final directory = await getApplicationDocumentsDirectory();
        final String path = '${directory.path}/laser_pulse_simulation_data.csv';
        final File file = File(path);

        await file.writeAsString(csvContent, encoding: utf8);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              kIsWeb
                  ? 'CSV file successfully downloaded to your browser!'
                  : 'CSV file successfully saved to application documents folder!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export engine anomaly: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double maxAxisY = _outputPulseSpots.isNotEmpty
        ? _outputPulseSpots.map((s) => s.y).reduce(math.max) * 1.15
        : 5.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laser Gain Simulator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportToCSV,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xff1e1e1e),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Math.tex(
                  r'I_{out}(t) = I_{in}(t) \cdot \exp\left[g_0 \cdot e^{-\int_{\infty}^t \frac{I_{in}(\tau)}{U_{sat}}d\tau}\right]',
                  textStyle: const TextStyle(fontSize: 15, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _formulaController,
                onChanged: _onFormulaChanged,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Input Pulse Profile Equation',
                  border: const OutlineInputBorder(),
                  errorText: _isTypingValid ? null : _errorMessage,
                  suffixIcon: Icon(
                    _isTypingValid ? Icons.check_circle : Icons.warning,
                    color: _isTypingValid ? Colors.green : Colors.redAccent,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Gaussian'),
                    onPressed: () {
                      _formulaController.text = 'E^(-(x^2))';
                      _runSimulation();
                    },
                  ),
                  ActionChip(
                    label: const Text('Sech² Pulse'),
                    onPressed: () {
                      _formulaController.text = '4 / ((E^x + E^(-x))^2)';
                      _runSimulation();
                    },
                  ),
                  ActionChip(
                    label: const Text('Lorentzian'),
                    onPressed: () {
                      _formulaController.text = '1 / (1 + x^2)';
                      _runSimulation();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Text(
                'Initial Medium Gain (g0): ${_initialGain.toStringAsFixed(2)}',
              ),
              Slider(
                value: _initialGain,
                min: 0.1,
                max: 5.0,
                divisions: 49,
                onChanged: (val) {
                  setState(() => _initialGain = val);
                  _runSimulation();
                },
              ),
              Text(
                'Saturation Fluence (Usat): ${_satFluence.toStringAsFixed(2)}',
              ),
              Slider(
                value: _satFluence,
                min: 0.2,
                max: 4.0,
                divisions: 38,
                onChanged: (val) {
                  setState(() => _satFluence = val);
                  _runSimulation();
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: Colors.blue.withAlpha(40),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          'Input FWHM:\n${_inputFWHM.toStringAsFixed(3)} fs',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      color: Colors.red.withAlpha(40),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          'Output FWHM:\n${_outputFWHM.toStringAsFixed(3)} fs',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20), // Upgraded Download Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _exportToCSV,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(
                    Icons.file_download,
                    color: Colors.greenAccent,
                  ),
                  label: const Text(
                    'DOWNLOAD SIMULATION DATA (CSV)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                height: 280,
                child: LineChart(
                  LineChartData(
                    minX: -4,
                    maxX: 4,
                    minY: 0,
                    maxY: maxAxisY < 1 ? 1 : maxAxisY,
                    gridData: const FlGridData(
                      show: true,
                      drawVerticalLine: false,
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.white24),
                    ),
                    titlesData: const FlTitlesData(
                      topTitles: AxisTitles(),
                      rightTitles: AxisTitles(),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _inputPulseSpots,
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                      ),
                      LineChartBarData(
                        spots: _outputPulseSpots,
                        isCurved: true,
                        color: Colors.red,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
