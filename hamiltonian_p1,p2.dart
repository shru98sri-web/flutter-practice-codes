import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:share_plus/share_plus.dart';

/// १. 4D फेज स्पेस स्टेट वेक्टर (Double Pendulum साठी)
class DoublePhaseState {
  final double q1; // पहिल्या लंबकाचा कोन (Angle 1)
  final double q2; // दुसऱ्या लंबकाचा कोन (Angle 2)
  final double p1; // पहिला संवेग (Momentum 1)
  final double p2; // दुसरा संवेग (Momentum 2)

  DoublePhaseState(this.q1, this.q2, this.p1, this.p2);

  DoublePhaseState operator +(DoublePhaseState o) =>
      DoublePhaseState(q1 + o.q1, q2 + o.q2, p1 + o.p1, p2 + o.p2);

  DoublePhaseState operator *(double scalar) =>
      DoublePhaseState(q1 * scalar, q2 * scalar, p1 * scalar, p2 * scalar);
}

/// २. प्रगत हॅमिल्टोनियन सॉल्व्हर (डॅम्पिंग, ड्रायव्हिंग फोर्स आणि न्यूमेरिकल डिफरेंशिएशनसह)
class AdvancedHamiltonianSolver {
  final double m1 = 1.0; // मास १
  final double m2 = 1.0; // मास २
  final double l1 = 1.5; // लांबी १
  final double l2 = 1.2; // लांबी २
  final double g = 9.81; // गुरुत्वाकर्षण स्थिरांक

  // नॉन-हॅमिल्टोनियन पॅरामीटर्स (बाह्य घटक)
  final double damping = 0.05; // डॅम्पिंग (हवेचा रोध)
  final double driveAmp = 0.4; // ड्रायव्हिंग फोर्सची तीव्रता
  final double driveFreq = 1.5; // ड्रायव्हिंग FORCE ची वारंवारता

  /// Double Pendulum चे हॅमिल्टोनियन सूत्र: H = T + V
  double computeHamiltonian(DoublePhaseState state) {
    double dQ = state.q1 - state.q2;

    double den = m1 + m2 * math.pow(math.sin(dQ), 2);
    double kinetic =
        (math.pow(state.p1, 2) * m2 * math.pow(l2, 2) +
            math.pow(state.p2, 2) * (m1 + m2) * math.pow(l1, 2) -
            2 * state.p1 * state.p2 * m2 * l1 * l2 * math.cos(dQ)) /
        (2 * math.pow(l1, 2) * math.pow(l2, 2) * den);

    double potential =
        -(m1 + m2) * g * l1 * math.cos(state.q1) -
        m2 * g * l2 * math.cos(state.q2);

    return kinetic + potential;
  }

  /// हॅमिल्टन समीकरणे + बाह्य डॅम्पिंग आणि ड्रायव्हिंग फोर्स
  DoublePhaseState computeVectorField(DoublePhaseState state, double t) {
    double h = 1e-5; // डिफरेंशिएशन स्टेप साईज

    // Numerical Automatic Differentiation
    double dH_dp1 =
        (computeHamiltonian(
              DoublePhaseState(state.q1, state.q2, state.p1 + h, state.p2),
            ) -
            computeHamiltonian(
              DoublePhaseState(state.q1, state.q2, state.p1 - h, state.p2),
            )) /
        (2.0 * h);

    double dH_dp2 =
        (computeHamiltonian(
              DoublePhaseState(state.q1, state.q2, state.p1, state.p2 + h),
            ) -
            computeHamiltonian(
              DoublePhaseState(state.q1, state.q2, state.p1, state.p2 - h),
            )) /
        (2.0 * h);

    double dH_dq1 =
        (computeHamiltonian(
              DoublePhaseState(state.q1 + h, state.q2, state.p1, state.p2),
            ) -
            computeHamiltonian(
              DoublePhaseState(state.q1 - h, state.q2, state.p1, state.p2),
            )) /
        (2.0 * h);

    double dH_dq2 =
        (computeHamiltonian(
              DoublePhaseState(state.q1, state.q2 + h, state.p1, state.p2),
            ) -
            computeHamiltonian(
              DoublePhaseState(state.q1, state.q2 - h, state.p1, state.p2),
            )) /
        (2.0 * h);

    double externalForce1 =
        -damping * state.p1 + driveAmp * math.cos(driveFreq * t);
    double externalForce2 = -damping * state.p2;

    return DoublePhaseState(
      dH_dp1,
      dH_dp2,
      -dH_dq1 + externalForce1,
      -dH_dq2 + externalForce2,
    );
  }

