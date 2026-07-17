import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// void main() {
//   runApp(const IsingApp());
// }

class IsingApp extends StatelessWidget {
  const IsingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: const IsingSimulationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class IsingSimulationScreen extends StatefulWidget {
  const IsingSimulationScreen({super.key});

  @override
  State<IsingSimulationScreen> createState() => _IsingSimulationScreenState();
}

class _IsingSimulationScreenState extends State<IsingSimulationScreen>
    with SingleTickerProviderStateMixin {
  static const int size = 40; // अचूक रिझोल्यूशनसाठी 40x40 ग्रीड
  late List<List<int>> grid;
  late Ticker _ticker;

  double temperature = 2.27; // क्रिटिकल तापमान (Tc) डीफॉल्ट ठेवले आहे
  final Random _random = Random();

  // मॅक्रोस्कोपिक ऑब्झर्व्हर्स (Statistical Metrics)
  double magnetization = 0.0;
  double energyPerSpin = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeGrid();
    _ticker = createTicker((_) {
      _metropolisStep();
      _calculateMetrics();
    });
    _ticker.start();
  }

  void _initializeGrid() {
    grid = List.generate(
      size,
      (_) => List.generate(size, (_) => _random.nextBool() ? 1 : -1),
    );
  }

  // मेट्रोपोलिस अल्गोरिदम (Metropolis Algorithm)
  void _metropolisStep() {
    for (int n = 0; n < size * size; n++) {
      int i = _random.nextInt(size);
      int j = _random.nextInt(size);
      int currentSpin = grid[i][j];

      int up = grid[(i - 1 + size) % size][j];
      int down = grid[(i + 1) % size][j];
      int left = grid[i][(j - 1 + size) % size];
      int right = grid[i][(j + 1) % size];

      int neighborsSum = up + down + left + right;
      double deltaE = 2.0 * currentSpin * neighborsSum;

      if (deltaE < 0 || _random.nextDouble() < exp(-deltaE / temperature)) {
        grid[i][j] = -currentSpin;
      }
    }
  }

  // मॅग्नेटायझेशन आणि एकूण ऊर्जेची गणना
  void _calculateMetrics() {
    int totalSpin = 0;
    int totalEnergy = 0;

    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        totalSpin += grid[i][j];

        int down = grid[(i + 1) % size][j];
        int right = grid[i][(j + 1) % size];
        totalEnergy += -grid[i][j] * (down + right);
      }
    }

    setState(() {
      magnetization = totalSpin / (size * size);
      energyPerSpin = totalEnergy / (size * size);
    });
  }

  // जेस्चर कंट्रोल: बोट फिरवून स्पिन उलट करणे (Interactive Flipping)
  void _handlePan(Offset localPosition, Size widgetSize) {
    double cellWidth = widgetSize.width / size;
    double cellHeight = widgetSize.height / size;

    int j = (localPosition.dx / cellWidth).floor();
    int i = (localPosition.dy / cellHeight).floor();

    if (i >= 0 && i < size && j >= 0 && j < size) {
      setState(() {
        grid[i][j] = 1; // बोट फिरवलेल्या जागी स्पिन 'Up' (+1) होईल
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Advanced Ising Model 2D')),
      body: Column(
        children: [
          // मॅक्रोस्कोपिक डेटा डॅशबोर्ड
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _metricTile(
                  'Magnetization (M)',
                  magnetization.toStringAsFixed(3),
                ),
                _metricTile(
                  'Energy/Spin (E)',
                  energyPerSpin.toStringAsFixed(3),
                ),
              ],
            ),
          ),

          // सिम्युलेशन ग्रीड + जेस्चर कंट्रोलर
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final widgetSize = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    return GestureDetector(
                      onPanUpdate: (details) =>
                          _handlePan(details.localPosition, widgetSize),
                      onPanDown: (details) =>
                          _handlePan(details.localPosition, widgetSize),
                      child: CustomPaint(
                        size: widgetSize,
                        painter: LatticePainter(grid: grid, size: size),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // फेज ट्रान्झिशन माहिती आणि तापमान कंट्रोलर
          Card(
            margin: const EdgeInsets.all(16.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Text(
                    'Temperature (T): ${temperature.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    temperature < 2.20
                        ? 'Ferromagnetic Phase (Ordered)'
                        : (temperature > 2.35
                              ? 'Paramagnetic Phase (Disordered)'
                              : 'Critical Point (Tc ≈ 2.27)'),
                    style: TextStyle(
                      color: temperature < 2.20
                          ? Colors.blue
                          : (temperature > 2.35 ? Colors.red : Colors.green),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Slider(
                    value: temperature,
                    min: 1.0,
                    max: 4.0,
                    divisions: 60,
                    onChanged: (value) {
                      setState(() {
                        temperature = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricTile(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class LatticePainter extends CustomPainter {
  final List<List<int>> grid;
  final int size;

  LatticePainter({required this.grid, required this.size});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint();
    final double cellWidth = canvasSize.width / size;
    final double cellHeight = canvasSize.height / size;

    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        // +1 साठी निळा (Up) आणि -1 साठी लाल (Down) रंग
        paint.color = grid[i][j] == 1 ? Colors.blueAccent : Colors.redAccent;
        canvas.drawRect(
          Rect.fromLTWH(
            j * cellWidth,
            i * cellHeight,
            cellWidth + 0.5,
            cellHeight + 0.5,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant LatticePainter oldDelegate) {
    return true; // रिअल-टाइम अपडेटसाठी नेहमी रिपेंट करा
  }
}
