import 'package:flutter/material.dart';
import '../main.dart';
import '../models/emotion_log.dart';
import '../services/interactive_message_service.dart';

class EmotionTrackingScreen extends StatefulWidget {
  const EmotionTrackingScreen({super.key});

  @override
  State<EmotionTrackingScreen> createState() => _EmotionTrackingScreenState();
}

class _EmotionTrackingScreenState extends State<EmotionTrackingScreen> {
  String? _selectedMood;
  final TextEditingController _noteController = TextEditingController();

  final List<Map<String, String>> _moods = [
    {'label': 'Happy', 'emoji': '😊'},
    {'label': 'Sad', 'emoji': '😢'},
    {'label': 'Anxious', 'emoji': '😰'},
    {'label': 'Angry', 'emoji': '😠'},
    {'label': 'Calm', 'emoji': '😌'},
    {'label': 'Tired', 'emoji': '😴'},
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _saveMood() {
    if (_selectedMood == null) {
      InteractiveMessageService.showError(
        context,
        title: 'Please select a mood',
        message: 'Choose how you\'re feeling before saving',
      );
      return;
    }
    // Simulation mapping...
    int score = 3;
    if (_selectedMood == 'Happy') score = 5;
    if (_selectedMood == 'Calm') score = 4;
    if (_selectedMood == 'Tired' || _selectedMood == 'Anxious') score = 2;
    if (_selectedMood == 'Sad' || _selectedMood == 'Angry') score = 1;

    final log = EmotionLog(
      logID: DateTime.now().millisecondsSinceEpoch.toString(),
      userID: '123', // mockup
      emotionType: _selectedMood!,
      intensityScore: score,
      notes: _noteController.text,
      timestamp: DateTime.now(),
    );

    InteractiveMessageService.showSuccess(
      context,
      title: 'Mood saved! 😊',
      message: 'You\'re feeling $_selectedMood',
      actionLabel: 'View Insights',
    );
    // Clearing for new entry
    setState(() {
      _selectedMood = null;
      _noteController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('How Are You Feeling?',
            style: TextStyle(
                color: AppColors.golden,
                fontWeight: FontWeight.w800,
                fontSize: 24)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _moods.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final mood = _moods[index];
                final isSelected = _selectedMood == mood['label'];

                return GestureDetector(
                  onTap: () => setState(() => _selectedMood = mood['label']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.golden.withOpacity(0.15)
                          : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.golden
                            : AppColors.golden.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(mood['emoji']!,
                            style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 8),
                        Text(
                          mood['label']!,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.golden
                                : AppColors.brownDark,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text('Add a note about your day',
                style: TextStyle(
                    color: AppColors.brownDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'What made you feel this way?',
                hintStyle:
                    TextStyle(color: AppColors.brownMedium.withOpacity(0.6)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: AppColors.golden, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                      color: AppColors.golden.withOpacity(0.5), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: AppColors.golden, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveMood,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.golden,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Save Mood Entry',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
