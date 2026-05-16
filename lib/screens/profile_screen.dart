import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../main.dart';
import '../services/interactive_message_service.dart';
import '../services/gamification_service.dart';
import '../viewmodels/emotion_viewmodel.dart';
import '../viewmodels/gamification_viewmodel.dart';
import 'gamification_screen.dart';
import 'avatar_store_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  UserModel? _userProfile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoadingProfile = true);
    final profile = await _authService.getUserProfile();
    if (mounted) {
      setState(() {
        _userProfile = profile;
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _refreshProfile() async {
    await _loadProfile();
    if (mounted) {
      Provider.of<GamificationViewModel>(context, listen: false).fetchUserStats();
      Provider.of<EmotionViewModel>(context, listen: false).checkTodaysLog();
    }
  }

  String get _displayName =>
      _userProfile?.userName ??
      _authService.currentUser?.displayName ??
      'New User';

  String get _email =>
      _userProfile?.userEmail ?? _authService.currentUser?.email ?? 'No email';

  String get _initials {
    final name = _displayName;
    if (name.isEmpty) return 'U';
    return name
        .trim()
        .split(RegExp(r'\s+'))
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();
  }

  String get _avatarEmoji {
    final avatarId = _userProfile?.settings['equippedAvatar'] as String? ?? 'default';
    if (avatarId == 'fox') return '🦊';
    if (avatarId == 'owl') return '🦉';
    if (avatarId == 'bear') return '🐻';
    if (avatarId == 'panda') return '🐼';
    if (avatarId == 'lion') return '🦁';
    return '';
  }

  bool get _notificationsEnabled {
    final prefs =
        _userProfile?.settings['notificationPrefs'] as Map<String, dynamic>?;
    if (prefs == null || prefs.isEmpty) return true; // default on
    return prefs.values.any((v) => v == true);
  }

  // ─── Edit Profile Dialog ───
  void _showEditProfile(BuildContext context) {
    final nameController = TextEditingController(text: _displayName);
    final ageController = TextEditingController(
        text: _userProfile?.age != null ? _userProfile!.age.toString() : '');
    String? selectedGender = _userProfile?.gender;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(28),
          backgroundColor: Colors.white,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Text(
                    'Edit Profile',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.golden),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _email,
                    style: const TextStyle(
                        color: AppColors.brownMedium, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFE0A0),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: _avatarEmoji.isNotEmpty
                        ? Text(_avatarEmoji, style: const TextStyle(fontSize: 40))
                        : Text(
                            _initials,
                            style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: AppColors.golden),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Full Name',
                    style: TextStyle(
                        color: AppColors.brownDark,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline,
                        color: AppColors.brownLight),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.fieldBorder)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.fieldBorder)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.golden, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Age',
                    style: TextStyle(
                        color: AppColors.brownDark,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.cake_outlined,
                        color: AppColors.brownLight),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.fieldBorder)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.fieldBorder)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.golden, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Gender',
                    style: TextStyle(
                        color: AppColors.brownDark,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.people_outline,
                        color: AppColors.brownLight),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.fieldBorder)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.fieldBorder)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.golden, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                  items: ['Male', 'Female', 'Other', 'Prefer not to say']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedGender = v),
                ),
                const SizedBox(height: 28),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                setDialogState(() => isSaving = true);
                                try {
                                  await _authService.updateUserProfile(
                                    name: nameController.text.trim(),
                                    age:
                                        int.tryParse(ageController.text.trim()),
                                    gender: selectedGender,
                                  );
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  // Record profile update in history feed
                                  final uid = _authService.currentUser?.uid;
                                  if (uid != null) {
                                    try {
                                      await GamificationService().recordAchievement(
                                        userID: uid,
                                        achievement: 'Profile Updated',
                                        points: 0,
                                        metadata: {'type': 'profile_update'},
                                      );
                                    } catch (_) {}
                                  }
                                  _loadProfile(); // refresh parent
                                  if (mounted) {
                                    InteractiveMessageService.showSuccess(
                                      context,
                                      title: 'Profile updated! ✨',
                                      message: 'Your changes have been saved',
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    InteractiveMessageService.showError(
                                      context,
                                      title: 'Update failed',
                                      message: e.toString(),
                                      onRetry: () {
                                        // Retry logic
                                      },
                                    );
                                  }
                                } finally {
                                  setDialogState(() => isSaving = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.golden,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white))
                            : const Text('Save Changes',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(
                                color: AppColors.brownMedium,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<EmotionViewModel, GamificationViewModel>(
      builder: (context, emotionVm, gamVm, _) {
        final streak = emotionVm.streak;
        final logCount = emotionVm.logCount;
        final completedActivities = emotionVm.completedActivityCount;
        final totalPoints = gamVm.totalPoints;
        final recentAch = (gamVm.userStats?['recentAchievements'] as List?) ?? [];

        // Determine unlocked badge count from real data
        int unlockedBadges = 0;
        if (streak >= 7) unlockedBadges++;
        if (logCount >= 10) unlockedBadges++;
        if (logCount >= 30) unlockedBadges++;
        if (streak >= 30) unlockedBadges++;

        return Scaffold(
          backgroundColor: AppColors.creamLight,
          body: SafeArea(
            child: _isLoadingProfile
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.golden))
                : RefreshIndicator(
                    color: AppColors.golden,
                    onRefresh: _refreshProfile,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 120),
                      child: Column(
                        children: [
                          const SizedBox(height: 32),
                          // Profile Header
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: const BoxDecoration(
                                    color: Color(0xFFFFE0A0),
                                    shape: BoxShape.circle),
                                alignment: Alignment.center,
                                child: _avatarEmoji.isNotEmpty
                                    ? Text(_avatarEmoji, style: const TextStyle(fontSize: 50))
                                    : Text(_initials,
                                        style: const TextStyle(
                                            fontSize: 40,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.golden)),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AvatarStoreScreen())).then((_) => _loadProfile());
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                      color: Colors.white, shape: BoxShape.circle),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                        color: AppColors.golden, shape: BoxShape.circle),
                                    child: const Icon(Icons.edit,
                                        color: Colors.white, size: 14),
                                  ),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(_displayName,
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.brownDark)),
                          const SizedBox(height: 4),
                          Text(_email,
                              style: const TextStyle(
                                  fontSize: 14, color: AppColors.brownMedium)),
                          if (_userProfile?.age != null ||
                              _userProfile?.gender != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              [
                                if (_userProfile?.age != null)
                                  '${_userProfile!.age} years old',
                                if (_userProfile?.gender != null)
                                  _userProfile!.gender!,
                              ].join(' • '),
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.brownLight),
                            ),
                          ],
                          const SizedBox(height: 32),

                          // Horizontal Stats — now real data
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _ProfileStatBox(
                                  value: streak > 0 ? '$streak' : '0',
                                  label: 'Streak Days',
                                  icon: Icons.local_fire_department,
                                ),
                                _ProfileStatBox(
                                  value: '$unlockedBadges',
                                  label: 'Badges',
                                  icon: Icons.workspace_premium,
                                ),
                                _ProfileStatBox(
                                  value: '$completedActivities',
                                  label: 'Activities',
                                  icon: Icons.check_circle_outline,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Points card
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.golden, Color(0xFFFF8F00)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: AppColors.golden.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                                    child: const Icon(Icons.star, color: Colors.white, size: 28),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('$totalPoints', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                                        const Text('Achievement Points', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70)),
                                      ],
                                    ),
                                  ),
                                  // Mood log count chip
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                                    child: Text('$logCount logs', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Recent Achievements header
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                      color: AppColors.golden.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.emoji_events,
                                      color: AppColors.golden, size: 20),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text('Recent Achievements',
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.brownDark)),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GamificationScreen())),
                                  child: const Text('See All →', style: TextStyle(color: AppColors.golden, fontWeight: FontWeight.w700, fontSize: 13)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 140,
                            child: recentAch.isEmpty 
                              ? const Center(child: Text('Complete activities to earn achievements!', style: TextStyle(color: AppColors.brownMedium)))
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  itemCount: recentAch.length,
                                  itemBuilder: (context, index) {
                                    final ach = recentAch[index] as Map<String, dynamic>;
                                    final title = ach['achievement'] as String;
                                    final points = ach['points'] as int;

                                    IconData icon = Icons.star;
                                    Color color = AppColors.golden;

                                    if (title.contains('Streak') || title.contains('Warrior') || title.contains('Master') || title.contains('Champion') || title.contains('Centurion')) {
                                      icon = Icons.emoji_events;
                                      color = const Color(0xFFFFB300);
                                    } else if (title.contains('Activity')) {
                                      icon = Icons.spa;
                                      color = const Color(0xFF009688);
                                    } else if (title.contains('First Step')) {
                                      icon = Icons.favorite;
                                      color = const Color(0xFFF44336);
                                    } else if (title.contains('Mood Logged')) {
                                      icon = Icons.edit_note;
                                      color = const Color(0xFF4CAF50);
                                    }

                                    // Truncate long activity titles
                                    String displayTitle = title.replaceAll('Activity Completed: ', '');
                                    if (displayTitle.length > 15) {
                                      displayTitle = '${displayTitle.substring(0, 13)}...';
                                    }

                                    return _AchievementBox(
                                      icon: icon,
                                      color: color,
                                      label: displayTitle,
                                      sublabel: points > 0 ? '+$points pts' : '$points pts',
                                      unlocked: true,
                                    );
                                  },
                                ),
                          ),
                          const SizedBox(height: 40),

                          // Settings Header
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                      color: AppColors.golden.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.settings,
                                      color: AppColors.golden, size: 20),
                                ),
                                const SizedBox(width: 12),
                                const Text('Settings',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.brownDark)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Settings List
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  _SettingsItem(
                                    icon: Icons.notifications_none,
                                    label: 'Notifications',
                                    trailingLabel:
                                        _notificationsEnabled ? 'On' : 'Off',
                                    onTap: () async {
                                      await Navigator.pushNamed(
                                          context, '/notifications-settings');
                                      _loadProfile(); // refresh after returning
                                    },
                                  ),
                                  const _SettingsItem(
                                      icon: Icons.shield_outlined,
                                      label: 'Privacy'),
                                  const _SettingsItem(
                                      icon: Icons.help_outline,
                                      label: 'Help & Support'),
                                  _SettingsItem(
                                    icon: Icons.logout,
                                    label: 'Logout',
                                    isDestructive: true,
                                    onTap: () async {
                                      await AuthService().signOut();
                                      if (context.mounted) {
                                        Navigator.pushNamedAndRemoveUntil(
                                            context, '/', (route) => false);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showEditProfile(context),
            backgroundColor: AppColors.golden,
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
          ),
        );
      },
    );
  }
}

