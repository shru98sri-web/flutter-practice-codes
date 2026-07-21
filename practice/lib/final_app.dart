import 'package:flutter/material.dart';
import 'package:practice/audio_signal.dart';
import 'package:practice/ising_model.dart';
import 'package:practice/lens.dart';
import 'package:practice/plot_graph.dart';
import 'package:practice/spectrum_chart.dart';
import 'package:practice/zemax_clone.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      home: CorporateWizard(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CorporateWizard extends StatefulWidget {
  @override
  _CorporateWizardState createState() => _CorporateWizardState();
}

class _CorporateWizardState extends State<CorporateWizard> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // The array of pages
  final List<Widget> _pages = [
    RayTracingApp(),
    ZemaxCloneApp(),
    OriginCsvApp(),
    SpectrumApp(),
    PostgraduateSpectrumApp(),
    IsingApp(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Corporate Dashboard'),
        backgroundColor: Colors.blueGrey,
      ),
      body: PageView(
        controller: _pageController,
        children: _pages,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        backgroundColor: Colors.blueGrey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.lens_blur_rounded),
            label: 'Lens Tracer App',
            backgroundColor: Colors.black87,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lens_outlined),
            label: 'Lens Refractive Index',
            backgroundColor: Colors.black87,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_graph),
            label: 'Plotter',
            backgroundColor: Colors.black87,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.graphic_eq_outlined),
            label: 'Spectrum Plotter',
            backgroundColor: Colors.black87,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.speaker),
            label: 'Spectrum',
            backgroundColor: Colors.black87,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.ac_unit),
            label: 'Stats Plotter',
            backgroundColor: Colors.black87,
          ),
        ],
      ),
    );
  }
}
