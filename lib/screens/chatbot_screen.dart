import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  late String _userId;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatbotViewModel>(context, listen: false).startNewSession(_userId);
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  void _handleSend([String? presetMessage]) {
    final text = presetMessage ?? _msgController.text.trim();
    if (text.isEmpty) return;
    
    Provider.of<ChatbotViewModel>(context, listen: false).sendMessage(_userId, text);
    if (presetMessage == null) _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamLight,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MindMate AI',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
                Text(
                  'Online • Ready to chat',
                  style: TextStyle(fontSize: 13, color: AppColors.textMedium.withOpacity(0.8), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Consumer<ChatbotViewModel>(
        builder: (context, vm, child) {
          if (vm.errorMessage != null) {
            return Center(child: Text("Error: ${vm.errorMessage}", style: const TextStyle(color: AppColors.errorRed)));
          }

          return Column(
            children: [
              Expanded(
                child: StreamBuilder<ChatbotSession>(
                  stream: vm.getSessionMessages(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                    }
                    if (!snapshot.hasData || snapshot.data!.messages.isEmpty) {
                      return const Center(child: Text('Say hi to start the conversation!', style: TextStyle(color: AppColors.textMedium)));
                    }

                    final messages = snapshot.data!.messages.reversed.toList();
                    
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isUser = msg['isUser'] == true;
                        // Use actual timestamp if available, else current time
                        final timeString = TimeOfDay.now().format(context);

                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                            child: Column(
                              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                if (!isUser) ...[
                                  const Icon(Icons.cloud, color: Color(0xFFD1C4E9), size: 24),
                                  const SizedBox(height: 4),
                                ],
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: isUser ? AppColors.primary : Colors.white,
                                    borderRadius: BorderRadius.circular(20).copyWith(
                                      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                                      bottomLeft: !isUser ? const Radius.circular(4) : const Radius.circular(20),
                                    ),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        msg['content'] ?? '',
                                        style: TextStyle(
                                          color: isUser ? AppColors.textDark : AppColors.textDark,
                                          fontSize: 15,
                                          height: 1.4,
                                          fontWeight: isUser ? FontWeight.w600 : FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        timeString,
                                        style: TextStyle(
                                          color: isUser ? AppColors.textMedium : AppColors.textLight,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Suggestion Pills
              Container(
                height: 50,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _SuggestionChip(icon: '😊', label: "I'm feeling happy!", onTap: () => _handleSend("I'm feeling happy!")),
                    _SuggestionChip(icon: '😓', label: "I'm feeling stressed", onTap: () => _handleSend("I'm feeling stressed")),
                    _SuggestionChip(icon: '😴', label: "I can't sleep", onTap: () => _handleSend("I can't sleep")),
                  ],
                ),
              ),

              // Typing Indicator placeholder if loading
              if (vm.isLoading)
                const Padding(
                  padding: EdgeInsets.only(left: 24, bottom: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('MindMate AI is typing...', style: TextStyle(color: AppColors.textLight, fontSize: 12, fontStyle: FontStyle.italic)),
                  ),
                ),

              // Input Area
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: TextField(
                          controller: _msgController,
                          decoration: const InputDecoration(
                            hintText: 'Type your message...',
                            hintStyle: TextStyle(color: AppColors.textLight),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          onSubmitted: (_) => _handleSend(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _handleSend(),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded, color: AppColors.textDark, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
