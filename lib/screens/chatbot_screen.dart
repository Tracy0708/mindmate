import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_emoji.dart';
import '../viewmodels/chatbot_viewmodel.dart';
import '../viewmodels/emotion_viewmodel.dart';
import '../models/chatbot_session.dart';
import '../models/emotion_log.dart';
import '../models/crisis_hotline.dart';
import '../services/interactive_message_service.dart';
import '../main.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});
  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _msgController = TextEditingController();
  bool _hasText = false;
  late String _userId;
  // Brief send cooldown so rapid taps can't trip the Gemini per-minute rate limit.
  static const Duration _sendCooldown = Duration(seconds: 3);
  bool _coolingDown = false;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    _msgController.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatbotViewModel>(context, listen: false)
          .startNewSession(_userId);
      // Load the user's mood so the greeting and suggestion chips can adapt.
      final emotionVm = Provider.of<EmotionViewModel>(context, listen: false);
      if (!emotionVm.checkedToday) emotionVm.checkTodaysLog();
    });
  }

  void _onTextChanged() {
    final has = _msgController.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _msgController.removeListener(_onTextChanged);
    _msgController.dispose();
    super.dispose();
  }

  void _handleSend([String? preset]) {
    if (_coolingDown) return;
    final vm = Provider.of<ChatbotViewModel>(context, listen: false);
    if (vm.isLoading) return;

    final text = preset ?? _msgController.text.trim();
    if (text.isEmpty) return;

    vm.sendMessage(_userId, text);
    if (preset == null) _msgController.clear();

    // Briefly lock sending to avoid hammering the AI rate limit.
    setState(() => _coolingDown = true);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(_sendCooldown, () {
      if (mounted) setState(() => _coolingDown = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final emotionVm = context.watch<EmotionViewModel>();
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
              height: 1,
              thickness: 1,
              color: AppColors.fieldBorder.withValues(alpha: 0.6)),
        ),
        title: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset('assets/images/MindMateAI.png',
                    width: 46, height: 46, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MindMate AI',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark),
                ),
                Row(
                  children: [
                    const SizedBox(
                      width: 7,
                      height: 7,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFF66BB6A),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Online · Ready to chat',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMedium.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: Consumer<ChatbotViewModel>(
        builder: (context, vm, _) {
          if (vm.errorMessage != null) {
            return Column(
              children: [
                Expanded(child: _buildErrorState(vm)),
                _buildInputArea(vm),
              ],
            );
          }
          return StreamBuilder<ChatbotSession>(
            stream: vm.getSessionMessages(),
            builder: (context, snapshot) {
              final messages = snapshot.data?.messages ?? [];
              final initialLoading =
                  snapshot.connectionState == ConnectionState.waiting &&
                      messages.isEmpty;

              return Column(
                children: [
                  Expanded(
                    child: initialLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary))
                        : (messages.isEmpty && !vm.crisisActive)
                            ? _buildEmptyState(emotionVm)
                            : _buildMessageList(messages, vm.crisisActive),
                  ),
                  if (vm.isLoading) const _TypingIndicator(),
                  if (messages.isEmpty && !initialLoading && !vm.crisisActive)
                    _buildSuggestionRow(emotionVm),
                  _buildInputArea(vm),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMessageList(
      List<Map<String, dynamic>> messages, bool crisisActive) {
    final reversed = messages.reversed.toList();
    // When a crisis is active, the hotline card rides along as the newest item
    // at the bottom of the conversation (reverse list → index 0), so it scrolls
    // with the chat instead of being pinned above the input.
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: reversed.length + (crisisActive ? 1 : 0),
      itemBuilder: (context, index) {
        if (crisisActive && index == 0) return _buildCrisisCard();
        final msgIndex = crisisActive ? index - 1 : index;
        return _MessageBubble(msg: reversed[msgIndex]);
      },
    );
  }

  Widget _buildEmptyState(EmotionViewModel emotionVm) {
    final greeting = _moodGreeting(emotionVm);
    // LayoutBuilder + scroll view so the greeting scrolls (and centers when it
    // fits) instead of overflowing when the keyboard shrinks the available area.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Image.asset('assets/images/MindMateAI.png',
                            width: 88, height: 88, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      greeting,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "I'm here to listen and support you.\nShare what's on your mind.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textMedium,
                          height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// A proactive, mood-aware greeting derived from the user's recent check-ins.
  /// Falls back to the generic prompt when there's no mood data yet.
  String _moodGreeting(EmotionViewModel vm) {
    final recent = vm.recentLogs;
    final today = vm.todaysLog;

    if (recent.isEmpty && today == null) {
      return 'How are you feeling today?';
    }

    // Negative trend: 3+ of the last 5 check-ins were effectively negative.
    final lastFive = recent.take(5).toList();
    final negativeCount = lastFive.where((l) => l.isEffectivelyNegative).length;
    if (lastFive.length >= 3 && negativeCount >= 3) {
      return "I've noticed the past few days have felt heavy. "
          "I'm here for you — want to talk about it?";
    }

    if (today != null) {
      if (today.isEffectivelyNegative) {
        return "I see you're feeling ${today.emotionType.toLowerCase()} today. "
            "Want to talk it through?";
      }
      return "Glad you're feeling ${today.emotionType.toLowerCase()} today 🌱 "
          "What's on your mind?";
    }

    if (vm.streak >= 2) {
      return "You're on a ${vm.streak}-day check-in streak! "
          "How are you feeling today?";
    }
    return "You haven't checked in today. How are you feeling?";
  }

  Widget _buildErrorState(ChatbotViewModel vm) {
    // LayoutBuilder + scroll view so a long error message scrolls instead of
    // overflowing, while still centering when the content is short.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.errorRed.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.cloud_off_rounded,
                          color: AppColors.errorRed, size: 36),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Something went wrong',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      vm.errorMessage ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMedium,
                          height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => vm.startNewSession(_userId),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Try Again',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textDark,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionRow(EmotionViewModel emotionVm) {
    final chips = _moodChips(emotionVm);
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final chip in chips)
            _SuggestionChip(
                icon: chip.icon,
                label: chip.label,
                onTap: () => _handleSend(chip.prompt)),
        ],
      ),
    );
  }

  /// Suggestion chips tailored to the user's current/dominant mood, falling back
  /// to a generic set when there's no mood data.
  List<_ChipData> _moodChips(EmotionViewModel vm) {
    final mood = vm.todaysLog?.emotionType ?? _dominantEmotion(vm.recentLogs);

    switch (mood) {
      case 'Anxious':
        return const [
          _ChipData('😮‍💨', 'Help me calm down', 'Help me calm down'),
          _ChipData('🫁', 'Breathing exercise',
              'Can you guide me through a breathing exercise?'),
          _ChipData('💭', 'My thoughts are racing',
              'My thoughts are racing and I feel anxious'),
        ];
      case 'Sad':
        return const [
          _ChipData('💙', 'I want to talk',
              "I'm feeling sad and want to talk through it"),
          _ChipData(
              '🌧️', 'Why do I feel down?', "I've been feeling down lately"),
          _ChipData(
              '🤗', 'I need comfort', 'I could use some comfort right now'),
        ];
      case 'Angry':
        return const [
          _ChipData('😤', 'Help me cool off',
              "I'm feeling angry and need to cool off"),
          _ChipData(
              '🧯', 'Manage frustration', 'Help me manage my frustration'),
          _ChipData('💬', 'Let me vent', 'I just need to vent'),
        ];
      case 'Happy':
      case 'Calm':
        return const [
          _ChipData('😊', 'Share good news',
              'I want to share something good that happened'),
          _ChipData('🙏', 'Practice gratitude', 'Help me practice gratitude'),
          _ChipData('✨', 'Keep the momentum',
              'How can I keep this positive momentum going?'),
        ];
      default:
        return const [
          _ChipData('😊', "I'm feeling happy!", "I'm feeling happy!"),
          _ChipData('😓', "I'm stressed", "I'm feeling stressed"),
          _ChipData('😴', "I can't sleep", "I can't sleep"),
        ];
    }
  }

  /// Most frequently logged emotion across recent logs, or null if none.
  String? _dominantEmotion(List<EmotionLog> logs) {
    if (logs.isEmpty) return null;
    final freq = <String, int>{};
    for (final log in logs) {
      freq[log.emotionType] = (freq[log.emotionType] ?? 0) + 1;
    }
    return freq.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  /// Crisis-escalation card surfaced when the AI flags crisis language.
  /// Numbers come from the shared [kCrisisHotlines] source of truth. Rendered
  /// inline as the newest item in the conversation so it scrolls with the chat.
  Widget _buildCrisisCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 4, 0, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emergency_rounded, color: Color(0xFFE65100), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You are not alone — help is available',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE65100),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'If you are in immediate danger, call 999. Reach out to a trained '
            'counsellor any time — tap a number to copy it.',
            style: TextStyle(
                fontSize: 12, color: AppColors.textMedium, height: 1.5),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < kCrisisHotlines.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _CrisisHotlineRow(hotline: kCrisisHotlines[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea(ChatbotViewModel vm) {
    final canSend = _hasText && !vm.isLoading && !_coolingDown;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      decoration: BoxDecoration(
        color: AppColors.cream,
        border: Border(
          top: BorderSide(
              color: AppColors.fieldBorder.withValues(alpha: 0.5), width: 0.8),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.fieldBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _msgController,
                maxLines: null,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 15, color: AppColors.textDark),
                decoration: const InputDecoration(
                  hintText: "Share what's on your mind…",
                  hintStyle:
                      TextStyle(color: AppColors.textLight, fontSize: 14),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                  isDense: true,
                ),
                onSubmitted: canSend ? (_) => _handleSend() : null,
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: canSend
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: canSend ? _handleSend : null,
                child: const Icon(Icons.send_rounded,
                    color: AppColors.textDark, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message Bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg['isUser'] == true;
    final content = (msg['content'] as String?) ?? '';
    final tsStr = (msg['timestamp'] as String?) ?? '';
    String timeLabel = '';
    if (tsStr.isNotEmpty) {
      try {
        final dt = DateTime.parse(tsStr).toLocal();
        timeLabel =
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset('assets/images/MindMateAI.png',
                    width: 30, height: 30, fit: BoxFit.cover),
              ),
            ),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isUser ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      content,
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 15,
                        height: 1.45,
                        fontWeight: isUser ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    if (timeLabel.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        timeLabel,
                        style: TextStyle(
                          color: isUser
                              ? AppColors.textMedium
                              : AppColors.textLight,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ── Animated Typing Indicator ────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (_) => AnimationController(
          vsync: this, duration: const Duration(milliseconds: 500)),
    );
    _animations = _controllers
        .map((c) => Tween<double>(begin: 0, end: -5)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)))
        .toList();
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset('assets/images/MindMateAI.png',
                  width: 28, height: 28, fit: BoxFit.cover),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => AnimatedBuilder(
                  animation: _animations[i],
                  builder: (_, __) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 7,
                    height: 7,
                    transform:
                        Matrix4.translationValues(0, _animations[i].value, 0),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mood-aware suggestion chip data ──────────────────────────────────────────

class _ChipData {
  final String icon;
  final String label;
  final String prompt;
  const _ChipData(this.icon, this.label, this.prompt);
}

// ── Crisis hotline row (chatbot crisis card) ─────────────────────────────────

class _CrisisHotlineRow extends StatelessWidget {
  final CrisisHotline hotline;
  const _CrisisHotlineRow({required this.hotline});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: hotline.number));
        InteractiveMessageService.showInfo(
          context,
          title: 'Number copied',
          message: '${hotline.number} copied to clipboard.',
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFFFFB300).withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.phone_outlined,
                color: Color(0xFFE65100), size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hotline.label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    hotline.number,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.copy_rounded,
                color: AppColors.textLight, size: 15),
          ],
        ),
      ),
    );
  }
}

// ── Suggestion Chip ──────────────────────────────────────────────────────────

class _SuggestionChip extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  const _SuggestionChip(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.4), width: 1.2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppEmoji(icon, size: 15),
            const SizedBox(width: 7),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
