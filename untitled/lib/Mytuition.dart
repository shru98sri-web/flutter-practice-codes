// import 'package:flutter/material.dart';
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       home: ImageSwitcherScreen(),
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }
//
// class ImageSwitcherScreen extends StatefulWidget {
//   const ImageSwitcherScreen({super.key});
//
//   @override
//   State<ImageSwitcherScreen> createState() => _ImageSwitcherScreenState();
// }
//
// class _ImageSwitcherScreenState extends State<ImageSwitcherScreen> {
//   // १. फोटोंच्या URL ची लिस्ट
//   final List<String> _images = [
//     'picsum.photos',
//     'picsum.photos',
//     'picsum.photos',
//     'picsum.photos',
//   ];
//
//   // २. सध्याच्या फोटोचा इंडेक्स (Index)
//   int _currentIndex = 0;
//
//   // ३. फोटो बदलणारे फंक्शन
//   void _changeImage() {
//     setState(() {
//       // लिस्ट संपल्यावर पुन्हा पहिल्या फोटोपासून (0) सुरुवात होईल
//       _currentIndex = (_currentIndex + 1) % _images.length;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('इमेज स्विचर (Image Switcher)'),
//         backgroundColor: Colors.blue,
//       ),
//       body: Center(
//         child: GestureDetector(
//           onTap: _changeImage, // क्लिक केल्यावर फंक्शन कॉल होईल
//           child: Container(
//             width: 300,
//             height: 300,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(15),
//               boxShadow: const [
//                 BoxShadow(
//                   color: Colors.black26,
//                   blurRadius: 8,
//                   offset: Offset(0, 4),
//                 )
//               ],
//             ),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(15),
//               child: Image.network(
//                 _images[_currentIndex],
//                 fit: BoxFit.cover,
//                 // फोटो लोड होईपर्यंत दाखवण्यासाठी इंडिकेटर
//                 loadingBuilder: (context, child, loadingProgress) {
//                   if (loadingProgress == null) return child;
//                   return const Center(child: CircularProgressIndicator());
//                 },
//                 // फोटो लोड न झाल्यास एरर दाखवण्यासाठी
//                 errorBuilder: (context, error, stackTrace) {
//                   return const Center(child: Icon(Icons.error, size: 50));
//                 },
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
