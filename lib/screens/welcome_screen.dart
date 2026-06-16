import 'package:flutter/material.dart';
import '../main.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        color: const Color(0xFFFFF8EE),
        child: Stack(
          children: [
            _WelcomeBackground(size: size),
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 32),
                          _buildLogo(),
                          const SizedBox(height: 14),
                          const Text(
                            'MINDMATE',
                            style: TextStyle(
                              fontSize: 46,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              letterSpacing: 3,
                              shadows: [
                                Shadow(
                                  color: Color(0x35F9A825),
                                  offset: Offset(0, 4),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Your Student Wellness Companion',
                            style: TextStyle(
                              fontSize: 15.5,
                              color: AppColors.textMedium,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildHeartDivider(),
                          const SizedBox(height: 28),
                          _buildFeatureCards(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pushReplacementNamed(
                                context, '/register'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                              elevation: 6,
                              shadowColor:
                                  AppColors.primary.withValues(alpha: 0.38),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Get Started',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Icon(Icons.arrow_forward_rounded,
                                    color: Colors.white, size: 22),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an account? ',
                              style: TextStyle(
                                color: AppColors.textMedium,
                                fontSize: 15,
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  Navigator.pushReplacementNamed(context, '/'),
                              child: const Text(
                                'Log In',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildLogo() {
    return SizedBox(
      width: 155,
      height: 155,
      child: Image.asset(
        'assets/images/MindMate_Logo.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          width: 155,
          height: 155,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.12),
          ),
          child: const Icon(
            Icons.psychology_alt_rounded,
            size: 80,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildHeartDivider() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 1.5,
          color: AppColors.primary.withValues(alpha: 0.45),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.favorite, color: AppColors.primary, size: 15),
        ),
        Container(
          width: 48,
          height: 1.5,
          color: AppColors.primary.withValues(alpha: 0.45),
        ),
      ],
    );
  }

  Widget _buildFeatureCards() {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _FeatureCard(
            iconWidget: _MoodIcon(),
            title: 'Mood\nTracking',
            description: 'Track your emotions daily',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _FeatureCard(
            iconWidget: _AiIcon(),
            title: 'AI Support',
            description: 'Talk whenever you need help',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _FeatureCard(
            iconWidget: _TrophyIcon(),
            title: 'Achievements',
            description: 'Stay motivated and build healthy habits',
          ),
        ),
      ],
    );
  }
}

// ─── Background decorations ───

class _WelcomeBackground extends StatelessWidget {
  final Size size;
  const _WelcomeBackground({required this.size});

  @override
  Widget build(BuildContext context) {
    const leafAmber = Color(0xFFEFCC82);
    const leafGold = Color(0xFFDDB96A);

    return Stack(
      children: [
        // Bottom-left large leaf cluster
        Positioned(
          bottom: -30,
          left: -40,
          child: Transform.rotate(
            angle: 0.2,
            child: Icon(Icons.eco, size: 220,
                color: leafAmber.withValues(alpha: 0.35)),
          ),
        ),
        Positioned(
          bottom: 10,
          left: -10,
          child: Transform.rotate(
            angle: 0.5,
            child: Icon(Icons.eco, size: 130,
                color: leafGold.withValues(alpha: 0.3)),
          ),
        ),
        // Bottom-right large leaf cluster
        Positioned(
          bottom: -30,
          right: -40,
          child: Transform.rotate(
            angle: -0.2,
            child: Icon(Icons.eco, size: 220,
                color: leafAmber.withValues(alpha: 0.35)),
          ),
        ),
        Positioned(
          bottom: 10,
          right: -10,
          child: Transform.rotate(
            angle: -0.5,
            child: Icon(Icons.eco, size: 130,
                color: leafGold.withValues(alpha: 0.3)),
          ),
        ),
        // Mid-left leaf accent
        Positioned(
          top: size.height * 0.38,
          left: -18,
          child: Transform.rotate(
            angle: 0.5,
            child: Icon(Icons.eco, size: 90,
                color: leafAmber.withValues(alpha: 0.25)),
          ),
        ),
        // Mid-right leaf accent
        Positioned(
          top: size.height * 0.38,
          right: -18,
          child: Transform.rotate(
            angle: -0.5,
            child: Icon(Icons.eco, size: 90,
                color: leafAmber.withValues(alpha: 0.25)),
          ),
        ),
        // Floating heart — upper left
        Positioned(
          top: size.height * 0.12,
          left: 26,
          child: Icon(Icons.favorite,
              size: 26, color: AppColors.primary.withValues(alpha: 0.4)),
        ),
        // Smiley circle — mid-left
        Positioned(
          top: size.height * 0.19,
          left: 16,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF9A825).withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('😊', style: TextStyle(fontSize: 18)),
            ),
          ),
        ),
        // Sparkle star — upper right
        Positioned(
          top: size.height * 0.1,
          right: 36,
          child: Icon(Icons.star_outline_rounded,
              size: 20, color: AppColors.primary.withValues(alpha: 0.4)),
        ),
        // Heart bubble — mid-right
        Positioned(
          top: size.height * 0.17,
          right: 14,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                ),
              ],
            ),
            child: const Icon(Icons.favorite,
                size: 18, color: AppColors.primary),
          ),
        ),
        // Small plus sparkles
        Positioned(
          top: size.height * 0.22,
          right: 58,
          child: Icon(Icons.add,
              size: 14, color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        Positioned(
          top: size.height * 0.25,
          left: 56,
          child: Icon(Icons.add,
              size: 14, color: AppColors.primary.withValues(alpha: 0.3)),
        ),
      ],
    );
  }
}

