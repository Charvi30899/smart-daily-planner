import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

import 'app_theme.dart';
import 'history_tab.dart';
import 'mood_bar.dart';
import 'onboarding_setup.dart';
import 'plan_card.dart';
import 'progress_ring.dart';
import 'settings_tab.dart';
import 'summary_card.dart';
import 'today_tab.dart';

/// The main screen. Owns ALL genui wiring (SurfaceController, Conversation,
/// A2uiTransportAdapter, the Gemini chat session) so it persists across tab
/// switches, and hosts the bottom navigation with Today / History / Settings.
class HomeScreen extends StatefulWidget {
  /// Onboarding answers from the Quick Setup step. When present, the AI opens
  /// with a personalized greeting and a first PlanCard tailored to them.
  final SetupAnswers? setup;

  const HomeScreen({super.key, this.setup});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ---- genui wiring (unchanged behavior) ---------------------------------
  late final SurfaceController _surfaceController;
  late final A2uiTransportAdapter _transport;
  late final Conversation _conversation;
  late final ChatSession _chat;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatEntry> _messages = [];

  // Index of the assistant bubble currently being streamed. The model's prose
  // arrives as several trimmed text fragments per turn; we append them into a
  // single bubble. Reset to -1 at the start of every turn (ConversationWaiting).
  int _activeAssistantIndex = -1;

  // Surfaces the AI has actually created (tracked via ConversationSurfaceAdded).
  final List<String> _surfaceIds = [];

  bool _isLoading = false;
  bool _hasText = false;

  // ---- mood-based planning (Feature 4) -----------------------------------
  int _selectedMood = -1;

  // ---- history (last 5 plan sessions, in memory) -------------------------
  final List<PlanSession> _sessions = [];

  // ---- navigation --------------------------------------------------------
  int _tab = 0;

  static final String _plannerInstructions =
      '''
You are a smart daily planning assistant. Help users organize their day.

When the user describes tasks or asks to plan their day, ALWAYS respond by
generating a "PlanCard" component containing their tasks organized by priority.

CRITICAL: Every plan requires TWO A2UI messages, each in its own ```json block,
in this exact order:
  1. a `createSurface` message, then
  2. an `updateComponents` message whose `components` array contains the PlanCard.
Sending only `createSurface` leaves the screen EMPTY. The `updateComponents`
message is mandatory.

Rules:
- Use a fresh unique surfaceId for every response (e.g. "plan_1", "plan_2", ...).
- Always use this exact catalogId: "$basicCatalogId".
- The root component MUST have "id": "root" and "component": "PlanCard".
- PlanCard properties ("title", "tasks") are written INLINE, as siblings of
  "id" and "component" — not nested under a "properties" key.
- Assign priority "high" for urgent/important tasks, "medium" for normal,
  "low" for optional.
- Set isCompleted to false for new tasks; use a unique completeAction per task.
- When you receive a completion action, respond with a NEW PlanCard (new
  surfaceId) containing ALL current tasks, with that task's isCompleted = true.
- Keep the title "Today's Plan", and include a short friendly text reply too.

PERSONALIZED START:
The very first message may begin with "SETUP COMPLETE" and describe the user's
onboarding preferences (how they want to start the day, how many tasks they can
handle, and their focus areas). When you see it, greet them warmly in one short
paragraph that reflects those preferences, then generate their first PlanCard
(following the two-message pattern above) with suggested starter tasks aligned
to their focus areas and pace. Never exceed the task count they gave.

MOOD-BASED PLANNING:
When a message says "User is feeling [mood] today", re-prioritize the CURRENT
plan to match that energy and respond with a NEW PlanCard (fresh surfaceId)
plus a short encouraging note:
- Low energy (Tired / Neutral): surface fewer, lighter tasks first and soften
  priorities; move demanding work down.
- High energy (Energized / On Fire): front-load the high-priority, demanding
  tasks while momentum is there.
If no plan exists yet, suggest a few tasks that suit the mood.

END-OF-DAY SUMMARY:
When the user signals they are finished for the day (e.g. "I'm done for today",
"wrap up my day", "that's it for today"), DO NOT return a PlanCard. Instead
return a "SummaryCard" using the SAME two-message pattern (createSurface then
updateComponents, fresh surfaceId). The root component MUST have "id": "root"
and "component": "SummaryCard", with these INLINE properties:
  - "title": e.g. "Day Wrapped".
  - "completedTasks": array of the names of tasks marked complete today.
  - "remainingTasks": array of the names of tasks still not complete.
  - "message": a warm, motivational one or two sentence closing message.
Include a short friendly text reply too.

EXAMPLE — for the request "plan my day: finish the report, water the plants",
respond with a brief sentence and then exactly these two blocks:

```json
{
  "version": "v0.9",
  "createSurface": {
    "surfaceId": "plan_1",
    "catalogId": "$basicCatalogId",
    "sendDataModel": true
  }
}
```

```json
{
  "version": "v0.9",
  "updateComponents": {
    "surfaceId": "plan_1",
    "components": [
      {
        "id": "root",
        "component": "PlanCard",
        "title": "Today's Plan",
        "tasks": [
          {"name": "Finish the report", "priority": "high", "isCompleted": false, "completeAction": "complete_task_1"},
          {"name": "Water the plants", "priority": "low", "isCompleted": false, "completeAction": "complete_task_2"}
        ]
      }
    ]
  }
}
```

EXAMPLE — end-of-day summary, exactly two blocks:

```json
{
  "version": "v0.9",
  "createSurface": {
    "surfaceId": "summary_1",
    "catalogId": "$basicCatalogId",
    "sendDataModel": true
  }
}
```

```json
{
  "version": "v0.9",
  "updateComponents": {
    "surfaceId": "summary_1",
    "components": [
      {
        "id": "root",
        "component": "SummaryCard",
        "title": "Day Wrapped",
        "completedTasks": ["Finish the report"],
        "remainingTasks": ["Water the plants"],
        "message": "Great focus today — you cleared the big one. Rest up!"
      }
    ]
  }
}
```
''';

