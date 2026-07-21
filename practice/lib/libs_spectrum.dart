import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Generate dummy data with 2048 samples for testing purposes
    final List<double> mockData = List.generate(2048, (i) {
      if (i > 150 && i < 200) return 4500.0; // Simulated peak near 247nm
      if (i > 800 && i < 850) return 3000.0; // Second simulated peak
      return 150.0; // Baseline noise floor
    });

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('LIBS Spectrum Loading Test'),
          backgroundColor: Colors.blueGrey,
        ),
        body: Center(
          child: SingleChildScrollView(
            child: InteractiveLibsGraph(rawIntensities: mockData),
          ),
        ),
      ),
    );
  }
}

class InteractiveLibsGraph extends StatefulWidget {
  final List<double> rawIntensities;

  const InteractiveLibsGraph({super.key, required this.rawIntensities});

  @override
  State<InteractiveLibsGraph> createState() => _InteractiveLibsGraphState();
}

class _InteractiveLibsGraphState extends State<InteractiveLibsGraph> {
  final double startWavelength = 190.0;
  final double endWavelength = 950.0;

  // Slider state variables
  double _centerWavelength = 247.0;
  final double _bandWidth = 20.0; // Total window width (+/- 10nm)

  @override
  Widget build(BuildContext context) {
    double targetStart = _centerWavelength - (_bandWidth / 2);
    double targetEnd = _centerWavelength + (_bandWidth / 2);

    double step =
        (endWavelength - startWavelength) / (widget.rawIntensities.length - 1);

    List<FlSpot> mainSpectrumSpots = [];
    List<FlSpot> loadedBandSpots = [];
    double calculatedBandLoading = 0.0;

    // Data points processing and loading calculation
    for (int i = 0; i < widget.rawIntensities.length; i++) {
      double wavelength = startWavelength + (i * step);
      double intensity = widget.rawIntensities[i];
      FlSpot spot = FlSpot(wavelength, intensity);

      mainSpectrumSpots.add(spot);

      // Verify if the current wavelength falls inside the selected target window
      if (wavelength >= targetStart && wavelength <= targetEnd) {
        loadedBandSpots.add(spot);
        calculatedBandLoading += intensity;
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Real-time metric visualization header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Card(
            elevation: 4,
            margin: const EdgeInsets.all(12.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Window Range: ${targetStart.toStringAsFixed(1)}nm - ${targetEnd.toStringAsFixed(1)}nm\n'
                'Band Loading Energy: ${calculatedBandLoading.toStringAsFixed(0)} Counts',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
            ),
          ),
        ),

        // Spectral Line Graph viewport
        SizedBox(
          height: 300,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true),
              titlesData: const FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 45),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                // Entire baseline spectrum rendering
                LineChartBarData(
                  spots: mainSpectrumSpots,
                  isCurved: false,
                  color: Colors.blue.withOpacity(0.5),
                  barWidth: 1,
                  dotData: const FlDotData(show: false),
                ),
                // Highlighted loaded band window
                LineChartBarData(
                  spots: loadedBandSpots,
                  isCurved: false,
                  color: Colors.redAccent,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.redAccent.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 25),

        // Interactive Band Control UI Slider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Adjust Target Wavelength Band:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              Slider(
                value: _centerWavelength,
                min: startWavelength + (_bandWidth / 2),
                max: endWavelength - (_bandWidth / 2),
                divisions: 200,
                label: '${_centerWavelength.toStringAsFixed(1)} nm',
                onChanged: (double newValue) {
                  setState(() {
                    _centerWavelength =
                        newValue; // Forces canvas refresh and numeric recalculation
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
