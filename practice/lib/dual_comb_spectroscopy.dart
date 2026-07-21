import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(), // सायंटिफिक ग्राफसाठी डार्क थीम उत्तम दिसते
      home: const DCSGraphScreen(),
    );
  }
}

// १. डेटा मॉडेल
class TransmittanceData {
  final double frequency; // RF Frequency (MHz)
  final double transmittance; // Value between 0.0 and 1.0

  TransmittanceData(this.frequency, this.transmittance);
}

class DCSGraphScreen extends StatefulWidget {
  const DCSGraphScreen({Key? key}) : super(key: key);

  @override
  State<DCSGraphScreen> createState() => _DCSGraphScreenState();
}

class _DCSGraphScreenState extends State<DCSGraphScreen> {
  List<TransmittanceData> _chartData = [];
  bool _isLive = true;
  Timer? _timer;
  double _phaseOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _startDataStreaming();
  }

  // २. बॅकग्राउंड थ्रेड (Isolate) द्वारे स्पेक्ट्रोस्कोपी डेटा जनरेट करणे
  // रिअल-टाइम अप्लिकेशनमध्ये इथे तुमचा रिअल FFT डेटा प्रोसेस होईल
  void _startDataStreaming() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) async {
      if (!_isLive) return;

      _phaseOffset += 0.1; // कॉम्ब फेज शिफ्ट सिम्युलेट करण्यासाठी

      // कॉम्पुटेशनल काम बॅकग्राउंड Isolate वर पाठवणे (UI लॅग रोखण्यासाठी)
      final List<TransmittanceData> freshData = await compute(
        _generateDCSData,
        _phaseOffset,
      );

      if (mounted) {
        setState(() {
          _chartData = freshData;
        });
      }
    });
  }

  // हा फंक्शन स्वतंत्र थ्रेडवर चालतो (Isolate)
  static List<TransmittanceData> _generateDCSData(double offset) {
    final List<TransmittanceData> data = [];
    const int combLines = 100; // कॉम्ब लाईन्सची संख्या
    const double startFreq = 10.0; // MHz
    const double spacing = 0.5; // MHz (Δf - Comb Spacing)

    for (int i = 0; i < combLines; i++) {
      double freq = startFreq + (i * spacing);

      // गॉस्सियन आणि लॉरेन्टझियन डीप्स (Absorption Lines) सिम्युलेट करणे
      double absorption1 = 0.6 * math.exp(-math.pow((freq - 25.0), 2) / 4.0);
      double absorption2 = 0.4 * math.exp(-math.pow((freq - 40.0), 2) / 2.0);

      // कॉम्बची मूळ ट्रान्समिटन्स आणि त्यावर येणारा नॉईज (Jitter)
      double noise = 0.02 * math.sin(freq * 10 + offset);
      double transmittance = 0.95 - absorption1 - absorption2 + noise;

      // व्हॅल्यू ० ते १ च्या दरम्यान ठेवणे
      transmittance = transmittance.clamp(0.0, 1.0);

      data.add(TransmittanceData(freq, transmittance));
    }
    return data;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dual-Comb Spectroscopy Spectrum'),
        actions: [
          IconButton(
            icon: Icon(_isLive ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              setState(() {
                _isLive = !_isLive;
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: SfCartesianChart(
                // ग्राफ सुबक दिसण्यासाठी ग्रिडलाईन्स आणि डिझाईन
                plotAreaBorderWidth: 0,
                title: ChartTitle(text: 'Transmission Spectrum (RF Domain)'),
                tooltipBehavior: TooltipBehavior(enable: true),
                primaryXAxis: NumericAxis(
                  title: AxisTitle(text: 'RF Frequency (MHz)'),
                  majorGridLines: const MajorGridLines(
                    width: 0.5,
                    color: Colors.grey,
                  ),
                  edgeLabelPlacement: EdgeLabelPlacement.shift,
                ),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(text: 'Transmittance (T)'),
                  minimum: 0.0,
                  maximum: 1.0,
                  majorGridLines: const MajorGridLines(
                    width: 0.5,
                    color: Colors.grey,
                  ),
                ),
                series: <CartesianSeries<TransmittanceData, double>>[
                  // कॉम्ब स्पेक्ट्रम अचूक दिसण्यासाठी FastLineSeries वापरली आहे
                  FastLineSeries<TransmittanceData, double>(
                    dataSource: _chartData,
                    xValueMapper: (TransmittanceData data, _) => data.frequency,
                    yValueMapper: (TransmittanceData data, _) =>
                        data.transmittance,
                    name: 'Transmittance',
                    color: Colors.cyanAccent,
                    width: 1.5,
                    animationDuration:
                        0, // रिअल-टाइम अपडेटसाठी ॲनिमेशन बंद केले आहे
                  ),
                ],
              ),
            ),
            // खालील पट्टीमध्ये सद्यस्थिती दर्शवणे
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isLive ? '● LIVE STREAMING' : '  PAUSED',
                    style: TextStyle(
                      color: _isLive ? Colors.greenAccent : Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('Points: ${_chartData.length} lines'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
