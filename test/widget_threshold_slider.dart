import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() {
  runApp(const SmartGreenhouseApp());
}

class SmartGreenhouseApp extends StatelessWidget {
  const SmartGreenhouseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Greenhouse',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFFB2F2BB), // Light green
        scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Light grey
      ),
      home: const GreenhouseHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GreenhouseHomePage extends StatefulWidget {
  const GreenhouseHomePage({super.key});

  @override
  State<GreenhouseHomePage> createState() => _GreenhouseHomePageState();
}

class _GreenhouseHomePageState extends State<GreenhouseHomePage> {
  double humidity = 50.0;
  double temperature = 25.0;
  double soilMoisture = 50.0;
  bool sprinklerOn = false;

  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'greenhouse_channel',
      'Greenhouse Alerts',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'greenhouse_alert',
    );
  }

  void updateSprinklerStatus() {
    bool shouldTurnOn = (humidity < 40 || temperature > 30 || soilMoisture < 30);

    if (shouldTurnOn != sprinklerOn) {
      String reason = '';
      if (humidity < 40) {
        reason = 'Low Humidity';
      } else if (temperature > 30) {
        reason = 'High Temperature';
      } else if (soilMoisture < 30) {
        reason = 'Low Soil Moisture';
      }

      if (shouldTurnOn) {
        _showNotification(
          'Sprinkler Activated',
          'Sprinkler turned ON due to $reason.',
        );
      } else {
        _showNotification(
          'Sprinkler Deactivated',
          'Sprinkler turned OFF as conditions are optimal.',
        );
      }

      setState(() {
        sprinklerOn = shouldTurnOn;
      });
    }
  }

  Widget _buildSensorCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required double sliderValue,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(fontSize: 20, color: color),
                ),
              ],
            ),
            Slider(
              value: sliderValue,
              min: min,
              max: max,
              divisions: (max - min).toInt(),
              label: value,
              activeColor: color,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSprinklerStatusIndicator() {
    return Card(
      color: sprinklerOn ? Colors.green[100] : Colors.red[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(
          Icons.spa,
          color: sprinklerOn ? Colors.green : Colors.red,
          size: 32,
        ),
        title: Text(
          sprinklerOn ? 'Sprinkler is ON' : 'Sprinkler is OFF',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: sprinklerOn ? Colors.green[900] : Colors.red[900],
          ),
        ),
      ),
    );
  }

  Widget _buildManualControl() {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.settings_remote, color: Colors.blueGrey, size: 32),
                const SizedBox(width: 12),
                const Text(
                  'Manual Sprinkler Control',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(
                sprinklerOn ? 'Sprinkler is ON' : 'Sprinkler is OFF',
                style: TextStyle(
                  fontSize: 18,
                  color: sprinklerOn ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              value: sprinklerOn,
              activeColor: Colors.green,
              inactiveThumbColor: Colors.red,
              onChanged: (val) {
                setState(() {
                  sprinklerOn = val;
                  _showNotification(
                    'Manual Control',
                    'Sprinkler turned ${val ? 'ON' : 'OFF'} manually.',
                  );
                });
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Use this switch to manually turn the sprinkler ON or OFF, regardless of automatic thresholds.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top Section with Light Green Background
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, left: 24, right: 24, bottom: 24),
            decoration: const BoxDecoration(
              color: Color(0xFFB2F2BB),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Greenhouse',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Monitor & control your plants with ease.',
                  style: TextStyle(fontSize: 16, color: Colors.green[800]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Sensor Cards
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _buildSensorCard(
                    icon: Icons.water_drop,
                    label: 'Humidity',
                    value: '${humidity.toStringAsFixed(1)}%',
                    color: Colors.blueAccent,
                    onChanged: (v) {
                      setState(() {
                        humidity = v;
                        updateSprinklerStatus();
                      });
                    },
                    sliderValue: humidity,
                    min: 0,
                    max: 100,
                  ),
                  _buildSensorCard(
                    icon: Icons.thermostat,
                    label: 'Temperature',
                    value: '${temperature.toStringAsFixed(1)}°C',
                    color: Colors.orangeAccent,
                    onChanged: (v) {
                      setState(() {
                        temperature = v;
                        updateSprinklerStatus();
                      });
                    },
                    sliderValue: temperature,
                    min: -10,
                    max: 50,
                  ),
                  _buildSensorCard(
                    icon: Icons.grass,
                    label: 'Soil Moisture',
                    value: '${soilMoisture.toStringAsFixed(1)}%',
                    color: Colors.brown,
                    onChanged: (v) {
                      setState(() {
                        soilMoisture = v;
                        updateSprinklerStatus();
                      });
                    },
                    sliderValue: soilMoisture,
                    min: 0,
                    max: 100,
                  ),
                  const SizedBox(height: 16),
                  _buildSprinklerStatusIndicator(),
                  const SizedBox(height: 32),
                  _buildManualControl(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
