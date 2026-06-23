import 'package:flutter/material.dart';

import 'plan_card.dart';

/// Feature 2 — a compact white circular progress ring showing the percentage
/// of tasks completed, sized to sit on the right of the app bar. Listens to
/// [planProgressNotifier], so it updates live as tasks are ticked off.
class AppBarProgressRing extends StatelessWidget {
  const AppBarProgressRing({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<({int completed, int total})>(
      valueListenable: planProgressNotifier,
      builder: (context, progress, _) {
        if (progress.total == 0) return const SizedBox.shrink();
        final pct = progress.completed / progress.total;
        return Padding(
          padding: const EdgeInsets.only(right: 14),
          child: Tooltip(
            message: '${progress.completed} of ${progress.total} tasks done',
            child: SizedBox(
              width: 40,
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 38,
                    height: 38,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: pct),
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeOut,
                      builder: (context, value, _) => CircularProgressIndicator(
                        value: value,
                        strokeWidth: 4,
                        backgroundColor: Colors.white.withValues(alpha: 0.28),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ),
                  Text(
                    '${(pct * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
