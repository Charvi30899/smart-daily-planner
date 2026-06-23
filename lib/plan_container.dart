import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

import 'app_theme.dart';

/// White card (max height 300, internal scroll) wrapping the genui [Surface].
/// Provides the "Today's Plan" header with today's date; the genui-rendered
/// task rows scroll inside it.
class PlanContainer extends StatelessWidget {
  final SurfaceController surfaceController;
  final String surfaceId;

  const PlanContainer({
    super.key,
    required this.surfaceController,
    required this.surfaceId,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 300),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: kCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: kAppGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text("Today's Plan", style: AppText.cardTitle),
                  ),
                  Text(prettyDate(DateTime.now()), style: AppText.secondary),
                ],
              ),
            ),
            const Divider(height: 1, color: kBorder),

            // The genui-rendered plan (task rows). Flexible + scroll view so a
            // long plan scrolls within the 300px card instead of overflowing.
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
                child: Surface(
                  key: ValueKey('surface_$surfaceId'),
                  surfaceContext: surfaceController.contextFor(surfaceId),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Illustration-style empty state shown before any plan exists.
class EmptyPlanState extends StatelessWidget {
  const EmptyPlanState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimary.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: kPrimary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              color: kPrimary.withValues(alpha: 0.85),
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No tasks yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Chat below to add your first task',
            textAlign: TextAlign.center,
            style: AppText.secondary,
          ),
        ],
      ),
    );
  }
}
