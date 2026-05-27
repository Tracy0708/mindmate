import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../main.dart';
import '../services/interactive_message_service.dart';
import '../services/gamification_service.dart';
import '../viewmodels/emotion_viewmodel.dart';
import '../viewmodels/gamification_viewmodel.dart';
import '../widgets/app_settings_tile.dart';
import '../widgets/app_emoji.dart';
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
    final prefs = _userProfile?.settings['notificationPrefs'] as Map<String, dynamic>?;
    if (prefs == null || prefs.isEmpty) return true;
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(28),
          backgroundColor: Colors.white,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Text('Edit Profile',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(_email,
                      style: const TextStyle(
                          color: AppColors.textMedium, fontSize: 13)),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    width: 80, height: 80,
                    decoration: const BoxDecoration(
                        color: AppColors.primaryLight, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: _avatarEmoji.isNotEmpty
                        ? AppEmoji(_avatarEmoji, size: 40)
                        : Text(_initials,
                            style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary)),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Full Name',
                    style: TextStyle(
                        color: AppColors.textDark, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.textLight),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.fieldBorder)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.fieldBorder)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Age',
                    style: TextStyle(
                        color: AppColors.textDark, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.cake_outlined, color: AppColors.textLight),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.fieldBorder)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.fieldBorder)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Gender',
                    style: TextStyle(
                        color: AppColors.textDark, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedGender,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.people_outline, color: AppColors.textLight),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.fieldBorder)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.fieldBorder)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                                    age: int.tryParse(ageController.text.trim()),
                                    gender: selectedGender,
                                  );
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
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  _loadProfile();
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
                                      onRetry: () {},
                                    );
                                  }
                                } finally {
                                  setDialogState(() => isSaving = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                height: 22, width: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: AppColors.textDark))
                            : const Text('Save Changes',
                                style: TextStyle(
                                    color: AppColors.textDark, fontWeight: FontWeight.w700)),
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
                                color: AppColors.textMedium,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamLight,
      body: SafeArea(
        child: _isLoadingProfile
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _refreshProfile,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 120),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),

                      // ── PROFILE HEADER ──
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 100, height: 100,
                            decoration: const BoxDecoration(
                                color: AppColors.primaryLight, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: _avatarEmoji.isNotEmpty
                                ? AppEmoji(_avatarEmoji, size: 50)
                                : Text(_initials,
                                    style: const TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary)),
                          ),
                          GestureDetector(
                            onTap: () => _showEditProfile(context),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                  color: Colors.white, shape: BoxShape.circle),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                    color: AppColors.primary, shape: BoxShape.circle),
                                child: const Icon(Icons.edit, color: AppColors.textDark, size: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(_displayName,
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark)),
                      const SizedBox(height: 4),
                      Text(_email,
                          style: const TextStyle(fontSize: 14, color: AppColors.textMedium)),
                      if (_userProfile?.age != null || _userProfile?.gender != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          [
                            if (_userProfile?.age != null) '${_userProfile!.age} years old',
                            if (_userProfile?.gender != null) _userProfile!.gender!,
                          ].join(' • '),
                          style: const TextStyle(fontSize: 13, color: AppColors.textLight),
                        ),
                      ],
                      const SizedBox(height: 36),

                      // ── AVATAR LIBRARY CARD ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: GestureDetector(
                          onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const AvatarStoreScreen()))
                              .then((_) => _loadProfile()),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withOpacity(0.15),
                                  AppColors.primary.withOpacity(0.04),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.15),
                                    shape: BoxShape.circle),
                                child: const AppEmoji('🦊', size: 28),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Avatar Store',
                                          style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textDark)),
                                      SizedBox(height: 3),
                                      Text('Unlock & equip avatars with your points',
                                          style: TextStyle(
                                              fontSize: 12, color: AppColors.textMedium)),
                                    ]),
                              ),
                              const Icon(Icons.chevron_right,
                                  color: AppColors.primary, size: 24),
                            ]),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── SETTINGS HEADER ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.settings,
                                color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Text('Settings',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark)),
                        ]),
                      ),
                      const SizedBox(height: 16),

                      // ── SETTINGS LIST ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                          child: Column(children: [
                            AppSettingsTile(
                              icon: Icons.notifications_none,
                              label: 'Notifications',
                              trailingLabel: _notificationsEnabled ? 'On' : 'Off',
                              onTap: () async {
                                await Navigator.pushNamed(context, '/notifications-settings');
                                _loadProfile();
                              },
                            ),
                            AppSettingsTile(
                              icon: Icons.shield_outlined,
                              label: 'Privacy',
                              onTap: () =>
                                  Navigator.pushNamed(context, '/privacy'),
                            ),
                            AppSettingsTile(
                              icon: Icons.help_outline,
                              label: 'Help & Support',
                              onTap: () => Navigator.pushNamed(
                                  context, '/help-support'),
                            ),
                            AppSettingsTile(
                              icon: Icons.logout,
                              label: 'Log out',
                              isDestructive: true,
                              onTap: () async {
                                await AuthService().signOut();
                                if (context.mounted) {
                                  Navigator.pushNamedAndRemoveUntil(
                                      context, '/', (route) => false);
                                }
                              },
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

