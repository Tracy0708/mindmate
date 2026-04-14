import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../main.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _authService = AuthService();
  int _currentStep = 0;
  bool _isLoading = false;
  bool _obscurePassword = true;
  final bool _obscureConfirm = true;

  // Step 1
  final _step1Key = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Step 2
  final _step2Key = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String? _selectedGender;

  // Password validation
  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUppercase => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasNumberOrSpecial => _passwordController.text.contains(RegExp(r'[0-9!@#$%^&*(),.?":{}|<>]'));

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_step1Key.currentState!.validate()) return;
      if (!_hasMinLength || !_hasUppercase || !_hasNumberOrSpecial) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password does not meet requirements'), backgroundColor: AppColors.errorRed),
        );
        return;
      }
    } else if (_currentStep == 1) {
      if (!_step2Key.currentState!.validate()) return;
    }
    setState(() => _currentStep++);
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  Future<void> _register() async {
    try {
      print('--- Registration Started ---');
      setState(() => _isLoading = true);
      
      print('1. Calling registerWithEmailPassword...');
      await _authService.registerWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      print('1. Successly finished registerWithEmailPassword');

      print('2. Calling updateUserProfile...');
      // Update profile info
      await _authService.updateUserProfile(
        name: _nameController.text.trim(),
        age: int.tryParse(_ageController.text.trim()),
      );
      print('2. Successfully finished updateUserProfile');

      print('3. Navigating to dashboard...');
      if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e, stacktrace) {
      print('!!! REGISTRATION ERROR !!!: $e');
      print(stacktrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.errorRed),
        );
      }
    } finally {
      print('--- Registration Block Ended ---');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  const Text(
                    'Create Account',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.golden),
                  ),
                  const SizedBox(height: 24),

                  // Step indicator
                  _buildStepIndicator(),
                  const SizedBox(height: 28),

                  // Step content
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _currentStep == 0
                        ? _buildStep1()
                        : _currentStep == 1
                            ? _buildStep2()
                            : _buildStep3(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _stepCircle(0),
        Expanded(child: Container(height: 2, color: _currentStep > 0 ? AppColors.golden : AppColors.fieldBorder)),
        _stepCircle(1),
        Expanded(child: Container(height: 2, color: _currentStep > 1 ? AppColors.golden : AppColors.fieldBorder)),
        _stepCircle(2),
      ],
    );
  }

  Widget _stepCircle(int step) {
    final isActive = _currentStep >= step;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isActive ? AppColors.golden : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: isActive ? AppColors.golden : AppColors.fieldBorder, width: 2),
      ),
      child: Center(
        child: Text(
          '${step + 1}',
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.brownLight,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ─── Step 1: Email & Password ───
  Widget _buildStep1() {
    return Form(
      key: _step1Key,
      child: Column(
        key: const ValueKey('step1'),
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'Email address', prefixIcon: Icon(Icons.email_outlined)),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter your email';
              if (!v.contains('@')) return 'Please enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Create password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.brownLight),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Please create a password' : null,
          ),
          const SizedBox(height: 16),

          // Password requirements
          _passwordReq('At least 8 characters', _hasMinLength),
          const SizedBox(height: 6),
          _passwordReq('One uppercase letter', _hasUppercase),
          const SizedBox(height: 6),
          _passwordReq('One number or special character', _hasNumberOrSpecial),
          const SizedBox(height: 24),

          // Continue button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(onPressed: _nextStep, child: const Text('Continue')),
          ),
          const SizedBox(height: 24),

          // Divider
          Row(
            children: [
              Expanded(child: Divider(color: AppColors.fieldBorder.withOpacity(0.6))),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Or register with', style: TextStyle(color: AppColors.brownLight, fontSize: 13)),
              ),
              Expanded(child: Divider(color: AppColors.fieldBorder.withOpacity(0.6))),
            ],
          ),
          const SizedBox(height: 24),

          // Google
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () async {
                try {
                  setState(() => _isLoading = true);
                  final cred = await _authService.signInWithGoogle();
                  if (mounted) {
                    if (cred.additionalUserInfo?.isNewUser == true) {
                      Navigator.pushReplacementNamed(context, '/complete-profile');
                    } else {
                      Navigator.pushReplacementNamed(context, '/dashboard');
                    }
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              icon: Image.network('https://www.google.com/favicon.ico', height: 20,
                  errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 24)),
              label: const Text('Sign up with Google', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 20),

          // Login link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Already have an account? ', style: TextStyle(color: AppColors.brownMedium, fontSize: 13)),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text('Log in', style: TextStyle(color: AppColors.golden, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _passwordReq(String text, bool met) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: met ? AppColors.golden : AppColors.brownLight.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: met ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
        ),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(fontSize: 13, color: met ? AppColors.brownDark : AppColors.brownLight)),
      ],
    );
  }

  // ─── Step 2: Personal Info ───
  Widget _buildStep2() {
    return Form(
      key: _step2Key,
      child: Column(
        key: const ValueKey('step2'),
        children: [
          const Text('Tell us about yourself', style: TextStyle(color: AppColors.brownMedium, fontSize: 14)),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
            validator: (v) => (v == null || v.isEmpty) ? 'Please enter your name' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Age', prefixIcon: Icon(Icons.cake_outlined)),
            validator: (v) => (v == null || v.isEmpty) ? 'Please enter your age' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedGender,
            decoration: const InputDecoration(hintText: 'Gender', prefixIcon: Icon(Icons.people_outline)),
            items: ['Male', 'Female', 'Other', 'Prefer not to say']
                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
            onChanged: (v) => setState(() => _selectedGender = v),
          ),
          const SizedBox(height: 32),
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(onPressed: _nextStep, child: const Text('Continue')),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: TextButton(onPressed: _prevStep, child: const Text('Back')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Step 3: Confirmation ───
  Widget _buildStep3() {
    return Column(
      key: const ValueKey('step3'),
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.golden.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_outline, size: 40, color: AppColors.golden),
        ),
        const SizedBox(height: 20),
        const Text('Ready to go!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.brownDark)),
        const SizedBox(height: 12),
        Text(
          'Welcome, ${_nameController.text.isNotEmpty ? _nameController.text : "there"}!\nLet\'s start your mental health journey.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.brownMedium, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 12),
        // Summary
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.golden.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _summaryRow(Icons.email_outlined, _emailController.text),
              const SizedBox(height: 8),
              _summaryRow(Icons.person_outline, _nameController.text.isNotEmpty ? _nameController.text : 'N/A'),
              const SizedBox(height: 8),
              _summaryRow(Icons.cake_outlined, _ageController.text.isNotEmpty ? '${_ageController.text} years' : 'N/A'),
              if (_selectedGender != null) ...[
                const SizedBox(height: 8),
                _summaryRow(Icons.people_outline, _selectedGender!),
              ],
            ],
          ),
        ),
        const SizedBox(height: 28),
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Create Account'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: TextButton(onPressed: _prevStep, child: const Text('Back')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.golden),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(color: AppColors.brownDark, fontSize: 14)),
      ],
    );
  }
}
