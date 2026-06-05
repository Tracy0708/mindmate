/// A Malaysian mental-health crisis hotline.
///
/// Single source of truth shared by the Help & Support screen
/// ([HelpSupportScreen]) and the chatbot crisis-escalation card so the numbers
/// never drift out of sync. Keep this list aligned with the crisis resources in
/// the chatbot system prompt (functions/index.js `MINDMATE_SYSTEM_PROMPT`).
class CrisisHotline {
  final String label;
  final String number;

  const CrisisHotline({required this.label, required this.number});
}

/// The crisis hotlines surfaced throughout the app.
const List<CrisisHotline> kCrisisHotlines = [
  CrisisHotline(label: 'Befrienders KL', number: '03-7627 2929'),
  CrisisHotline(label: 'Talian Kasih (MOW)', number: '15999'),
  CrisisHotline(
      label: 'Mental Health Psychosocial Support (MOH)', number: '1800-82-0066'),
];

/// Emergency services number for immediate danger.
const String kEmergencyNumber = '999';
