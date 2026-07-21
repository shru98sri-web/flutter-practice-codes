import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const NumericalMethodsApp());
}

class NumericalMethodsApp extends StatelessWidget {
  const NumericalMethodsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Numerical Methods Solver',
      theme: ThemeData(primarySwatch: Colors.deepPurple, useMaterial3: true),
      home: const SolverScreen(),
    );
  }
}

class SolverScreen extends StatefulWidget {
  const SolverScreen({super.key});

  @override
  State<SolverScreen> createState() => _SolverScreenState();
}

class _SolverScreenState extends State<SolverScreen> {
  // Method Dropdown Selection
  String _selectedMethod = 'Newton-Raphson';
  final List<String> _methods = [
    'Bisection',
    'Secant',
    'Newton-Raphson',
    'Runge-Kutta (RK4)',
  ];

  // Input Controllers
  final TextEditingController _guessController = TextEditingController(
    text: '1.0',
  );
  final TextEditingController _toleranceController = TextEditingController(
    text: '0.0001',
  );

  String _result = '';
  List<Map<String, dynamic>> _steps = [];

  // Standard Function for Root Finding: f(x) = x^2 - 2
  double f(double x) => pow(x, 2) - 2.0;

  // Derivative Function for Newton-Raphson: f'(x) = 2x
  double df(double x) => 2.0 * x;

  // ODE Function for Runge-Kutta (RK4): dy/dx = x + y
  double dydx(double x, double y) => x + y;

