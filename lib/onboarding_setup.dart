import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'home_screen.dart';

/// The answers the user gives during onboarding. Passed into [HomeScreen] so
/// the AI can open with a personalized greeting and a first PlanCard tailored
/// to these preferences.
class SetupAnswers {
  /// How they want to start the day.
  final String pace;

  /// How many tasks they can handle today (3–15).
  final int taskCount;

  /// What matters most today (Work / Health / Family / Learning / Personal).
  final List<String> focuses;

  const SetupAnswers({
    required this.pace,
    required this.taskCount,
    required this.focuses,
  });

  /// The opening context message sent to the model right after setup.
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

/// Feature 1, Screen 2 — Quick setup. One question per screen with page
/// indicator dots and a horizontal slide between questions. Each question is
/// answered with a GenUI-style widget (radio, slider, chips) rather than text.
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

  static const int _pageCount = 3;

  final PageController _pageController = PageController();
  int _page = 0;

  String? _pace;
  double _taskCount = 8;
  final Set<String> _focuses = {};

  bool get _canAdvance {
    switch (_page) {
      case 0:
        return _pace != null;
      case 2:
        return _focuses.isNotEmpty;
      default:
        return true;
    }
  }

  void _next() {
    if (_page < _pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _back() {
    if (_page == 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _finish() {
    final answers = SetupAnswers(
      pace: _pace!,
      taskCount: _taskCount.round(),
      focuses: _focuses.toList(),
    );
    Navigator.of(context).pushReplacement(fadeRoute(HomeScreen(setup: answers)));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pageCount - 1;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: back arrow + page dots.
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
              child: Row(
                children: [
                  AnimatedOpacity(
                    opacity: _page == 0 ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: kTextPrimary,
                      onPressed: _page == 0 ? null : _back,
                    ),
                  ),
                  const Spacer(),
                  _PageDots(count: _pageCount, active: _page),
                  const Spacer(),
                  // Symmetry spacer matching the back button width.
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Quick setup',
                  style: AppText.secondary.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),

            // Questions.
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _QuestionPage(
                    question: 'How do you want to start your day?',
                    child: _PaceRadios(
                      options: _paceOptions,
                      selected: _pace,
                      onChanged: (v) => setState(() => _pace = v),
                    ),
                  ),
                  _QuestionPage(
                    question: 'How many tasks can you handle today?',
                    child: _TaskSlider(
                      value: _taskCount,
                      onChanged: (v) => setState(() => _taskCount = v),
                    ),
                  ),
                  _QuestionPage(
                    question: 'What matters most today?',
                    child: _FocusChips(
                      options: _focusOptions,
                      selected: _focuses,
                      onToggle: (option, on) => setState(() {
                        if (on) {
                          _focuses.add(option);
                        } else {
                          _focuses.remove(option);
                        }
                      }),
                    ),
                  ),
                ],
              ),
            ),

            // Continue button (indigo filled, full width, rounded 12).
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _canAdvance ? _next : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: kPrimary,
                    disabledBackgroundColor: kPrimary.withValues(alpha: 0.35),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLast ? 'Create My Plan' : 'Continue',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isLast
                            ? Icons.auto_awesome
                            : Icons.arrow_forward_rounded,
                        size: 20,
                      ),
                    ],
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

/// Row of page indicator dots; the active dot is wider and indigo.
class _PageDots extends StatelessWidget {
  final int count;
  final int active;

  const _PageDots({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? kPrimary : kPrimary.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

/// A single question screen: AI avatar + question, then the answer widget.
class _QuestionPage extends StatelessWidget {
  final String question;
  final Widget child;

  const _QuestionPage({required this.question, required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: kPrimary.withValues(alpha: 0.12),
                child: const Text('🤖', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                    color: kTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: kSoftShadow,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Q1 — pace radio buttons (uses the new RadioGroup ancestor API).
class _PaceRadios extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _PaceRadios({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioGroup<String>(
      groupValue: selected,
      onChanged: onChanged,
      child: Column(
        children: options.map((option) {
          final isSelected = selected == option;
          return RadioListTile<String>(
            value: option,
            activeColor: kPrimary,
            contentPadding: EdgeInsets.zero,
            title: Text(
              option,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? kPrimary : kTextPrimary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Q2 — task capacity slider (3–15).
class _TaskSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _TaskSlider({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: kPrimary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              '${value.round()} tasks',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kPrimary,
              ),
            ),
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: kPrimary,
            inactiveTrackColor: kPrimary.withValues(alpha: 0.16),
            thumbColor: kPrimary,
            overlayColor: kPrimary.withValues(alpha: 0.12),
          ),
          child: Slider(
            value: value,
            min: 3,
            max: 15,
            divisions: 12,
            label: '${value.round()}',
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('3', style: AppText.secondary),
              Text('15', style: AppText.secondary),
            ],
          ),
        ),
      ],
    );
  }
}

/// Q3 — focus area multi-select chips.
class _FocusChips extends StatelessWidget {
  final List<String> options;
  final Set<String> selected;
  final void Function(String option, bool on) onToggle;

  const _FocusChips({
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (on) => onToggle(option, on),
          showCheckmark: false,
          selectedColor: kPrimary,
          backgroundColor: kSurface,
          side: BorderSide(color: isSelected ? kPrimary : kBorder),
          labelStyle: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : kTextPrimary,
          ),
        );
      }).toList(),
    );
  }
}
