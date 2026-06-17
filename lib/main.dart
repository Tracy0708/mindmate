import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/welcome_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/complete_profile_screen.dart';
import 'screens/notification_settings_screen.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/admin_notification_settings_screen.dart';
import 'screens/privacy_screen.dart';
import 'screens/help_support_screen.dart';
import 'screens/notification_center_screen.dart';
import 'services/auth_service.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'viewmodels/profile_viewmodel.dart';
import 'viewmodels/chatbot_viewmodel.dart';
import 'viewmodels/insights_viewmodel.dart';
import 'viewmodels/gamification_viewmodel.dart';
import 'viewmodels/admin_viewmodel.dart';
import 'viewmodels/emotion_viewmodel.dart';
import 'services/local_notification_service.dart';
import 'services/interactive_message_service.dart';
import 'services/fcm_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final n = message.notification;
  if (n != null) {
    await LocalNotificationService().initialize();
    await LocalNotificationService().showPushNotification(
      id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title: n.title ?? '',
      body: n.body ?? '',
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await AuthService.initializeGoogleSignIn();
  await LocalNotificationService().initialize();
  FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);
  FirebaseMessaging.onMessageOpenedApp.listen((msg) {
    MyApp.navigatorKey.currentState?.pushNamed('/notifications');
  });
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => ChatbotViewModel()),
        ChangeNotifierProvider(create: (_) => InsightsViewModel()),
        ChangeNotifierProvider(create: (_) => GamificationViewModel()),
        ChangeNotifierProvider(create: (_) => AdminViewModel()),
        ChangeNotifierProvider(create: (_) => EmotionViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

// ─── MindMate Color Palette — Lemon Yellow Theme ───
class AppColors {
  static const primary = Color(0xFFF9A825); // deep amber (calm, readable)
  static const primaryDark = Color(0xFFF57F17); // deep orange-amber
  static const primaryLight = Color(0xFFFFF9C4); // pale lemon
  static const cream = Color(0xFFFFFDE7); // warm white
  static const creamLight = Color(0xFFFFFFFA); // off-white
  static const textDark = Color(0xFF3E2723); // dark brown (primary text)
  static const textMedium = Color(0xFF5D4037); // mid brown (secondary text)
  static const textLight = Color(0xFF8D6E63); // soft brown (hints/tertiary)
  static const fieldBorder = Color(0xFFE8E0A0); // soft yellow border
  static const errorRed = Color(0xFFE53935);
  // Aliases kept for service files — do not remove
  static const golden = primary;
  static const goldenLight = primaryLight;
  static const brownDark = textDark;
  static const brownMedium = textMedium;
  static const brownLight = textLight;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final navigatorKey = GlobalKey<NavigatorState>();
  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: MyApp.navigatorKey,
      scaffoldMessengerKey: MyApp.scaffoldMessengerKey,
      title: 'MindMate',
      debugShowCheckedModeBanner: false,
      theme: _lightTheme(),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const _SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/': (context) => const LoginPage(),
        '/register': (context) => const RegistrationScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/complete-profile': (context) => const CompleteProfileScreen(),
        '/notifications-settings': (context) =>
            const NotificationSettingsScreen(),
        '/admin-login': (context) => const AdminLoginScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/admin-notifications-settings': (context) =>
            const AdminNotificationSettingsScreen(),
        '/privacy': (context) => const PrivacyScreen(),
        '/help-support': (context) => const HelpSupportScreen(),
        '/notifications': (context) => const NotificationCenterScreen(),
      },
    );
  }

  ThemeData _lightTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Nunito',
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.primaryLight,
        onSecondary: AppColors.textDark,
        tertiary: Color(0xFFFFE082),
        surface: AppColors.cream,
        onSurface: AppColors.textDark,
        error: AppColors.errorRed,
        outline: AppColors.fieldBorder,
      ),
      scaffoldBackgroundColor: AppColors.cream,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w800,
            fontSize: 30),
        headlineMedium: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 24),
        headlineSmall: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
            fontSize: 20),
        titleLarge: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 20),
        titleMedium: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w500,
            fontSize: 16),
        bodyLarge: TextStyle(color: AppColors.textDark, fontSize: 16),
        bodyMedium: TextStyle(color: AppColors.textMedium, fontSize: 14),
        bodySmall: TextStyle(color: AppColors.textLight, fontSize: 12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.fieldBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.fieldBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.errorRed)),
        prefixIconColor: AppColors.textLight,
        labelStyle: const TextStyle(color: AppColors.textLight),
        hintStyle: const TextStyle(color: AppColors.textLight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textDark,
          side: const BorderSide(color: AppColors.fieldBorder),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}