  @override
  void initState() {
    super.initState();

    // 1. Catalog: basic widgets plus our custom PlanCard and SummaryCard
    //    (same catalogId).
    final catalog = BasicCatalogItems.asCatalog().copyWith(
      newItems: [planCardItem, summaryCardItem],
    );

    // 2. System prompt via PromptBuilder.chat (create-a-new-surface-per-turn).
    final promptBuilder = PromptBuilder.chat(
      catalog: catalog,
      systemPromptFragments: [_plannerInstructions],
    );

    // 3. Firebase AI (Gemini Developer API) with the system instruction.
    final model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      systemInstruction: Content.system(promptBuilder.systemPromptJoined()),
    );
    _chat = model.startChat();

    // 4. Wire up genui: controller -> transport -> conversation.
    _surfaceController = SurfaceController(catalogs: [catalog]);
    _transport = A2uiTransportAdapter(onSend: _onSendToLlm);
    _conversation = Conversation(
      controller: _surfaceController,
      transport: _transport,
    );

    // 5. React to conversation events.
    _conversation.events.listen((event) {
      if (!mounted) return;
      switch (event) {
        case ConversationWaiting():
          _activeAssistantIndex = -1;
        case ConversationContentReceived(:final text):
          final fragment = text.trim();
          if (fragment.isEmpty) break;
          setState(() {
            if (_activeAssistantIndex >= 0 &&
                _activeAssistantIndex < _messages.length) {
              final existing = _messages[_activeAssistantIndex];
              _messages[_activeAssistantIndex] = (
                text: '${existing.text} $fragment',
                isUser: false,
                time: existing.time,
              );
            } else {
              _messages.add((
                text: fragment,
                isUser: false,
                time: DateTime.now(),
              ));
              _activeAssistantIndex = _messages.length - 1;
            }
          });
          _scrollToBottom();
        case ConversationSurfaceAdded(:final surfaceId):
          setState(() {
            _surfaceIds
              ..remove(surfaceId)
              ..add(surfaceId);
          });
        case ConversationSurfaceRemoved(:final surfaceId):
          setState(() => _surfaceIds.remove(surfaceId));
        case ConversationError(:final error):
          setState(() {
            _isLoading = false;
            _messages.add((
              text: 'Error: $error',
              isUser: false,
              time: DateTime.now(),
            ));
          });
        default:
          break;
      }
    });

    _conversation.state.addListener(() {
      if (!mounted) return;
      setState(() => _isLoading = _conversation.state.value.isWaiting);
    });

    _textController.addListener(() {
      final hasText = _textController.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });

