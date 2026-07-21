import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:math_expressions/math_expressions.dart';

void main() {
  runApp(const LaserGainApp());
}

class LaserGainApp extends StatelessWidget {
  const LaserGainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
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
  // इनपुट पॅरामीटर्स
  double _initialGain = 2.0;
  double _satFluence = 1.0; // J/cm² (उदा. Ti:Sapphire साठी)

  List<FlSpot> _inputPulseSpots = [];
  List<FlSpot> _outputPulseSpots = [];

  @override
  void initState() {
    super.initState();
    _runSimulation(); // ✅ अतिरिक्त कर्ली ब्रॅकेट्स ({}) काढले आहेत
  }

  // Frantz-Nodvik गणिताचा वापर करून सिम्युलेशन रन करणे
  void _runSimulation() {
    List<FlSpot> inputSpots = [];
    List<FlSpot> outputSpots = [];

    // १. math_expressions चा वापर करून गॉशियन (Gaussian) पल्स इनपुट तयार करणे
    Variable x = Variable('x');

    // ✅ त्रुटी सुधारली: 'exp(-x^2)' ऐवजी 'e^(-(x^2))' वापरले आहे जे पॅकेजला अचूक समजते
    Expression gaussian = Parser().parse('e^(-(x^2))');
    ContextModel cm = ContextModel();

    double currentGain = _initialGain;
    int steps = 50;

    for (int i = 0; i <= steps; i++) {
      // वेळ -३ ते +३ फेंटोसेकंडच्या स्केलवर विभागली आहे
      double t = -3.0 + (i / steps) * 6.0;
      cm.bindVariable(x, Number(t));

      // इनपुट पल्सची तीव्रता (Intensity)
      double inputIntensity = gaussian.evaluate(EvaluationType.REAL, cm);
      inputSpots.add(FlSpot(t, inputIntensity));

      // २. Frantz-Nodvik लेझर गेन कॅल्क्युलेशन
      // G(t) = exp(g(t))
      double gainFactor = math.exp(currentGain);

      // Output Intensity = Input * Gain Factor
      double outputIntensity = inputIntensity * gainFactor;
      outputSpots.add(FlSpot(t, outputIntensity));

      // ३. गेन डिप्लेशन (Gain Depletion) अपडेट करणे
      // पुढील पल्ससाठी गेन कमी होतो
      double depletionFactor = math.exp(inputIntensity / _satFluence);
      currentGain = math.log(
        1.0 + (math.exp(currentGain) - 1.0) / depletionFactor,
      );
    }

    setState(() {
      _inputPulseSpots = inputSpots;
      _outputPulseSpots = outputSpots;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Femtosecond Laser Gain Simulator')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ३. flutter_math चा वापर करून मुख्य समीकरण दाखवणे
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Math.tex(
                r'G(t) = \exp\left[g_0 - \int \frac{I_{in}(t)}{U_{sat}} dt\right]',
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),

            // ४. fl_chart चा वापर करून आलेखाचे सादरीकरण
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
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

            // कंट्रोलर्स (Sliders)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('Initial Gain ($_initialGain)'),
                    Slider(
                      value: _initialGain,
                      min: 0.5,
                      max: 5.0,
                      onChanged: (val) {
                        setState(() => _initialGain = val);
                        _runSimulation();
                      },
                    ),
                    Text('Saturation Fluence ($_satFluence)'),
                    Slider(
                      value: _satFluence,
                      min: 0.2,
                      max: 3.0,
                      onChanged: (val) {
                        setState(() => _satFluence = val);
                        _runSimulation();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
