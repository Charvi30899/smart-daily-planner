import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

import 'app_theme.dart';
import 'chat_input_bar.dart';
import 'message_bubble.dart';
import 'plan_container.dart';
import 'typing_indicator.dart';

/// A chat message with its send/receive time.
typedef ChatEntry = ({String text, bool isUser, DateTime time});

/// The "Today" tab: a pinned PlanCard container at the top, the chat thread in
/// the middle, and the input bar at the bottom.
///
/// This is a pure view — all genui state lives in HomeScreen and is passed in.
class TodayTab extends StatelessWidget {
  final SurfaceController surfaceController;
  final String? pinnedSurfaceId;
  final List<ChatEntry> messages;
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
    final showEmptyChat = messages.isEmpty && !isLoading;

    return Column(
      children: [
        // Pinned plan area — animates between empty state and the plan card.
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: pinnedSurfaceId != null
                ? PlanContainer(
                    key: ValueKey('plan_$pinnedSurfaceId'),
                    surfaceController: surfaceController,
                    surfaceId: pinnedSurfaceId!,
                  )
                : const EmptyPlanState(key: ValueKey('empty')),
          ),
        ),

        // Chat thread (with trailing typing indicator while loading).
        Expanded(
          child: showEmptyChat
              ? const _EmptyChatState()
              : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: messages.length + (isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= messages.length) {
                      return const TypingIndicator();
                    }
                    final msg = messages[index];
                    return MessageBubble(
                      text: msg.text,
                      isUser: msg.isUser,
                      time: msg.time,
                    );
                  },
                ),
        ),

        ChatInputBar(
          controller: textController,
          enabled: !isLoading,
          canSend: canSend,
          onSend: onSend,
        ),
      ],
    );
  }
}

/// Centered empty state for the chat thread before any messages exist.
class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 44,
              color: kPrimary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 14),
            const Text(
              'Tell me what you need to do today',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.5, height: 1.4, color: kTextSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
