import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

// Top-level background message handler
Future<void> _backgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'Flutter Demo', home: Home());
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  // Safely handle async initialization outside of initState
  Future<void> _initializeNotifications() async {
    await _notificationService.requestNotificationPermission();
    String? token = await _notificationService.getFcmToken();
    print("FCM Token initialized in UI: $token");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Push Notification')),
      body: const Center(child: Text('This is push notification tutorial')),
    );
  }
}

class NotificationService {
  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Requests push notification permissions from the user
  Future<void> requestNotificationPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      criticalAlert: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Permission granted by user');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('Permission granted provisionally');
    } else {
      print('Permission denied or restricted by user');
    }
  }

  // Completes the missing FCM token retrieval method
  Future<String?> getFcmToken() async {
    try {
      String? token = await messaging.getToken();
      print("FCM Token: $token");
      return token;
    } catch (e) {
      print("Error fetching FCM token: $e");
      return null;
    }
  }
}
