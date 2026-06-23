import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// Central design system. NO palette colors are hardcoded anywhere else in the
/// app — every screen references these constants and text styles.
/// ---------------------------------------------------------------------------

// ---- Brand palette ---------------------------------------------------------
const Color kPrimary = Color(0xFF3730A3); // deep indigo
const Color kSecondary = Color(0xFF7C3AED); // violet
const Color kAccent = Color(0xFF06B6D4); // cyan
const Color kBg = Color(0xFFF8FAFC); // off-white app background
const Color kSurface = Color(0xFFFFFFFF); // cards / sheets
const Color kTextPrimary = Color(0xFF0F172A); // slate-900
const Color kTextSecondary = Color(0xFF64748B); // slate-500

// Supporting tones.
const Color kSplashBg = Color(0xFF1E1B4B); // dark indigo splash
const Color kBorder = Color(0xFFE2E8F0); // hairline borders
const Color kInputFill = Color(0xFFF1F5F9); // text field fill
const Color kShadow = Color(0x14000000); // 8% black shadow

// ---- Task priority colors --------------------------------------------------
const Color kPriorityHigh = Color(0xFFEF4444); // red
const Color kPriorityMedium = Color(0xFFF59E0B); // amber
const Color kPriorityLow = Color(0xFF10B981); // green

/// Maps a priority keyword to its badge color.
Color priorityColor(String priority) {
  switch (priority) {
    case 'high':
      return kPriorityHigh;
    case 'medium':
      return kPriorityMedium;
    case 'low':
      return kPriorityLow;
    default:
      return kTextSecondary;
  }
}

// ---- Gradients -------------------------------------------------------------
/// Primary indigo -> violet gradient used by the app bar, buttons, logo.
/// Left to right per the app bar spec.
const LinearGradient kAppGradient = LinearGradient(
  colors: [kPrimary, kSecondary],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

/// Diagonal variant for large surfaces (logos, splash composition).
const LinearGradient kBrandGradientDiagonal = LinearGradient(
  colors: [kPrimary, kSecondary],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ---- Shared shadows --------------------------------------------------------
const List<BoxShadow> kCardShadow = [
  BoxShadow(color: kShadow, blurRadius: 20, offset: Offset(0, 8)),
];

const List<BoxShadow> kSoftShadow = [
  BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
];

// ---- Text styles -----------------------------------------------------------
abstract final class AppText {
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 0.2,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: kTextPrimary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.bold,
    color: kTextPrimary,
  );

  static const TextStyle task = TextStyle(fontSize: 14, color: kTextPrimary);

  static const TextStyle body = TextStyle(
    fontSize: 14.5,
    height: 1.4,
    color: kTextPrimary,
  );

  static const TextStyle secondary = TextStyle(
    fontSize: 13,
    height: 1.35,
    color: kTextSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 10,
    color: kTextSecondary,
  );

  static const TextStyle badge = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.3,
  );
}

// ---- Date / time helpers (no intl package) ---------------------------------
const List<String> _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const List<String> _months = [
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

/// Formats a date like "Monday, June 9".
String prettyDate(DateTime d) =>
    '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}';

/// Formats a short date like "Jun 9".
String shortDate(DateTime d) => '${_months[d.month - 1].substring(0, 3)} ${d.day}';

/// Formats a clock time like "3:07 PM".
String prettyTime(DateTime d) {
  final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final minute = d.minute.toString().padLeft(2, '0');
  final period = d.hour < 12 ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

// ---- Page transitions (Navigator, no GoRouter) -----------------------------
/// A fade page transition.
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

/// A horizontal slide (+ fade) page transition.
Route<T> slideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}