  /// Runge-Kutta 4th Order (RK4) इंटिग्रेशन
  DoublePhaseState rk4Step(DoublePhaseState state, double dt, double t) {
    DoublePhaseState k1 = computeVectorField(state, t);
    DoublePhaseState k2 = computeVectorField(
      state + k1 * (dt / 2.0),
      t + dt / 2.0,
    );
    DoublePhaseState k3 = computeVectorField(
      state + k2 * (dt / 2.0),
      t + dt / 2.0,
    );
    DoublePhaseState k4 = computeVectorField(state + k3 * dt, t + dt);

    return state + (k1 + k2 * 2.0 + k3 * 2.0 + k4) * (dt / 6.0);
  }
}

/// ३. मुख्य ऍप्लिकेशन एन्ट्री पॉईंट
void main() => runApp(const ChaosSimulationApp());

class ChaosSimulationApp extends StatelessWidget {
  const ChaosSimulationApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(theme: ThemeData.dark(), home: const ChaoticDashboard());
  }
}

/// ४. मुख्य डॅशबोर्ड विजेट (सिम्युलेशन, मल्टि-प्लॉट आणि सेफ एक्सपोर्ट)
class ChaoticDashboard extends StatefulWidget {
  const ChaoticDashboard({Key? key}) : super(key: key);
  @override
  State<ChaoticDashboard> createState() => _ChaoticDashboardState();
}

