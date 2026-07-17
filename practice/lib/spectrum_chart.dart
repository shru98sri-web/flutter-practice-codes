import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

//void main() => runApp(const SpectrumApp());

class SpectrumApp extends StatelessWidget {
  const SpectrumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const SpectrumPlotScreen(),
    );
  }
}

// 1. Spectrum Template Model
class SpectrumType {
  final String name;
  final String xAxisLabel;
  final String yAxisLabel;
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  final List<FlSpot> sampleData;

  const SpectrumType({
    required this.name,
    required this.xAxisLabel,
    required this.yAxisLabel,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.sampleData,
  });
}

class SpectrumPlotScreen extends StatefulWidget {
  const SpectrumPlotScreen({super.key});

  @override
  State<SpectrumPlotScreen> createState() => _SpectrumPlotScreenState();
}

class _SpectrumPlotScreenState extends State<SpectrumPlotScreen> {
  late List<SpectrumType> _spectraTemplates;
  late SpectrumType _selectedSpectrum;

  @override
  void initState() {
    super.initState();
    _initializeMockData();
    _selectedSpectrum = _spectraTemplates.first;
  }

  // 2. Mock Data (नवीन OCT आणि Correlation Spectroscopy सह)
  void _initializeMockData() {
    _spectraTemplates = [
      SpectrumType(
        name: "FTIR / IR",
        xAxisLabel: "Wavenumber (cm⁻¹)",
        yAxisLabel: "Transmittance (%)",
        minX: 400,
        maxX: 4000,
        minY: 0,
        maxY: 100,
        sampleData: [
          const FlSpot(400, 95),
          const FlSpot(1500, 90),
          const FlSpot(1700, 20),
          const FlSpot(1800, 90),
          const FlSpot(3300, 40),
          const FlSpot(4000, 95),
        ],
      ),
      SpectrumType(
        name: "Raman",
        xAxisLabel: "Raman Shift (cm⁻¹)",
        yAxisLabel: "Intensity (a.u.)",
        minX: 100,
        maxX: 3200,
        minY: 0,
        maxY: 1000,
        sampleData: [
          const FlSpot(100, 50),
          const FlSpot(520, 950),
          const FlSpot(600, 100),
          const FlSpot(1350, 400),
          const FlSpot(1580, 800),
          const FlSpot(3200, 50),
        ],
      ),
      SpectrumType(
        name: "LIBS",
        xAxisLabel: "Wavelength (nm)",
        yAxisLabel: "Intensity (Counts)",
        minX: 200,
        maxX: 900,
        minY: 0,
        maxY: 5000,
        sampleData: [
          const FlSpot(200, 100),
          const FlSpot(393, 4800),
          const FlSpot(396, 4500),
          const FlSpot(589, 3500),
          const FlSpot(900, 200),
        ],
      ),
      SpectrumType(
        name: "LIF",
        xAxisLabel: "Wavelength (nm)",
        yAxisLabel: "Fluorescence Intensity",
        minX: 300,
        maxX: 700,
        minY: 0,
        maxY: 100,
        sampleData: [
          const FlSpot(300, 5),
          const FlSpot(450, 85),
          const FlSpot(520, 40),
          const FlSpot(700, 2),
        ],
      ),
      SpectrumType(
        name: "XRD",
        xAxisLabel: "2-Theta (Degrees)",
        yAxisLabel: "Intensity (Counts)",
        minX: 10,
        maxX: 90,
        minY: 0,
        maxY: 3000,
        sampleData: [
          const FlSpot(10, 200),
          const FlSpot(27.3, 2800),
          const FlSpot(35, 400),
          const FlSpot(45.2, 1900),
          const FlSpot(90, 150),
        ],
      ),
      SpectrumType(
        name: "XRF",
        xAxisLabel: "Energy (keV)",
        yAxisLabel: "Intensity (CPS)",
        minX: 0,
        maxX: 40,
        minY: 0,
        maxY: 10000,
        sampleData: [
          const FlSpot(0, 100),
          const FlSpot(6.4, 9500),
          const FlSpot(7.0, 1200),
          const FlSpot(8.0, 7000),
          const FlSpot(40, 50),
        ],
      ),
      // --- नवीन जोडलेले स्पेक्ट्रम ---
      SpectrumType(
        name: "OCT (Optical Coherence Tomography)",
        xAxisLabel: "Wavelength (nm)",
        yAxisLabel: "Spectral Power (dB)",
        minX: 750,
        maxX: 930,
        minY: -40,
        maxY: 0, // 840nm मध्यवर्ती Gaussian Peak
        sampleData: [
          const FlSpot(750, -38),
          const FlSpot(800, -25),
          const FlSpot(830, -5),
          const FlSpot(840, -1),
          const FlSpot(850, -4),
          const FlSpot(880, -22),
          const FlSpot(930, -39),
        ],
      ),
      SpectrumType(
        name: "Correlation Spectroscopy (FCS)",
        xAxisLabel: "Lag Time (τ in ms)",
        yAxisLabel: "Autocorrelation G(τ)",
        minX: 0.01,
        maxX: 100,
        minY: 1.0,
        maxY: 2.0, // विशिष्ट Decay Curve
        sampleData: [
          const FlSpot(0.01, 1.95),
          const FlSpot(0.1, 1.90),
          const FlSpot(1.0, 1.50),
          const FlSpot(10.0, 1.10),
          const FlSpot(100.0, 1.01),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scientific Spectrum Plotter")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Dropdown Menu
            DropdownButton<SpectrumType>(
              value: _selectedSpectrum,
              isExpanded: true,
              items: _spectraTemplates.map((SpectrumType value) {
                return DropdownMenuItem<SpectrumType>(
                  value: value,
                  child: Text(value.name, style: const TextStyle(fontSize: 16)),
                );
              }).toList(),
              onChanged: (SpectrumType? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedSpectrum = newValue;
                  });
                }
              },
            ),
            const SizedBox(height: 10),
            Text(
              "Y-Axis: ${_selectedSpectrum.yAxisLabel}",
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),

            // Interactive Chart
            Expanded(
              child: LineChart(
                LineChartData(
                  minX: _selectedSpectrum.minX,
                  maxX: _selectedSpectrum.maxX,
                  minY: _selectedSpectrum.minY,
                  maxY: _selectedSpectrum.maxY,
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: true,
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval:
                            (_selectedSpectrum.maxX - _selectedSpectrum.minX) /
                            5,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        interval:
                            (_selectedSpectrum.maxY - _selectedSpectrum.minY) /
                            4,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.white30, width: 1),
                  ),
                  lineBarsData: [getLineChartBarData(_selectedSpectrum)],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "X-Axis: ${_selectedSpectrum.xAxisLabel}",
              style: const TextStyle(
                color: Colors.cyan,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  LineChartBarData getLineChartBarData(SpectrumType spectrum) {
    return LineChartBarData(
      spots: spectrum.sampleData,
      isCurved: true,
      barWidth: 2,
      color: Colors.cyanAccent,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: Colors.cyanAccent.withOpacity(0.15),
      ),
    );
  }
}
