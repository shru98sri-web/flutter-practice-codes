import 'package:flutter/material.dart';

import 'home.dart';

// Future<void> _backgroundMessageHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
// }
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//   FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);
//   runApp(const MyAppush());
// }

class MyAppush extends StatelessWidget {
  const MyAppush({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(title: 'Flutter Demo', home: Home());
  }
}

// class Home extends StatefulWidget {
//   const Home({super.key});
//
//   @override
//   State<Home> createState() => _HomeState();
//   // TODO: implement createState
// }
//
// class _HomeState extends State<Home> {
//   @override
//   void initState() {
//     NotificationService notificationService = NotificationService();
//     notificationService.requestNotificationPermission();
//     notificationService.getFcmToken();
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // TODO: implement build
//     return Scaffold(
//       appBar: AppBar(title: Text('push notification')),
//       body: Center(child: Text('This is push notification tutorial')),
//     );
//   }
// }
//
// class NotificationService {
//   FirebaseMessaging messaging = FirebaseMessaging.instance;
//
//   void requestNotificationPermission() async {
//     NotificationSettings settings = await messaging.requestPermission(
//       alert: true,
//       badge: true,
//       criticalAlert: true,
//       sound: true,
//     );
//     if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//       print('permission granted by user');
//     } else if (settings.authorizationStatus ==
//         AuthorizationStatus.provisional) {
//       print('permission granted provissionally');
//     } else {
//       print('permission decided by user');
//     }
//   }
//
//   Future<String?> getFcmToken() async {
//     String? token = await messaging.getToken();
//     print('Token $token');
//     return token;
//   }
// }
