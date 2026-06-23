import 'package:flutter/material.dart';

import 'app_theme.dart';

/// The chat input bar: rounded top corners, subtle top shadow, a pill text
/// field, and an indigo circular send button that scales down on press and
/// greys out while the AI is loading.
class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool canSend;
  final void Function(String text) onSend;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.enabled,
    required this.canSend,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: const BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, -2)),
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
                style: const TextStyle(fontSize: 15, color: kTextPrimary),
                decoration: InputDecoration(
                  hintText: 'Tell me what you need to do today...',
                  hintStyle: const TextStyle(color: kTextSecondary),
                  filled: true,
                  fillColor: kInputFill,
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
                    borderSide: const BorderSide(color: kPrimary, width: 1.6),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _SendButton(
              enabled: canSend,
              onTap: () => onSend(controller.text),
            ),
          ],
        ),
      ),
    );
  }
}

/// Indigo circular send button that scales down briefly while pressed.
class _SendButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _SendButton({required this.enabled, required this.onTap});

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: enabled ? widget.onTap : null,
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: enabled ? kPrimary : kPrimary.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.arrow_upward_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}