    // Keep the History tab in sync as task-completion progress changes.
    planProgressNotifier.addListener(_onProgressChanged);

    // Feature 1: kick off a personalized greeting + first plan from the
    // onboarding answers once the first frame is up. Sent as context (no user
    // bubble) so the AI appears to greet the user proactively.
    final setup = widget.setup;
    if (setup != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _conversation.sendRequest(ChatMessage.user(setup.toPromptContext()));
      });
    }
  }

  /// Bridges genui to Firebase: serialize the outgoing message, stream the
  /// Gemini response, and feed each chunk back into the transport adapter.
  Future<void> _onSendToLlm(ChatMessage message) async {
    final prompt = _serializeMessage(message);
    final responseStream = _chat.sendMessageStream(Content.text(prompt));
    await for (final response in responseStream) {
      final chunk = response.text;
      if (chunk != null && chunk.isNotEmpty) {
        // Do NOT flush()/close — the adapter is reused for every turn.
        _transport.addChunk(chunk);
      }
    }
  }

  String _serializeMessage(ChatMessage message) {
    final buffer = StringBuffer();
    if (message.text.trim().isNotEmpty) {
      buffer.writeln(message.text.trim());
    }
    for (final part in message.parts.uiInteractionParts) {
      buffer.writeln('User interaction: ${part.interaction}');
    }
    return buffer.toString().trim();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _textController.clear();
    setState(() {
      _messages.add((text: text, isUser: true, time: DateTime.now()));
    });
    _scrollToBottom();
    _conversation.sendRequest(ChatMessage.user(text));
  }

  /// Feature 4: tapping a mood emoji sends the user's energy level to the AI so
  /// it can re-prioritize the plan. We show a short user bubble for context.
  void _sendMood(int index) {
    if (_isLoading) return;
    final mood = kMoods[index];
    setState(() {
      _selectedMood = index;
      _messages.add((
        text: "I'm feeling ${mood.emoji} ${mood.name.toLowerCase()} today",
        isUser: true,
        time: DateTime.now(),
      ));
    });
    _scrollToBottom();
    _conversation.sendRequest(
      ChatMessage.user(
        'User is feeling ${mood.name} ${mood.emoji} today. Adjust the task '
        'priorities in their plan to match this energy level.',
      ),
    );
  }

  /// Upserts today's session into the in-memory history (capped to 5).
  void _onProgressChanged() {
    if (!mounted) return;
    final p = planProgressNotifier.value;
    if (p.total == 0) return;
    final now = DateTime.now();
    setState(() {
      _sessions.removeWhere((s) => s.sameDayAs(now));
      _sessions.insert(
        0,
        PlanSession(date: now, taskCount: p.total, completed: p.completed),
      );
      if (_sessions.length > 5) {
        _sessions.removeRange(5, _sessions.length);
      }
    });
  }

  /// Settings action: clear the displayed plan and reset progress/mood.
  void _clearPlan() {
    setState(() {
      _surfaceIds.clear();
      _selectedMood = -1;
    });
    planProgressNotifier.value = (completed: 0, total: 0);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    planProgressNotifier.removeListener(_onProgressChanged);
    _conversation.dispose();
    _transport.dispose();
    _surfaceController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pinnedSurfaceId = _surfaceIds.isEmpty ? null : _surfaceIds.last;

    const titles = ['Smart Daily Planner', 'History', 'Settings'];

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: kAppGradient),
        ),
        title: Row(
          children: [
            const Text('📅', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                titles[_tab],
                style: AppText.appBarTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: const [AppBarProgressRing()],
      ),
      body: Column(
        children: [
          // Feature 4: mood selector row, shown right below the app bar on the
          // Today tab only.
          if (_tab == 0)
            MoodBar(
              selectedIndex: _selectedMood,
              enabled: !_isLoading,
              onSelect: _sendMood,
            ),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                TodayTab(
                  surfaceController: _surfaceController,
                  pinnedSurfaceId: pinnedSurfaceId,
                  messages: _messages,
                  isLoading: _isLoading,
                  textController: _textController,
                  scrollController: _scrollController,
                  canSend: _hasText && !_isLoading,
                  onSend: _sendMessage,
                ),
                HistoryTab(sessions: _sessions),
                SettingsTab(onClearPlan: _clearPlan),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
