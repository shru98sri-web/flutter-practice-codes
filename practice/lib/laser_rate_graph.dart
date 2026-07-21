import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const UltimateLaserSimulatorApp());
}

class UltimateLaserSimulatorApp extends StatelessWidget {
  const UltimateLaserSimulatorApp({Key? key}) : super(key: key);

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
  // Slider Parameters (Boundaries and Initial Conditions)
  double Wp = 2.0; // Pumping Rate
  double G = 1.5; // Gain Coefficient
  double tauS = 1.0; // Upper State Lifetime
  double tauP = 0.1; // Photon Lifetime
  double beta = 0.05; // Spontaneous Emission Factor

  // Graph Layout and Axis Scaling Flags
  bool isPhaseSpace = false; // Toggle for S vs N Phase Plot
  bool isLogScale = false; // Toggle for Logarithmic Y-Axis

  // State Containers for Automated Steady State Script
  double steadyN = 0.0;
  double steadyS = 0.0;

  List<FlSpot> nSpots = [];
  List<FlSpot> sSpots = [];
  List<FlSpot> phaseSpots = [];

  // Viewport Manipulation Variables (Zoom and Pan)
  double _scaleX = 1.0;
  double _scaleY = 1.0;
  double _offsetX = 0.0;
  double _offsetY = 0.0;

  @override
  void initState() {
    super.initState();
    _runSimulation();
  }

  // Laser First-Order System Derivatives
  double _dNdt(double N, double S) => Wp - (N / tauS) - (G * N * S);
  double _dSdt(double N, double S) =>
      (G * N * S) - (S / tauP) + (beta * N / tauS);

  // 1. AUTOMATED SCRIPT: Analytical Steady-State Matrix Resolution
  void _calculateSteadyState() {
    // Solves the quadratic convergence equation derived from setting dN/dt = 0 and dS/dt = 0
    // Formulation: A*S^2 + B*S + C = 0
    double A = G * tauP;
    double B = 1 + G * tauP * beta - G * Wp * tauS * tauP;
    double C = -Wp * beta;

    double discriminant = B * B - 4 * A * C;
    if (discriminant >= 0) {
      // Isolate the meaningful positive real root for Photon Density (S*)
      steadyS = (-B + math.sqrt(discriminant)) / (2 * A);
      // Back-substitute to resolve Population Inversion steady state (N*)
      steadyN = Wp / ((1 / tauS) + G * steadyS);
    } else {
      steadyS = 0.0;
      steadyN = 0.0;
    }
  }

