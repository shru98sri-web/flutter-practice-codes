import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(Stoke());
}

class Stoke extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(home: StokesCompleteSimulation());
  }
}

class StokesCompleteSimulation extends StatefulWidget {
  const StokesCompleteSimulation({Key? key}) : super(key: key);

  @override
  _StokesCompleteSimulationState createState() =>
      _StokesCompleteSimulationState();
}

class _StokesCompleteSimulationState extends State<StokesCompleteSimulation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // --- कंट्रोलेबल फिजिक्स पॅरामीटर्स (Sliders) ---
  double r = 0.04; // गोलाची त्रिज्या (Radius in meters, range: 0.01 - 0.08)
  double eta = 1.2; // द्रवाची विस्कॉसिटी (Viscosity in Pa·s, range: 0.5 - 3.0)

  // --- स्थिर फिजिक्स पॅरामीटर्स ---
  final double rho = 7800; // गोलाची घनता (Iron: 7800 kg/m³)
  final double sigma = 1260; // द्रवाची घनता (Glycerin: 1260 kg/m³)
  final double g = 9.8; // गुरुत्वाकर्षण (9.8 m/s²)

  // --- सिम्युलेशन स्टेट्स ---
  double yPos = 40.0; // स्क्रीनवरील Y स्थान
  double velocity = 0.0; // सद्य वेग (Current Velocity)
  double terminalVelocity = 0.0;
  double lastTime = 0.0;
  double elapsedTime = 0.0;

  // ग्राफसाठी डेटा पॉईंट्स (Time, Velocity)
  List<Offset> graphData = [];

  @override
  void initState() {
    super.initState();
    _calculateTerminalVelocity();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updatePhysics);

    _controller.repeat();
  }

  void _calculateTerminalVelocity() {
    terminalVelocity = (2 * pow(r, 2) * (rho - sigma) * g) / (9 * eta);
  }

  void _updatePhysics() {
    // वेळेतील बदल (Delta Time) मोजणे
    double totalElapsed =
        _controller.value +
        (_controller.status == AnimationStatus.forward ? 0 : 1);
    // साधे सोपे टाइम स्टेपिंग (dt)
    double dt = 0.016; // साधारण ६० FPS साठी स्थिर dt

    elapsedTime += dt;

    // स्टोक्स नियमानुसार प्रवेग (Acceleration) गणना
    double dragAcc =
        (6 * pi * eta * r * velocity) / ((4 / 3) * pi * pow(r, 3) * rho);
    double gravityAcc = g * (1 - (sigma / rho));
    double netAcceleration = gravityAcc - dragAcc;

    setState(() {
      // वेग अपडेट करणे
      velocity += netAcceleration * dt;

      // जर वेग टर्मिनल व्हेलाॅसिटीच्या जवळ गेला तर तो स्थिर ठेवणे
      if (velocity > terminalVelocity) velocity = terminalVelocity;

      // स्क्रीन पिक्सेल्ससाठी स्केल करणे (१ मीटर = २०० पिक्सेल)
      double pixelVelocity = velocity * 200;
      yPos += pixelVelocity * dt;

      // ग्राफमध्ये डेटा पॉईंट जोडणे (जास्तीत जास्त १०० पॉईंट्स ठेवणे)
      if (graphData.length > 100) {
        graphData.removeAt(0);
      }
      graphData.add(Offset(elapsedTime, velocity));

      // सिम्युलेशन मर्यादेबाहेर गेल्यास रिसेट करणे
      if (yPos > 400) {
        _resetSimulation();
      }
    });
  }

  void _resetSimulation() {
    yPos = 40.0;
    velocity = 0.0;
    elapsedTime = 0.0;
    graphData.clear();
    _calculateTerminalVelocity();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stokes Law Simulation with Graph')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // १. सिम्युलेशन आणि ग्राफ एरिया (शेजारी शेजारी)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // डावीकडे: लिक्विड ट्यूब सिम्युलेशन
                  Column(
                    children: [
                      const Text(
                        'Fluid Tube',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 100,
                        height: 420,
                        decoration: BoxDecoration(
                          color: Colors.lightBlue.withOpacity(0.25),
                          border: Border.all(color: Colors.blue, width: 3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CustomPaint(
                          painter: StokesBallPainter(
                            yPos: yPos,
                            radius: r * 350,
                          ), // स्क्रीन स्केलसाठी त्रिज्या वाढवली आहे
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  // उजवीकडे: रियल-टाइम ग्राफ पेंटर
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Velocity vs Time Graph',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 250,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.05),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: CustomPaint(
                            painter: VelocityGraphPainter(
                              dataPoints: graphData,
                              maxVel: terminalVelocity > 0
                                  ? terminalVelocity * 1.2
                                  : 2.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        // रियल-टाइम वाचन (Readings)
                        Text(
                          'Current Velocity: ${velocity.toStringAsFixed(3)} m/s',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Terminal Velocity: ${terminalVelocity.toStringAsFixed(3)} m/s',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _resetSimulation,
                          child: const Text('Reset Physics'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 40, thickness: 1.5),

              // २. स्लाईडर्स कंट्रोल्स (UI Controls)
              const Text(
                'Physics Tuning Controls',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              // त्रिज्येचा स्लाईडर (Ball Radius Slider)
              Text('Ball Radius (r): ${r.toStringAsFixed(3)} meters'),
              Slider(
                value: r,
                min: 0.02,
                max: 0.07,
                divisions: 5,
                label: '${r.toStringAsFixed(3)} m',
                onChanged: (val) {
                  setState(() {
                    r = val;
                    _resetSimulation();
                  });
                },
              ),

              // विस्कॉसिटीचा स्लाईडर (Liquid Viscosity Slider)
              Text('Liquid Viscosity (η): ${eta.toStringAsFixed(2)} Pa·s'),
              Slider(
                value: eta,
                min: 0.5,
                max: 3.0,
                divisions: 5,
                label: '${eta.toStringAsFixed(2)} Pa·s',
                onChanged: (val) {
                  setState(() {
                    eta = val;
                    _resetSimulation();
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- बॉल ड्रॉ करण्यासाठी पेंटर ---
class StokesBallPainter extends CustomPainter {
  final double yPos;
  final double radius;
  StokesBallPainter({required this.yPos, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;

    // मर्यादेत चेंडू ठेवणे
    double constrainedY = yPos.clamp(radius, size.height - radius);
    canvas.drawCircle(
      Offset(size.width / 2, constrainedY),
      radius.clamp(8, 25),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant StokesBallPainter oldDelegate) {
    return oldDelegate.yPos != yPos || oldDelegate.radius != radius;
  }
}

// --- ग्राफ ड्रॉ करण्यासाठी कस्टम पेंटer ---
class VelocityGraphPainter extends CustomPainter {
  final List<Offset> dataPoints;
  final double maxVel;

  VelocityGraphPainter({required this.dataPoints, required this.maxVel});

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final graphPaint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // १. अक्ष (X आणि Y Axis) तयार करणे
    // Y-Axis
    canvas.drawLine(Offset(30, 10), Offset(30, size.height - 20), axisPaint);
    // X-Axis
    canvas.drawLine(
      Offset(30, size.height - 20),
      Offset(size.width - 10, size.height - 20),
      axisPaint,
    );

    if (dataPoints.isEmpty) return;

    // २. डेटा पॉईंट्स मॅप करून ग्राफची लाईन तयार करणे
    final path = Path();
    double maxTime = dataPoints.last.dx > 4.0 ? dataPoints.last.dx : 4.0;

    for (int i = 0; i < dataPoints.length; i++) {
      // वेळ X अक्षावर मॅप करणे
      double x = 30 + ((dataPoints[i].dx / maxTime) * (size.width - 40));
      // वेग Y अक्षावर मॅप करणे (खालील बाजूने वर जाण्यासाठी वजाबाकी)
      double y =
          (size.height - 20) -
          ((dataPoints[i].dy / maxVel) * (size.height - 30));

      // कॅनव्हासच्या सीमारेषा ओलांडणार नाही याची काळजी घेणे
      x = x.clamp(30, size.width - 10);
      y = y.clamp(10, size.height - 20);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, graphPaint);
  }

  @override
  bool shouldRepaint(covariant VelocityGraphPainter oldDelegate) {
    return true;
    // set to true since the data is constantly changing
  }
}
