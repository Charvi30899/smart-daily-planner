import 'package:flutter/material.dart';

import 'app_theme.dart';

/// The AI "typing" bubble: a 🤖 avatar + three vertically bouncing dots driven
/// by a single [AnimationController] with staggered phase offsets.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 5, 12, 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: kPrimary.withValues(alpha: 0.12),
            child: const Text('🤖', style: TextStyle(fontSize: 15)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: kBorder),
              boxShadow: kSoftShadow,
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    // Staggered bounce: each dot's phase is offset.
                    final t = (_controller.value + i * 0.18) % 1.0;
                    // A short hop: only the first ~40% of the cycle lifts.
                    final lift = t < 0.4
                        ? Curves.easeOut.transform(t / 0.4)
                        : (t < 0.8
                            ? 1 - Curves.easeIn.transform((t - 0.4) / 0.4)
                            : 0.0);
                    return Padding(
                      padding: EdgeInsets.only(right: i == 2 ? 0 : 6),
                      child: Transform.translate(
                        offset: Offset(0, -5 * lift),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: kPrimary.withValues(alpha: 0.4 + 0.5 * lift),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
