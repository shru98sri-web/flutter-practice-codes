import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const NewtonRaphsonApp());
}

class NewtonRaphsonApp extends StatelessWidget {
  const NewtonRaphsonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Newton-Raphson Solver',
      theme: ThemeData(primarySwatch: Colors.blue),
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
  // Input Controllers
  final TextEditingController _guessController = TextEditingController(
    text: '1.0',
  );
  final TextEditingController _toleranceController = TextEditingController(
    text: '0.0001',
  );

  String _result = '';
  List<Map<String, dynamic>> _steps = [];

  // Main Equation: f(x) = x^2 - 2
  double f(double x) => pow(x, 2) - 2.0;

  // Derivative of the equation: f'(x) = 2x
  double df(double x) => 2.0 * x;

  // Newton-Raphson Algorithm Execution
  void _calculateRoot() {
    double? xNew = double.tryParse(_guessController.text);
    double? tolerance = double.tryParse(_toleranceController.text);
    int maxIterations = 50;

    if (xNew == null || tolerance == null) {
      setState(() {
        _result = 'Please enter valid numeric values.';
        _steps = [];
      });
      return;
    }

    List<Map<String, dynamic>> tempSteps = [];
    bool found = false;

    for (int i = 1; i <= maxIterations; i++) {
      double fx = f(xNew!);
      double dfx = df(xNew);

      // Prevent division by zero if derivative is zero
      if (dfx.abs() < 1e-12) {
        setState(() {
          _result = 'Error: Derivative became zero.';
        });
        return;
      }

      // Newton-Raphson Formula: x_next = x_n - f(x_n)/f'(x_n)
      double xNext = xNew - (fx / dfx);

      // Save step data for the UI list
      tempSteps.add({
        'iteration': i,
        'xNew': xNew.toStringAsFixed(6),
        'fx': fx.toStringAsFixed(6),
        'xNext': xNext.toStringAsFixed(6),
      });

      // Check convergence criteria
      if ((xNext - xNew).abs() < tolerance) {
        xNew = xNext;
        found = true;
        break;
      }
      xNew = xNext;
    }

    setState(() {
      _steps = tempSteps;
      if (found) {
        _result = 'Final Root: ${xNew!.toStringAsFixed(6)}';
      } else {
        _result = 'Max iterations reached. Could not find accurate root.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Newton-Raphson Solver'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Inputs
            TextField(
              controller: _guessController,
              decoration: const InputDecoration(
                labelText: 'Initial Guess (x0)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _toleranceController,
              decoration: const InputDecoration(labelText: 'Tolerance'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            // Calculate Button
            ElevatedButton(
              onPressed: _calculateRoot,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(15),
              ),
              child: const Text('Find Root', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 20),
            // Result Display
            Text(
              _result,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Iteration Steps List
            if (_steps.isNotEmpty) ...[
              const Text(
                'Iteration Process Steps:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: _steps.length,
                  itemBuilder: (context, index) {
                    final step = _steps[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('${step['iteration']}'),
                        ),
                        title: Text(
                          'xₙ = ${step['xNew']}  |  xₙ₊₁ = ${step['xNext']}',
                        ),
                        subtitle: Text('f(xₙ) = ${step['fx']}'),
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
