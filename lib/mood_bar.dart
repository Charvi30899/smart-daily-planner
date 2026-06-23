import 'package:flutter/material.dart';

import 'app_theme.dart';

/// One selectable mood for the mood-based planning row (Feature 4).
class Mood {
  final String emoji;
  final String name;
  const Mood(this.emoji, this.name);
}

/// The five moods, low energy -> high energy.
const List<Mood> kMoods = [
  Mood('😴', 'Tired'),
  Mood('😐', 'Neutral'),
  Mood('🙂', 'Good'),
  Mood('💪', 'Energized'),
  Mood('🔥', 'On Fire'),
];

/// Feature 4 — the mood selector row, shown directly below the app bar on the
/// Today tab. The selected emoji sits in an indigo pill; its name animates in
/// below the row. Tapping pushes the index up via [onSelect].
class MoodBar extends StatelessWidget {
  final int selectedIndex;
  final bool enabled;
  final void Function(int index) onSelect;

  const MoodBar({
    super.key,
    required this.selectedIndex,
    required this.enabled,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedIndex >= 0 && selectedIndex < kMoods.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: const BoxDecoration(
        color: kSurface,
        boxShadow: kSoftShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(kMoods.length, (i) {
              final selected = i == selectedIndex;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: enabled ? () => onSelect(i) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: selected
                        ? kPrimary.withValues(alpha: 0.14)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? kPrimary : kBorder,
                      width: selected ? 1.8 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: enabled ? 1 : 0.45,
                    child: Text(
                      kMoods[i].emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
              );
            }),
          ),
          // Selected mood name fades in below the row.
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: hasSelection
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      kMoods[selectedIndex].name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: kPrimary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
