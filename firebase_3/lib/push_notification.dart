//
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

// Global Navigation Key to handle routing without BuildContext
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // 1. Request permission (Runs asynchronously without blocking the UI)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    }

    // 2. Fetch FCM Token
    String? token = await _fcm.getToken(
      vapidKey:
          "BPPiMr6BTgGOfhk3DGu1r4KNHXD9LvilILAm7OFON3rRGMYZkRJL9kdFz2RW6X3jI6L7wf-wUZGHjiXBA4nzjiM",
    );
    print("FCM Device Token: $token");

    // 3. Initialize background & terminated handlers
    initPushNotifications();
  }

  void initPushNotifications() {
    // STATE 1: Foreground - App is open and active
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Foreground Message received: ${message.notification?.title}");
    });

    // STATE 2: Background - App minimized, user clicks the notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("App opened from background: ${message.data}");
      _handleNavigation(message);
    });

    // STATE 3: Terminated - App completely closed, user clicks the notification
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print("App launched from terminated state: ${message.data}");
        // Slight delay to ensure the widget tree and navigator are fully mounted
        Future.delayed(const Duration(seconds: 1), () {
          _handleNavigation(message);
        });
      }
    });
  }

  // Handle screen routing based on data payload
  void _handleNavigation(RemoteMessage message) {
    if (message.data['type'] == 'screen-2') {
      navigatorKey.currentState?.pushNamed('/screen-2');
    }
  }
}

// STATE 4: Background handler required to run in an isolated top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling background message ID: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Register the global key here
      initialRoute: '/screen-2',
      routes: {
        '/': (context) => const HomeScreen(),
        '/screen-2': (context) => const SecondScreen(),
      },
    );
  }
}

// Home Screen: This displays immediately without getting blocked
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize notification service in the background after the screen mounts
    NotificationService().initNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Firebase Push Notifications Home')),
    );
  }
}

// Second Screen: Opens dynamically when tapping a notification payload containing {'type': 'screen-2'}
class SecondScreen extends StatelessWidget {
  const SecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Second Screen")),
      body: const Center(child: Text("Welcome to the Second Screen!")),
    );
  }
}
