import 'dart:async';

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'onboarding_setup.dart';

/// Feature 1, Screen 1 — Splash. Dark indigo background with a brain+calendar
/// emoji composition, the app name in white, and a cyan subtitle. Fades and
/// slides in, then auto-navigates to onboarding after 2.5 seconds.
///
/// NOTE: Persisting "show only on first launch" needs a storage plugin such as
/// `shared_preferences`; under the no-new-packages rule it shows every cold
/// start.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.14),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    // Auto-advance to onboarding after 2.5s (Navigator, not GoRouter).
    _navTimer = Timer(const Duration(milliseconds: 2500), _goToOnboarding);
  }

  void _goToOnboarding() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(slideRoute(const QuickSetupScreen()));
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSplashBg,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Emoji composition (brain + calendar) on a gradient tile.
                Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    gradient: kBrandGradientDiagonal,
                    borderRadius: BorderRadius.circular(34),
                    boxShadow: [
                      BoxShadow(
                        color: kSecondary.withValues(alpha: 0.45),
                        blurRadius: 36,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🧠', style: TextStyle(fontSize: 64)),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('📅', style: TextStyle(fontSize: 30)),
                const SizedBox(height: 26),

                // App name.
                const Text(
                  'Smart Daily Planner',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle in cyan.
                const Text(
                  'Your AI partner for a productive day',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: kAccent,
                  ),
                ),
                const SizedBox(height: 40),

                // Subtle loading hint.
                SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation(
                      kAccent.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
