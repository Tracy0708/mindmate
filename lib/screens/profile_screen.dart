import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../main.dart';
import '../viewmodels/theme_viewmodel.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final String displayName = user?.displayName ?? 'New User';
    final String email = user?.email ?? 'No email';
    final String initials = displayName.isNotEmpty 
        ? displayName.trim().split(RegExp(r'\s+')).map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: AppColors.creamLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            children: [
              const SizedBox(height: 32),
              // Profile Header
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: const BoxDecoration(color: Color(0xFFFFE0A0), shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(initials, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: AppColors.golden)),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                      child: const Icon(Icons.check, color: Colors.white, size: 14),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Text(displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.brownDark)),
              const SizedBox(height: 4),
              Text(email, style: const TextStyle(fontSize: 14, color: AppColors.brownMedium)),
              const SizedBox(height: 32),

              // Horizontal Stats
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ProfileStatBox(value: '45', label: 'Streak Days'),
                    _ProfileStatBox(value: '12', label: 'Badges'),
                    _ProfileStatBox(value: '89%', label: 'Complete'),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Recent Achievements header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.golden.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.emoji_events, color: AppColors.golden, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('Recent Achievements', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.brownDark)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Recent achievements boxes
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: const [
                    _AchievementBox(icon: Icons.ads_click, color: Color(0xFFE91E63)),
                    _AchievementBox(icon: Icons.star, color: Color(0xFFFFB300)),
                    _AchievementBox(icon: Icons.local_fire_department, color: Color(0xFFFF5722)),
                  ],
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
                      decoration: BoxDecoration(color: AppColors.golden.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.settings, color: AppColors.golden, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.brownDark)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Settings List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const _SettingsItem(icon: Icons.notifications_none, label: 'Notifications', trailingLabel: 'On'),
                    Consumer<ThemeViewModel>(
                      builder: (context, vm, _) => _SettingsItem(
                        icon: Icons.nightlight_round,
                        label: 'Dark Mode',
                        trailingLabel: vm.isDarkMode ? 'On' : 'Off',
                        onTap: () => vm.toggleDarkMode(!vm.isDarkMode),
                      ),
                    ),
                    const _SettingsItem(icon: Icons.language, label: 'Language', trailingLabel: 'English'),
                    const _SettingsItem(icon: Icons.shield_outlined, label: 'Privacy'),
                    const _SettingsItem(icon: Icons.help_outline, label: 'Help & Support'),
                    _SettingsItem(
                      icon: Icons.logout,
                      label: 'Logout',
                      isDestructive: true,
                      onTap: () async {
                        await AuthService().signOut();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                        }
                      },
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditProfile(context),
        backgroundColor: AppColors.golden,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.edit),
      ),
    );
  }

  void _showEditProfile(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(32),
        backgroundColor: Colors.white,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Text(
                'Edit Profile',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.golden, decoration: TextDecoration.underline, decorationColor: AppColors.golden, decorationThickness: 2),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.golden, width: 2)),
                child: const Icon(Icons.face, size: 40, color: AppColors.brownMedium),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Full Name', style: TextStyle(color: AppColors.brownDark, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _EditField(hint: AuthService().currentUser?.displayName ?? 'Your Name', icon: Icons.person),
            const SizedBox(height: 16),
            const Text('Email Address', style: TextStyle(color: AppColors.brownDark, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _EditField(hint: AuthService().currentUser?.email ?? 'Your Email', icon: Icons.email),
            const SizedBox(height: 16),
            const Text('Age', style: TextStyle(color: AppColors.brownDark, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const _EditField(hint: 'Age', icon: Icons.cake),
            const SizedBox(height: 32),
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.golden,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.brownMedium, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final String hint;
  final IconData icon;
  const _EditField({required this.hint, required this.icon});

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.brownLight),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.fieldBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.fieldBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.golden)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class _ProfileStatBox extends StatelessWidget {
  final String value, label;
  const _ProfileStatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldBorder.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.golden)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.brownMedium)),
        ],
      ),
    );
  }
}

class _AchievementBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _AchievementBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.fieldBorder.withOpacity(0.5)),
      ),
      child: Center(
        child: Icon(icon, size: 48, color: color),
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

  const _SettingsItem({required this.icon, required this.label, this.trailingLabel, this.isDestructive = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.errorRed : AppColors.brownDark;
    
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: isDestructive ? color : AppColors.brownMedium, size: 22),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w500))),
            if (trailingLabel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.golden.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(trailingLabel!, style: const TextStyle(color: AppColors.golden, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
          ],
        ),
      ),
    );
  }
}
