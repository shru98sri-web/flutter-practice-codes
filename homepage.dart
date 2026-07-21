import 'package:flutter/material.dart';
import 'package:physics_one/femtosecond_graph.dart';

import 'basic_radar.dart';
import 'lidar.dart';

void main() => runApp(const PhotonicsApp());

class PhotonicsApp extends StatelessWidget {
  const PhotonicsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F13),
        primaryColor: Colors.blueAccent,
        cardColor: const Color(0xFF181820),
        drawerTheme: const DrawerThemeData(
          backgroundColor: const Color(0xFF14141A),
        ),
      ),
      // Set the dashboard as the starting home route
      home: const PhotonicsControlPage(),
    );
  }
}

// ==========================================
// MAIN SCREEN: PHOTONICS SOFTWARE DASHBOARD
// ==========================================
class PhotonicsControlPage extends StatefulWidget {
  const PhotonicsControlPage({super.key});

  @override
  State<PhotonicsControlPage> createState() => _PhotonicsControlPageState();
}

class _PhotonicsControlPageState extends State<PhotonicsControlPage> {
  String statusTerminalMessage =
      "System Ready. Open the drawer to access pages.";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Photonics Software Suite",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF14141A),
        centerTitle: true,
      ),

      // The Menu Drawer handles routing actions
      drawer: Drawer(
        child: Column(
          children: [
            const UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF1A1A26)),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.blur_on, size: 36, color: Colors.white),
              ),
              accountName: Text(
                "Optics Core Engine v4.2",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text("system_router_active.io"),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerTile(Icons.biotech, "Basic radar", () {
                    Navigator.pop(context); // Close Drawer first
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RadarScreen(),
                      ),
                    );
                  }),
                  _buildDrawerTile(Icons.waves, "LIDAR ", () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PointCloudApp(),
                      ),
                    );
                  }),
                  _buildDrawerTile(
                    Icons.show_chart,
                    "Femtosecond Laser Gain Simulator",
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LaserGainApp(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              color: const Color(0xFF14141A),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Icon(Icons.apps, size: 64, color: Colors.blueAccent),
                    const SizedBox(height: 16),
                    Text(
                      statusTerminalMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.greenAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      onTap: onTap,
    );
  }
}
