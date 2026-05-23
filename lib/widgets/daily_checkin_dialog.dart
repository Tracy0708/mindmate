import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../viewmodels/emotion_viewmodel.dart';
import '../viewmodels/gamification_viewmodel.dart';
import '../services/interactive_message_service.dart';

/// Bottom sheet dialog shown at app launch when no emotion has been logged today (NF1, NF2)
class DailyCheckinDialog extends StatefulWidget {
  final VoidCallback? onCompleted;
  final VoidCallback? onSkipped;
  final VoidCallback? onOpenChat;

  const DailyCheckinDialog({super.key, this.onCompleted, this.onSkipped, this.onOpenChat});

  /// Show this dialog as a modal bottom sheet
  static Future<void> show(BuildContext context, {VoidCallback? onCompleted, VoidCallback? onSkipped, VoidCallback? onOpenChat}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (_) => DailyCheckinDialog(onCompleted: onCompleted, onSkipped: onSkipped, onOpenChat: onOpenChat),
    );
  }

  @override
  State<DailyCheckinDialog> createState() => _DailyCheckinDialogState();
}

class _DailyCheckinDialogState extends State<DailyCheckinDialog> {
  String? _selectedMood;
  int _selectedIntensity = 3;
  final TextEditingController _noteController = TextEditingController();
  bool _showMixedNudge = false;

  final List<Map<String, String>> _moods = [
    {'label': 'Happy', 'emoji': '😊'},
    {'label': 'Sad', 'emoji': '😢'},
    {'label': 'Anxious', 'emoji': '😰'},
    {'label': 'Angry', 'emoji': '😠'},
    {'label': 'Calm', 'emoji': '😌'},
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedMood == null) {
      InteractiveMessageService.showError(context, title: 'Select a mood', message: 'Choose how you\'re feeling first');
      return;
    }
    final vm = Provider.of<EmotionViewModel>(context, listen: false);
    final wasLoggedToday = vm.hasLoggedToday;
    final success = await vm.submitEmotion(emotionType: _selectedMood!, intensity: _selectedIntensity, notes: _noteController.text.isNotEmpty ? _noteController.text : null);
    if (!mounted || !success) return;

    // Capture isMixedMood before any further awaits
    final isMixed = vm.todaysLog?.isMixedMood == true;

    if (!wasLoggedToday) {
      final gamVm = Provider.of<GamificationViewModel>(context, listen: false);
      await gamVm.awardMoodLogPoints();
      final streakAch = await gamVm.checkStreakMilestones(vm.streak);
      final firstAch = await gamVm.checkFirstLogMilestone(vm.logCount);
      await gamVm.fetchUserStats();

      if (mounted) {
        final allAch = [...streakAch, if (firstAch != null) firstAch];
        for (var a in allAch) {
          InteractiveMessageService.showSuccess(context, title: 'Achievement Unlocked! 🏆', message: 'You earned ${a.achievement} (+${a.pointsEarned} pts)');
        }
      }
    }

    if (!mounted) return;
    if (isMixed) {
      setState(() => _showMixedNudge = true);
    } else {
      Navigator.pop(context);
      widget.onCompleted?.call();
    }
  }

  void _skip() {
    final vm = Provider.of<EmotionViewModel>(context, listen: false);
    vm.dismissDailyPrompt();
    Navigator.pop(context);
    widget.onSkipped?.call();
  }

  void _dismissNudge() {
    Navigator.pop(context);
    widget.onCompleted?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EmotionViewModel>(builder: (context, vm, _) {
      if (_showMixedNudge) {
        return Container(
          margin: const EdgeInsets.only(top: 80),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 24),
                  const Text('💬', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  const Text(
                    "It's okay to feel mixed emotions",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Your note sounds a bit heavier than your selected mood — emotions can be complex. Would you like to talk it through with the AI Assistant?",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.textMedium, height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  Row(children: [
                    Expanded(child: OutlinedButton(
                      onPressed: _dismissNudge,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(color: AppColors.fieldBorder),
                      ),
                      child: const Text('No, thanks', style: TextStyle(color: AppColors.textMedium, fontWeight: FontWeight.w600)),
                    )),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onCompleted?.call();
                        widget.onOpenChat?.call();
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.textDark),
                      label: const Text("Let's talk", style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    )),
                  ]),
                ],
              ),
            ),
          ),
        );
      }

      return Container(
        margin: const EdgeInsets.only(top: 80),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(left: 24, right: 24, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Handle
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textLight.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            // Title
            const Text('How are you feeling today?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            const SizedBox(height: 6),
            const Text('Take a moment to check in with yourself', style: TextStyle(fontSize: 14, color: AppColors.textMedium)),
            const SizedBox(height: 24),
            // Mood grid
            GridView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              itemCount: _moods.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1),
              itemBuilder: (context, index) {
                final mood = _moods[index];
                final isSelected = _selectedMood == mood['label'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedMood = mood['label']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.white,
                      border: Border.all(color: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.3), width: isSelected ? 2 : 1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(mood['emoji']!, style: TextStyle(fontSize: isSelected ? 36 : 32)),
                      const SizedBox(height: 6),
                      Text(mood['label']!, style: TextStyle(color: isSelected ? AppColors.primary : AppColors.textDark, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, fontSize: 13)),
                    ]),
                  ),
                );
              },
            ),
            // Intensity slider
            if (_selectedMood != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('How intense is this feeling?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  Text(
                    ['Mild', 'Low', 'Moderate', 'Strong', 'Intense'][_selectedIntensity - 1],
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.primary.withValues(alpha: 0.2),
                  thumbColor: AppColors.primary,
                  overlayColor: AppColors.primary.withValues(alpha: 0.12),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _selectedIntensity.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  onChanged: (val) => setState(() => _selectedIntensity = val.round()),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Mild', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                    Text('Intense', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            // Quick note
            TextField(
              controller: _noteController, maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Quick note (optional)', hintStyle: TextStyle(color: AppColors.textMedium.withOpacity(0.5)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.primary.withOpacity(0.5))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                filled: true, fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            // Buttons
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: _skip,
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), side: const BorderSide(color: AppColors.fieldBorder)),
                child: const Text('Skip', style: TextStyle(color: AppColors.textMedium, fontWeight: FontWeight.w600)),
              )),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: ElevatedButton(
                onPressed: vm.isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: vm.isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textDark))
                    : const Text('Log & Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              )),
            ]),
          ]),
        ),
      );
    });
  }
}
