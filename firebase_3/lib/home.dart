import 'package:flutter/material.dart';

import 'main_push.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
  // TODO: implement createState
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    NotificationService notificationService = NotificationService();
    notificationService.requestNotificationPermission();
    notificationService.getFcmToken();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(title: Text('push notification')),
      body: Center(
        // child: Text('This is push notification tutorial')
        child: TextButton(
          onPressed: () => throw Exception(),
          child: const Text("Throw Test Exception"),
        ),
      ),
    );
  }
}
