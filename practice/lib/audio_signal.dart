import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

//void main() => runApp(const PostgraduateSpectrumApp());

class PostgraduateSpectrumApp extends StatelessWidget {
  const PostgraduateSpectrumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const SpectrumAnalyzerHome(),
    );
  }
}

class SpectrumAnalyzerHome extends StatefulWidget {
  const SpectrumAnalyzerHome({super.key});

  @override
  State<SpectrumAnalyzerHome> createState() => _SpectrumAnalyzerHomeState();
}

class _SpectrumAnalyzerHomeState extends State<SpectrumAnalyzerHome> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  StreamSubscription<RecordState>? _stateSubscription;
  StreamSubscription<Uint8List>? _audioStreamSubscription;

  // Buffer configuration (Must be a power of 2 for Radix-2 FFT)
  static const int fftSize = 512;
  List<double> _processedSpectralMagnitudes = List.filled(fftSize ~/ 2, -60.0);
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _stateSubscription = _audioRecorder.onStateChanged().listen((state) {
      setState(() => _isAnalyzing = state == RecordState.record);
    });
  }

  Future<void> _toggleAnalysis() async {
    if (_isAnalyzing) {
      await _stopSignalCapture();
    } else {
      await _startSignalCapture();
    }
  }

  Future<void> _startSignalCapture() async {
    final hasPermission = await Permission.microphone.request().isGranted;
    if (!hasPermission) return;

    // Request raw 16-bit Linear PCM stream (Mono, 44.1kHz standard)
    final recordStream = await _audioRecorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 44100,
        numChannels: 1,
      ),
    );

    // Accumulation list for processing windows
    List<int> rawPcmByteAccumulator = [];

    _audioStreamSubscription = recordStream.listen((Uint8List chunk) {
      rawPcmByteAccumulator.addAll(chunk);

      // Process when enough bytes arrive for a complete window
      // 1 sample = 16-bit (2 bytes). Thus, fftSize samples = fftSize * 2 bytes.
      int bytesRequired = fftSize * 2;
      while (rawPcmByteAccumulator.length >= bytesRequired) {
        final windowBytes = rawPcmByteAccumulator.sublist(0, bytesRequired);
        rawPcmByteAccumulator.removeRange(0, bytesRequired);

        _executeDigitalSignalProcessing(Uint8List.fromList(windowBytes));
      }
    });
  }

  void _executeDigitalSignalProcessing(Uint8List pcmBytes) {
    // 1. Convert Int16 Byte stream to Normalized Float Samples [-1.0, 1.0]
    final Int16List int16Samples = pcmBytes.buffer.asInt16List();
    List<double> signalSamples = int16Samples.map((x) => x / 32768.0).toList();

    // Pad with zeros if chunk size falls short
    while (signalSamples.length < fftSize) {
      signalSamples.add(0.0);
    }

    // 2. Windowing Stage: Apply Hanning Window to combat Spectral Leakage
    List<double> windowedSignal = List.filled(fftSize, 0.0);
    for (int n = 0; n < fftSize; n++) {
      double hanningMultiplier =
          0.5 * (1.0 - math.cos((2 * math.pi * n) / (fftSize - 1)));
      windowedSignal[n] = signalSamples[n] * hanningMultiplier;
    }

    // 3. Compute Fast Fourier Transform (Cooley-Tukey Algorithm)
    List<_Complex> complexSignal = windowedSignal
        .map((real) => _Complex(real, 0.0))
        .toList();
    _cooleyTukeyFFT(complexSignal);

    // 4. Magnitude extraction & Decibel (dBFS) conversion
    // We only evaluate the first half (Nyquist Frequency Limit)
    int halfSize = fftSize ~/ 2;
    List<double> dbMagnitudes = List.filled(halfSize, -60.0);

    for (int i = 0; i < halfSize; i++) {
      double magnitude = complexSignal[i].magnitude;

      // Calculate Decibels Relative to Full Scale (dBFS) with a -60dB noise floor
      double db = (magnitude > 0.00001)
          ? 20 * (math.log(magnitude) / math.ln10)
          : -60.0;
      dbMagnitudes[i] = db.clamp(-60.0, 0.0);
    }

    if (mounted) {
      setState(() {
        _processedSpectralMagnitudes = dbMagnitudes;
      });
    }
  }

  // Pure Radix-2 Cooley-Tukey FFT Implementation
  void _cooleyTukeyFFT(List<_Complex> buffer) {
    int n = buffer.length;
    if (n <= 1) return;

    // Split even and odd components
    List<_Complex> even = List.generate(n ~/ 2, (i) => buffer[i * 2]);
    List<_Complex> odd = List.generate(n ~/ 2, (i) => buffer[i * 2 + 1]);

    _cooleyTukeyFFT(even);
    _cooleyTukeyFFT(odd);

    // Combine stages using twiddle factors
    for (int k = 0; k < n ~/ 2; k++) {
      double th = -2 * math.pi * k / n;
      _Complex twiddle = _Complex(math.cos(th), math.sin(th)) * odd[k];
      buffer[k] = even[k] + twiddle;
      buffer[k + n ~/ 2] = even[k] - twiddle;
    }
  }

  Future<void> _stopSignalCapture() async {
    await _audioStreamSubscription?.cancel();
    await _audioRecorder.stop();
    setState(() {
      _isAnalyzing = false;
      _processedSpectralMagnitudes = List.filled(fftSize ~/ 2, -60.0);
    });
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _audioStreamSubscription?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0C),
      appBar: AppBar(
        title: const Text(
          'Academic FFT Spectrum Analyzer',
          style: TextStyle(fontFamily: 'monospace'),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF121214),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 24.0,
              ),
              child: CustomPaint(
                painter: AdvancedSpectrumPainter(_processedSpectralMagnitudes),
                size: Size.infinite,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24.0),
            color: const Color(0xFF121214),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton.extended(
                  onPressed: _toggleAnalysis,
                  backgroundColor: _isAnalyzing
                      ? Colors.redAccent
                      : Colors.tealAccent,
                  label: Text(
                    _isAnalyzing ? 'HALT ACQUISITION' : 'START ACQUISITION',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  icon: Icon(
                    _isAnalyzing ? Icons.stop : Icons.analytics,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Academic CustomPainter Rendering Engine
class AdvancedSpectrumPainter extends CustomPainter {
  final List<double> magnitudes;
  AdvancedSpectrumPainter(this.magnitudes);

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    // Draw Gridlines representing standard scientific intervals (-10dB steps)
    final Paint gridPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= 6; i++) {
      double yCoord = (height / 6) * i;
      canvas.drawLine(Offset(0, yCoord), Offset(width, yCoord), gridPaint);
    }

    if (magnitudes.isEmpty) return;

    final Paint barPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.cyanAccent, Colors.blueAccent, Colors.indigo],
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;

    final double barWidth = width / magnitudes.length;

    for (int i = 0; i < magnitudes.length; i++) {
      // Map dB scale [-60, 0] to dynamic pixel coordinates [0, height]
      double normalizedDb =
          (magnitudes[i] + 60.0) / 60.0; // Converts scale bounds to [0.0, 1.0]
      double barHeight = normalizedDb.clamp(0.0, 1.0) * height;

      double x = i * barWidth;
      double y = height - barHeight;

      canvas.drawRect(
        Rect.fromLTWH(x, y, barWidth * 0.85, barHeight),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant AdvancedSpectrumPainter oldDelegate) {
    return oldDelegate.magnitudes != magnitudes;
  }
}

// Mathematical Helper Structure for Handling Complex Numbers
class _Complex {
  final double real;
  final double imaginary;

  _Complex(this.real, this.imaginary);

  double get magnitude => math.sqrt(real * real + imaginary * imaginary);

  _Complex operator +(_Complex other) =>
      _Complex(real + other.real, imaginary + other.imaginary);

  _Complex operator -(_Complex other) =>
      _Complex(real - other.real, imaginary - other.imaginary);

  _Complex operator *(_Complex other) => _Complex(
    real * other.real - imaginary * other.imaginary,
    real * other.imaginary + imaginary * other.real,
  );
}
