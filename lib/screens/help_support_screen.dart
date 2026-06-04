import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../services/interactive_message_service.dart';
import '../widgets/app_screen_header.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            const AppScreenHeader(
              title: 'Help & Support',
              subtitle: 'Answers and ways to reach us.',
              icon: Icons.help_outline_rounded,
              showBack: true,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

            // ── CRISIS RESOURCES ──
            _CrisisCard(context: context),
            const SizedBox(height: 16),

            // ── FAQS ──
            const _SectionHeader(
              icon: Icons.quiz_outlined,
              title: 'Frequently Asked Questions',
            ),
            const SizedBox(height: 10),
            Container(
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: const Column(
                  children: [
                    _FaqTile(
                      question: 'How do I log my emotions?',
                      answer:
                          'Tap the "Emotion" tab in the bottom navigation bar. Select your current mood from the list, optionally add a note, then tap "Log Emotion". Your entry will be saved and reflected in your insights.',
                    ),
                    Divider(height: 1, color: AppColors.fieldBorder),
                    _FaqTile(
                      question: 'How do I earn points?',
                      answer:
                          'You earn points by completing daily activities: logging your emotions, checking in, completing wellness activities, and maintaining streaks. Points can be spent in the Avatar Store to unlock new avatars.',
                    ),
                    Divider(height: 1, color: AppColors.fieldBorder),
                    _FaqTile(
                      question: 'Can I change my avatar?',
                      answer:
                          'Yes! Go to your Profile and tap "Avatar Store". Browse available avatars, unlock them using your earned points, and tap "Equip" to set your active avatar.',
                    ),
                    Divider(height: 1, color: AppColors.fieldBorder),
                    _FaqTile(
                      question: 'How do notifications work?',
                      answer:
                          'MindMate can send you daily reminders to log your emotions and complete check-ins. Go to Profile → Notifications to customize which reminders you receive and when.',
                    ),
                    Divider(height: 1, color: AppColors.fieldBorder),
                    _FaqTile(
                      question: 'Is my data secure?',
                      answer:
                          'Yes. All your data is stored securely in Firebase with industry-standard encryption. MindMate never sells or shares your personal information with third parties. See our Privacy section for full details.',
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── CONTACT SUPPORT ──
            const _SectionHeader(
              icon: Icons.support_agent_rounded,
              title: 'Contact Support',
            ),
            const SizedBox(height: 10),
            _ContactTile(
              icon: Icons.email_outlined,
              label: 'Email Support',
              subtitle: 'support@mindmate.app',
              onTap: () {
                Clipboard.setData(
                    const ClipboardData(text: 'support@mindmate.app'));
                InteractiveMessageService.showSuccess(
                  context,
                  title: 'Email copied!',
                  message: 'support@mindmate.app copied to clipboard.',
                );
              },
            ),
            const SizedBox(height: 24),

            // ── ABOUT APP ──
            const _SectionHeader(
              icon: Icons.info_outline_rounded,
              title: 'About MindMate',
            ),
            const SizedBox(height: 10),
            Container(
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.psychology_alt,
                        color: AppColors.primary, size: 32),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'MindMate',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMedium,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppColors.fieldBorder),
                  const SizedBox(height: 14),
                  const Text(
                    'A mental wellness companion app built to support your emotional journey — helping you track moods, build healthy habits, and reflect on your well-being.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMedium,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Made with ❤️ by Lau Yun Xi',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CrisisCard extends StatelessWidget {
  final BuildContext context;
  const _CrisisCard({required this.context});

  void _copyNumber(String number) {
    Clipboard.setData(ClipboardData(text: number));
    InteractiveMessageService.showInfo(
      context,
      title: 'Number copied',
      message: '$number copied to clipboard.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB300).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emergency_rounded, color: Color(0xFFE65100), size: 22),
              SizedBox(width: 10),
              Text(
                'Need Immediate Help?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFE65100),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'If you or someone you know is in crisis, please reach out to these resources immediately:',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMedium,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _HotlineTile(
            label: 'Befrienders KL',
            number: '03-7627 2929',
            onTap: () => _copyNumber('03-7627 2929'),
          ),
          const SizedBox(height: 10),
          _HotlineTile(
            label: 'Talian Kasih (MOW)',
            number: '15999',
            onTap: () => _copyNumber('15999'),
          ),
          const SizedBox(height: 10),
          _HotlineTile(
            label: 'Mental Health Psychosocial Support (MOH)',
            number: '1800-82-0066',
            onTap: () => _copyNumber('1800-82-0066'),
          ),
          const SizedBox(height: 14),
          const Text(
            'Tap a number to copy it to your clipboard.',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textLight,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _HotlineTile extends StatelessWidget {
  final String label;
  final String number;
  final VoidCallback onTap;

  const _HotlineTile({
    required this.label,
    required this.number,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFFFFB300).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.phone_outlined,
                color: Color(0xFFE65100), size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    number,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.copy_rounded,
                color: AppColors.textLight, size: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 17),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;
  final bool isLast;

  const _FaqTile({
    required this.question,
    required this.answer,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding:
            const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.textLight,
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        children: [
          Text(
            answer,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMedium,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.copy_rounded,
                color: AppColors.textLight, size: 18),
          ],
        ),
      ),
    );
  }
}
