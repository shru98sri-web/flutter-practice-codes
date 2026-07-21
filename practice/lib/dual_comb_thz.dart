import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      theme: ThemeData.dark(), // सायंटिफिक लूकसाठी डार्क थीम
      home: const DCSGraphScreen(),
    );
  }
}

// डेटा मॉडेल
class TransmittanceData {
  final double frequencyTHz;
  final double transmittance;

  TransmittanceData(this.frequencyTHz, this.transmittance);
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

  // स्लायडर्ससाठी कंट्रोल्स (डिफॉल्ट व्हॅल्यूज)
  double _centerFreqTHz = 193.0; // 193.0 THz (Telecom C-band center)
  double _combSpacingGHz = 20.0; // 20.0 GHz कॉम्ब स्पेसिंग

  @override
  void initState() {
    super.initState();
    _startDataStreaming();
  }

  void _startDataStreaming() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) async {
      if (!_isLive) return;

      _phaseOffset += 0.05;

      // स्लायडर्सचे पॅरामीटर्स मॅपमध्ये पॅक करून बॅकग्राउंड Isolate कडे पाठवणे
      final Map<String, dynamic> params = {
        'offset': _phaseOffset,
        'centerFreq': _centerFreqTHz,
        'spacingGHz': _combSpacingGHz,
      };

      final List<TransmittanceData> freshData = await compute(
        _generateTHzDCSData,
        params,
      );

      if (mounted) {
        setState(() {
          _chartData = freshData;
        });
      }
    });
  }

  // बॅकग्राउंड Isolate फंक्शन - स्लायडरनुसार डेटा बदलतो
  static List<TransmittanceData> _generateTHzDCSData(
    Map<String, dynamic> params,
  ) {
    final List<TransmittanceData> data = [];
    final double offset = params['offset'];
    final double centerFreq = params['centerFreq'];
    final double spacingGHz = params['spacingGHz'];

    // GHz चे रूपांतर THz मध्ये करणे (1 GHz = 0.001 THz)
    final double spacingTHz = spacingGHz * 0.001;
    const int combLines = 150;

    // सेंटर फ्रिक्वेन्सीनुसार स्टार्ट फ्रिक्वेन्सी ठरवणे
    final double startFreqTHz = centerFreq - ((combLines / 2) * spacingTHz);

    for (int i = 0; i < combLines; i++) {
      double freqTHz = startFreqTHz + (i * spacingTHz);

      // स्लायडर हलवल्यास अब्सॉर्प्शन लाईन्स देखील रिअल-टाइम शिफ्ट होतात
      double absorption1 =
          0.6 * math.exp(-math.pow((freqTHz - (centerFreq - 0.4)), 2) / 0.01);
      double absorption2 =
          0.4 * math.exp(-math.pow((freqTHz - (centerFreq + 0.5)), 2) / 0.03);

      double noise = 0.015 * math.sin(freqTHz * 100 + offset);
      double transmittance = 0.95 - absorption1 - absorption2 + noise;
      transmittance = transmittance.clamp(0.0, 1.0);

      data.add(TransmittanceData(freqTHz, transmittance));
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
        title: const Text('DCS Parameter Controller'),
        actions: [
          IconButton(
            icon: Icon(_isLive ? Icons.pause : Icons.play_arrow),
            onPressed: () => setState(() => _isLive = !_isLive),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // १. ग्राफ सेक्शन
            Expanded(
              child: SfCartesianChart(
                plotAreaBorderWidth: 0,
                title: ChartTitle(
                  text: 'Dynamic Optical Transmittance Spectrum',
                ),
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  format: 'point.x THz : point.y',
                ),
                primaryXAxis: NumericAxis(
                  title: AxisTitle(text: 'Optical Frequency (THz)'),
                  majorGridLines: const MajorGridLines(
                    width: 0.5,
                    color: Colors.blueGrey,
                  ),
                  edgeLabelPlacement: EdgeLabelPlacement.shift,
                  numberFormat: NumberFormat(
                    "###.000",
                  ), // intl पॅकेजचा योग्य वापर
                ),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(text: 'Transmittance (T)'),
                  minimum: 0.0,
                  maximum: 1.0,
                  majorGridLines: const MajorGridLines(
                    width: 0.5,
                    color: Colors.blueGrey,
                  ),
                ),
                series: <CartesianSeries<TransmittanceData, double>>[
                  FastLineSeries<TransmittanceData, double>(
                    dataSource: _chartData,
                    xValueMapper: (TransmittanceData data, _) =>
                        data.frequencyTHz,
                    yValueMapper: (TransmittanceData data, _) =>
                        data.transmittance,
                    name: 'Optical Transmittance',
                    color: Colors.orangeAccent,
                    width: 1.8,
                    animationDuration: 0,
                  ),
                ],
              ),
            ),

            const Divider(height: 20, color: Colors.grey),

            // २. स्लायडर्स कंट्रोल पॅनेल (UI च्या तळाशी)
            Card(
              color: Colors.grey[900],
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // स्लायडर १: Center Frequency Controls
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Center Frequency',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${_centerFreqTHz.toStringAsFixed(2)} THz',
                              style: const TextStyle(
                                color: Colors.orangeAccent,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _centerFreqTHz,
                          min: 191.0,
                          max: 196.0,
                          activeColor: Colors.orangeAccent,
                          onChanged: (value) {
                            setState(() {
                              _centerFreqTHz = value;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // स्लायडर २: Comb Spacing (Resolution) Controls
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Comb Spacing (Δf)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${_combSpacingGHz.toStringAsFixed(1)} GHz',
                              style: const TextStyle(color: Colors.cyanAccent),
                            ),
                          ],
                        ),
                        Slider(
                          value: _combSpacingGHz,
                          min: 5.0,
                          max: 50.0,
                          activeColor: Colors.cyanAccent,
                          onChanged: (value) {
                            setState(() {
                              _combSpacingGHz = value;
                            });
                          },
                        ),
                      ],
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
