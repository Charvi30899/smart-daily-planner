import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

import 'app_theme.dart';
import 'message_bubble.dart';

/// The "Today" tab: a styled PlanCard container at the top, the chat thread in
/// the middle, and the input bar at the bottom (above the bottom nav).
///
/// This is a pure view — all genui state lives in HomeScreen and is passed in.
class TodayTab extends StatelessWidget {
  final SurfaceController surfaceController;
  final String? pinnedSurfaceId;
  final List<({String text, bool isUser})> messages;
  final bool isLoading;
  final TextEditingController textController;
  final ScrollController scrollController;
  final bool canSend;
  final void Function(String text) onSend;

  const TodayTab({
    super.key,
    required this.surfaceController,
    required this.pinnedSurfaceId,
    required this.messages,
    required this.isLoading,
    required this.textController,
    required this.scrollController,
    required this.canSend,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Pinned plan area (styled container) — animates between empty / plan.
        // Capped to a fraction of the screen so a long plan scrolls inside the
        // card instead of overflowing the column.
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.42,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: pinnedSurfaceId != null
                  ? _PlanContainer(
                      key: ValueKey('plan_$pinnedSurfaceId'),
                      surfaceController: surfaceController,
                      surfaceId: pinnedSurfaceId!,
                    )
                  : const _EmptyPlanState(key: ValueKey('empty')),
            ),
          ),
        ),

        // Chat thread (with trailing typing indicator while loading).
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: messages.length + (isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= messages.length) {
                return const _TypingIndicator();
              }
              final msg = messages[index];
              return MessageBubble(text: msg.text, isUser: msg.isUser);
            },
          ),
        ),

        _InputBar(
          controller: textController,
          enabled: !isLoading,
          canSend: canSend,
          onSend: onSend,
        ),
      ],
    );
  }
}

/// White card with shadow + rounded corners wrapping the genui [Surface].
/// Provides the "Today's Plan" header with today's date.
class _PlanContainer extends StatelessWidget {
  final SurfaceController surfaceController;
  final String surfaceId;

  const _PlanContainer({
    super.key,
    required this.surfaceController,
    required this.surfaceId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header.
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: kAppGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.event_note_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Today's Plan",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1B4B),
                      ),
                    ),
                    Text(
                      prettyDate(DateTime.now()),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),

          // The genui-rendered plan (task rows). Flexible + a scroll view so a
          // long plan scrolls within the capped card instead of overflowing.
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
              child: Surface(
                key: ValueKey('surface_$surfaceId'),
                surfaceContext: surfaceController.contextFor(surfaceId),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Illustration-style empty state shown before any plan exists.
class _EmptyPlanState extends StatelessWidget {
  const _EmptyPlanState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kIndigo.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: kIndigo.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: kIndigo,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Start chatting to plan your day',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E1B4B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tell me your tasks and I\'ll organize them by priority.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.35,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

/// AI "typing" bubble: a sparkle avatar + three pulsing dots.
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 5, 12, 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: kIndigo.withValues(alpha: 0.12),
            child: const Icon(Icons.auto_awesome, size: 16, color: kIndigo),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const _PulsingDots(),
          ),
        ],
      ),
    );
  }
}

/// Three dots that pulse in a staggered wave.
class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Staggered sine wave -> opacity + slight vertical bob.
            final phase = (_controller.value + i * 0.18) % 1.0;
            final wave = (math.sin(phase * 2 * math.pi) + 1) / 2; // 0..1
            return Padding(
              padding: EdgeInsets.only(right: i == 2 ? 0 : 6),
              child: Transform.translate(
                offset: Offset(0, -2 * wave),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: kIndigo.withValues(alpha: 0.35 + 0.55 * wave),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// White input bar with a pill text field and an indigo arrow send button.
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool canSend;
  final void Function(String text) onSend;

  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.canSend,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: canSend ? onSend : null,
                decoration: InputDecoration(
                  hintText: 'Tell me what you need to do today...',
                  filled: true,
                  fillColor: const Color(0xFFF1F1F8),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: const BorderSide(color: kIndigo, width: 1.6),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            AnimatedScale(
              scale: canSend ? 1.0 : 0.88,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              child: Material(
                color: canSend ? kIndigo : kIndigo.withValues(alpha: 0.4),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: canSend ? () => onSend(controller.text) : null,
                  child: const Padding(
                    padding: EdgeInsets.all(13),
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
