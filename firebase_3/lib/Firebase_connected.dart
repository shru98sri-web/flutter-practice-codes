import 'package:flutter/material.dart';

class MyAppfb extends StatelessWidget {
  const MyAppfb({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(body: Center(child: Text('Firebase Connected'))),
    );
  }
}