// ─── SPLASH / AUTH GATE ───
class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveRoute());
  }

  Future<void> _resolveRoute() async {
    final user = FirebaseAuth.instance.currentUser;
    if (!mounted) return;

    if (user == null) {
      Navigator.pushReplacementNamed(context, '/welcome');
      return;
    }

    final profile = await AuthService().getUserProfileById(user.uid);
    if (!mounted) return;

    RemoteMessage? initialMessage;
    if (profile != null) {
      await FCMService().initialize();
      if (!mounted) return;
      initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (!mounted) return;
    }

    if (profile?.role == 'admin') {
      Navigator.pushReplacementNamed(context, '/admin-dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }

    if (initialMessage != null && mounted) {
      Navigator.pushNamed(context, '/notifications');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Center(
        child: Image.asset(
          'assets/images/MindMate_Logo.png',
          width: 120,
          height: 120,
        ),
      ),
    );
  }
}

// ─── LOGIN PAGE (matching mockup) ───
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
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
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
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
      await _authService.signInWithEmailPassword(
          _emailController.text.trim(), _passwordController.text);
      await FCMService().initialize();
      if (mounted) {
        InteractiveMessageService.showSuccess(
          context,
          title: 'Welcome back! 👋',
          message: 'You\'re logged in',
          duration: const Duration(seconds: 1),
        );
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
        });
      }
    } catch (e) {
      if (mounted) {
        InteractiveMessageService.showError(
          context,
          title: 'Sign in failed',
          message: e.toString(),
          onRetry: _signIn,
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
      await FCMService().initialize();
      if (mounted) {
        InteractiveMessageService.showSuccess(
          context,
          title: 'Google sign in successful! 🎉',
          message: cred.additionalUserInfo?.isNewUser == true
              ? 'Let\'s complete your profile'
              : 'Welcome back!',
          duration: const Duration(seconds: 1),
        );
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            if (cred.additionalUserInfo?.isNewUser == true) {
              Navigator.pushReplacementNamed(context, '/complete-profile');
            } else {
              Navigator.pushReplacementNamed(context, '/dashboard');
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        InteractiveMessageService.showError(
          context,
          title: 'Google sign in failed',
          message: e.toString(),
          onRetry: _signInWithGoogle,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          // Background — warm gradient + soft decorative blobs (shared with admin login)
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
                color: AppColors.primary.withValues(alpha: 0.10),
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
                color: AppColors.textDark.withValues(alpha: 0.06),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo — your image asset, with a gradient-badge fallback.
                          // Scaled up inside a clip to crop the PNG's transparent padding.
                          SizedBox(
                            width: 96,
                            height: 96,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Transform.scale(
                                scale: 1.35,
                                child: Image.asset(
                                  'assets/images/MindMate_Logo.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 96,
                                    height: 96,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppColors.primaryLight,
                                          AppColors.primary,
                                        ],
                                      ),
                                    ),
                                    child: const Icon(Icons.favorite_rounded,
                                        size: 40, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'MINDMATE',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Welcome back',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textMedium,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                                hintText: 'Email address',
                                prefixIcon: Icon(Icons.email_outlined)),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Please enter your email'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.textLight),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Please enter your password'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Login button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signIn,
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 32),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: AppColors.textDark))
                                  : const Text('Log in'),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Divider
                          Row(
                            children: [
                              Expanded(
                                  child: Divider(
                                      color: AppColors.fieldBorder
                                          .withValues(alpha: 0.6))),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text('Or continue with',
                                    style: TextStyle(
                                        color: AppColors.textLight,
                                        fontSize: 13)),
                              ),
                              Expanded(
                                  child: Divider(
                                      color: AppColors.fieldBorder
                                          .withValues(alpha: 0.6))),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Google
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _signInWithGoogle,
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                              ),
                              icon: Image.network(
                                  'https://www.google.com/favicon.ico',
                                  height: 20,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.g_mobiledata, size: 24)),
                              label: const Text('Sign in with Google',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Links
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(
                                    context, '/forgot-password'),
                                child: const Text('Forgot Password?',
                                    style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text('•',
                                    style:
                                        TextStyle(color: AppColors.textLight)),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    Navigator.pushNamed(context, '/register'),
                                child: const Text('Create Account',
                                    style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/admin-login'),
                            child: const Text(
                              'Admin Portal',
                              style: TextStyle(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w700,
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
            ),
          ),
        ],
      ),
    );
  }
}
