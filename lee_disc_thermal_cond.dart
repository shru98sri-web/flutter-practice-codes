import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  runApp(const LeesDiscApp());
}

class LeesDiscApp extends StatelessWidget {
  const LeesDiscApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Lee's Disc Method",
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const LeesDiscScreen(),
    );
  }
}

class LeesDiscScreen extends StatefulWidget {
  const LeesDiscScreen({super.key});

  @override
  State<LeesDiscScreen> createState() => _LeesDiscScreenState();
}

class _LeesDiscScreenState extends State<LeesDiscScreen> {
  // Standard Initial Experimental Values
  double mass = 0.850; // 850 grams = 0.850 kg
  double specHeat = 385.0; // Specific heat capacity of Copper (J/kg·K)
  double thickness = 0.003; // Thickness of sample (3 mm = 0.003 m)
  double radius = 0.055; // Radius of the disc (5.5 cm = 0.055 m)
  double tempSteam = 373.15; // Temperature of steam chamber T1 (100°C)
  double tempDisc = 343.15; // Steady temperature of disc T2 (70°C)

  // Data for Regression Slope (Cooling Time and Temperature)
  // X = Time in seconds, Y = Temperature in Kelvin or Celsius
  final List<double> timeData = [0.0, 30.0, 60.0, 90.0, 120.0, 150.0];

  // Modifiable final temperature value (Controlled by Slider)
  double lastTempReading = 340.15;

  // Calculate cooling rate (dT/dt) using Linear Regression
  double calculateCoolingRate() {
    List<double> yData = [
      343.15,
      342.45,
      341.85,
      341.25,
      340.65,
      lastTempReading,
    ];

    int n = timeData.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;

    for (int i = 0; i < n; i++) {
      sumX += timeData[i];
      sumY += yData[i];
      sumXY += timeData[i] * yData[i];
      sumXX += timeData[i] * timeData[i];
    }

    // Slope formula: m = (n*ΣXY - ΣX*ΣY) / (n*ΣXX - (ΣX)²)
    double slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);

    // Returns cooling rate as a positive value (rate of heat loss)
    return slope.abs();
  }

  // Calculate final Thermal Conductivity (k)
  double calculateThermalConductivity(double coolingRate) {
    double area = math.pi * math.pow(radius, 2);
    double heatFlow = mass * specHeat * coolingRate;

    if ((tempSteam - tempDisc) <= 0) return 0.0;

    return (heatFlow * thickness) / (area * (tempSteam - tempDisc));
  }

  @override
  Widget build(BuildContext context) {
    double coolingRate = calculateCoolingRate();
    double kValue = calculateThermalConductivity(coolingRate);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lee's Disc Calculator"),
        centerTitle: true,
        backgroundColor: Colors.teal.shade100,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Result Card
            Card(
              color: Colors.teal.shade50,
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      "Thermal Conductivity (k)",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${kValue.toStringAsFixed(4)} W/(m·K)",
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade900,
                          ),
                    ),
                    const Divider(),
                    Text(
                      "Cooling Rate (dT/dt): ${coolingRate.toStringAsFixed(5)} K/s",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Experimental Parameters and Sliders
            _buildSliderSection(
              title: "Disc Mass: ${mass.toStringAsFixed(3)} kg",
              min: 0.1,
              max: 2.0,
              value: mass,
              onChanged: (val) => setState(() => mass = val),
            ),
            _buildSliderSection(
              title: "Specific Heat: ${specHeat.toStringAsFixed(0)} J/kg·K",
              min: 100,
              max: 1000,
              value: specHeat,
              onChanged: (val) => setState(() => specHeat = val),
            ),
            _buildSliderSection(
              title:
                  "Sample Thickness: ${(thickness * 1000).toStringAsFixed(1)} mm",
              min: 0.001,
              max: 0.010,
              value: thickness,
              onChanged: (val) => setState(() => thickness = val),
            ),
            _buildSliderSection(
              title: "Radius: ${(radius * 100).toStringAsFixed(1)} cm",
              min: 0.02,
              max: 0.10,
              value: radius,
              onChanged: (val) => setState(() => radius = val),
            ),
            _buildSliderSection(
              title:
                  "Steam Temp (T1): ${(tempSteam - 273.15).toStringAsFixed(1)} °C",
              min: 353.15,
              max: 393.15,
              value: tempSteam,
              onChanged: (val) => setState(() => tempSteam = val),
            ),
            _buildSliderSection(
              title:
                  "Disc Steady Temp (T2): ${(tempDisc - 273.15).toStringAsFixed(1)} °C",
              min: 313.15,
              max: 363.15,
              value: tempDisc,
              onChanged: (val) => setState(() => tempDisc = val),
            ),
            _buildSliderSection(
              title:
                  "Regression Data - Last Reading (150s): ${(lastTempReading - 273.15).toStringAsFixed(1)} °C",
              min: 333.15,
              max: 343.15,
              value: lastTempReading,
              onChanged: (val) => setState(() => lastTempReading = val),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable method to build sliders uniformly
  Widget _buildSliderSection({
    required String title,
    required double min,
    required double max,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, top: 8.0),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Slider(min: min, max: max, value: value, onChanged: onChanged),
      ],
    );
  }
}
