import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class LibsLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(home: InteractiveLibsGraph(rawIntensities: []));
  }
}

class InteractiveLibsGraph extends StatefulWidget {
  final List<double> rawIntensities; // E.g., 2048 or 4096 size array

  const InteractiveLibsGraph({super.key, required this.rawIntensities});

  @override
  State<InteractiveLibsGraph> createState() => _InteractiveLibsGraphState();
}

class _InteractiveLibsGraphState extends State<InteractiveLibsGraph> {
  final double startWavelength = 190.0;
  final double endWavelength = 950.0;

  // Mutable slider state variables
  double _centerWavelength =
      247.0; // Initial center of band (e.g., Carbon line)
  final double _bandWidth = 10.0; // Total window width in nm (+/- 5nm)

  @override
  Widget build(BuildContext context) {
    // 1. Calculate active band boundaries based on slider position
    double targetStart = _centerWavelength - (_bandWidth / 2);
    double targetEnd = _centerWavelength + (_bandWidth / 2);

    double step =
        (endWavelength - startWavelength) / (widget.rawIntensities.length - 1);

    List<FlSpot> mainSpectrumSpots = [];
    List<FlSpot> loadedBandSpots = [];
    double calculatedBandLoading = 0.0;

    // 2. Generate chart data points and calculate local loading energy
    for (int i = 0; i < widget.rawIntensities.length; i++) {
      double wavelength = startWavelength + (i * step);
      double intensity = widget.rawIntensities[i];
      FlSpot spot = FlSpot(wavelength, intensity);

      mainSpectrumSpots.add(spot);

      // Check if data point falls inside the slider's window
      if (wavelength >= targetStart && wavelength <= targetEnd) {
        loadedBandSpots.add(spot);
        calculatedBandLoading += intensity; // Sum of intensities inside band
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Real-time Loading metrics header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Target Window: ${targetStart.toStringAsFixed(1)}nm - ${targetEnd.toStringAsFixed(1)}nm\n'
            'Band Loading Energy: ${calculatedBandLoading.toStringAsFixed(0)} Counts',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),

        // 3. The Spectrum Graph Display
        SizedBox(
          height: 300,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true),
              titlesData: const FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 40),
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
                // Full Spectrum Data Line
                LineChartBarData(
                  spots: mainSpectrumSpots,
                  isCurved: false,
                  color: Colors.blue.withOpacity(0.5),
                  barWidth: 1,
                  dotData: const FlDotData(show: false),
                ),
                // Dynamic Highlighted Loading Band (updates via slider)
                LineChartBarData(
                  spots: loadedBandSpots,
                  isCurved: false,
                  color: Colors.redAccent,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.redAccent.withOpacity(0.35),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // 4. The Interactive Slider Widget
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Adjust Target Frequency/Wavelength Band:',
                style: TextStyle(color: Colors.grey),
              ),
              Slider(
                value: _centerWavelength,
                min: startWavelength + (_bandWidth / 2),
                max: endWavelength - (_bandWidth / 2),
                divisions: 100,
                label: '${_centerWavelength.toStringAsFixed(1)} nm',
                onChanged: (double newValue) {
                  setState(() {
                    _centerWavelength =
                        newValue; // Triggers UI rebuild with updated calculations
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
