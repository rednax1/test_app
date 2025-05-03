import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

// This ValueNotifier controls the theme mode globally.
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.dark);

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

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
            primarySwatch: Colors.green,
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
          home: const SmartGreenhouseApp(),
        );
      },
    );
  }
}
