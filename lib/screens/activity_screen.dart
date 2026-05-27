import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_twemoji/flutter_twemoji.dart';
import '../main.dart';
import '../services/emotion_service.dart';
import '../viewmodels/emotion_viewmodel.dart';
import '../viewmodels/gamification_viewmodel.dart';
import '../services/interactive_message_service.dart';
import '../widgets/app_emoji.dart';

class ActivityScreen extends StatefulWidget {
  final RecommendedActivity activity;
  const ActivityScreen({super.key, required this.activity});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with TickerProviderStateMixin {
  bool _isActive = false;
  bool _isCompleted = false;
  int _elapsedSeconds = 0;
  Timer? _timer;

  // TTS
  final FlutterTts _tts = FlutterTts();
  bool _voiceEnabled = true;

  // Breathing
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;
  String _breathPhase = 'Ready';
  int _breathCycle = 0;
  static const int _totalBreathCycles = 4;

  // Journaling
  final TextEditingController _journalController = TextEditingController();

  // Steps (auto-advance)
  int _currentStep = 0;
  Timer? _stepTimer;
  int _stepCountdown = 0;
  static const int _stepDurationSeconds = 10; // seconds per step

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _breathAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45); // calm, slow pace
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stepTimer?.cancel();
    _breathController.dispose();
    _journalController.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    if (!_voiceEnabled) return;
    // Strip quotes for cleaner speech
    final clean = text.replaceAll('"', '').replaceAll('"', '').replaceAll('"', '');
    await _tts.speak(clean);
  }

  void _toggleVoice() {
    setState(() => _voiceEnabled = !_voiceEnabled);
    if (!_voiceEnabled) _tts.stop();
    HapticFeedback.lightImpact();
  }

  void _startActivity() {
    setState(() => _isActive = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
    });

    final type = widget.activity.activityType;
    if (type == 'breathing') {
      _speak('Let\'s begin. Inhale deeply.');
      _runBreathPhase();
    } else if (type == 'journaling') {
      _speak('Take your time to write about 3 things you\'re grateful for.');
    } else {
      // Step-based: start auto-advance
      _speakCurrentStep();
      _startStepTimer();
    }
  }

  // ─── Breathing ───
  void _runBreathPhase() {
    if (_breathCycle >= _totalBreathCycles) { _completeActivity(); return; }
    setState(() => _breathPhase = 'Inhale');
    _speak('Inhale');
    _breathController.forward(from: 0.0);
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted || _isCompleted) return;
      setState(() => _breathPhase = 'Hold');
      _speak('Hold');
      Future.delayed(const Duration(seconds: 4), () {
        if (!mounted || _isCompleted) return;
        setState(() => _breathPhase = 'Exhale');
        _speak('Exhale');
        _breathController.reverse();
        Future.delayed(const Duration(seconds: 4), () {
          if (!mounted || _isCompleted) return;
          setState(() => _breathPhase = 'Hold');
          _speak('Hold');
          Future.delayed(const Duration(seconds: 4), () {
            if (!mounted || _isCompleted) return;
            _breathCycle++;
            _runBreathPhase();
          });
        });
      });
    });
  }

  // ─── Steps ───
  List<String> _getSteps() {
    switch (widget.activity.activityType) {
      case 'relaxation':
        return [
          'Close your eyes and take 3 deep breaths.',
          'Tense your feet tightly for 5 seconds… then release.',
          'Tense your calves for 5 seconds… then release.',
          'Tense your thighs for 5 seconds… then release.',
          'Clench your fists for 5 seconds… then release.',
          'Tense your shoulders for 5 seconds… then release.',
          'Scrunch your face for 5 seconds… then release.',
          'Take 3 final deep breaths. Notice how relaxed you feel.',
        ];
      case 'meditation':
        return [
          'Find a comfortable position and close your eyes.',
          'Bring attention to the top of your head.',
          'Move awareness to your forehead and face. Relax.',
          'Shift focus to your neck and shoulders.',
          'Notice your arms and hands. Let them feel heavy.',
          'Bring awareness to your chest. Feel each breath.',
          'Move to your stomach. Notice it rise and fall.',
          'Shift to your legs and feet. Feel grounded.',
          'Take 3 deep breaths. Open your eyes when ready.',
        ];
      case 'affirmations':
        return [
          '"I am worthy of happiness and joy."',
          '"I choose to focus on what I can control."',
          '"I am grateful for this moment of peace."',
          '"My feelings are valid and I honor them."',
          '"I am growing stronger every day."',
          '"I deserve kindness — from others and myself."',
          '"Today is a fresh start, full of possibility."',
        ];
      case 'gratitude':
        return [
          'Think of one person who made you smile recently.',
          'Remember a small moment of beauty today.',
          'Consider something about your body you\'re grateful for.',
          'Recall a skill or ability you\'re thankful to have.',
          'Think about a place that brings you peace.',
          'Appreciate something simple — a warm drink, a soft breeze.',
          'Hold this feeling of gratitude for a few breaths.',
        ];
      default:
        return ['Follow along with the guided exercise.'];
    }
  }

  void _speakCurrentStep() {
    final steps = _getSteps();
    if (_currentStep < steps.length) {
      _speak(steps[_currentStep]);
    }
  }

  void _startStepTimer() {
    _stepCountdown = _stepDurationSeconds;
    _stepTimer?.cancel();
    _stepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isCompleted) { timer.cancel(); return; }
      setState(() => _stepCountdown--);
      if (_stepCountdown <= 0) {
        timer.cancel();
        _autoNextStep();
      }
    });
  }

  void _autoNextStep() {
    final steps = _getSteps();
    if (_currentStep < steps.length - 1) {
      setState(() => _currentStep++);
      HapticFeedback.mediumImpact(); // gentle vibration to signal transition
      _speakCurrentStep();
      _startStepTimer();
    } else {
      _completeActivity();
    }
  }

  void _manualNextStep() {
    _stepTimer?.cancel();
    final steps = _getSteps();
    if (_currentStep < steps.length - 1) {
      setState(() => _currentStep++);
      _tts.stop(); // stop current speech
      _speakCurrentStep();
      _startStepTimer();
    } else {
      _completeActivity();
    }
  }

  void _manualPrevStep() {
    if (_currentStep > 0) {
      _stepTimer?.cancel();
      setState(() => _currentStep--);
      _tts.stop();
      _speakCurrentStep();
      _startStepTimer();
    }
  }

  Future<void> _completeActivity() async {
    _timer?.cancel();
    _stepTimer?.cancel();
    await _tts.stop();
    setState(() => _isCompleted = true);
    _speak('Well done. You completed the activity.');
    HapticFeedback.heavyImpact();

    final vm = Provider.of<EmotionViewModel>(context, listen: false);
    final success = await vm.logCompletedActivity(
      title: widget.activity.title,
      activityType: widget.activity.activityType,
      duration: Duration(seconds: _elapsedSeconds),
      notes: widget.activity.activityType == 'journaling' ? _journalController.text : null,
    );
    if (mounted && success) {
      final gamVm = Provider.of<GamificationViewModel>(context, listen: false);
      await gamVm.awardActivityPoints(widget.activity.title);
      final actAch = await gamVm.checkActivityMilestones(vm.completedActivityCount);
      await gamVm.fetchUserStats();

      if (mounted) {
        InteractiveMessageService.showSuccess(context, title: 'Activity Complete! 🎉', message: 'Great job taking care of yourself. (+25 pts)');
        if (actAch != null) {
          InteractiveMessageService.showSuccess(context, title: 'Achievement Unlocked! 🏆', message: 'You earned ${actAch.achievement} (+${actAch.pointsEarned} pts)');
        }
      }
    }
  }

  String _formatTime(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamLight,
      appBar: AppBar(
        title: Text(widget.activity.title, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 20)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        actions: [
          // Voice toggle
          IconButton(
            icon: Icon(_voiceEnabled ? Icons.volume_up : Icons.volume_off, color: AppColors.primary),
            tooltip: _voiceEnabled ? 'Mute voice' : 'Enable voice',
            onPressed: _toggleVoice,
          ),
        ],
      ),
      body: _isCompleted ? _completedView() : _activityView(),
    );
  }

  Widget _activityView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        // Header card
        Container(
          width: double.infinity, padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.15), AppColors.primary.withOpacity(0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(children: [
            AppEmoji(widget.activity.emoji, size: 48),
            const SizedBox(height: 12),
            Text(widget.activity.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            const SizedBox(height: 8),
            Text(widget.activity.description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.textMedium, height: 1.5)),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Text('~${widget.activity.durationMinutes} min', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
              if (_isStepBased) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFF42A5F5).withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.volume_up, size: 14, color: const Color(0xFF42A5F5).withOpacity(0.8)),
                    const SizedBox(width: 4),
                    const Text('Voice guided', style: TextStyle(color: Color(0xFF42A5F5), fontWeight: FontWeight.w600, fontSize: 12)),
                  ]),
                ),
              ],
            ]),
          ]),
        ),
        const SizedBox(height: 32),
        if (_isActive) ...[
          Text(_formatTime(_elapsedSeconds), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.primary)),
          const SizedBox(height: 24),
        ],
        if (!_isActive)
          SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
            onPressed: _startActivity,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: const Text('Start Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          ))
        else ...[
          if (widget.activity.activityType == 'breathing') _breathingView()
          else if (widget.activity.activityType == 'journaling') _journalingView()
          else _stepView(),
        ],
      ]),
    );
  }

  bool get _isStepBased => !['breathing', 'journaling'].contains(widget.activity.activityType);

  // ─── BREATHING VIEW ───
  Widget _breathingView() {
    return Column(children: [
      AnimatedBuilder(
        animation: _breathAnimation,
        builder: (context, _) => Container(
          width: 200 * _breathAnimation.value, height: 200 * _breathAnimation.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [AppColors.primary.withOpacity(0.3), AppColors.primary.withOpacity(0.1)]),
            border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 3),
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 30 * _breathAnimation.value, spreadRadius: 10 * _breathAnimation.value)],
          ),
          child: Center(child: Text(_breathPhase, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark))),
        ),
      ),
      const SizedBox(height: 32),
      Text('Cycle ${_breathCycle + 1} of $_totalBreathCycles', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
      const SizedBox(height: 32),
      OutlinedButton(
        onPressed: _completeActivity,
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), side: const BorderSide(color: AppColors.primary)),
        child: const Text('End Early & Complete', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
      ),
    ]);
  }

  // ─── JOURNALING VIEW ───
  Widget _journalingView() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Write about 3 things you\'re grateful for:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
      const SizedBox(height: 16),
      TextField(
        controller: _journalController, maxLines: 10,
        decoration: InputDecoration(
          hintText: '1. I\'m grateful for...\n\n2. I appreciate...\n\n3. I\'m thankful for...',
          hintStyle: TextStyle(color: AppColors.textMedium.withOpacity(0.5)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.primary.withOpacity(0.5))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          filled: true, fillColor: Colors.white,
        ),
      ),
      const SizedBox(height: 24),
      SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
        onPressed: _completeActivity,
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: const Text('Save & Complete', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
      )),
    ]);
  }

  // ─── STEP VIEW (auto-advance + voice + manual controls) ───
  Widget _stepView() {
    final steps = _getSteps();
    final progress = (_currentStep + 1) / steps.length;

    return Column(children: [
      // Progress bar
      LinearProgressIndicator(
        value: progress,
        backgroundColor: AppColors.primary.withOpacity(0.15),
        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
        minHeight: 6,
        borderRadius: BorderRadius.circular(3),
      ),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Step ${_currentStep + 1} of ${steps.length}', style: const TextStyle(fontSize: 13, color: AppColors.textMedium, fontWeight: FontWeight.w600)),
        // Countdown indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.timer, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text('${_stepCountdown}s', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ]),
        ),
      ]),
      const SizedBox(height: 28),

      // Step content card
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(anim),
            child: child,
          ),
        ),
        child: Container(
          key: ValueKey(_currentStep),
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Column(children: [
            // Voice indicator
            if (_voiceEnabled)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.graphic_eq, size: 18, color: AppColors.primary.withOpacity(0.6)),
                  const SizedBox(width: 6),
                  Text('Listening...', style: TextStyle(fontSize: 12, color: AppColors.primary.withOpacity(0.6), fontWeight: FontWeight.w500)),
                ]),
              ),
            Text(
              steps[_currentStep],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textDark, height: 1.6),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 28),

      // Navigation controls: Prev / Skip Next
      Row(children: [
        // Previous
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _currentStep > 0 ? _manualPrevStep : null,
            icon: const Icon(Icons.skip_previous, size: 18),
            label: const Text('Prev'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              side: BorderSide(color: _currentStep > 0 ? AppColors.primary : AppColors.primary.withOpacity(0.3)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Next / Complete
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _manualNextStep,
            icon: Icon(_currentStep < steps.length - 1 ? Icons.skip_next : Icons.check_circle, size: 18, color: AppColors.textDark),
            label: Text(
              _currentStep < steps.length - 1 ? 'Next Step' : 'Complete',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ]),
      const SizedBox(height: 12),
      // End early
      TextButton(
        onPressed: _completeActivity,
        child: const Text('End Early & Complete', style: TextStyle(color: AppColors.textMedium, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    ]);
  }

  // ─── COMPLETED VIEW ───
  Widget _completedView() {
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 100, height: 100, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.check_circle, size: 64, color: AppColors.primary)),
      const SizedBox(height: 24),
      const TwemojiText(text: 'Well Done! 🎉', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textDark)),
      const SizedBox(height: 12),
      Text('You completed ${widget.activity.title} in ${_formatTime(_elapsedSeconds)}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: AppColors.textMedium, height: 1.5)),
      const SizedBox(height: 8),
      const Text('Taking time for self-care is a sign of strength.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.textLight, fontStyle: FontStyle.italic)),
      const SizedBox(height: 40),
      SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: const Text('Back to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
      )),
    ])));
  }
}
