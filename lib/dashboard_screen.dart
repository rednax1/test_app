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
      title: 'Metal Gear Greenhouse',
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'RobotoMono',
        scaffoldBackgroundColor: const Color(0xFF1A2321),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3A5C3A),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
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
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    _requestNotificationPermissions();
  }

  // Request notification permissions for iOS/macOS and Android 13+
  Future<void> _requestNotificationPermissions() async {
    // iOS/macOS
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Android 13+
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'greenhouse_channel',
      'Greenhouse Alerts',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      color: Color(0xFF3A5C3A),
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
    bool shouldTurnOn = (humidity < 40 || temperature > 30 || soilMoisture < 50);

    if (shouldTurnOn && !sprinklerOn) {
      String reason = '';
      if (humidity < 40) {
        reason = 'Low Humidity';
      } else if (temperature > 30) {
        reason = 'High Temperature';
      } else if (soilMoisture < 50) {
        reason = 'Low Soil Moisture';
      }

      _showNotification(
        'Sprinkler Activated',
        'Sprinkler turned ON due to $reason.',
      );
    }

    setState(() {
      sprinklerOn = shouldTurnOn;
    });
  }

  Color get hudGreen => const Color(0xFF3AFF36);
  Color get hudOrange => const Color(0xFFFFA726);

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
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF22332D),
        border: Border.all(color: hudGreen, width: 2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: hudGreen.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 30),
                const SizedBox(width: 16),
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: hudGreen,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    color: hudOrange,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbColor: hudOrange,
                activeTrackColor: hudGreen,
                inactiveTrackColor: Colors.white24,
                overlayColor: hudGreen.withOpacity(0.2),
                trackHeight: 4,
              ),
              child: Slider(
                value: sliderValue,
                min: min,
                max: max,
                divisions: (max - min).toInt(),
                label: value,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSprinklerStatusIndicator() {
    final Color borderColor = sprinklerOn ? hudGreen : Colors.redAccent;
    final Color textColor = sprinklerOn ? hudGreen : Colors.redAccent;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF22332D),
        border: Border.all(color: borderColor, width: 3),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          Icons.spa,
          color: textColor,
          size: 32,
        ),
        title: Text(
          sprinklerOn ? 'SPRINKLER: ACTIVE' : 'SPRINKLER: INACTIVE',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: 2,
            fontFamily: 'RobotoMono',
          ),
        ),
      ),
    );
  }

  Widget _buildManualControl() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF22332D),
        border: Border.all(color: hudGreen, width: 2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: hudGreen.withOpacity(0.15),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.settings_remote, color: hudOrange, size: 28),
                const SizedBox(width: 10),
                Text(
                  'MANUAL SPRINKLER CONTROL',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: hudGreen,
                    letterSpacing: 2,
                    fontFamily: 'RobotoMono',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: Text(
                sprinklerOn ? 'ACTIVE' : 'INACTIVE',
                style: TextStyle(
                  fontSize: 16,
                  color: sprinklerOn ? hudGreen : Colors.redAccent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  fontFamily: 'RobotoMono',
                ),
              ),
              value: sprinklerOn,
              activeColor: hudGreen,
              inactiveThumbColor: Colors.redAccent,
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
            const SizedBox(height: 6),
            Text(
              'Toggle sprinkler manually (overrides auto).',
              style: TextStyle(
                fontSize: 13,
                color: hudGreen,
                fontFamily: 'RobotoMono',
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHudHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 48, left: 24, right: 24, bottom: 18),
      decoration: const BoxDecoration(
        color: Color(0xFF22332D),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(18),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF3AFF36),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SMART GREENHOUSE',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: hudGreen,
              letterSpacing: 4,
              fontFamily: 'RobotoMono',
              shadows: [
                Shadow(
                  color: hudGreen.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Smart Tomato Monitoring',
            style: TextStyle(
              fontSize: 14,
              color: hudOrange,
              fontFamily: 'RobotoMono',
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHudHeader(),
          const SizedBox(height: 18),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildSensorCard(
                    icon: Icons.water_drop,
                    label: 'Humidity',
                    value: '${humidity.toStringAsFixed(1)}%',
                    color: hudGreen,
                    sliderValue: humidity,
                    min: 0,
                    max: 100,
                    onChanged: (v) {
                      setState(() {
                        humidity = v;
                        updateSprinklerStatus();
                      });
                    },
                  ),
                  _buildSensorCard(
                    icon: Icons.thermostat,
                    label: 'Temperature',
                    value: '${temperature.toStringAsFixed(1)}°C',
                    color: hudOrange,
                    sliderValue: temperature,
                    min: -10,
                    max: 50,
                    onChanged: (v) {
                      setState(() {
                        temperature = v;
                        updateSprinklerStatus();
                      });
                    },
                  ),
                  _buildSensorCard(
                    icon: Icons.grass,
                    label: 'Soil Moisture',
                    value: '${soilMoisture.toStringAsFixed(1)}%',
                    color: hudGreen,
                    sliderValue: soilMoisture,
                    min: 0,
                    max: 100,
                    onChanged: (v) {
                      setState(() {
                        soilMoisture = v;
                        updateSprinklerStatus();
                      });
                    },
                  ),
                  _buildSprinklerStatusIndicator(),
                  _buildManualControl(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension on AndroidFlutterLocalNotificationsPlugin? {
  requestPermission() {}
}
