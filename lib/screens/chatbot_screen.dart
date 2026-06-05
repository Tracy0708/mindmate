import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_emoji.dart';
import '../viewmodels/chatbot_viewmodel.dart';
import '../models/chatbot_session.dart';
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

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    _msgController.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatbotViewModel>(context, listen: false).startNewSession(_userId);
    });
  }

  void _onTextChanged() {
    final has = _msgController.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  void dispose() {
    _msgController.removeListener(_onTextChanged);
    _msgController.dispose();
    super.dispose();
  }

  void _handleSend([String? preset]) {
    final text = preset ?? _msgController.text.trim();
    if (text.isEmpty) return;
    Provider.of<ChatbotViewModel>(context, listen: false).sendMessage(_userId, text);
    if (preset == null) _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
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
          child: Divider(height: 1, thickness: 1, color: AppColors.fieldBorder.withValues(alpha: 0.6)),
        ),
        title: Row(
          children: [
            Container(
              width: 46, height: 46,
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
                ),
                Row(
                  children: [
                    const SizedBox(
                      width: 7, height: 7,
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
                  snapshot.connectionState == ConnectionState.waiting && messages.isEmpty;

              return Column(
                children: [
                  Expanded(
                    child: initialLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: AppColors.primary))
                        : messages.isEmpty
                            ? _buildEmptyState()
                            : _buildMessageList(messages),
                  ),
                  if (vm.isLoading) const _TypingIndicator(),
                  if (messages.isEmpty && !initialLoading) _buildSuggestionRow(),
                  _buildInputArea(vm),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMessageList(List<Map<String, dynamic>> messages) {
    final reversed = messages.reversed.toList();
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: reversed.length,
      itemBuilder: (context, index) => _MessageBubble(msg: reversed[index]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88, height: 88,
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
            const Text(
              'How are you feeling today?',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              "I'm here to listen and support you.\nShare what's on your mind.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textMedium, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ChatbotViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded, color: AppColors.errorRed, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            Text(
              vm.errorMessage ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textMedium, height: 1.4),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionRow() {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _SuggestionChip(
              icon: '😊',
              label: "I'm feeling happy!",
              onTap: () => _handleSend("I'm feeling happy!")),
          _SuggestionChip(
              icon: '😓',
              label: "I'm stressed",
              onTap: () => _handleSend("I'm feeling stressed")),
          _SuggestionChip(
              icon: '😴',
              label: "I can't sleep",
              onTap: () => _handleSend("I can't sleep")),
        ],
      ),
    );
  }

  Widget _buildInputArea(ChatbotViewModel vm) {
    final canSend = _hasText && !vm.isLoading;
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
                  hintStyle: TextStyle(color: AppColors.textLight, fontSize: 14),
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
            width: 48, height: 48,
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
              width: 30, height: 30,
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
                        fontWeight:
                            isUser ? FontWeight.w600 : FontWeight.w500,
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
    for (final c in _controllers) { c.dispose(); }
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
            width: 28, height: 28,
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
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                    width: 7, height: 7,
                    transform: Matrix4.translationValues(
                        0, _animations[i].value, 0),
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
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
