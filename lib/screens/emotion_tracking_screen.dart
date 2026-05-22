import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../viewmodels/emotion_viewmodel.dart';
import '../services/interactive_message_service.dart';
import '../viewmodels/gamification_viewmodel.dart';
import 'activity_screen.dart';
import 'dashboard_screen.dart';

class EmotionTrackingScreen extends StatefulWidget {
  const EmotionTrackingScreen({super.key});

  @override
  State<EmotionTrackingScreen> createState() => _EmotionTrackingScreenState();
}

class _EmotionTrackingScreenState extends State<EmotionTrackingScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedMood;
  final TextEditingController _noteController = TextEditingController();
  bool _showRecommendation = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<Map<String, String>> _moods = [
    {'label': 'Happy', 'emoji': '😊'},
    {'label': 'Sad', 'emoji': '😢'},
    {'label': 'Anxious', 'emoji': '😰'},
    {'label': 'Angry', 'emoji': '😠'},
    {'label': 'Calm', 'emoji': '😌'},
    {'label': 'Tired', 'emoji': '😴'},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _saveMood() async {
    if (_selectedMood == null) {
      InteractiveMessageService.showError(context, title: 'Please select a mood', message: 'Choose how you\'re feeling before saving');
      return;
    }

    final vm = Provider.of<EmotionViewModel>(context, listen: false);
    final wasLoggedToday = vm.hasLoggedToday;
    final success = await vm.submitEmotion(
      emotionType: _selectedMood!,
      notes: _noteController.text.isNotEmpty ? _noteController.text : null,
    );

    if (success && mounted) {
      if (!wasLoggedToday) {
        final gamVm = Provider.of<GamificationViewModel>(context, listen: false);
        await gamVm.awardMoodLogPoints();
        final streakAch = await gamVm.checkStreakMilestones(vm.streak);
        final firstAch = await gamVm.checkFirstLogMilestone(vm.logCount);
        final logAch = await gamVm.checkLogMilestones(vm.logCount);
        await gamVm.fetchUserStats();

        final allAch = [...streakAch, if (firstAch != null) firstAch, if (logAch != null) logAch];
        if (allAch.isNotEmpty && mounted) {
          for (var a in allAch) {
            InteractiveMessageService.showSuccess(context, title: 'Achievement Unlocked! 🏆', message: 'You earned ${a.achievement} (+${a.pointsEarned} pts)');
          }
        }
      }

      InteractiveMessageService.showSuccess(context, title: 'Mood saved! 😊', message: 'You\'re feeling $_selectedMood');
      setState(() => _showRecommendation = true);
      _animController.forward(from: 0);
    } else if (!success && mounted) {
      final err = vm.errorMessage ?? 'Unknown error';
      InteractiveMessageService.showError(context, title: 'Save failed', message: err, onRetry: _saveMood);
    }
  }

  void _startActivity() {
    final vm = Provider.of<EmotionViewModel>(context, listen: false);
    final activity = vm.recommendedActivity;
    if (activity == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => ActivityScreen(activity: activity)));
  }

  void _skipActivity() {
    setState(() {
      _showRecommendation = false;
      _selectedMood = null;
      _noteController.clear();
    });
    Provider.of<EmotionViewModel>(context, listen: false).clearRecommendation();
  }

  void _openChatbot() {
    Provider.of<EmotionViewModel>(context, listen: false).dismissChatbotPrompt();
    final dashState = context.findAncestorStateOfType<DashboardScreenState>();
    Navigator.of(context).popUntil((route) => route.isFirst);
    dashState?.navigateToTab(3);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EmotionViewModel>(builder: (context, vm, _) {
      // If today is already logged and showing recommendation
      if (_showRecommendation && vm.recommendedActivity != null) {
        return _buildRecommendationView(vm);
      }
      // If today's mood is already logged (from daily check-in), show summary
      if (vm.hasLoggedToday && vm.todaysLog != null && !_showRecommendation) {
        return _buildAlreadyLoggedView(vm);
      }
      return _buildMoodSelectionView(vm);
    });
  }

  // ─── Mood Selection View (NF2, NF3, NF4, NF5) ───
  Widget _buildMoodSelectionView(EmotionViewModel vm) {
    return Scaffold(
      backgroundColor: AppColors.creamLight,
      appBar: AppBar(
        title: const Text('How Are You Feeling?', style: TextStyle(color: AppColors.golden, fontWeight: FontWeight.w800, fontSize: 24)),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Mood grid
            GridView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              itemCount: _moods.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1),
              itemBuilder: (context, index) {
                final mood = _moods[index];
                final isSelected = _selectedMood == mood['label'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedMood = mood['label']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.golden.withOpacity(0.15) : Colors.white,
                      border: Border.all(color: isSelected ? AppColors.golden : AppColors.golden.withOpacity(0.3), width: isSelected ? 2.5 : 1),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isSelected ? [BoxShadow(color: AppColors.golden.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))] : [],
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      AnimatedScale(
                        scale: isSelected ? 1.2 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Text(mood['emoji']!, style: const TextStyle(fontSize: 32)),
                      ),
                      const SizedBox(height: 8),
                      Text(mood['label']!, style: TextStyle(color: isSelected ? AppColors.golden : AppColors.brownDark, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, fontSize: 13)),
                    ]),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // Notes field
            const Text('Add a note about your day', style: TextStyle(color: AppColors.brownDark, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController, maxLines: 5,
              decoration: InputDecoration(
                hintText: 'What made you feel this way?', hintStyle: TextStyle(color: AppColors.brownMedium.withOpacity(0.6)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.golden, width: 1)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.golden.withOpacity(0.5), width: 1)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.golden, width: 2)),
                filled: true, fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: vm.isSubmitting ? null : _saveMood,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.golden, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
              child: vm.isSubmitting
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Save Mood Entry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ]),
        ),
      ),
    );
  }

  // ─── Recommendation View (NF8, AF3, AF4) ───
  Widget _buildRecommendationView(EmotionViewModel vm) {
    final activity = vm.recommendedActivity!;
    return Scaffold(
      backgroundColor: AppColors.creamLight,
      appBar: AppBar(
        title: const Text('Your Recommendation', style: TextStyle(color: AppColors.golden, fontWeight: FontWeight.w800, fontSize: 22)),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            // Saved mood confirmation
            Container(
              width: double.infinity, padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 28),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Mood Logged!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.brownDark)),
                  Text('You\'re feeling ${vm.todaysLog?.emotionType ?? _selectedMood}', style: const TextStyle(fontSize: 13, color: AppColors.brownMedium)),
                ])),
              ]),
            ),
            // Mixed mood nudge — shown when selected emotion and notes diverge
            if (vm.todaysLog?.isMixedMood == true) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFB74D).withOpacity(0.5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💬', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'It\'s okay to feel mixed emotions',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.brownDark),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Your note sounds a bit heavier than your selected mood — emotions can be complex. Would you like to talk it through?',
                            style: TextStyle(fontSize: 13, color: AppColors.brownMedium, height: 1.4),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _openChatbot,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              backgroundColor: AppColors.golden.withValues(alpha: 0.12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Talk to AI Assistant', style: TextStyle(color: AppColors.golden, fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Activity recommendation card
            Container(
              width: double.infinity, padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Column(children: [
                Text(activity.emoji, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                const Text('We recommend', style: TextStyle(fontSize: 13, color: AppColors.brownMedium, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(activity.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.brownDark)),
                const SizedBox(height: 12),
                Text(activity.description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.brownMedium, height: 1.5)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.golden.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                  child: Text('~${activity.durationMinutes} min', style: const TextStyle(color: AppColors.golden, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
                const SizedBox(height: 24),
                // Start button
                SizedBox(width: double.infinity, height: 52, child: ElevatedButton.icon(
                  onPressed: _startActivity,
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                  label: const Text('Start Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.golden, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                )),
                const SizedBox(height: 12),
                // Skip button
                TextButton(
                  onPressed: _skipActivity,
                  child: const Text('Skip for now', style: TextStyle(color: AppColors.brownMedium, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),

            // AI Chatbot prompt (AF4)
            if (vm.showChatbotPrompt) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity, padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.golden.withOpacity(0.12), AppColors.golden.withOpacity(0.04)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.golden.withOpacity(0.3)),
                ),
                child: Column(children: [
                  const Icon(Icons.smart_toy_rounded, size: 40, color: AppColors.golden),
                  const SizedBox(height: 12),
                  const Text('We\'ve noticed you\'ve been feeling down lately', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.brownDark)),
                  const SizedBox(height: 8),
                  const Text('Would you like to talk to our AI Assistant?', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.brownMedium)),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: OutlinedButton(
                      onPressed: () => vm.dismissChatbotPrompt(),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: const BorderSide(color: AppColors.fieldBorder)),
                      child: const Text('No, thanks', style: TextStyle(color: AppColors.brownMedium)),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: ElevatedButton.icon(
                      onPressed: _openChatbot,
                      icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.white),
                      label: const Text('Yes, let\'s talk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.golden, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    )),
                  ]),
                ]),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  // ─── Already Logged View (when user comes back after daily check-in) ───
  Widget _buildAlreadyLoggedView(EmotionViewModel vm) {
    final log = vm.todaysLog!;
    final emoji = _moods.firstWhere((m) => m['label'] == log.emotionType, orElse: () => {'emoji': '🙂'})['emoji']!;
    return Scaffold(
      backgroundColor: AppColors.creamLight,
      appBar: AppBar(
        title: const Text('Today\'s Check-in', style: TextStyle(color: AppColors.golden, fontWeight: FontWeight.w800, fontSize: 22)),
        centerTitle: true,
      ),
      body: Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(emoji, style: const TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        Text('You\'re feeling ${log.emotionType}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.brownDark)),
        const SizedBox(height: 8),
        if (log.notes != null && log.notes!.isNotEmpty)
          Text('"${log.notes}"', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.brownMedium, fontStyle: FontStyle.italic, height: 1.5)),
        const SizedBox(height: 8),
        Text('Logged at ${TimeOfDay.fromDateTime(log.timestamp).format(context)}', style: const TextStyle(fontSize: 13, color: AppColors.brownLight)),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(color: const Color(0xFF4CAF50).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.local_fire_department, size: 18, color: Color(0xFF4CAF50)),
            const SizedBox(width: 6),
            Text('${vm.streak} day streak', style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
        ),
        const SizedBox(height: 32),
        const Text('✅ You\'ve already checked in today!', style: TextStyle(fontSize: 15, color: AppColors.brownMedium, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text('Come back tomorrow for your next check-in.', style: TextStyle(fontSize: 13, color: AppColors.brownLight)),
        if (log.isMixedMood) ...[
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFB74D).withValues(alpha: 0.5)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('💬  It\'s okay to feel mixed emotions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.brownDark)),
              const SizedBox(height: 6),
              const Text('Your note sounds heavier than your selected mood. Would you like to talk it through?', style: TextStyle(fontSize: 13, color: AppColors.brownMedium, height: 1.4)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _openChatbot,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  backgroundColor: AppColors.golden.withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Talk to AI Assistant', style: TextStyle(color: AppColors.golden, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ]),
          ),
        ],
      ]))),
    );
  }
}
