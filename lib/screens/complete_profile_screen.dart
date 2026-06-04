import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../services/auth_service.dart';
import '../main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/auth_shell.dart';
import '../services/interactive_message_service.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final TextEditingController _ageController = TextEditingController();
  String? _selectedGender;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      developer.log('Completing profile setup', name: 'Auth');
      await AuthService().updateUserProfile(
        name: _nameController.text.trim(),
        age: int.tryParse(_ageController.text.trim()),
        gender: _selectedGender,
      );
      developer.log('Profile setup completed', name: 'Auth');
      if (mounted) {
        InteractiveMessageService.showSuccess(
          context,
          title: 'Profile complete! 🌟',
          message: 'Let\'s start your mindfulness journey',
          duration: const Duration(seconds: 2),
        );
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
        });
      }
    } catch (e) {
      developer.log('Profile setup error: $e', name: 'Auth', level: 900);
      if (mounted) {
        InteractiveMessageService.showError(
          context,
          title: 'Profile update failed',
          message: e.toString(),
          onRetry: _submit,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      eyebrow: 'ONE MORE STEP',
      title: 'Complete your profile',
      subtitle:
          'A few details help us personalize your experience and prepare the right reminders for you.',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'You can update these details again later from your profile settings.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMedium,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                  hintText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline)),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Please enter your name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  hintText: 'Age', prefixIcon: Icon(Icons.cake_outlined)),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter your age';
                final age = int.tryParse(v);
                if (age == null || age < 1 || age > 150) {
                  return 'Please enter a valid age between 1 and 150';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedGender,
              decoration: const InputDecoration(
                  hintText: 'Gender', prefixIcon: Icon(Icons.people_outline)),
              items: ['Male', 'Female', 'Other', 'Prefer not to say']
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedGender = v),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: AppColors.textDark))
                    : const Text('Complete Registration'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
