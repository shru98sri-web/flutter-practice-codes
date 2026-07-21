import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const NeuromorphicBrainApp());
}

class NeuromorphicBrainApp extends StatelessWidget {
  const NeuromorphicBrainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neuromorphic Synaptic Network',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const BrainNetworkScreen(),
    );
  }
}

/// बायोमिमिक न्यूरॉन मॉडेल (सिनेप्टिक कनेक्टिव्हिटीसह)
class NetworkNeuron {
  final int id;
  double a, b, c, d;
  double v; // मेंब्रेन पोटेंशियल (Voltage)
  double u; // रिकव्हरी व्हेरिएबल
  bool isSpiking = false;
  double synapticInput = 0.0; // इतर नोड्स कडून मिळणारा करंट

  NetworkNeuron({
    required this.id,
    this.a = 0.02,
    this.b = 0.2,
    this.c = -65.0,
    this.d = 6.0,
    this.v = -65.0,
    this.u = -13.0,
  });

  /// बाह्य आणि सिनेप्टिक इनपुटच्या आधारे नोड अपडेट करणे
  void update(double externalInput) {
    double totalInput = externalInput + synapticInput;

    // Izhikevich समीकरणे
    v += 0.04 * v * v + 5 * v + 140 - u + totalInput;
    u += a * (b * v - u);

    // सिनेप्टिक इनपुट हळूहळू कमी करणे (Decay)
    synapticInput *= 0.75;

    if (v >= 30.0) {
      isSpiking = true;
      v = c;
      u += d;
    } else {
      isSpiking = false;
    }
  }
}

class BrainNetworkScreen extends StatefulWidget {
  const BrainNetworkScreen({Key? key}) : super(key: key);

  @override
  State<BrainNetworkScreen> createState() => _BrainNetworkScreenState();
}

class _BrainNetworkScreenState extends State<BrainNetworkScreen> {
  final List<NetworkNeuron> _neurons = [];
  final List<FlSpot> _chartData = [];
  late Timer _networkTimer;
  final int _maxChartPoints = 50;

  // प्रत्येक ६ नोड्ससाठी स्वतंत्र इनपुट करंट नियंत्रित करणारी लिस्ट
  final List<double> _nodeCurrents = [15.0, 0.0, 0.0, 0.0, 0.0, 0.0];

  // निवडलेला नोड ज्याचा लाइव्ह ग्राफ Oscilloscope वर दिसेल
  int _selectedNodeForChart = 0;

  // सिनेप्टिक कनेक्शन मॅट्रिक्स
  final Map<int, List<int>> _synapticConnections = {
    0: [], // Node 0 -> Node 1, 2
    1: [], // Node 1 -> Node 3, 4
    2: [], // Node 2 -> Node 5
    3: [], // Feedback Loop
    4: [],
    5: [],
  };

  @override
  void initState() {
    super.initState();
    // ६ न्यूरॉन्सचे जाळे तयार करणे
    for (int i = 0; i < 6; i++) {
      _neurons.add(NetworkNeuron(id: i));
    }

    // ग्राफचा सुरुवातीचा डेटा भरणे
    for (int i = 0; i < _maxChartPoints; i++) {
      _chartData.add(FlSpot(i.toDouble(), -65.0));
    }

    // कॉम्प्युटेशनल इंजिन लूप (30ms)
    _networkTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      // १. सर्व ६ नोड्सना त्यांचे वैयक्तिक करंट इनपुट देऊन अपडेट करणे
      for (int i = 0; i < _neurons.length; i++) {
        _neurons[i].update(_nodeCurrents[i]);
      }

      // २. सिनेप्टिक सिग्नल ट्रान्सफर (Chain Reaction)
      for (var neuron in _neurons) {
        if (neuron.isSpiking) {
          var targets = _synapticConnections[neuron.id] ?? [];
          for (var targetId in targets) {
            _neurons[targetId].synapticInput += 28.0;
          }
        }
      }

      // ३. सिलेक्ट केलेल्या नोडचा लाइव्ह ईईजी (EEG) ग्राफ अपडेट करणे
      setState(() {
        _chartData.removeAt(0);
        for (int i = 0; i < _chartData.length; i++) {
          _chartData[i] = FlSpot(i.toDouble(), _chartData[i].y);
        }
        _chartData.add(
          FlSpot(
            (_maxChartPoints - 1).toDouble(),
            _neurons[_selectedNodeForChart].v,
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _networkTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12131C),
      appBar: AppBar(
        title: const Text("Multi-Current Synaptic Lab"),
        backgroundColor: const Color(0xFF1A1B26),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // विभाग १: सिनेप्टिक नोड्स ग्रिड (क्लिक केल्यावर ग्राफ बदलतो)
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemCount: _neurons.length,
                itemBuilder: (context, index) {
                  final neuron = _neurons[index];
                  final isSelectedForGraph = _selectedNodeForChart == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedNodeForChart = index;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 50),
                      decoration: BoxDecoration(
                        color: isSelectedForGraph
                            ? const Color(0xFF25283D)
                            : const Color(0xFF1E2030),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: neuron.isSpiking
                              ? Colors.purpleAccent
                              : (isSelectedForGraph
                                    ? Colors.cyanAccent
                                    : Colors.transparent),
                          width: 2,
                        ),
                        boxShadow: neuron.isSpiking
                            ? [
                                BoxShadow(
                                  color: Colors.purpleAccent.withAlpha(180),
                                  blurRadius: 20,
                                  spreadRadius: 6,
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withAlpha(100),
                                  offset: const Offset(3, 3),
                                  blurRadius: 8,
                                ),
                              ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bolt,
                            color: neuron.isSpiking
                                ? Colors.amberAccent
                                : Colors.blueGrey,
                            size: neuron.isSpiking ? 30 : 22,
                          ),
                          Text(
                            "N-$index",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: neuron.isSpiking
                                  ? Colors.white
                                  : Colors.grey,
                            ),
                          ),
                          Text(
                            "${neuron.v.toStringAsFixed(0)}mV",
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.cyanAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // विभाग २: लाइव्ह ऑसिलोस्कोप ग्राफ (निवडलेल्या नोडचा आलेख)
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1B26),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Live Waveform: Node N-$_selectedNodeForChart",
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: LineChart(
                      LineChartData(
                        minY: -90,
                        maxY: 40,
                        gridData: const FlGridData(
                          show: true,
                          drawVerticalLine: false,
                        ),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _chartData,
                            isCurved: true,
                            barWidth: 2,
                            color: Colors.purpleAccent,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.purpleAccent.withAlpha(20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // विभाग ३: वैयक्तिक नोड करंट कंट्रोलर (६ स्लायडर्सची स्क्रोल करण्यायोग्य लिस्ट)
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: const Color(0xFF161722),
              child: ListView.builder(
                itemCount: _neurons.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Text(
                          "N-$index Current:",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: _nodeCurrents[index],
                            min: 0,
                            max: 35,
                            activeColor: Colors.purpleAccent,
                            inactiveColor: Colors.grey.shade900,
                            onChanged: (value) {
                              setState(() {
                                _nodeCurrents[index] = value;
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          width: 45,
                          child: Text(
                            "${_nodeCurrents[index].toStringAsFixed(1)} mA",
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontFamily: 'Courier',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
