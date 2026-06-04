import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../main.dart';
import '../../services/admin_service.dart';
import '../../services/interactive_message_service.dart';
import '../../services/fcm_service.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final AdminService _adminService = AdminService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleLogin() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      InteractiveMessageService.showError(
        context,
        title: 'Missing credentials',
        message: 'Please enter email and password',
      );
      return;
    }

    try {
      setState(() => _isLoading = true);
      final uc = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      final profile = await _adminService.getUserById(uc.user!.uid);
      final isAdmin = profile?.role == 'admin';
      final isDisabled = profile?.isDisabled ?? false;

      if (!isAdmin || isDisabled) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        InteractiveMessageService.showError(
          context,
          title: 'Access denied',
          message: isDisabled
              ? 'This admin account is disabled.'
              : 'Only users with the admin role can access this portal.',
        );
        return;
      }

      await FCMService().initialize();
      if (!mounted) return;
      InteractiveMessageService.showSuccess(
        context,
        title: 'Admin access granted',
        message: 'Welcome to the MindMate admin portal',
        duration: const Duration(seconds: 1),
      );
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/admin-dashboard');
        }
      });
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        InteractiveMessageService.showError(
          context,
          title: 'Authentication failed',
          message: e.message ?? 'Unable to sign in',
        );
      }
    } catch (e) {
      if (mounted) {
        InteractiveMessageService.showError(
          context,
          title: 'Admin login failed',
          message: e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFF9EC),
                  Color(0xFFFFF1D1),
                  Color(0xFFFFFBF3),
                ],
              ),
            ),
          ),
          Positioned(
            top: -60,
            right: -20,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha:0.10),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.textDark.withValues(alpha:0.06),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight - 40),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                                color: AppColors.fieldBorder.withValues(alpha:0.55)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha:0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: SizedBox(
                                  width: 130,
                                  height: 130,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Transform.scale(
                                      scale: 1.1,
                                      child: Image.asset(
                                        'assets/images/MindMate_Logo_Admin.png',
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 120,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                              Icons.admin_panel_settings_rounded,
                                              size: 38,
                                              color: AppColors.textDark),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Center(
                                child: Text(
                                  'MINDMATE',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Center(
                                child: Text(
                                  'Admin Portal',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textMedium,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha:0.10),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text(
                                    'Authorized staff only',
                                    style: TextStyle(
                                      color: AppColors.textDark,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),
                              TextField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  hintText: 'Email address',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                              ),
                              const SizedBox(height: 18),
                              TextField(
                                controller: _passCtrl,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) {
                                  if (!_isLoading) {
                                    _handleLogin();
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.textDark,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: _isLoading
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: AppColors.textDark,
                                          ),
                                        )
                                      : const Icon(Icons.login_rounded),
                                  label: Text(
                                    _isLoading ? 'Signing in...' : 'Sign In',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        if (Navigator.canPop(context)) {
                                          Navigator.pop(context);
                                        } else {
                                          Navigator.pushReplacementNamed(context, '/');
                                        }
                                      },
                                style: TextButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text(
                                  'Back to regular login',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
