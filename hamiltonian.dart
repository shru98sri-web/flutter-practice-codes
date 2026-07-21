import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// 1. PHYSICS CORE & MATHEMATICAL UTILITIES
/// Encapsulates the canonical state vectors in phase space
class PhaseState {
  final double q; // Generalized coordinate (e.g., Angle theta)
  final double p; // Generalized momentum
  PhaseState(this.q, this.p);

  PhaseState operator +(PhaseState o) => PhaseState(q + o.q, p + o.p);
  PhaseState operator *(double scalar) => PhaseState(q * scalar, p * scalar);
}

/// A non-linear pendulum solver using numerical Automatic Differentiation
class HamiltonianSolver {
  final double m; // Mass
  final double l; // Length
  final double g = 9.81; // Gravity constant

  HamiltonianSolver({required this.m, required this.l});

  /// Scalar Hamiltonian Function: H(q, p) = T(p) + V(q)
  /// Kinetic Energy: T = p^2 / (2 * m * l^2)
  /// Potential Energy: V = m * g * l * (1 - cos(q))
  double computeHamiltonian(PhaseState state) {
    double kinetic = math.pow(state.p, 2) / (2.0 * m * math.pow(l, 2));
    double potential = m * g * l * (1.0 - math.cos(state.q));
    return kinetic + potential;
  }

  /// Calculates Hamilton's equations using central difference numerical differentiation
  /// dq/dt =  dH/dp
  /// dp/dt = -dH/dq
  PhaseState computeVectorField(PhaseState state) {
    double h = 1e-5; // Finite difference step sizing

    // Partial derivative with respect to p: dH/dp
    double dH_dp =
        (computeHamiltonian(PhaseState(state.q, state.p + h)) -
            computeHamiltonian(PhaseState(state.q, state.p - h))) /
        (2.0 * h);

    // Partial derivative with respect to q: dH/dq
    double dH_dq =
        (computeHamiltonian(PhaseState(state.q + h, state.p)) -
            computeHamiltonian(PhaseState(state.q - h, state.p))) /
        (2.0 * h);

    return PhaseState(dH_dp, -dH_dq);
  }

  /// Explicit Runge-Kutta 4th Order (RK4) integration scheme
  PhaseState rk4Step(PhaseState state, double dt) {
    PhaseState k1 = computeVectorField(state);
    PhaseState k2 = computeVectorField(state + k1 * (dt / 2.0));
    PhaseState k3 = computeVectorField(state + k2 * (dt / 2.0));
    PhaseState k4 = computeVectorField(state + k3 * dt);

    return state + (k1 + k2 * 2.0 + k3 * 2.0 + k4) * (dt / 6.0);
  }
}

/// 2. MAIN APPLICATION APPLICATION ENTRY
void main() => runApp(const HamiltonianApp());

class HamiltonianApp extends StatelessWidget {
  const HamiltonianApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: const HamiltonianSimulatorDashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// 3. DASHBOARD WIDGET WITH PHYSICS TICKER LOOP
class HamiltonianSimulatorDashboard extends StatefulWidget {
  const HamiltonianSimulatorDashboard({Key? key}) : super(key: key);
  @override
  State<HamiltonianSimulatorDashboard> createState() =>
      _HamiltonianSimulatorDashboardState();
}

class _HamiltonianSimulatorDashboardState
    extends State<HamiltonianSimulatorDashboard>
    with SingleTickerProviderStateMixin {
  late final HamiltonianSolver _solver;
  PhaseState _state = PhaseState(
    math.pi / 3,
    0.0,
  ); // Initial condition: 60 degrees, 0 momentum
  final List<FlSpot> _trajectoryHistory = [];

  late final Ticker _physicsTicker;
  double _time = 0.0;
  final double _dt = 0.016; // Stable targeted step sizing (~60fps physics)

  @override
  void initState() {
    super.initState();
    _solver = HamiltonianSolver(m: 1.5, l: 2.0);

    // Ticker profile drives smooth state refreshes synchronized with display refresh rates
    _physicsTicker = createTicker((Duration elapsed) {
      setState(() {
        _state = _solver.rk4Step(_state, _dt);
        _time += _dt;

        _trajectoryHistory.add(FlSpot(_state.q, _state.p));
        if (_trajectoryHistory.length > 300) {
          _trajectoryHistory.removeAt(
            0,
          ); // Restrict data footprint memory bounds
        }
      });
    });
    _physicsTicker.start();
  }

  @override
  void dispose() {
    _physicsTicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hamiltonian Mechanical Solver Engine')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return Row(
              children: [
                Expanded(flex: 4, child: _buildAnimationView()),
                Expanded(flex: 5, child: _buildTelemetryGraph()),
              ],
            );
          } else {
            return Column(
              children: [
                Expanded(flex: 5, child: _buildAnimationView()),
                Expanded(flex: 5, child: _buildTelemetryGraph()),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildAnimationView() {
    return Card(
      margin: const EdgeInsets.all(12),
      color: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Text(
              "System State Canvas",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Expanded(
              child: CustomPaint(
                painter: MechanicalSystemPainter(
                  state: _state,
                  length: _solver.l,
                ),
                child: Container(),
              ),
            ),
            Text(
              "Coordinate (q): ${_state.q.toStringAsFixed(3)} rad  |  Momentum (p): ${_state.p.toStringAsFixed(3)} kg·m²/s",
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryGraph() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Phase Space Phase Portrait (q vs p)",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LineChart(
                LineChartData(
                  minX: -4.0,
                  maxX: 4.0,
                  minY: -15.0,
                  maxY: 15.0,
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: true,
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.white24),
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
                      spots: _trajectoryHistory,
                      isCurved: true,
                      color: Colors.cyanAccent,
                      barWidth: 2,
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

/// 4. REAL-TIME CANVAS PAINTER GRAPHICS ENGINE
class MechanicalSystemPainter extends CustomPainter {
  final PhaseState state;
  final double length;

  MechanicalSystemPainter({required this.state, required this.length});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 3);

    // Dynamic coordinate mapping scale metric calculations
    final double meterToPixels =
        math.min(size.width, size.height) / (length * 2.5);

    final Paint rodPaint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final Paint bobPaint = Paint()
      ..color = Colors.amberAccent
      ..style = PaintingStyle.fill;

    final Paint pivotPaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;

    // Convert generalized coordinate configuration space (q) to Cartesian (x, y) 2D vector coordinates
    double x = center.dx + (length * math.sin(state.q) * meterToPixels);
    double y = center.dy + (length * math.cos(state.q) * meterToPixels);
    Offset bobPosition = Offset(x, y);

    // Draw mechanical string arm configurations
    canvas.drawLine(center, bobPosition, rodPaint);
    // Draw structural support anchor pivot nodes
    canvas.drawCircle(center, 8.0, pivotPaint);
    // Draw kinetic load elements mass bobs
    canvas.drawCircle(bobPosition, 18.0, bobPaint);
  }

  @override
  bool shouldRepaint(covariant MechanicalSystemPainter oldDelegate) {
    return oldDelegate.state.q != state.q || oldDelegate.state.p != state.p;
  }
}
