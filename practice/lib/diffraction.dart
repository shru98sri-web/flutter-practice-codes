import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  runApp(const DiffractionFringeApp());
}

class DiffractionFringeApp extends StatelessWidget {
  const DiffractionFringeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Diffraction Simulator',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      ),
      home: const FringeSimulatorDashboard(),
    );
  }
}

class FringeSimulatorDashboard extends StatefulWidget {
  const FringeSimulatorDashboard({Key? key}) : super(key: key);

  @override
  State<FringeSimulatorDashboard> createState() =>
      _FringeSimulatorDashboardState();
}

class _FringeSimulatorDashboardState extends State<FringeSimulatorDashboard> {
  // अ‍ॅपचे स्लायडर पॅरामीटर्स
  double _slitWidth = 15.0; // झिरीची रुंदी (Slit Width 'a' in micrometers)
  double _wavelength =
      550.0; // प्रकाशाची वेव्हलेंथ (Wavelength 'λ' in nanometers)
  Color _laserColor = Colors.greenAccent; // लेझरचा रंग

  // वेव्हलेंथनुसार लेझरचा रंग बदलणे
  void _updateLaserColor(double wl) {
    if (wl >= 400 && wl < 480) {
      _laserColor = Colors.blueAccent;
    } else if (wl >= 480 && wl < 560) {
      _laserColor = Colors.greenAccent;
    } else if (wl >= 560 && wl < 600) {
      _laserColor = Colors.yellowAccent;
    } else {
      _laserColor = Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔬 Diffraction Fringe Lab'),
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // १. रिअल-टाईम कंट्रोल पॅनेल
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  children: [
                    // स्लायडर १: Slit Width
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Slit Width (a): ${_slitWidth.toStringAsFixed(1)} µm',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Icon(Icons.tune, size: 18, color: Colors.grey),
                      ],
                    ),
                    Slider(
                      value: _slitWidth,
                      min: 5.0,
                      max: 40.0,
                      activeColor: _laserColor,
                      onChanged: (val) => setState(() => _slitWidth = val),
                    ),

                    // स्लायडर २: Wavelength
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Wavelength (λ): ${_wavelength.toStringAsFixed(0)} nm',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Container(width: 20, height: 10, color: _laserColor),
                      ],
                    ),
                    Slider(
                      value: _wavelength,
                      min: 400.0,
                      max: 700.0,
                      activeColor: _laserColor,
                      onChanged: (val) {
                        setState(() {
                          _wavelength = val;
                          _updateLaserColor(val);
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            // २. ग्राफ आणि फ्रिंज व्हिज्युअलायझेशन विंडो
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Intensity Distribution Graph',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 5),

                      // तीव्रता दाखवणारा वरचा आलेख (Intensity Graph)
                      Expanded(
                        flex: 4,
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: DiffractionGraphPainter(
                            slitWidth: _slitWidth,
                            wavelength: _wavelength,
                            laserColor: _laserColor,
                          ),
                        ),
                      ),

                      const Divider(color: Colors.grey, height: 20),
                      const Text(
                        'Diffraction Pattern Fringes',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 5),

                      // प्रत्यक्ष उमटणाऱ्या फ्रिंजेस (Fringe View Area)
                      Expanded(
                        flex: 3,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: ClipRect(
                            child: CustomPaint(
                              size: Size.infinite,
                              painter: DiffractionFringePainter(
                                slitWidth: _slitWidth,
                                wavelength: _wavelength,
                                laserColor: _laserColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ३. मॅथेमॅटिकल ग्राफ ड्रॉ करणारा पेंटर [ Single Slit: I = I0 * (sin(β)/β)² ]
class DiffractionGraphPainter extends CustomPainter {
  final double slitWidth;
  final double wavelength;
  final Color laserColor;

  DiffractionGraphPainter({
    required this.slitWidth,
    required this.wavelength,
    required this.laserColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = laserColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final axisPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.0;

    double midX = size.width / 2;
    double bottomY = size.height - 10;

    // ग्राफचे एक्स आणि वाय अ‍ॅक्सिस ड्रॉ करणे
    canvas.drawLine(Offset(0, bottomY), Offset(size.width, bottomY), axisPaint);
    canvas.drawLine(Offset(midX, 0), Offset(midX, size.height), axisPaint);

    final Path path = Path();
    bool first = true;

    // स्केल फॅक्टर: ग्राफ पडद्यावर व्यवस्थित मॅप करण्यासाठी
    double scale = (slitWidth * 500) / wavelength;

    for (double x = 0; x < size.width; x++) {
      double theta = (x - midX) / scale;
      double intensity = 1.0;

      if (theta != 0) {
        // Single Slit चा प्रामाणिक मॅथेमॅटिकल फॉर्म्युला: [Sinc Function squared]
        intensity = math.pow(math.sin(theta) / theta, 2).toDouble();
      }

      // ग्राफची उंची सेट करणे
      double graphY = bottomY - (intensity * (size.height - 20));

      if (first) {
        path.moveTo(x, graphY);
        first = false;
      } else {
        path.lineTo(x, graphY);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant DiffractionGraphPainter oldDelegate) => true;
}

// ४. प्रत्यक्ष अल्टरनेटिंग ब्राइट आणि डार्क पट्ट्या ड्रॉ करणारा पेंटर
class DiffractionFringePainter extends CustomPainter {
  final double slitWidth;
  final double wavelength;
  final Color laserColor;

  DiffractionFringePainter({
    required this.slitWidth,
    required this.wavelength,
    required this.laserColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double midX = size.width / 2;
    double scale = (slitWidth * 500) / wavelength;

    // संपूर्ण स्क्रीनवर १-१ पिक्सेलच्या उभ्या रेषा मारून फ्रिंज इफेक्ट देणे
    for (double x = 0; x < size.width; x++) {
      double theta = (x - midX) / scale;
      double intensity = 1.0;

      if (theta != 0) {
        intensity = math.pow(math.sin(theta) / theta, 2).toDouble();
      }

      // तीव्रता ० ते १ च्या दरम्यान मर्यादित ठेवणे
      intensity = intensity.clamp(0.0, 1.0);

      final paint = Paint()
        ..color = laserColor.withOpacity(intensity)
        ..strokeWidth = 1.0;

      // उभ्या पट्ट्यांची निर्मिती
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant DiffractionFringePainter oldDelegate) => true;
}
