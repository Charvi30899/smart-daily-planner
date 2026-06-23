import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:logging/logging.dart';

import 'app_theme.dart';
import 'firebase_options.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Log genui's A2UI parsing + validation to the console so we can see exactly
  // what the model emits. Remove or lower the level for production.
  final logger = configureLogging(level: Level.ALL);
  logger.onRecord.listen((r) => debugPrint('[${r.loggerName}] ${r.message}'));

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SmartDailyPlannerApp());
}

class SmartDailyPlannerApp extends StatelessWidget {
  const SmartDailyPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: kPrimary,
      primary: kPrimary,
      secondary: kSecondary,
      surface: kSurface,
    );

    return MaterialApp(
      title: 'Smart Daily Planner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: kBg,
        textSelectionTheme: const TextSelectionThemeData(cursorColor: kPrimary),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: kSurface,
          elevation: 3,
          height: 64,
          // Clean, minimal: icons only.
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          indicatorColor: kPrimary.withValues(alpha: 0.12),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected ? kPrimary : kTextSecondary,
              size: 26,
            );
          }),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