// ─── Feature cards ───

class _FeatureCard extends StatelessWidget {
  final Widget iconWidget;
  final String title;
  final String description;

  const _FeatureCard({
    required this.iconWidget,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          iconWidget,
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: AppColors.textDark,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMedium,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card icons ───

class _MoodIcon extends StatelessWidget {
  const _MoodIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Bar chart (bottom-right)
          Positioned(
            right: 3,
            bottom: 3,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                    width: 5,
                    height: 10,
                    margin: const EdgeInsets.only(right: 2),
                    decoration: BoxDecoration(
                        color: const Color(0xFF8BC34A).withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(2))),
                Container(
                    width: 5,
                    height: 16,
                    margin: const EdgeInsets.only(right: 2),
                    decoration: BoxDecoration(
                        color: const Color(0xFF8BC34A).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(2))),
                Container(
                    width: 5,
                    height: 12,
                    decoration: BoxDecoration(
                        color: const Color(0xFF8BC34A).withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(2))),
              ],
            ),
          ),
          // Leaf bottom-left
          Positioned(
            left: 1,
            bottom: 3,
            child: Icon(Icons.eco,
                size: 18,
                color: const Color(0xFF8BC34A).withValues(alpha: 0.85)),
          ),
          // Smiley
          const Text('😊', style: TextStyle(fontSize: 32)),
        ],
      ),
    );
  }
}

class _AiIcon extends StatelessWidget {
  const _AiIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Robot body
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: AppColors.textDark, size: 26),
          ),
          // Speech bubble (top-right)
          Positioned(
            top: 1,
            right: 1,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '···',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          // Lightbulb sparkle (top-left)
          Positioned(
            top: 1,
            left: 6,
            child: Icon(Icons.lightbulb_outline_rounded,
                size: 13, color: AppColors.primary.withValues(alpha: 0.55)),
          ),
        ],
      ),
    );
  }
}

class _TrophyIcon extends StatelessWidget {
  const _TrophyIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Left leaf
          Positioned(
            left: 1,
            bottom: 6,
            child: Transform.rotate(
              angle: 0.35,
              child: Icon(Icons.eco,
                  size: 20,
                  color: const Color(0xFF8BC34A).withValues(alpha: 0.85)),
            ),
          ),
          // Right leaf
          Positioned(
            right: 1,
            bottom: 6,
            child: Transform.rotate(
              angle: -0.35,
              child: Icon(Icons.eco,
                  size: 20,
                  color: const Color(0xFF8BC34A).withValues(alpha: 0.85)),
            ),
          ),
          // Trophy
          const Icon(Icons.emoji_events_rounded,
              color: AppColors.primary, size: 44),
        ],
      ),
    );
  }
}
