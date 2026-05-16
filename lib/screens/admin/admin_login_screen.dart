import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../main.dart';
import '../../services/admin_service.dart';
import '../../services/interactive_message_service.dart';

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
      backgroundColor: AppColors.creamLight,
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
                color: AppColors.golden.withOpacity(0.10),
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
                color: AppColors.brownDark.withOpacity(0.06),
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
                                color: AppColors.fieldBorder.withOpacity(0.55)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
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
                                    foregroundColor: AppColors.brownMedium,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 6),
                                  ),
                                  icon: const Icon(Icons.arrow_back_rounded,
                                      size: 18),
                                  label: const Text('Back to login'),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Center(
                                child: Container(
                                  width: 92,
                                  height: 92,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.golden.withOpacity(0.20),
                                        AppColors.golden.withOpacity(0.06),
                                      ],
                                    ),
                                    border: Border.all(
                                        color:
                                            AppColors.golden.withOpacity(0.55),
                                        width: 2),
                                  ),
                                  child: const Icon(
                                      Icons.admin_panel_settings_rounded,
                                      size: 44,
                                      color: AppColors.brownDark),
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Center(
                                child: Text(
                                  'MINDMATE',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.golden,
                                    letterSpacing: 2.4,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Center(
                                child: Text(
                                  'Admin Portal',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.brownDark,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Center(
                                child: Text(
                                  'Sign in with an admin account to monitor users, review usage, and manage access.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.45,
                                    color: AppColors.brownMedium,
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
                                    color: AppColors.golden.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text(
                                    'Authorized staff only',
                                    style: TextStyle(
                                      color: AppColors.brownDark,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),
                              const Text('Email Address',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.brownDark)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  hintText: 'admin@mindmate.com',
                                  prefixIcon: const Icon(Icons.email_rounded,
                                      color: AppColors.brownMedium),
                                  filled: true,
                                  fillColor: const Color(0xFFFFFCF8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                        color: AppColors.fieldBorder),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                        color: AppColors.fieldBorder),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                        color: AppColors.golden, width: 2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text('Password',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.brownDark)),
                              const SizedBox(height: 8),
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
                                  hintText: 'Enter your password',
                                  prefixIcon: const Icon(Icons.lock_rounded,
                                      color: AppColors.brownMedium),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.brownLight,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFFFFCF8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                        color: AppColors.fieldBorder),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                        color: AppColors.fieldBorder),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                        color: AppColors.golden, width: 2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.golden,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  icon: _isLoading
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: Colors.white,
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
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Icon(Icons.security_rounded,
                                      size: 16,
                                      color: AppColors.brownMedium
                                          .withOpacity(0.9)),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Only admin accounts stored in Firebase can enter this portal.',
                                      style: TextStyle(
                                        color: AppColors.brownMedium,
                                        fontSize: 12,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
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
                                    color: AppColors.golden,
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