class _ChaoticDashboardState extends State<ChaoticDashboard>
    with SingleTickerProviderStateMixin {
  late final AdvancedHamiltonianSolver _solver;
  DoublePhaseState _state = DoublePhaseState(
    math.pi / 2,
    math.pi / 2,
    0.0,
    0.0,
  );

  final List<FlSpot> _phaseHistory1 = [];
  final List<FlSpot> _phaseHistory2 = [];
  final List<String> _csvRows = ["Time,q1,q2,p1,p2,Energy"];

  late final Ticker _ticker;
  double _currentTime = 0.0;
  final double _dt = 0.01;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _solver = AdvancedHamiltonianSolver();

    _ticker = createTicker((Duration elapsed) {
      setState(() {
        _state = _solver.rk4Step(_state, _dt, _currentTime);
        _currentTime += _dt;
        double currentEnergy = _solver.computeHamiltonian(_state);

        // लंबक १ डेटा ट्रॅकिंग (q1 vs p1)
        _phaseHistory1.add(FlSpot(_state.q1, _state.p1));
        if (_phaseHistory1.length > 300) _phaseHistory1.removeAt(0);

        // लंबक २ डेटा ट्रॅकिंग (q2 vs p2)
        _phaseHistory2.add(FlSpot(_state.q2, _state.p2));
        if (_phaseHistory2.length > 300) _phaseHistory2.removeAt(0);

        _csvRows.add(
          "$_currentTime,${_state.q1},${_state.q2},${_state.p1},${_state.p2},$currentEnergy",
        );
      });
    });
    _ticker.start();
  }

  /// मेमरी डेटा शेअरिंग सिस्टीम (No Path Exception Error)
  Future<void> _exportToCSV() async {
    setState(() => _isExporting = true);
    try {
      final String csvContent = _csvRows.join("\n");
      final List<int> bytes = const Utf8Encoder().convert(csvContent);

      final XFile csvFile = XFile.fromData(
        Uint8List.fromList(bytes) as Uint8List,
        mimeType: 'text/csv',
        name: 'hamiltonian_chaos_data.csv',
      );

      await Share.shareXFiles([
        csvFile,
      ], text: 'Chaotic Pendulum Simulation Data');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Export Error: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
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
      appBar: AppBar(
        title: const Text('Chaotic Double Pendulum Solver'),
        actions: [
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            tooltip: "Export CSV",
            onPressed: _isExporting ? null : _exportToCSV,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 900;
          return Flex(
            direction: isWide ? Axis.horizontal : Axis.vertical,
            children: [
              Expanded(flex: 5, child: _buildLiveCanvas()),
              Expanded(flex: 5, child: _buildPhasePortrait()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLiveCanvas() {
    return Card(
      margin: const EdgeInsets.all(12),
      color: Colors.black38,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Real-Time Double Pendulum",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            child: CustomPaint(
              painter: DoublePendulumPainter(state: _state, solver: _solver),
              child: Container(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhasePortrait() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(width: 12, height: 12, color: Colors.cyan),
                    const SizedBox(width: 6),
                    const Text(
                      "Pendulum 1 (q1 vs p1)",
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Row(
                  children: [
                    Container(width: 12, height: 12, color: Colors.pinkAccent),
                    const SizedBox(width: 6),
                    const Text(
                      "Pendulum 2 (q2 vs p2)",
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LineChart(
                LineChartData(
                  minX: -3.14,
                  maxX: 3.14,
                  minY: -20.0,
                  maxY: 20.0,
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(
                    border: Border.all(color: Colors.white10),
                  ),
                  titlesData: const FlTitlesData(
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _phaseHistory1,
                      isCurved: false,
                      color: Colors.cyan,
                      barWidth: 1.5,
                      dotData: const FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: _phaseHistory2,
                      isCurved: false,
                      color: Colors.pinkAccent,
                      barWidth: 1.5,
                      dotData: const FlDotData(show: false),
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

/// 5. 2D Graphics Engine (Double Pendulum Custom Painter)
class DoublePendulumPainter extends CustomPainter {
  final DoublePhaseState state;
  final AdvancedHamiltonianSolver solver;
  DoublePendulumPainter({required this.state, required this.solver});
  @override
  void paint(Canvas canvas, Size size) {
    final Offset pivot = Offset(size.width / 2, size.height / 2.5);
    const double scale = 80.0;
    final Paint armPaint = Paint()
      ..color = Colors.blueGrey
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final Paint bob1Paint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.fill;
    final Paint bob2Paint = Paint()
      ..color = Colors.pinkAccent
      ..style = PaintingStyle.fill;
    // पहिल्या लंबकाचे कार्टेशियन कोऑर्डिनेट्स
    double x1 = pivot.dx + solver.l1 * math.sin(state.q1) * scale;
    double y1 = pivot.dy + solver.l1 * math.cos(state.q1) * scale;
    Offset bob1 = Offset(x1, y1); // दुसऱ्या लंबकाचे कार्टेशियन कोऑर्डिनेट्स
    double x2 = x1 + solver.l2 * math.sin(state.q2) * scale;
    double y2 = y1 + solver.l2 * math.cos(state.q2) * scale;
    Offset bob2 = Offset(x2, y2); // ड्रॉइंग
    canvas.drawLine(pivot, bob1, armPaint);
    canvas.drawLine(bob1, bob2, armPaint);
    canvas.drawCircle(pivot, 6.0, Paint()..color = Colors.white);
    canvas.drawCircle(bob1, 14.0, bob1Paint);
    canvas.drawCircle(bob2, 12.0, bob2Paint);
  }

  @override
  bool shouldRepaint(covariant DoublePendulumPainter oldDelegate) => true;
}
