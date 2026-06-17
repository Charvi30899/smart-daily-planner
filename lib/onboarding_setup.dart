import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'home_screen.dart';

/// The answers the user gives during the Quick Setup onboarding step. Passed
/// into [HomeScreen] so the AI can open with a personalized greeting and a
/// first PlanCard tailored to these preferences.
class SetupAnswers {
  /// How they want to start the day: "Slow & mindful" / "Energized & focused" /
  /// "Flexible".
  final String pace;

  /// How many tasks they can handle today (3–15).
  final int taskCount;

  /// What matters most today: any of Work / Health / Family / Learning /
  /// Personal.
  final List<String> focuses;

  const SetupAnswers({
    required this.pace,
    required this.taskCount,
    required this.focuses,
  });

  /// The opening context message sent to the model right after setup so it can
  /// greet the user and generate their first plan.
  String toPromptContext() {
    final focusText = focuses.isEmpty ? 'a balanced day' : focuses.join(', ');
    return 'SETUP COMPLETE. The user just finished onboarding.\n'
        '- They want to start their day: "$pace".\n'
        '- They can handle about $taskCount tasks today.\n'
        '- What matters most to them today: $focusText.\n\n'
        'Greet them warmly in one short paragraph that acknowledges these '
        'preferences, then immediately generate their first PlanCard with '
        'suggested starter tasks that fit their focus areas and pace. Use no '
        'more than $taskCount tasks, and set priorities to match the pace '
        '(slow & mindful = gentler, fewer high-priority items; energized & '
        'focused = front-load the important tasks).';
  }
}

/// Feature 1, Screen 2 — Quick setup. The AI "asks" three questions, each
/// answered with a GenUI-style widget (radio buttons, a slider, multi-select
/// chips) rather than free text. When all are answered, it transitions to the
/// main planner with the collected [SetupAnswers].
class QuickSetupScreen extends StatefulWidget {
  const QuickSetupScreen({super.key});

  @override
  State<QuickSetupScreen> createState() => _QuickSetupScreenState();
}

class _QuickSetupScreenState extends State<QuickSetupScreen> {
  static const List<String> _paceOptions = [
    'Slow & mindful',
    'Energized & focused',
    'Flexible',
  ];

  static const List<String> _focusOptions = [
    'Work',
    'Health',
    'Family',
    'Learning',
    'Personal',
  ];

  String? _pace;
  double _taskCount = 8;
  final Set<String> _focuses = {};

  bool get _isComplete => _pace != null && _focuses.isNotEmpty;

  void _continue() {
    final answers = SetupAnswers(
      pace: _pace!,
      taskCount: _taskCount.round(),
      focuses: _focuses.toList(),
    );
    Navigator.of(context).pushReplacement(
      fadeRoute(HomeScreen(setup: answers)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: kAppGradient),
        ),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, size: 20),
            SizedBox(width: 8),
            Text(
              'Quick Setup',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.2),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          Text(
            "Let's tune your day. Answer a few quick questions.",
            style: TextStyle(
              fontSize: 14.5,
              height: 1.4,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 18),

          // Q1 — pace (radio buttons).
          _QuestionCard(
            question: 'How do you want to start your day?',
            child: RadioGroup<String>(
              groupValue: _pace,
              onChanged: (v) => setState(() => _pace = v),
              child: Column(
                children: _paceOptions.map((option) {
                  final selected = _pace == option;
                  return RadioListTile<String>(
                    value: option,
                    activeColor: kIndigo,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      option,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected ? kIndigo : const Color(0xFF1E1B4B),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Q2 — task capacity (slider).
          _QuestionCard(
            question: 'How many tasks can you handle today?',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: kIndigo.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_taskCount.round()} tasks',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kIndigo,
                      ),
                    ),
                  ),
                ),
                Slider(
                  value: _taskCount,
                  min: 3,
                  max: 15,
                  divisions: 12,
                  label: '${_taskCount.round()}',
                  activeColor: kIndigo,
                  onChanged: (v) => setState(() => _taskCount = v),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('3', style: TextStyle(color: Colors.grey.shade600)),
                      Text('15', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Q3 — focus areas (multi-select chips).
          _QuestionCard(
            question: 'What matters most today?',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _focusOptions.map((option) {
                final selected = _focuses.contains(option);
                return FilterChip(
                  label: Text(option),
                  selected: selected,
                  onSelected: (on) => setState(() {
                    if (on) {
                      _focuses.add(option);
                    } else {
                      _focuses.remove(option);
                    }
                  }),
                  showCheckmark: false,
                  selectedColor: kIndigo,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: selected ? kIndigo : Colors.grey.shade300,
                  ),
                  labelStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? Colors.white : const Color(0xFF1E1B4B),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Continue button (enabled once pace + at least one focus chosen).
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: _isComplete ? kAppGradient : null,
              color: _isComplete ? null : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _isComplete
                  ? [
                      BoxShadow(
                        color: kIndigo.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: FilledButton(
              onPressed: _isComplete ? _continue : null,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Create My Plan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _isComplete ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.auto_awesome,
                    size: 20,
                    color: _isComplete ? Colors.white : Colors.grey.shade600,
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

/// One white card presenting a question (with an AI sparkle avatar) and its
/// answer widget below.
class _QuestionCard extends StatelessWidget {
  final String question;
  final Widget child;

  const _QuestionCard({required this.question, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: kIndigo.withValues(alpha: 0.12),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 15,
                  color: kIndigo,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: Color(0xFF1E1B4B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
