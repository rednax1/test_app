import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Global theme mode notifier
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.dark);

void main() {
  runApp(const SmartGreenhouseApp());
}

class SmartGreenhouseApp extends StatelessWidget {
  const SmartGreenhouseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Smart Greenhouse',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.light,
            fontFamily: 'RobotoMono',
            scaffoldBackgroundColor: const Color(0xFFF3F6F4),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3A5C3A),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            fontFamily: 'RobotoMono',
            scaffoldBackgroundColor: const Color(0xFF1A2321),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3A5C3A),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: mode,
          home: const GreenhouseHomePage(),
        );
      },
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
  List<double> soilMoistures = List.filled(6, 50.0);
  bool sprinklerOn = false;

  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  List<Map<String, String>> notifications = [];

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

  Future<void> _requestNotificationPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

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

    setState(() {
      notifications.insert(0, {
        'title': title,
        'body': body,
        'time': DateTime.now().toLocal().toString().substring(0, 19),
      });
    });
  }

  void updateSprinklerStatus() {
    bool anySoilDry = soilMoistures.any((sm) => sm < 50);
    bool shouldTurnOn = (humidity < 40 || temperature > 30 || anySoilDry);

    if (shouldTurnOn && !sprinklerOn) {
      String reason = '';
      if (humidity < 40) {
        reason = 'Low Humidity';
      } else if (temperature > 30) {
        reason = 'High Temperature';
      } else if (anySoilDry) {
        int idx = soilMoistures.indexWhere((sm) => sm < 50);
        reason = 'Low Soil Moisture (Sensor ${idx + 1})';
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

  Color get accentGreen => const Color(0xFF6DFE64);
  Color get accentOrange => const Color(0xFFFFB74D);
  Color get cardColor => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF22332D)
      : Colors.white;

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor:
          Theme.of(context).brightness == Brightness.dark ? const Color(0xFF22332D) : Colors.white,
      elevation: 0,
      title: Text(
        'Smart Greenhouse',
        style: TextStyle(
          fontFamily: 'RobotoMono',
          fontWeight: FontWeight.bold,
          fontSize: 22,
          letterSpacing: 1.5,
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.notifications, color: accentGreen),
          tooltip: 'Notifications',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AlertsPage(notifications: notifications),
              ),
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.account_circle, color: accentOrange),
          tooltip: 'Profile',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProfilePage(),
              ),
            );
          },
        ),
        IconButton(
          icon: Icon(
            themeModeNotifier.value == ThemeMode.dark ? Icons.wb_sunny : Icons.nights_stay,
            color: themeModeNotifier.value == ThemeMode.dark ? Colors.yellow : Colors.blueGrey,
          ),
          tooltip: themeModeNotifier.value == ThemeMode.dark
              ? 'Switch to Light Mode'
              : 'Switch to Dark Mode',
          onPressed: () {
            themeModeNotifier.value = themeModeNotifier.value == ThemeMode.dark
                ? ThemeMode.light
                : ThemeMode.dark;
          },
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8, left: 6),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: accentGreen, size: 22),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: TextStyle(
              color: accentGreen,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
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
      color: cardColor,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(width: 18),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    color: accentOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Slider(
              value: sliderValue,
              min: min,
              max: max,
              divisions: (max - min).toInt(),
              label: value,
              onChanged: onChanged,
              activeColor: color,
              inactiveColor: Colors.white24,
              thumbColor: accentOrange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoilMoistureMeters() {
    return Card(
      color: cardColor,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Soil Moisture Sensors', icon: Icons.grass),
            ...List.generate(soilMoistures.length, (i) {
              final value = soilMoistures[i];
              final barColor = value < 50 ? accentOrange : accentGreen;
              return GestureDetector(
                onTap: () async {
                  double? newValue = await showDialog<double>(
                    context: context,
                    builder: (context) {
                      double tempValue = value;
                      return AlertDialog(
                        backgroundColor: cardColor,
                        title: Text('Adjust Soil ${i + 1} Moisture'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Slider(
                              value: tempValue,
                              min: 0,
                              max: 100,
                              activeColor: barColor,
                              onChanged: (v) {
                                setState(() => tempValue = v);
                              },
                            ),
                            Text('${tempValue.toStringAsFixed(1)}%'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () => Navigator.pop(context),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentGreen,
                            ),
                            child: const Text('Set'),
                            onPressed: () => Navigator.pop(context, tempValue),
                          ),
                        ],
                      );
                    },
                  );
                  if (newValue != null) {
                    setState(() {
                      soilMoistures[i] = newValue;
                      updateSprinklerStatus();
                    });
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(Icons.grass, color: barColor, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Soil ${i + 1}',
                        style: TextStyle(
                          color: accentGreen,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: value / 100,
                          minHeight: 12,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(barColor),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${value.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: accentOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSprinklerStatusIndicator() {
    final Color borderColor = sprinklerOn ? accentGreen : Colors.redAccent;
    final Color textColor = sprinklerOn ? accentGreen : Colors.redAccent;
    return Card(
      color: cardColor,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor, width: 2),
      ),
      child: ListTile(
        leading: Icon(
          Icons.spa,
          color: textColor,
          size: 32,
        ),
        title: Text(
          sprinklerOn ? 'Sprinkler: ACTIVE' : 'Sprinkler: INACTIVE',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildManualControl() {
    return Card(
      color: cardColor,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.settings_remote, color: accentOrange, size: 26),
                const SizedBox(width: 10),
                Text(
                  'Manual Sprinkler Control',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: accentGreen,
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
                  color: sprinklerOn ? accentGreen : Colors.redAccent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              value: sprinklerOn,
              activeColor: accentGreen,
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
                color: accentGreen.withOpacity(0.7),
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 36, left: 24, right: 24, bottom: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: accentGreen.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 2),
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
              color: accentGreen,
              letterSpacing: 3,
              fontFamily: 'RobotoMono',
              shadows: [
                Shadow(
                  color: accentGreen.withOpacity(0.3),
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
              fontSize: 15,
              color: accentOrange,
              fontFamily: 'RobotoMono',
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                _buildSectionTitle('Environment'),
                _buildSensorCard(
                  icon: Icons.water_drop,
                  label: 'Humidity',
                  value: '${humidity.toStringAsFixed(1)}%',
                  color: accentGreen,
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
                  color: accentOrange,
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
                _buildSoilMoistureMeters(),
                _buildSprinklerStatusIndicator(),
                _buildManualControl(),
              ],
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

// Dummy AlertsPage for navigation (replace with your actual implementation)
class AlertsPage extends StatelessWidget {
  final List<Map<String, String>> notifications;
  const AlertsPage({required this.notifications, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alerts')),
      body: notifications.isEmpty
          ? const Center(child: Text('No alerts yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final n = notifications[index];
                return Card(
                  child: ListTile(
                    title: Text(n['title'] ?? ''),
                    subtitle: Text(n['body'] ?? ''),
                    trailing: Text(n['time'] ?? ''),
                  ),
                );
              },
            ),
    );
  }
}

// Dummy ProfilePage for navigation (replace with your actual implementation)
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(child: Text('Profile Page')),
    );
  }
}
