import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../main.dart';
import 'admin_dashboard.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();

  Future<void> _handleLogin() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter email and password'),
            backgroundColor: AppColors.errorRed),
      );
      return;
    }

    try {
      // Simulate real admin logic. "Only admin users... can be granted access"
      final uc = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      // Usually you'd check a custom claim or a Firestore 'users' doc with role='admin'
      // But we just check if it's admin@mindmate.com
      if (uc.user?.email == 'admin@mindmate.com') {
        if (!mounted) return;
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
      } else {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Access denied. Admin only.'),
              backgroundColor: AppColors.errorRed),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.message ?? 'Authentication failed'),
            backgroundColor: AppColors.errorRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamLight,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.brownDark, width: 2),
                  ),
                  child: const Icon(Icons.psychology,
                      size: 40, color: AppColors.brownDark),
                ),
                const SizedBox(height: 16),
                const Text('MINDMATE',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.golden,
                        letterSpacing: 2)),
                const SizedBox(height: 32),
                const Text('Admin Portal',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.golden)),
                const SizedBox(height: 32),
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Email Address',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.brownDark))),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailCtrl,
                  decoration: InputDecoration(
                    hintText: 'admin@mindmate.com',
                    prefixIcon:
                        const Icon(Icons.email, color: AppColors.brownMedium),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.fieldBorder)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.golden, width: 2)),
                  ),
                ),
                const SizedBox(height: 20),
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Password',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.brownDark))),
                const SizedBox(height: 8),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    prefixIcon:
                        const Icon(Icons.lock, color: AppColors.brownMedium),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.fieldBorder)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.golden, width: 2)),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.golden,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.login),
                    label: const Text('Sign In',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.security,
                        size: 16, color: AppColors.brownMedium),
                    const SizedBox(width: 8),
                    Text('Secure access for authorized personnel only',
                        style: TextStyle(
                            color: AppColors.brownMedium.withOpacity(0.8),
                            fontSize: 12)),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
