import 'dart:async';

import 'package:flutter/material.dart';

void main() {
  runApp(const BiomimeticBrainApp());
}

class BiomimeticBrainApp extends StatelessWidget {
  const BiomimeticBrainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Biomimetic Brain Simulation',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const BrainBiomimicScreen(),
    );
  }
}

/// A mathematical model simulating a single biological neuron using Izhikevich equations.
class BiomimeticNeuron {
  // Izhikevich model parameters
  double a; // Time scale of the recovery variable
  double b; // Sensitivity of the recovery variable to subthreshold fluctuations
  double c; // After-spike reset value of the membrane potential
  double d; // After-spike reset of the recovery variable

  double v; // Membrane potential (current cell voltage)
  double u; // Membrane recovery variable
  bool isSpiking = false;

  BiomimeticNeuron({
    this.a = 0.02,
    this.b = 0.2,
    this.c = -65.0,
    this.d = 6.0,
    this.v = -65.0,
    this.u = -13.0,
  });

  /// Updates the neuron state based on the received external electrical stimulus.
  void update(double currentInput) {
    // Ordinary differential equation approximation for biological membrane potential
    v += 0.04 * v * v + 5 * v + 140 - u + currentInput;
    u += a * (b * v - u);

    // If the voltage reaches the threshold threshold (30mV), the neuron fires an action potential (spike)
    if (v >= 30.0) {
      isSpiking = true;
      v = c; // Reset voltage
      u += d; // Reset recovery variable
    } else {
      isSpiking = false;
    }
  }
}

class BrainBiomimicScreen extends StatefulWidget {
  const BrainBiomimicScreen({Key? key}) : super(key: key);

  @override
  State<BrainBiomimicScreen> createState() => _BrainBiomimicScreenState();
}

class _BrainBiomimicScreenState extends State<BrainBiomimicScreen> {
  late BiomimeticNeuron _neuron;
  late Timer _timer;
  double _inputStimulus =
      10.0; // Simulated constant input current to the brain cell

  @override
  void initState() {
    super.initState();
    _neuron = BiomimeticNeuron();

    // High-frequency periodic timer (every 20ms) to compute real-time biological states
    _timer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      setState(() {
        _neuron.update(_inputStimulus);
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0E15),
      appBar: AppBar(
        title: const Text("Biomimetic Brain Simulation"),
        centerTitle: true,
        backgroundColor: const Color(0xFF161722),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Biomimetic Node Representation (Expands and glows dynamically when firing/spiking)
              AnimatedContainer(
                duration: const Duration(milliseconds: 40),
                width: _neuron.isSpiking ? 160 : 120,
                height: _neuron.isSpiking ? 160 : 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _neuron.isSpiking
                      ? Colors.cyanAccent
                      : Colors.blueGrey.shade800,
                  boxShadow: _neuron.isSpiking
                      ? [
                          BoxShadow(
                            color: Colors.cyan.withAlpha(180),
                            blurRadius: 40,
                            spreadRadius: 15,
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  Icons.psychology,
                  size: _neuron.isSpiking ? 70 : 55,
                  color: _neuron.isSpiking ? Colors.black : Colors.white70,
                ),
              ),
              const SizedBox(height: 50),

              // Biological Metrics Display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF161722),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      "Membrane Potential: ${_neuron.v.toStringAsFixed(2)} mV",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily:
                            'Courier', // Monospace for static number sizing
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _neuron.isSpiking
                          ? "ACTION POTENTIAL (FIRING)"
                          : "IDLE / CHARGING",
                      style: TextStyle(
                        color: _neuron.isSpiking
                            ? Colors.cyanAccent
                            : Colors.grey,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),

              // Interactive Input Stimulus Controller
              const Text(
                "Input Stimulus Current (I)",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Slider(
                value: _inputStimulus,
                min: 0.0,
                max: 30.0,
                activeColor: Colors.cyanAccent,
                inactiveColor: Colors.grey.shade800,
                onChanged: (value) {
                  setState(() {
                    _inputStimulus = value;
                  });
                },
              ),
              Text(
                "Value: ${_inputStimulus.toStringAsFixed(1)} mA",
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
