import 'package:flutter/material.dart';

import 'app_theme.dart';

/// The "Settings" tab: app identity, info tiles, a "Clear today's plan" action,
/// and an "About GenUI" tile that opens an explainer bottom sheet.
class SettingsTab extends StatelessWidget {
  /// Resets the pinned plan (clears the displayed SurfaceController surfaces).
  final VoidCallback onClearPlan;

  const SettingsTab({super.key, required this.onClearPlan});

  static const String _appVersion = '1.0.0';

  void _confirmClear(BuildContext context) {
    onClearPlan();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Today's plan cleared"),
        behavior: SnackBarBehavior.floating,
        backgroundColor: kPrimary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAboutGenUi(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: kSurface,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _AboutGenUiSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // App identity card.
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: kSoftShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: kAppGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Smart Daily Planner', style: AppText.cardTitle),
                    SizedBox(height: 2),
                    Text(
                      'Your AI partner for a productive day',
                      style: AppText.secondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Info section.
        Text('ABOUT', style: AppText.secondary.copyWith(letterSpacing: 1.2)),
        const SizedBox(height: 8),
        const _SettingsTile(
          icon: Icons.info_outline_rounded,
          title: 'Version',
          trailing: _appVersion,
        ),
        const _SettingsTile(
          icon: Icons.bolt_outlined,
          title: 'AI Model',
          trailing: 'Gemini 2.5 Flash',
        ),
        const _SettingsTile(
          icon: Icons.code_rounded,
          title: 'Built with',
          trailing: 'Flutter · GenUI · Gemini',
        ),
        _SettingsTile(
          icon: Icons.auto_awesome_outlined,
          title: 'About GenUI',
          trailing: '',
          showChevron: true,
          onTap: () => _showAboutGenUi(context),
        ),

        const SizedBox(height: 22),

        // Actions section.
        Text('ACTIONS', style: AppText.secondary.copyWith(letterSpacing: 1.2)),
        const SizedBox(height: 8),
        _SettingsTile(
          icon: Icons.delete_outline_rounded,
          title: "Clear today's plan",
          trailing: '',
          iconColor: kPriorityHigh,
          titleColor: kPriorityHigh,
          onTap: () => _confirmClear(context),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String trailing;
  final bool showChevron;
  final Color? iconColor;
  final Color? titleColor;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.trailing,
    this.showChevron = false,
    this.iconColor,
    this.titleColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: iconColor ?? kPrimary, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: titleColor ?? kTextPrimary,
                    ),
                  ),
                ),
                if (trailing.isNotEmpty)
                  Text(trailing, style: AppText.secondary),
                if (showChevron)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: kTextSecondary,
                      size: 20,
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

/// Plain-English explainer of what GenUI is, shown in a bottom sheet.
class _AboutGenUiSheet extends StatelessWidget {
  const _AboutGenUiSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: kAppGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text('What is GenUI?', style: AppText.cardTitle),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Most apps show the same fixed screens to everyone. GenUI '
              '(Generative UI) lets the AI build the interface on the fly.',
              style: AppText.body,
            ),
            const SizedBox(height: 14),
            const Text(
              'Instead of just replying with text, the assistant decides which '
              'interactive pieces to show — like your plan card with real, '
              'tappable checkboxes — and the app renders them instantly.',
              style: AppText.body,
            ),
            const SizedBox(height: 14),
            const Text(
              'So when you describe your day, the AI assembles a live, '
              'personalized layout for you rather than a one-size-fits-all '
              'screen.',
              style: AppText.body,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
