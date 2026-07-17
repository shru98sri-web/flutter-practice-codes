import 'package:flutter/material.dart';

void main() {
  runApp(const LaserSimulatorApp());
}

class LaserSimulatorApp extends StatelessWidget {
  const LaserSimulatorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const LaserSimulatorScreen(),
    );
  }
}

class LaserSimulatorScreen extends StatefulWidget {
  const LaserSimulatorScreen({Key? key}) : super(key: key);

  @override
  _LaserSimulatorScreenState createState() => _LaserSimulatorScreenState();
}

class _LaserSimulatorScreenState extends State<LaserSimulatorScreen> {
  // Slider Parameters (Initial Values)
  double Wp = 2.0; // Pumping Rate
  double G = 1.5; // Gain Coefficient
  double tauS = 1.0; // Upper State Lifetime
  double tauP = 0.1; // Photon Lifetime
  double beta = 0.05; // Beta Factor

  List<double> tData = [];
  List<double> NData = [];
  List<double> SData = [];

  @override
  void initState() {
    super.initState();
    _runSimulation();
  }

  // Numerical Solver using Euler's Method
  void _runSimulation() {
    tData.clear();
    NData.clear();
    SData.clear();

    double t = 0.0;
    double N = 0.0; // Initial Population Inversion
    double S = 0.01; // Initial Photon Density
    double dt = 0.01; // Time Step
    int steps = 200; // Total Iterations

    for (int i = 0; i < steps; i++) {
      tData.add(t);
      NData.add(N);
      SData.add(S);

      // Rate Equations (Differential Equations)
      double dN = Wp - (N / tauS) - (G * N * S);
      double dS = (G * N * S) - (S / tauP) + (beta * N / tauS);

      // Compute next step values
      N = N + dN * dt;
      S = S + dS * dt;
      t = t + dt;

      // Safety guard against negative values due to step-size issues
      if (N < 0) N = 0;
      if (S < 0) S = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laser Rate Equations Simulator')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Graph Display Area
            Expanded(
              child: Card(
                color: Colors.black26,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CustomPaint(
                    painter: SimulationPainter(NData: NData, SData: SData),
                    child: Container(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegend("Population Inversion (N)", Colors.blue),
                _buildLegend("Photon Density (S)", Colors.red),
              ],
            ),
            const Divider(height: 30),

            // Interactive UI Sliders
            _buildSlider("Pump Rate (Wp)", Wp, 0.1, 5.0, (val) {
              setState(() {
                Wp = val;
                _runSimulation();
              });
            }),
            _buildSlider("Gain (G)", G, 0.1, 4.0, (val) {
              setState(() {
                G = val;
                _runSimulation();
              });
            }),
            _buildSlider("Upper Lifetime (tauS)", tauS, 0.1, 2.0, (val) {
              setState(() {
                tauS = val;
                _runSimulation();
              });
            }),
            _buildSlider("Photon Lifetime (tauP)", tauP, 0.05, 0.5, (val) {
              setState(() {
                tauP = val;
                _runSimulation();
              });
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 160,
          child: Text("$label: ${value.toStringAsFixed(2)}"),
        ),
        Expanded(
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildLegend(String text, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 5),
        Text(text),
      ],
    );
  }
}

// Custom Painter Class to Plot the Simulation Graph
class SimulationPainter extends CustomPainter {
  final List<double> NData;
  final List<double> SData;

  SimulationPainter({required this.NData, required this.SData});

  @override
  void paint(Canvas canvas, Size size) {
    if (NData.isEmpty || SData.isEmpty) return;

    final paintN = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final paintS = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final pathN = Path();
    final pathS = Path();

    double maxVal = 5.0; // Scale ceiling for the graph
    double dx = size.width / (NData.length - 1);

    pathN.moveTo(0, size.height - (NData[0] / maxVal) * size.height);
    pathS.moveTo(0, size.height - (SData[0] / maxVal) * size.height);

    for (int i = 1; i < NData.length; i++) {
      double x = i * dx;

      // Flutter coordinates start from top-left, so we subtract from height
      double yN = size.height - (NData[i] / maxVal) * size.height;
      double yS = size.height - (SData[i] / maxVal) * size.height;

      // Clamp values to keep paths inside the visual card bounds
      yN = yN.clamp(0.0, size.height);
      yS = yS.clamp(0.0, size.height);

      pathN.lineTo(x, yN);
      pathS.lineTo(x, yS);
    }

    canvas.drawPath(pathN, paintN);
    canvas.drawPath(pathS, paintS);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
