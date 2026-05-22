import 'package:flutter/material.dart';
import '../main.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamLight,
      appBar: AppBar(
        backgroundColor: AppColors.creamLight,
        title: const Text('Privacy'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.brownDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            const Text(
              'Your privacy matters to us. Here\'s how MindMate handles your data.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.brownMedium,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // ── DATA WE COLLECT ──
            _PrivacyCard(
              icon: Icons.data_usage_rounded,
              title: 'Data We Collect',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MindMate collects the following information to provide you with a personalized experience:',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.brownMedium,
                        height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  ...[
                    ('Icons.mood_rounded', Icons.mood_rounded,
                        'Mood logs & emotion entries you create'),
                    ('Icons.person_outline', Icons.person_outline,
                        'Profile information: name, age, and gender'),
                    ('Icons.insights_rounded', Icons.insights_rounded,
                        'App usage patterns to personalize your experience'),
                    ('Icons.notifications_none', Icons.notifications_none,
                        'Device information required for push notifications'),
                    ('Icons.email_outlined', Icons.email_outlined,
                        'Email address used for account authentication'),
                  ].map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.golden.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(item.$2,
                                color: AppColors.golden, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.$3,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.brownDark,
                                  height: 1.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── DATA SHARING ──
            _PrivacyCard(
              icon: Icons.shield_outlined,
              title: 'How We Share Your Data',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.golden.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.golden.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_rounded,
                            color: AppColors.golden, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'MindMate does not sell your personal data.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brownDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Your mental health information is strictly private. We do not share your personal data, mood logs, or profile details with any third parties.',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.brownMedium,
                        height: 1.55),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'All data is stored securely in Firebase, protected by industry-standard encryption. Only you can access your personal wellness journey.',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.brownMedium,
                        height: 1.55),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── PRIVACY POLICY ──
            _PrivacyCard(
              icon: Icons.policy_outlined,
              title: 'Privacy Policy',
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PolicySection(
                    title: 'Effective Date',
                    body:
                        'This Privacy Policy is effective as of January 1, 2025.',
                  ),
                  _PolicySection(
                    title: 'Data Retention',
                    body:
                        'We retain your personal data for as long as your account is active. Mood logs and emotion entries are kept to provide historical insights. You may request deletion of your data at any time by contacting our support team.',
                  ),
                  _PolicySection(
                    title: 'Your Rights',
                    body:
                        'You have the right to access, correct, or delete your personal data. You may also object to or restrict certain processing of your data. To exercise these rights, contact us at support@mindmate.app.',
                  ),
                  _PolicySection(
                    title: "Children's Privacy",
                    body:
                        'MindMate is intended for users aged 13 and above. We do not knowingly collect personal information from children under 13 without parental consent.',
                  ),
                  _PolicySection(
                    title: 'Changes to This Policy',
                    body:
                        'We may update this Privacy Policy periodically. We will notify you of significant changes through the app. Continued use of MindMate after changes constitutes your acceptance of the revised policy.',
                  ),
                  _PolicySection(
                    title: 'Contact Us',
                    body:
                        'For privacy-related questions or requests, please contact us at:\nsupport@mindmate.app\n\nWe aim to respond within 3–5 business days.',
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _PrivacyCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.golden.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.golden, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brownDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.fieldBorder),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String body;
  final bool isLast;

  const _PolicySection({
    required this.title,
    required this.body,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.brownDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.brownMedium,
            height: 1.55,
          ),
        ),
        if (!isLast) ...[
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.fieldBorder),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}
