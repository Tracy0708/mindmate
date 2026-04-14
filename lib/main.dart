import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/registration_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/complete_profile_screen.dart';
import 'services/auth_service.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'viewmodels/profile_viewmodel.dart';
import 'viewmodels/chatbot_viewmodel.dart';
import 'viewmodels/insights_viewmodel.dart';
import 'viewmodels/gamification_viewmodel.dart';
import 'viewmodels/admin_viewmodel.dart';
import 'viewmodels/theme_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await AuthService.initializeGoogleSignIn();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => ChatbotViewModel()),
        ChangeNotifierProvider(create: (_) => InsightsViewModel()),
        ChangeNotifierProvider(create: (_) => GamificationViewModel()),
        ChangeNotifierProvider(create: (_) => AdminViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

// ─── MindMate Color Palette (matching UI mockups) ───
class AppColors {
  static const golden = Color(0xFFFFB300);
  static const goldenLight = Color(0xFFFFD54F);
  static const cream = Color(0xFFFFF8E1);
  static const creamLight = Color(0xFFFFFDE7);
  static const brownDark = Color(0xFF5D4037);
  static const brownMedium = Color(0xFF795548);
  static const brownLight = Color(0xFFA1887F);
  static const fieldBorder = Color(0xFFE0D5C1);
  static const errorRed = Color(0xFFE53935);
  // Dark
  static const darkBg = Color(0xFF1A1A2E);
  static const darkCard = Color(0xFF252540);
  static const darkText = Color(0xFFF5EDE8);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeViewModel>(
      builder: (context, themeVM, _) {
        return MaterialApp(
          title: 'MindMate',
          debugShowCheckedModeBanner: false,
          theme: _lightTheme(),
          darkTheme: _darkTheme(),
          themeMode: themeVM.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute:
              FirebaseAuth.instance.currentUser != null ? '/dashboard' : '/',
          routes: {
            '/': (context) => const LoginPage(),
            '/register': (context) => const RegistrationScreen(),
            '/dashboard': (context) => const DashboardScreen(),
            '/forgot-password': (context) => const ForgotPasswordScreen(),
            '/complete-profile': (context) => const CompleteProfileScreen(),
          },
        );
      },
    );
  }

  ThemeData _lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.golden,
        onPrimary: Colors.white,
        secondary: AppColors.goldenLight,
        onSecondary: AppColors.brownDark,
        tertiary: Color(0xFFFFE082),
        surface: AppColors.cream,
        onSurface: AppColors.brownDark,
        error: AppColors.errorRed,
        outline: AppColors.fieldBorder,
      ),
      scaffoldBackgroundColor: AppColors.cream,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: AppColors.brownDark, fontWeight: FontWeight.w800, fontSize: 30),
        headlineMedium: TextStyle(color: AppColors.brownDark, fontWeight: FontWeight.w700, fontSize: 24),
        headlineSmall: TextStyle(color: AppColors.brownDark, fontWeight: FontWeight.w600, fontSize: 20),
        titleLarge: TextStyle(color: AppColors.brownDark, fontWeight: FontWeight.w700, fontSize: 20),
        titleMedium: TextStyle(color: AppColors.brownDark, fontWeight: FontWeight.w500, fontSize: 16),
        bodyLarge: TextStyle(color: AppColors.brownDark, fontSize: 16),
        bodyMedium: TextStyle(color: AppColors.brownMedium, fontSize: 14),
        bodySmall: TextStyle(color: AppColors.brownLight, fontSize: 12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.fieldBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.fieldBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.golden, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.errorRed)),
        prefixIconColor: AppColors.brownLight,
        labelStyle: const TextStyle(color: AppColors.brownLight),
        hintStyle: const TextStyle(color: AppColors.brownLight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.golden,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brownDark,
          side: const BorderSide(color: AppColors.fieldBorder),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.golden.withOpacity(0.12),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(color: AppColors.brownDark, fontWeight: FontWeight.w700, fontSize: 20),
        iconTheme: IconThemeData(color: AppColors.brownDark),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.fieldBorder, thickness: 1),
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.golden,
        onPrimary: AppColors.darkBg,
        secondary: AppColors.goldenLight,
        onSecondary: AppColors.darkBg,
        tertiary: Color(0xFFFFE082),
        surface: AppColors.darkBg,
        onSurface: AppColors.darkText,
        error: Color(0xFFFF8A80),
        outline: Color(0xFF4A4A5E),
      ),
      scaffoldBackgroundColor: AppColors.darkBg,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w800, fontSize: 30),
        headlineMedium: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w700, fontSize: 24),
        headlineSmall: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w600, fontSize: 20),
        titleLarge: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w700, fontSize: 20),
        titleMedium: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w500, fontSize: 16),
        bodyLarge: TextStyle(color: AppColors.darkText, fontSize: 16),
        bodyMedium: TextStyle(color: Color(0xFFB8AFA8), fontSize: 14),
        bodySmall: TextStyle(color: Color(0xFF8E8E9E), fontSize: 12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF4A4A5E))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF4A4A5E))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.golden, width: 2)),
        prefixIconColor: const Color(0xFF8E8E9E),
        labelStyle: const TextStyle(color: Color(0xFF8E8E9E)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.golden,
          foregroundColor: AppColors.darkBg,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkText,
          side: const BorderSide(color: Color(0xFF4A4A5E)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        color: AppColors.darkCard,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF151528),
        indicatorColor: AppColors.golden.withOpacity(0.12),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w700, fontSize: 20),
        iconTheme: IconThemeData(color: AppColors.darkText),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF353550), thickness: 1),
    );
  }
}

// ─── LOGIN PAGE (matching mockup) ───
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      setState(() => _isLoading = true);
      await _authService.signInWithEmailPassword(_emailController.text.trim(), _passwordController.text);
      if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.errorRed, behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.errorRed, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
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
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      const Icon(Icons.psychology_alt, size: 56, color: AppColors.brownDark),
                      const SizedBox(height: 8),
                      const Text(
                        'MINDMATE',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.golden,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(hintText: 'Email address', prefixIcon: Icon(Icons.email_outlined)),
                        validator: (v) => (v == null || v.isEmpty) ? 'Please enter your email' : null,
                      ),
                      const SizedBox(height: 16),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.brownLight),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Please enter your password' : null,
                      ),
                      const SizedBox(height: 24),

                      // Login button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signIn,
                          child: _isLoading
                              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                              : const Text('Log in'),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: AppColors.fieldBorder.withOpacity(0.6))),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('Or continue with', style: TextStyle(color: AppColors.brownLight, fontSize: 13)),
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
                          onPressed: _isLoading ? null : _signInWithGoogle,
                          icon: Image.network('https://www.google.com/favicon.ico', height: 20,
                            errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 24)),
                          label: const Text('Sign in with Google', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Links
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/forgot-password'),
                            child: const Text('Forgot Password?', style: TextStyle(color: AppColors.golden, fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('•', style: TextStyle(color: AppColors.brownLight)),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/register'),
                            child: const Text('Create Account', style: TextStyle(color: AppColors.golden, fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
