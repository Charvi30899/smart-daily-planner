import 'package:flutter/material.dart';

import 'app_theme.dart';

/// A snapshot of one day's plan, kept in memory for the History tab.
class PlanSession {
  final DateTime date;
  final int taskCount;
  final int completed;

  const PlanSession({
    required this.date,
    required this.taskCount,
    required this.completed,
  });

  double get completionPct => taskCount == 0 ? 0 : completed / taskCount;

  /// Whether [other] falls on the same calendar day.
  bool sameDayAs(DateTime other) =>
      date.year == other.year &&
      date.month == other.month &&
      date.day == other.day;
}

/// The "History" tab: the last few plan sessions held in memory. Empty until
/// the user has built a plan.
class HistoryTab extends StatelessWidget {
  final List<PlanSession> sessions;

  const HistoryTab({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const _EmptyHistory();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      itemBuilder: (context, index) => _SessionTile(session: sessions[index]),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final PlanSession session;

  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final pct = (session.completionPct * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: kSoftShadow,
      ),
      child: Row(
        children: [
          // Completion ring.
          SizedBox(
            width: 46,
            height: 46,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 46,
                  height: 46,
                  child: CircularProgressIndicator(
                    value: session.completionPct,
                    strokeWidth: 4,
                    backgroundColor: kPrimary.withValues(alpha: 0.14),
                    valueColor: const AlwaysStoppedAnimation(kPrimary),
                  ),
                ),
                Text(
                  '$pct%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: kPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(prettyDate(session.date), style: AppText.cardTitle),
                const SizedBox(height: 4),
                Text(
                  '${session.completed} of ${session.taskCount} tasks completed',
                  style: AppText.secondary,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: kTextSecondary),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: kSecondary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history, size: 40, color: kSecondary),
            ),
            const SizedBox(height: 20),
            const Text(
              'No history yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your completed plans will appear here.',
              textAlign: TextAlign.center,
              style: AppText.secondary,
            ),
          ],
        ),
      ),
    );
  }
}
