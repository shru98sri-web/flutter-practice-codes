// import 'package:flutter/material.dart';
//
// class Tuitionapp extends StatefulWidget {
//   const Tuitionapp({super.key}); // Fixed: super.key
//
//   @override
//   State<Tuitionapp> createState() => _TuitionappState();
// }
//
// class _TuitionappState extends State<Tuitionapp> {
//   // 1. Create a variable to hold the current icon
//   IconData displayIcon = Icons.backpack;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Subject'),
//         centerTitle: true,
//         backgroundColor: Colors.black26,
//       ),
//       body: Column(
//         children: [
//           // 2. Use the variable here
//           Center(child: Icon(displayIcon, size: 50)),
//
//           ElevatedButton(
//             onPressed: () {
//               // 3. Use setState to update the UI
//               setState(() {
//                 displayIcon = Icons.icecream;
//               });
//             },
//             child: const Text('Ice Cream'),
//           ),
//
//           ElevatedButton(
//             onPressed: () {
//               setState(() {
//                 displayIcon = Icons.coffee;
//               });
//             },
//             child: const Text('Coffee'),
//           ),
//         ],
//       ),
//     );
//   }
// }