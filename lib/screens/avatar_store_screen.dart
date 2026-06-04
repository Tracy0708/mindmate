import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../viewmodels/gamification_viewmodel.dart';
import '../main.dart';
import '../services/interactive_message_service.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/app_emoji.dart';

class AvatarStoreScreen extends StatefulWidget {
  const AvatarStoreScreen({super.key});

  @override
  State<AvatarStoreScreen> createState() => _AvatarStoreScreenState();
}

class _AvatarStoreScreenState extends State<AvatarStoreScreen> {
  final AuthService _authService = AuthService();
  UserModel? _userProfile;
  bool _isLoading = true;

  final List<Map<String, dynamic>> _availableAvatars = [
    {'id': 'default', 'emoji': '👤', 'name': 'Default', 'cost': 0},
    {'id': 'fox', 'emoji': '🦊', 'name': 'Clever Fox', 'cost': 100},
    {'id': 'owl', 'emoji': '🦉', 'name': 'Wise Owl', 'cost': 200},
    {'id': 'bear', 'emoji': '🐻', 'name': 'Brave Bear', 'cost': 300},
    {'id': 'panda', 'emoji': '🐼', 'name': 'Peaceful Panda', 'cost': 400},
    {'id': 'lion', 'emoji': '🦁', 'name': 'Courageous Lion', 'cost': 500},
    {'id': 'butterfly', 'emoji': '🦋', 'name': 'Gentle Butterfly', 'cost': 600},
    {'id': 'turtle', 'emoji': '🐢', 'name': 'Patient Turtle', 'cost': 700},
    {'id': 'dolphin', 'emoji': '🐬', 'name': 'Playful Dolphin', 'cost': 800},
    {'id': 'deer', 'emoji': '🦌', 'name': 'Graceful Deer', 'cost': 900},
    {'id': 'koala', 'emoji': '🐨', 'name': 'Restful Koala', 'cost': 1000},
    {'id': 'hedgehog', 'emoji': '🦔', 'name': 'Cozy Hedgehog', 'cost': 1100},
    {'id': 'swan', 'emoji': '🦢', 'name': 'Serene Swan', 'cost': 1200},
    {'id': 'otter', 'emoji': '🦦', 'name': 'Cheerful Otter', 'cost': 1300},
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final profile = await _authService.getUserProfile();
    if (mounted) {
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    }
  }

  List<String> get _unlockedAvatars {
    final list = _userProfile?.settings['unlockedAvatars'] as List<dynamic>?;
    return list?.map((e) => e.toString()).toList() ?? ['default'];
  }

  String get _equippedAvatar {
    return _userProfile?.settings['equippedAvatar'] as String? ?? 'default';
  }

  Future<void> _unlockAvatar(String id, int cost) async {
    final gamVm = Provider.of<GamificationViewModel>(context, listen: false);
    
    if (gamVm.totalPoints < cost) {
      InteractiveMessageService.showError(context, title: 'Not enough points', message: 'Keep logging your moods to earn more!');
      return;
    }

    // Spend points
    final success = await gamVm.spendPoints(id, cost);
    if (success) {
      // Unlock in Firestore
      await _authService.unlockAvatar(id);
      await _loadProfile(); // Refresh UI
      if (mounted) {
        InteractiveMessageService.showSuccess(context, title: 'Unlocked! 🎉', message: 'You can now equip this avatar.');
      }
    } else {
      if (mounted) {
        InteractiveMessageService.showError(context, title: 'Error', message: 'Failed to process transaction.');
      }
    }
  }

  Future<void> _equipAvatar(String id) async {
    await _authService.updateEquippedAvatar(id);
    await _loadProfile(); // Refresh UI
    if (mounted) {
      InteractiveMessageService.showSuccess(context, title: 'Avatar Equipped', message: 'Your profile has been updated.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final gamVm = Provider.of<GamificationViewModel>(context);

    return Scaffold(
      backgroundColor: AppColors.creamLight,
      body: SafeArea(
        child: Column(
          children: [
            const AppScreenHeader(
              title: 'Avatar Store',
              subtitle: 'Spend points to unlock avatars.',
              icon: Icons.storefront_rounded,
              showBack: true,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : Column(
                      children: [
                // Points Header
                Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFFFFCC4D)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.textDark.withValues(alpha: 0.12), shape: BoxShape.circle),
                        child: const Icon(Icons.star, color: AppColors.textDark, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${gamVm.totalPoints}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textDark)),
                            const Text('Available Points', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Avatar Grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.74,
                    ),
                    itemCount: _availableAvatars.length,
                    itemBuilder: (context, index) {
                      final avatar = _availableAvatars[index];
                      final id = avatar['id'] as String;
                      final emoji = avatar['emoji'] as String;
                      final name = avatar['name'] as String;
                      final cost = avatar['cost'] as int;

                      final isUnlocked = _unlockedAvatars.contains(id);
                      final isEquipped = _equippedAvatar == id;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        decoration: BoxDecoration(
                          color: isEquipped ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isEquipped ? AppColors.primary : (isUnlocked ? AppColors.fieldBorder : Colors.transparent),
                            width: isEquipped ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Dim locked avatars so unlocked ones stand out.
                            Opacity(
                              opacity: isUnlocked ? 1.0 : 0.4,
                              child: AppEmoji(emoji, size: 48),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isUnlocked ? AppColors.textDark : AppColors.textMedium,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (isEquipped)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.primary, width: 1.5),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle, color: AppColors.primary, size: 14),
                                    SizedBox(width: 6),
                                    Text('Equipped', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w800)),
                                  ],
                                ),
                              )
                            else if (isUnlocked)
                              OutlinedButton(
                                onPressed: () => _equipAvatar(id),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textDark,
                                  side: const BorderSide(color: AppColors.fieldBorder, width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  minimumSize: const Size(double.infinity, 40),
                                ),
                                child: const Text('Equip', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                              )
                            else
                              InkWell(
                                onTap: () => _unlockAvatar(id, cost),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [AppColors.primary, Color(0xFFFFCC4D)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3)),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.lock_open_rounded, color: AppColors.textDark, size: 14),
                                      const SizedBox(width: 6),
                                      Text('$cost pts', style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w800)),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            ),
          ],
        ),
      ),
    );
  }
}
