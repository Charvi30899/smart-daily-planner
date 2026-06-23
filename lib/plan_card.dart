import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import 'app_theme.dart';

/// The widget type name the AI references in A2UI JSON to build this card.
const String planCardName = 'PlanCard';

/// Live task-completion progress for the currently pinned plan. Updated by
/// [planCardItem] every time a PlanCard rebuilds (e.g. after a task is checked
/// off and the model returns a fresh card). The app bar progress ring and the
/// History tab listen to this so they stay in sync as tasks are ticked.
final ValueNotifier<({int completed, int total})> planProgressNotifier =
    ValueNotifier<({int completed, int total})>((completed: 0, total: 0));

/// A custom [CatalogItem] that renders the task rows of a daily plan.
///
/// The styled card chrome (white card, header, date, divider, scroll) is
/// supplied by the Today tab's plan container, so this builder renders ONLY the
/// task rows. It reads literal values out of [CatalogItemContext.data] (the
/// JSON the AI emits) and dispatches a [UserActionEvent] when a task is checked
/// off, so the framework forwards it back to the model as the next turn's
/// context.
final CatalogItem planCardItem = CatalogItem(
  name: planCardName,
  dataSchema: S.object(
    description:
        'Displays a daily plan with tasks. Each task has a name, a priority '
        '(high/medium/low), and a checkbox to mark it complete.',
    properties: {
      'title': S.string(description: 'Title of the plan, e.g. "Today\'s Plan".'),
      'tasks': S.list(
        description: 'The list of tasks in the plan.',
        items: S.object(
          properties: {
            'name': S.string(description: 'Task name.'),
            'priority': S.string(
              description: 'Priority level.',
              enumValues: ['high', 'medium', 'low'],
            ),
            'isCompleted': S.boolean(
              description: 'Whether the task is completed.',
            ),
            'completeAction': S.string(
              description:
                  'Unique action name to dispatch when this task is checked '
                  'off, e.g. "complete_task_1".',
            ),
          },
          required: ['name', 'priority', 'isCompleted', 'completeAction'],
        ),
      ),
    },
    required: ['title', 'tasks'],
  ),
  widgetBuilder: (itemContext) {
    final data = itemContext.data as Map<String, Object?>;
    final tasks = (data['tasks'] as List<Object?>? ?? const []);

    // Feature 2: push live completion stats to the app bar progress ring. Done
    // in a post-frame callback so we never mutate the notifier mid-build.
    final total = tasks.length;
    final completed = tasks.where((t) {
      final m = t as Map<String, Object?>;
      return m['isCompleted'] == true;
    }).length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      planProgressNotifier.value = (completed: completed, total: total);
    });

    if (tasks.isEmpty) {
      return const _EmptyTasks();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...tasks.map((task) {
          final t = task as Map<String, Object?>;
          final name = t['name'] as String? ?? '';
          final priority = t['priority'] as String? ?? 'medium';
          final isCompleted = t['isCompleted'] as bool? ?? false;
          final completeAction = t['completeAction'] as String? ?? '';

          return _TaskRow(
            // Stable key so Flutter preserves the element across genui rebuilds
            // and the completion animation plays when isCompleted flips.
            key: ValueKey('task_$completeAction'),
            name: name,
            priority: priority,
            isCompleted: isCompleted,
            onTap: isCompleted
                ? null
                : () => itemContext.dispatchEvent(
                      UserActionEvent(
                        name: completeAction,
                        sourceComponentId: itemContext.id,
                        context: {'task': name},
                      ),
                    ),
          );
        }),
      ],
    );
  },
);

/// Shown when a PlanCard arrives with no tasks.
class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 40,
            color: kPrimary.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 10),
          Text(
            'Chat below to add your first task',
            style: AppText.secondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// A single task row: indigo checkbox + priority pill + name. Subtly slides and
/// fades when marked complete.
class _TaskRow extends StatelessWidget {
  final String name;
  final String priority;
  final bool isCompleted;
  final VoidCallback? onTap;

  const _TaskRow({
    super.key,
    required this.name,
    required this.priority,
    required this.isCompleted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = priorityColor(priority);

    return AnimatedSlide(
      offset: isCompleted ? const Offset(0.04, 0) : Offset.zero,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: isCompleted ? 0.55 : 1,
        duration: const Duration(milliseconds: 300),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: Checkbox(
                    value: isCompleted,
                    onChanged: onTap == null ? null : (_) => onTap!(),
                    activeColor: kPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 10),
                _PriorityBadge(priority: priority, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.3,
                      color: isCompleted ? kTextSecondary : kTextPrimary,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
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

/// A pill-shaped priority badge (HIGH / MEDIUM / LOW).
class _PriorityBadge extends StatelessWidget {
  final String priority;
  final Color color;

  const _PriorityBadge({required this.priority, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        priority.toUpperCase(),
        style: AppText.badge.copyWith(color: color),
      ),
    );
  }
}
