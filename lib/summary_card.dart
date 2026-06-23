import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import 'app_theme.dart';

/// The widget type name the AI references in A2UI JSON to build the end-of-day
/// summary card.
const String summaryCardName = 'SummaryCard';

/// A custom [CatalogItem] for Feature 3 — the "wrap up my day" summary.
///
/// When the user signals they are finished for the day, the model emits a
/// SummaryCard listing the tasks they completed, the tasks still remaining, and
/// a short motivational message. Like the PlanCard, properties are written
/// INLINE (siblings of "id"/"component"), and the styled outer container +
/// header are supplied by the Today tab.
final CatalogItem summaryCardItem = CatalogItem(
  name: summaryCardName,
  dataSchema: S.object(
    description:
        'An end-of-day summary showing the tasks completed today, the tasks '
        'still remaining, and a short motivational closing message.',
    properties: {
      'title': S.string(
        description: 'Title of the summary, e.g. "Day Wrapped".',
      ),
      'completedTasks': S.list(
        description: 'Names of the tasks the user completed today.',
        items: S.string(description: 'A completed task name.'),
      ),
      'remainingTasks': S.list(
        description: 'Names of the tasks still not completed.',
        items: S.string(description: 'A remaining task name.'),
      ),
      'message': S.string(
        description:
            'A warm, motivational one or two sentence closing message for the '
            'user about their day.',
      ),
    },
    required: ['title', 'completedTasks', 'remainingTasks', 'message'],
  ),
  widgetBuilder: (itemContext) {
    final data = itemContext.data as Map<String, Object?>;
    final title = data['title'] as String? ?? 'Day Wrapped';
    final completed = ((data['completedTasks'] as List<Object?>?) ?? const [])
        .map((e) => e.toString())
        .toList();
    final remaining = ((data['remainingTasks'] as List<Object?>?) ?? const [])
        .map((e) => e.toString())
        .toList();
    final message = data['message'] as String? ?? '';

    final totalCount = completed.length + remaining.length;
    final pct = totalCount == 0 ? 0.0 : completed.length / totalCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Headline + progress chip.
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
          child: Row(
            children: [
              const Icon(Icons.nightlight_round, color: kSecondary, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: AppText.cardTitle)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: kAppGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(pct * 100).round()}% done',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        _SummarySection(
          icon: Icons.check_circle,
          iconColor: kPriorityLow,
          label: 'Completed',
          emptyText: 'Nothing checked off yet — that\'s okay.',
          items: completed,
          strikeThrough: true,
        ),
        const SizedBox(height: 12),
        _SummarySection(
          icon: Icons.hourglass_bottom_rounded,
          iconColor: kPriorityMedium,
          label: 'Remaining',
          emptyText: 'All clear — everything is done! 🎉',
          items: remaining,
          strikeThrough: false,
        ),

        if (message.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kPrimary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kPrimary.withValues(alpha: 0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🤖', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: kTextPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  },
);

/// One labelled list block ("Completed" / "Remaining") inside the summary.
class _SummarySection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String emptyText;
  final List<String> items;
  final bool strikeThrough;

  const _SummarySection({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.emptyText,
    required this.items,
    required this.strikeThrough,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text('$label (${items.length})', style: AppText.sectionTitle),
            ],
          ),
          const SizedBox(height: 6),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 26, top: 2),
              child: Text(
                emptyText,
                style: AppText.secondary.copyWith(fontStyle: FontStyle.italic),
              ),
            )
          else
            ...items.map(
              (name) => Padding(
                padding: const EdgeInsets.only(left: 26, top: 3, bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strikeThrough ? '✅' : '⏳',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 14,
                          color: strikeThrough ? kTextSecondary : kTextPrimary,
                          decoration: strikeThrough
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
