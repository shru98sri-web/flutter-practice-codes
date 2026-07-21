import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: PotentiometerDashboard()));

class PotentiometerDashboard extends StatefulWidget {
  const PotentiometerDashboard({super.key});

  @override
  State<PotentiometerDashboard> createState() => _PotentiometerDashboardState();
}

class _PotentiometerDashboardState extends State<PotentiometerDashboard> {
  double _rotationPercent = 0.5; // सुरवातीला ५०% वर सेट
  bool _isLogarithmic =
      false; // टायपिंग स्विच: False = Linear (A), True = Log (B)
  bool _enableNoise = true; // नॉइज सिम्युलेशन स्विच
  double _currentNoise = 0.0; // चालू गोंधळ/स्पाइक व्हॅल्यू
  late Timer _noiseTimer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // दर ५० मिलीसेकंदांनी रिअल-टाइम नॉइज जनरेट करण्यासाठी टाइमर
    _noiseTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_enableNoise) {
        setState(() {
          // -१.५ ते +१.५ मधील यादृच्छिक इलेक्ट्रॉनिक स्पाइक
          _currentNoise = (_random.nextDouble() * 3.0) - 1.5;
        });
      } else if (_currentNoise != 0.0) {
        setState(() {
          _currentNoise = 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _noiseTimer.cancel();
    super.dispose();
  }

  // मूळ सैद्धांतिक मूल्य (Theoretical Value)
  double get _theoreticalValue {
    if (_isLogarithmic) {
      // Logarithmic (Type B) सूत्र
      return ((pow(10, _rotationPercent) - 1) / 9) * 100;
    } else {
      // Linear (Type A) सूत्र
      return _rotationPercent * 100;
    }
  }

  // नॉइज समाविष्ट असलेले अंतिम रिअल-टाइम आउटपुट
  double get _actualLiveValue {
    double value = _theoreticalValue + _currentNoise;
    return value.clamp(0.0, 100.0); // ० ते १०० च्या दरम्यान मर्यादित ठेवणे
  }

  void _calculateAngle(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final x = localPosition.dx - center.dx;
    final y = localPosition.dy - center.dy;

    double angle = atan2(y, x) + (pi / 2);
    if (angle < 0) angle += 2 * pi;

    setState(() {
      _rotationPercent = angle / (2 * pi);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: const Color(0xFF121214),
      appBar: AppBar(
        title: const Text(
          'Advanced Potentiometer Sim',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1A1A1E),
        elevation: 0,
      ),
      body: Flex(
        direction: isLandscape ? Axis.horizontal : Axis.vertical,
        children: [
          // डावी बाजू / वरची बाजू: नियंत्रणे (Controls & Dial)
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 15),
                  // वैशिष्ट्य १: प्रकार बदलण्याचा स्विच
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Linear (A)',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Switch(
                        value: _isLogarithmic,
                        activeColor: Colors.amberAccent,
                        inactiveThumbColor: Colors.cyanAccent,
                        onChanged: (val) =>
                            setState(() => _isLogarithmic = val),
                      ),
                      const Text(
                        'Logarithmic (B)',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  // वैशिष्ट्य २: नॉइज सिम्युलेटर स्विच
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Hardware Noise',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      Checkbox(
                        value: _enableNoise,
                        activeColor: Colors.redAccent,
                        onChanged: (val) =>
                            setState(() => _enableNoise = val ?? false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Output: ${_actualLiveValue.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 36,
                      color: _isLogarithmic
                          ? Colors.amberAccent
                          : Colors.cyanAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  // इंटरएक्टिव्ह डायल नॉब
                  GestureDetector(
                    onPanUpdate: (d) =>
                        _calculateAngle(d.localPosition, const Size(160, 160)),
                    onPanDown: (d) =>
                        _calculateAngle(d.localPosition, const Size(160, 160)),
                    child: SizedBox(
                      width: 160,
                      height: 160,
                      child: CustomPaint(
                        painter: DialPainter(
                          percent: _rotationPercent,
                          color: _isLogarithmic
                              ? Colors.amberAccent
                              : Colors.cyanAccent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),

          // उजवी बाजू / खालची बाजू: लाईव्ह ग्राफ (Graph Display)
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: const Color(0xFF1A1A1E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    right: 20,
                    left: 10,
                    top: 20,
                    bottom: 10,
                  ),
                  child: _buildComparisonChart(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonChart() {
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 100,
        minY: 0,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.white10, strokeWidth: 1),
          getDrawingVerticalLine: (value) =>
              FlLine(color: Colors.white10, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              getTitlesWidget: (v, m) => Text(
                '${v.toInt()}',
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 25,
              getTitlesWidget: (v, m) => Text(
                '${v.toInt()}',
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.white24),
        ),
        lineBarsData: [
          // १. बेस मार्गदर्शक रेषा (Theoretical Background Curve)
          LineChartBarData(
            spots: List.generate(21, (i) {
              double rot = (i * 5) / 100;
              double v = _isLogarithmic
                  ? ((pow(10, rot) - 1) / 9) * 100
                  : rot * 100;
              return FlSpot(i * 5, v);
            }),
            isCurved: _isLogarithmic,
            color: Colors.white24,
            barWidth: 2,
            dotData: const FlDotData(show: false),
          ),
          // २. लाईव्ह चालू बिंदू / मार्कर (Dynamic Noise Dot Tracker)
          LineChartBarData(
            spots: [FlSpot(_rotationPercent * 100, _actualLiveValue)],
            isCurved: false,
            color: _isLogarithmic ? Colors.amberAccent : Colors.cyanAccent,
            barWidth: 0,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, xPct, bar, index) => FlDotCirclePainter(
                radius: 7,
                color: _isLogarithmic ? Colors.amberAccent : Colors.cyanAccent,
                strokeColor: Colors.black,
                strokeWidth: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//X (Horizontal Distance):
// The distance from the center point of the touch screen to the left or right.Y
// (Vertical Distance):
// The distance above or below the center point of the touch screen.

// डायल पेंटर (UI Knob Rendering)
class DialPainter extends CustomPainter {
  final double percent;
  final Color color;
  DialPainter({required this.percent, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.drawCircle(
      center,
      radius - 8,
      Paint()
        ..color = Colors.white12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 8),
      -pi / 2,
      percent * 2 * pi,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(
      center,
      radius - 20,
      Paint()
        ..color = const Color(0xFF23232A)
        ..style = PaintingStyle.fill,
    );

    double currentRad = (-pi / 2) + (percent * 2 * pi);
    double indicatorX = center.dx + (radius - 35) * cos(currentRad);
    double indicatorY = center.dy + (radius - 35) * sin(currentRad);
    canvas.drawCircle(
      Offset(indicatorX, indicatorY),
      5,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant DialPainter oldDelegate) =>
      oldDelegate.percent != percent || oldDelegate.color != color;
}