  void _runSolver() {
    double? x0 = double.tryParse(_guessController.text);
    double? tolerance = double.tryParse(_toleranceController.text);
    int maxIterations = 50;

    if (x0 == null || tolerance == null) {
      setState(() {
        _result = 'Please enter valid numeric values.';
        _steps = [];
      });
      return;
    }

    List<Map<String, dynamic>> tempSteps = [];
    _result = '';

    switch (_selectedMethod) {
      case 'Bisection':
        // Generate an interval [a, b] around the initial guess
        double a = x0 - 1.0;
        double b = x0 + 1.0;

        // Ensure root-bracketing condition
        if (f(a) * f(b) >= 0) {
          a = 0.0; // Fallback typical interval for x^2 - 2 = 0
          b = 2.0;
        }

        double c = a;
        bool foundBisection = false;

        for (int i = 1; i <= maxIterations; i++) {
          c = (a + b) / 2;
          double fc = f(c);

          tempSteps.add({
            'title': 'Iteration $i',
            'detail':
                'Interval: [${a.toStringAsFixed(4)}, ${b.toStringAsFixed(4)}]',
            'sub':
                'Midpoint (c) = ${c.toStringAsFixed(6)} | f(c) = ${fc.toStringAsFixed(6)}',
          });

          if (fc.abs() < tolerance || ((b - a) / 2).abs() < tolerance) {
            foundBisection = true;
            break;
          }

          if (f(a) * fc < 0) {
            b = c;
          } else {
            a = c;
          }
        }
        _result = foundBisection
            ? 'Root Found: ${c.toStringAsFixed(6)}'
            : 'Max iterations reached.';
        break;

      case 'Secant':
        // Generate two initial points near x0
        double xPrev = x0 - 0.5;
        double xCurr = x0;
        bool foundSecant = false;

        for (int i = 1; i <= maxIterations; i++) {
          double fPrev = f(xPrev);
          double fCurr = f(xCurr);

          if ((fCurr - fPrev).abs() < 1e-12) {
            _result = 'Error: Division by zero in Secant calculation.';
            return;
          }

          double xNext = xCurr - (fCurr * (xCurr - xPrev)) / (fCurr - fPrev);

          tempSteps.add({
            'title': 'Iteration $i',
            'detail':
                'xₙ₋₁ = ${xPrev.toStringAsFixed(4)} | xₙ = ${xCurr.toStringAsFixed(4)}',
            'sub': 'Next x = ${xNext.toStringAsFixed(6)}',
          });

          if ((xNext - xCurr).abs() < tolerance) {
            xCurr = xNext;
            foundSecant = true;
            break;
          }
          xPrev = xCurr;
          xCurr = xNext;
        }
        _result = foundSecant
            ? 'Root Found: ${xCurr.toStringAsFixed(6)}'
            : 'Max iterations reached.';
        break;

      case 'Newton-Raphson':
        double xNew = x0;
        bool foundNewton = false;

        for (int i = 1; i <= maxIterations; i++) {
          double fx = f(xNew);
          double dfx = df(xNew);

          if (dfx.abs() < 1e-12) {
            _result = 'Error: Derivative became zero.';
            return;
          }

          double xNext = xNew - (fx / dfx);

          tempSteps.add({
            'title': 'Iteration $i',
            'detail':
                'xₙ = ${xNew.toStringAsFixed(6)} | f(xₙ) = ${fx.toStringAsFixed(4)}',
            'sub': 'xₙ₊₁ = ${xNext.toStringAsFixed(6)}',
          });

          if ((xNext - xNew).abs() < tolerance) {
            xNew = xNext;
            foundNewton = true;
            break;
          }
          xNew = xNext;
        }
        _result = foundNewton
            ? 'Root Found: ${xNew.toStringAsFixed(6)}'
            : 'Max iterations reached.';
        break;

      case 'Runge-Kutta (RK4)':
        // Solving dy/dx = x + y, with y(x0) = 1.0 over fixed step size
        double x = x0;
        double y = 1.0;
        double h = 0.1; // Step size
        int rkSteps = 5;

        _result = 'ODE Approximate Profile Evaluated.';
        tempSteps.add({
          'title': 'Initial Condition',
          'detail':
              'x₀ = ${x.toStringAsFixed(2)} | y₀ = ${y.toStringAsFixed(4)}',
          'sub': 'Solving dy/dx = x + y',
        });

        for (int i = 1; i <= rkSteps; i++) {
          double k1 = h * dydx(x, y);
          double k2 = h * dydx(x + h / 2, y + k1 / 2);
          double k3 = h * dydx(x + h / 2, y + k2 / 2);
          double k4 = h * dydx(x + h, y + k3);

          y = y + (k1 + 2 * k2 + 2 * k3 + k4) / 6;
          x = x + h;

          tempSteps.add({
            'title': 'Step $i (h = $h)',
            'detail':
                'x = ${x.toStringAsFixed(2)} | y = ${y.toStringAsFixed(6)}',
            'sub':
                'k₁=${k1.toStringAsFixed(3)}, k₂=${k2.toStringAsFixed(3)}, k₃=${k3.toStringAsFixed(3)}, k₄=${k4.toStringAsFixed(3)}',
          });
        }
        break;
    }

    setState(() {
      _steps = tempSteps;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Numerical Methods Toolbox'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dropdown Picker
            DropdownButtonFormField<String>(
              value: _selectedMethod,
              decoration: const InputDecoration(
                labelText: 'Select Computational Method',
                border: OutlineInputBorder(),
              ),
              items: _methods.map((String method) {
                return DropdownMenuItem<String>(
                  value: method,
                  child: Text(method),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedMethod = newValue!;
                  _result = '';
                  _steps = [];
                });
              },
            ),
            const SizedBox(height: 15),

            // Inputs
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _guessController,
                    decoration: const InputDecoration(
                      labelText: 'Initial Guess (x0)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _toleranceController,
                    decoration: const InputDecoration(
                      labelText: 'Tolerance / Step',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Compute Trigger Button
            ElevatedButton.icon(
              onPressed: _runSolver,
              icon: const Icon(Icons.calculate),
              label: const Text('Compute Math Execution'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.deepPurple[50],
              ),
            ),
            const SizedBox(height: 20),

            // Numerical Answer Output Header
            if (_result.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Text(
                  _result,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 15),

            // Dynamic Data Logging List
            if (_steps.isNotEmpty) ...[
              const Text(
                'Algorithm Trace Logs:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 5),
              Expanded(
                child: ListView.builder(
                  itemCount: _steps.length,
                  itemBuilder: (context, index) {
                    final step = _steps[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        dense: true,
                        title: Text(
                          step['title'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(step['detail']),
                            Text(
                              step['sub'],
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