class _ProfileStatBox extends StatelessWidget {
  final String value, label;
  final IconData icon;
  const _ProfileStatBox({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.fieldBorder.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.golden),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.golden)),
            const SizedBox(height: 4),
            Text(label,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.brownMedium)),
          ],
        ),
      ),
    );
  }
}

class _AchievementBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String sublabel;
  final bool unlocked;
  const _AchievementBox({
    required this.icon,
    required this.color,
    required this.label,
    required this.sublabel,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unlocked ? const Color(0xFFFFFDF5) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: unlocked ? AppColors.golden.withOpacity(0.3) : Colors.grey.withOpacity(0.15),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: unlocked ? color : Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: unlocked ? AppColors.brownDark : Colors.grey,
          )),
          const SizedBox(height: 4),
          Text(sublabel, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(
            fontSize: 11,
            color: unlocked ? AppColors.brownMedium : Colors.grey.shade400,
          )),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailingLabel;
  final bool isDestructive;
  final VoidCallback? onTap;

  const _SettingsItem(
      {required this.icon,
      required this.label,
      this.trailingLabel,
      this.isDestructive = false,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.errorRed : AppColors.brownDark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon,
                color: isDestructive ? color : AppColors.brownMedium, size: 22),
            const SizedBox(width: 16),
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.w500))),
            if (trailingLabel != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.golden.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(trailingLabel!,
                    style: const TextStyle(
                        color: AppColors.golden,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            if (!isDestructive && trailingLabel == null)
              const Icon(Icons.chevron_right,
                  color: AppColors.brownLight, size: 20),
          ],
        ),
      ),
    );
  }
}
