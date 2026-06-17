import 'package:flutter/material.dart';

/// Brand palette: deep indigo + soft purple accents on white.
const Color kIndigo = Color(0xFF4F46E5);
const Color kPurple = Color(0xFF7C3AED);
const Color kScaffoldBg = Color(0xFFF6F6FB);

/// Shared indigo -> purple gradient used by the app bar, splash logo, etc.
const LinearGradient kAppGradient = LinearGradient(
  colors: [kIndigo, kPurple],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Formats a date like "Monday, June 9" without needing the intl package.
String prettyDate(DateTime d) {
  const days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
}

/// A fade page transition for smooth navigation between screens.
Route<T> fadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}
