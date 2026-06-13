import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/emotion_log.dart';
import '../services/emotion_service.dart';
import '../viewmodels/emotion_viewmodel.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/app_emoji.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final EmotionService _emotionService = EmotionService();
  DateTime _currentMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  String _selectedFilter = 'All Moods';
  List<EmotionLog> _monthLogs = [];
  bool _isLoading = true;
  EmotionLog? _selectedDayLog;
  String? _lastSeenLogId;
  EmotionViewModel? _emotionViewModel;

  static const _emojiMap = {
    'Happy': '😊',
    'Sad': '😢',
    'Anxious': '😰',
    'Angry': '😠',
    'Calm': '😌',
  };

  static const _filters = [
    'All Moods',
    'Happy',
    'Sad',
    'Anxious',
    'Angry',
    'Calm'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _emotionViewModel = Provider.of<EmotionViewModel>(context, listen: false);
      _emotionViewModel!.addListener(_onEmotionChanged);
      _loadMonthData();
    });
  }

  @override
  void dispose() {
    _emotionViewModel?.removeListener(_onEmotionChanged);
    super.dispose();
  }

  void _onEmotionChanged() {
    if (!mounted) return;
    final newLogId = _emotionViewModel?.todaysLog?.logID;
    if (newLogId != null && newLogId != _lastSeenLogId) {
      _lastSeenLogId = newLogId;
      _loadMonthData();
    }
  }

  Future<void> _loadMonthData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
      final logs =
          await _emotionService.getRecentLogs(userId, days: lastDay.day + 30);
      _monthLogs = logs
          .where((log) =>
              log.timestamp.year == _currentMonth.year &&
              log.timestamp.month == _currentMonth.month)
          .toList();
    } catch (_) {
      _monthLogs = [];
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
      _selectedDayLog = null;
    });
    _loadMonthData();
  }

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    if (next.isAfter(DateTime(now.year, now.month + 1, 1))) return;
    setState(() {
      _currentMonth = next;
      _selectedDayLog = null;
    });
    _loadMonthData();
  }

  EmotionLog? _getLogForDay(int day) {
    final filtered = _monthLogs.where((log) => log.timestamp.day == day);
    if (filtered.isEmpty) return null;
    final log = filtered.first;

    // Apply filter
    if (_selectedFilter != 'All Moods' && log.emotionType != _selectedFilter) {
      return null;
    }
    return log;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth =
        _currentMonth.year == now.year && _currentMonth.month == now.month;
    final monthLabel = DateFormat('MMMM yyyy').format(_currentMonth);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            const AppScreenHeader(
              title: 'Calendar',
              subtitle: 'Your mood, day by day.',
              icon: Icons.calendar_month_rounded,
            ),
            // Filters
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;
                  final emoji =
                      filter != 'All Moods' ? _emojiMap[filter] : null;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedFilter = filter;
                        _selectedDayLog = null;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (emoji != null) ...[
                              AppEmoji(emoji, size: 14),
                              const SizedBox(width: 6)
                            ],
                            Text(
                              filter,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.textDark
                                    : AppColors.textDark,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Month navigator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _prevMonth,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_left,
                          color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    monthLabel,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: isCurrentMonth ? null : _nextMonth,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isCurrentMonth
                            ? Colors.grey.withValues(alpha: 0.1)
                            : AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_right,
                        color: isCurrentMonth ? Colors.grey : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Calendar grid
            Expanded(
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary))
                  : SingleChildScrollView(
                      // Generous bottom padding so the selected-day card has
                      // breathing room above the bottom nav instead of hugging it.
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: Column(
                        children: [
                          _buildCalendarGrid(now),
                          // Selected day detail
                          if (_selectedDayLog != null) ...[
                            const SizedBox(height: 20),
                            _buildDayDetail(_selectedDayLog!),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(DateTime now) {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0
    final totalCells = startWeekday + daysInMonth;
    final rows = ((totalCells) / 7).ceil();

    return Column(
      children: [
        // Day headers
        Row(
          children: days
              .map((d) => Expanded(
                    child: Center(
                      child: Text(d,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textLight,
                              fontSize: 13)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
        // Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rows * 7,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 0.75,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemBuilder: (context, index) {
            final day = index - startWeekday + 1;
            if (day < 1 || day > daysInMonth) {
              return const SizedBox.shrink();
            }

            final isToday = now.year == _currentMonth.year &&
                now.month == _currentMonth.month &&
                now.day == day;
            final log = _getLogForDay(day);
            final emoji = log != null ? _emojiMap[log.emotionType] : null;
            final isSelected = _selectedDayLog != null &&
                _selectedDayLog!.timestamp.day == day;

            return GestureDetector(
              onTap: () {
                if (log != null) {
                  setState(() => _selectedDayLog = log);
                } else {
                  setState(() => _selectedDayLog = null);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : (isToday
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : Colors.transparent),
                  borderRadius: BorderRadius.circular(12),
                  border: isToday
                      ? Border.all(color: AppColors.primary, width: 2)
                      : (isSelected
                          ? Border.all(color: AppColors.primary, width: 1.5)
                          : null),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        color: isToday ? AppColors.primary : AppColors.textDark,
                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (emoji != null) ...[
                      const SizedBox(height: 2),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AppEmoji(emoji, size: 16),
                          if (log!.isMixedMood)
                            Positioned(
                              top: -3,
                              right: -5,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF7043),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ] else
                      const SizedBox(height: 18),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDayDetail(EmotionLog log) {
    final emoji = _emojiMap[log.emotionType] ?? '🙂';
    final timeStr = DateFormat('h:mm a').format(log.timestamp);
    final dateStr = DateFormat('EEEE, MMMM d').format(log.timestamp);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppEmoji(emoji, size: 36),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.emotionType,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$dateStr at $timeStr',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textMedium),
                    ),
                  ],
                ),
              ),
              // Intensity badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _intensityColor(log.wellbeingScore.round())
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Intensity: ${log.intensityScore}/5',
                  style: TextStyle(
                    color: _intensityColor(log.wellbeingScore.round()),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (log.isMixedMood) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7043).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFFF7043).withValues(alpha: 0.35)),
              ),
              child: const Row(
                children: [
                  AppEmoji('💬', size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mixed mood detected — your note reflects a different emotional tone than your selected mood.',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFFBF360C), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (log.notes != null && log.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Notes',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textLight)),
                  const SizedBox(height: 6),
                  Text(
                    log.notes!,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textDark, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _intensityColor(int score) {
    if (score >= 4) return const Color(0xFF4CAF50);
    if (score >= 3) return AppColors.primary;
    return const Color(0xFFE53935);
  }
}
