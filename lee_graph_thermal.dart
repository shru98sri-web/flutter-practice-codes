import 'dart:convert';
import 'dart:math' as math;

import 'package:csv/csv.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart'
    as html; // Platform-agnostic file handling

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ), // Updated to Blue Theme
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
  double mass = 0.850;
  double specHeat = 385.0;
  double thickness = 0.003;
  double radius = 0.055;
  double tempSteam = 373.15;
  double tempDisc = 343.15;

  final List<double> timeData = [0.0, 30.0, 60.0, 90.0, 120.0, 150.0];
  double lastTempReading = 340.15;

  List<double> getYDataInCelsius() {
    return [
      343.15 - 273.15,
      342.45 - 273.15,
      341.85 - 273.15,
      341.25 - 273.15,
      340.65 - 273.15,
      lastTempReading - 273.15,
    ];
  }

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

    double slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
    return slope.abs();
  }

  double calculateThermalConductivity(double coolingRate) {
    double area = math.pi * math.pow(radius, 2);
    double heatFlow = mass * specHeat * coolingRate;
    if ((tempSteam - tempDisc) <= 0) return 0.0;
    return (heatFlow * thickness) / (area * (tempSteam - tempDisc));
  }

  // Generates and triggers the browser/device download for CSV data
  void exportToCSV(double coolingRate, double kValue) {
    List<double> cData = getYDataInCelsius();

    // Structuring experimental matrix layout
    List<List<dynamic>> csvData = [
      ["Lee's Disc Experiment Report"],
      [],
      ["Parameter", "Value", "Unit"],
      ["Mass of Disc", mass, "kg"],
      ["Specific Heat Capacity", specHeat, "J/kg·K"],
      ["Thickness of Sample", thickness, "m"],
      ["Radius of Disc", radius, "m"],
      ["Steam Temp (T1)", tempSteam - 273.15, "°C"],
      ["Disc Temp (T2)", tempDisc - 273.15, "°C"],
      ["Calculated Cooling Rate (dT/dt)", coolingRate, "K/s"],
      ["Thermal Conductivity (k)", kValue, "W/m·K"],
      [],
      ["Cooling Curve Data Points"],
      ["Time (Seconds)", "Temperature (°C)"],
    ];

    // Append graphical matrix plots
    for (int i = 0; i < timeData.length; i++) {
      csvData.add([timeData[i], cData[i]]);
    }

    // Convert matrix rows into comma-separated strings
    String csvString = const ListToCsvConverter().convert(csvData);

    // Package stream into dynamic executable link block
    final bytes = utf8.encode(csvString);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute("download", "Lees_Disc_Experiment_Data.csv")
      ..click();

    html.Url.revokeObjectUrl(url);

    // Notify user with localized interactive banner UI
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("CSV Document Exported Successfully!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    double coolingRate = calculateCoolingRate();
    double kValue = calculateThermalConductivity(coolingRate);
    List<double> cData = getYDataInCelsius();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lee's Disc Calculator (Blue)"),
        centerTitle: true,
        backgroundColor: Colors.blue.shade100,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Results Card Window
            Card(
              color: Colors.blue.shade50,
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
                            color: Colors.blue.shade900,
                          ),
                    ),
                    const Divider(color: Colors.blueAccent),
                    Text(
                      "Cooling Rate (dT/dt): ${coolingRate.toStringAsFixed(5)} K/s",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // CSV Download Call to Action Button
            ElevatedButton.icon(
              onPressed: () => exportToCSV(coolingRate, kValue),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.download_rounded),
              label: const Text(
                "EXPORT DATA TO CSV",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Line Chart Vector Graph Panel
            Text(
              "Cooling Curve Graph",
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Container(
              height: 220,
              padding: const EdgeInsets.only(right: 20, top: 10, left: 10),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: Colors.blue.shade50, strokeWidth: 1),
                    getDrawingVerticalLine: (value) =>
                        FlLine(color: Colors.blue.shade50, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text(
                        "Time (Seconds)",
                        style: TextStyle(color: Colors.blueGrey, fontSize: 12),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (val, index) =>
                            Text(val.toInt().toString()),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: const Text(
                        "Temperature (°C)",
                        style: TextStyle(color: Colors.blueGrey, fontSize: 12),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (val, index) =>
                            Text(val.toStringAsFixed(1)),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        timeData.length,
                        (i) => FlSpot(timeData[i], cData[i]),
                      ),
                      isCurved: true,
                      color: Colors.blue.shade700,
                      barWidth: 4,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                              radius: 4,
                              color: Colors.blue.shade900,
                              strokeWidth: 1,
                              strokeColor: Colors.white,
                            ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.shade700.withOpacity(0.08),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Continuous Real-Time Adjustment Sliders
            _buildSliderSection(
              title: "Disc Mass: ${mass.toStringAsFixed(3)} kg",
              min: 0.1,
              max: 2.0,
              value: mass,
              onChanged: (val) => setState(() => mass = val),
            ),
            _buildSliderSection(
              title: "Specific Heat (c): ${specHeat.toStringAsFixed(0)} J/kg·K",
              min: 100,
              max: 1000,
              value: specHeat,
              onChanged: (val) => setState(() => specHeat = val),
            ),
            _buildSliderSection(
              title:
                  "Sample Thickness (x): ${(thickness * 1000).toStringAsFixed(1)} mm",
              min: 0.001,
              max: 0.010,
              value: thickness,
              onChanged: (val) => setState(() => thickness = val),
            ),
            _buildSliderSection(
              title: "Disc Radius (r): ${(radius * 100).toStringAsFixed(1)} cm",
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
                  "Last Temp Reading (150s): ${(lastTempReading - 273.15).toStringAsFixed(1)} °C",
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

  Widget _buildSliderSection({
    required String title,
    required double min,
    required double max,
    required double value,
    required ValueChanged onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, top: 8.0),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade900,
            ),
          ),
        ),
        Slider(
          min: min,
          max: max,
          value: value,
          activeColor: Colors.blue.shade600,
          inactiveColor: Colors.blue.shade100,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