  // Runge-Kutta 4th Order Numerical Integration Engine
  void _runSimulation() {
    nSpots.clear();
    sSpots.clear();
    phaseSpots.clear();
    _calculateSteadyState();

    double t = 0.0;
    double N = 0.0;
    double S =
        0.001; // Avoid exact zero to protect against Logarithmic singularities
    double dt = 0.01;
    int steps = 300;

    for (int i = 0; i < steps; i++) {
      // 2. LOGARITHMIC VIEWPOINT MAPPING
      double displayN = isLogScale
          ? (N > 0 ? math.log(N) / math.ln10 : -3.0)
          : N;
      double displayS = isLogScale
          ? (S > 0 ? math.log(S) / math.ln10 : -3.0)
          : S;

      nSpots.add(FlSpot(t, displayN));
      sSpots.add(FlSpot(t, displayS));
      phaseSpots.add(
        FlSpot(displayN, displayS),
      ); // 3. PHASE SPACE MAPPER (S vs N)

      // Compute RK4 Derivative Projections
      double kn1 = _dNdt(N, S);
      double ks1 = _dSdt(N, S);

      double kn2 = _dNdt(N + 0.5 * dt * kn1, S + 0.5 * dt * ks1);
      double ks2 = _dSdt(N + 0.5 * dt * kn1, S + 0.5 * dt * ks1);

      double kn3 = _dNdt(N + 0.5 * dt * kn2, S + 0.5 * dt * ks2);
      double ks3 = _dSdt(N + 0.5 * dt * kn2, S + 0.5 * dt * ks2);

      double kn4 = _dNdt(N + dt * kn3, S + dt * ks3);
      double ks4 = _dSdt(N + dt * kn3, S + dt * ks3);

      // Weighted combination step update
      N = N + (dt / 6.0) * (kn1 + 2 * kn2 + 2 * kn3 + kn4);
      S = S + (dt / 6.0) * (ks1 + 2 * ks2 + 2 * ks3 + ks4);
      t = t + dt;

      if (N < 0) N = 0;
      if (S < 0) S = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic Axis Bounds Assignment depending on the active View Mode
    double defaultMaxX = isPhaseSpace ? 5.0 : 3.0;
    double defaultMaxY = isLogScale ? 1.0 : 5.0;
    double defaultMinY = isLogScale ? -3.0 : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ultimate Laser Simulator PRO'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _scaleX = 1.0;
                _scaleY = 1.0;
                _offsetX = 0.0;
                _offsetY = 0.0;
              });
            },
            tooltip: 'Reset Chart Boundaries',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Mode Selectors (Filter Chips)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FilterChip(
                  label: const Text("Phase Space (S vs N)"),
                  selected: isPhaseSpace,
                  onSelected: (val) {
                    setState(() {
                      isPhaseSpace = val;
                      _runSimulation();
                    });
                  },
                ),
                FilterChip(
                  label: const Text("Logarithmic Scale"),
                  selected: isLogScale,
                  disabledColor: Colors.grey,
                  onSelected: isPhaseSpace
                      ? null
                      : (val) {
                          setState(() {
                            isLogScale = val;
                            _runSimulation();
                          });
                        },
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Graphic Visualization Space (with Gestures, Scaling, and Interventions)
            Expanded(
              child: GestureDetector(
                onScaleUpdate: (details) {
                  setState(() {
                    if (details.scale != 1.0) {
                      _scaleX = (_scaleX * details.scale).clamp(1.0, 5.0);
                      _scaleY = (_scaleY * details.scale).clamp(1.0, 5.0);
                    } else {
                      _offsetX -= details.focalPointDelta.dx * 0.005;
                      _offsetY += details.focalPointDelta.dy * 0.01;
                    }
                  });
                },
                child: Card(
                  color: const Color(0xFF0F0F15),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      right: 24.0,
                      left: 12.0,
                      top: 24.0,
                      bottom: 12.0,
                    ),
                    child: LineChart(
                      LineChartData(
                        // Interactivity Tooltip Handler Block
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (touchedSpot) =>
                                Colors.indigo.withOpacity(0.9),
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                if (isPhaseSpace) {
                                  return LineTooltipItem(
                                    'N: ${spot.x.toStringAsFixed(3)}\nS: ${spot.y.toStringAsFixed(3)}',
                                    const TextStyle(
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }
                                final isN = spot.barIndex == 0;
                                String label = isN ? "N" : "S";
                                String valueStr = isLogScale
                                    ? math.pow(10, spot.y).toStringAsFixed(4)
                                    : spot.y.toStringAsFixed(3);
                                return LineTooltipItem(
                                  '$label: $valueStr\nTime: ${spot.x.toStringAsFixed(2)}',
                                  TextStyle(
                                    color: isN
                                        ? Colors.blueAccent
                                        : Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                        gridData: const FlGridData(show: true),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            axisNameWidget: Text(
                              isPhaseSpace
                                  ? "Population Inversion (N)"
                                  : "Time (t)",
                            ),
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) => Text(
                                val.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 9),
                              ),
                            ),
                          ),
                          leftTitles: AxisTitles(
                            axisNameWidget: Text(
                              isPhaseSpace
                                  ? "Photon Density (S)"
                                  : (isLogScale
                                        ? "Log10(Density)"
                                        : "Intensity / Density"),
                            ),
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) => Text(
                                val.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 9),
                              ),
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: Colors.white24),
                        ),
                        minX: 0.0 + _offsetX,
                        maxX: (defaultMaxX / _scaleX) + _offsetX,
                        minY: defaultMinY + _offsetY,
                        maxY: (defaultMaxY / _scaleY) + _offsetY,
                        lineBarsData: isPhaseSpace
                            ? [
                                LineChartBarData(
                                  spots: phaseSpots,
                                  isCurved: true,
                                  color: Colors.greenAccent,
                                  barWidth: 3,
                                  dotData: const FlDotData(show: false),
                                ),
                              ]
                            : [
                                // Time Coordinates Tracks (N and S separately)
                                LineChartBarData(
                                  spots: nSpots,
                                  isCurved: true,
                                  color: Colors.blueAccent,
                                  barWidth: 3,
                                  dotData: const FlDotData(show: false),
                                ),
                                LineChartBarData(
                                  spots: sSpots,
                                  isCurved: true,
                                  color: Colors.redAccent,
                                  barWidth: 3,
                                  dotData: const FlDotData(show: false),
                                ),
                              ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Script Analysis Output Readout
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Calculated Steady State:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amberAccent,
                    ),
                  ),
                  Text(
                    "N* = ${steadyN.toStringAsFixed(3)}   |   S* = ${steadyS.toStringAsFixed(3)}",
                  ),
                ],
              ),
            ),
            //Continuous Variables Input Dashboard (Sliders)
            Expanded(
              flex: 0,
              child: SingleChildScrollView(
                child: Column(
                  children: [
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
                    _buildSlider("Upper Lifetime (tauS)", tauS, 0.1, 2.0, (
                      val,
                    ) {
                      setState(() {
                        tauS = val;
                        _runSimulation();
                      });
                    }),
                    _buildSlider("Photon Lifetime (tauP)", tauP, 0.05, 0.5, (
                      val,
                    ) {
                      setState(() {
                        tauP = val;
                        _runSimulation();
                      });
                    }),
                  ],
                ),
              ),
            ),
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
    ValueChanged onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            "$label: ${value.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Expanded(
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }
}
