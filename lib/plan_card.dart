import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// The widget type name the AI references in A2UI JSON to build this card.
const String planCardName = 'PlanCard';

/// Live task-completion progress for the currently pinned plan. Updated by
/// [planCardItem] every time a PlanCard rebuilds (e.g. after a task is checked
/// off and the model returns a fresh card). The app bar progress ring in
/// HomeScreen listens to this so the percentage updates as tasks are ticked.
final ValueNotifier<({int completed, int total})> planProgressNotifier =
    ValueNotifier<({int completed, int total})>((completed: 0, total: 0));

/// A custom [CatalogItem] that renders a daily plan.
///
/// In genui 0.9.2, a [CatalogItem] is a value (not a base class to extend).
/// It pairs a [name], a [Schema] describing the data the AI must produce, and a
/// `widgetBuilder` that receives a [CatalogItemContext].
///
/// The card reads literal values out of [CatalogItemContext.data] (the JSON the
/// AI emits) and dispatches a [UserActionEvent] when a task is checked off, so
/// the framework forwards it back to the model as the next turn's context.
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
  // Renders ONLY the task rows. The styled card, header ("Today's Plan") and
  // date are provided by the container in the Today tab, so this stays a plain
  // Column to avoid nested cards / duplicate headers.
  widgetBuilder: (itemContext) {
    final data = itemContext.data as Map<String, Object?>;
    final tasks = (data['tasks'] as List<Object?>? ?? const []);

    // Feature 2: push live completion stats to the app bar progress ring.
    // Done in a post-frame callback so we never mutate the notifier mid-build.
    final total = tasks.length;
    final completed = tasks.where((t) {
      final m = t as Map<String, Object?>;
      return m['isCompleted'] == true;
    }).length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      planProgressNotifier.value = (completed: completed, total: total);
    });

    if (tasks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No tasks yet.', style: TextStyle(color: Colors.grey)),
      );
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

class _TaskRow extends StatelessWidget {
  final String name;
  final String priority;
  final bool isCompleted;
  final VoidCallback? onTap;

  const _TaskRow({
    required this.name,
    required this.priority,
    required this.isCompleted,
    this.onTap,
  });

  Color _priorityColor() {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Checkbox(
            value: isCompleted,
            onChanged: onTap == null ? null : (_) => onTap!(),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color),
            ),
            child: Text(
              priority.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 14,
                decoration: isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                color: isCompleted ? Colors.grey : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
