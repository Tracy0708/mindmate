import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/emotion_log.dart';

class ReportPdfService {
  static const _golden = PdfColor.fromInt(0xFFFFB300);
  static const _brownDark = PdfColor.fromInt(0xFF5D4037);
  static const _cream = PdfColor.fromInt(0xFFFFF8E1);
  static const _errorRed = PdfColor.fromInt(0xFFE53935);
  static const _amber = PdfColor.fromInt(0xFFDD8A00);
  static const _green = PdfColor.fromInt(0xFF43A047);

  // Warm accent palette — mirrors the in-app Insights screen so the reports
  // share the app's Golden/Cream/Brown aesthetic.
  static const _peach = PdfColor.fromInt(0xFFF4A261);
  static const _sage = PdfColor.fromInt(0xFF81B29A);
  static const _terracotta = PdfColor.fromInt(0xFFE07A5F);
  static const _dustyBlue = PdfColor.fromInt(0xFF6B9AC4);
  static const _rose = PdfColor.fromInt(0xFFBF616A);
  static const _taupe = PdfColor.fromInt(0xFFA8845C);

  // Pre-computed light backgrounds (alpha blended with white, since PDF doesn't
  // composite transparent colors against the page background automatically).
  static PdfColor _withOpacity(PdfColor c, double opacity) => PdfColor(
        1.0 * (1 - opacity) + c.red * opacity,
        1.0 * (1 - opacity) + c.green * opacity,
        1.0 * (1 - opacity) + c.blue * opacity,
      );

  static const _emotionColors = {
    'Happy': _peach,
    'Calm': _sage,
    'Anxious': _terracotta,
    'Sad': _dustyBlue,
    'Angry': _rose,
  };

  static const _emotions = [
    'Happy', 'Calm', 'Anxious', 'Sad', 'Angry',
  ];

  // ── System Report ──────────────────────────────────────────────────────────

  Future<Uint8List> generateSystemReportPdf({
    required Map<String, dynamic> usageReport,
    required Map<String, dynamic> platformEmotionStats,
    required List<Map<String, dynamic>> moodRiskUsers,
    Map<String, dynamic> chatbotUsage = const {},
    List<Map<String, dynamic>> crisisFlags = const [],
    int lookbackDays = 21,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateFmt = DateFormat('dd MMM yyyy  HH:mm');
    final emotionCounts = (platformEmotionStats['emotionCounts'] as Map?)
            ?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ??
        <String, int>{};
    final dailyCounts = (platformEmotionStats['dailyCounts'] as Map?)
            ?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ??
        <String, int>{};

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (_) =>
            _buildPageHeader('MindMate System Report', dateFmt.format(now)),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) => [
          pw.SizedBox(height: 22),
          _sectionTitle('PLATFORM OVERVIEW',
              'User accounts and overall mood-logging totals.'),
          pw.SizedBox(height: 12),
          _buildStatCards(usageReport),
          pw.SizedBox(height: 26),
          _sectionTitle('AI CHATBOT USAGE  |  last $lookbackDays days',
              'How much the MindMate AI companion is being used (no conversation content is stored).'),
          pw.SizedBox(height: 12),
          _buildChatbotUsageCards(chatbotUsage),
          pw.SizedBox(height: 26),
          _sectionTitle('MOOD DISTRIBUTION  |  last $lookbackDays days',
              'How often each mood was logged across all users.'),
          pw.SizedBox(height: 12),
          _buildMoodDonut(emotionCounts),
          pw.SizedBox(height: 26),
          _sectionTitle('DAILY MOOD CHECK-INS  |  last $lookbackDays days',
              'Number of mood logs submitted across all users each day.'),
          pw.SizedBox(height: 12),
          _buildDailyTrendChart(dailyCounts),
          pw.SizedBox(height: 26),
          _sectionTitle('AT-RISK USERS  |  top ${moodRiskUsers.length}',
              'Users with sustained negative mood who may need a counselling follow-up.'),
          pw.SizedBox(height: 12),
          _buildRiskUsersTable(moodRiskUsers),
          pw.SizedBox(height: 26),
          _sectionTitle('CRISIS FLAGS  |  last $lookbackDays days',
              'When the AI detected crisis language and whether it has been followed up.'),
          pw.SizedBox(height: 12),
          _buildCrisisFlagsTable(crisisFlags),
        ],
      ),
    );

    return pdf.save();
  }

  // ── User Mood Report ───────────────────────────────────────────────────────

  Future<Uint8List> generateUserMoodReportPdf({
    required List<
            ({
              Map<String, dynamic> riskUser,
              List<EmotionLog> logs,
              List<Map<String, dynamic>> crisisFlags
            })>
        usersWithLogs,
    int lookbackDays = 21,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateFmt = DateFormat('dd MMM yyyy  HH:mm');
    final dayFmt = DateFormat('dd MMM yyyy');

    for (final entry in usersWithLogs) {
      final user = entry.riskUser;
      final logs = entry.logs;
      final crisisFlags = entry.crisisFlags;
      final name = (user['name'] as String?)?.isNotEmpty == true
          ? user['name'] as String
          : 'Unknown User';
      final email = (user['email'] as String?) ?? '';
      final riskScore = (user['riskScore'] as num?)?.toDouble() ?? 0;
      final riskLevel = _riskLevel(riskScore);
      final riskColor = _riskColor(riskScore);
      final dominantMood = (user['dominantNegativeMood'] as String?) ?? 'Mixed';
      final negativeRatio = (user['negativeRatio'] as num?)?.toDouble() ?? 0;
      final totalLogs = (user['totalLogs'] as num?)?.toInt() ?? logs.length;
      final positiveLogs = (user['positiveLogs'] as num?)?.toInt() ?? 0;
      final negativeLogs = (user['negativeLogs'] as num?)?.toInt() ?? 0;
      final isActive = !(user['isDisabled'] as bool? ?? false);
      final emotionByType = (user['emotionByType'] as Map?)
              ?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ??
          <String, int>{};

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          header: (_) => _buildPageHeader(
              'MindMate - User Mood Analytics', dateFmt.format(now)),
          footer: (ctx) => _buildFooter(ctx),
          build: (ctx) => [
            pw.SizedBox(height: 22),
            _buildUserProfileHeader(name, email, isActive, totalLogs),
            pw.SizedBox(height: 22),
            _sectionTitle('RISK ASSESSMENT',
                'How concerning this user\'s recent mood pattern is, based on negative check-ins.'),
            pw.SizedBox(height: 10),
            _buildRiskCard(
                riskScore, riskLevel, riskColor, dominantMood, negativeRatio),
            pw.SizedBox(height: 22),
            _sectionTitle('CRISIS FLAGS  |  last $lookbackDays days',
                'When the AI detected crisis language from this user, and whether it was followed up.'),
            pw.SizedBox(height: 10),
            _buildUserCrisisTable(crisisFlags),
            pw.SizedBox(height: 22),
            if (emotionByType.isNotEmpty) ...[
              _sectionTitle('MOOD BREAKDOWN',
                  'How often this user logged each mood.'),
              pw.SizedBox(height: 10),
              _buildMoodDonut(emotionByType),
              pw.SizedBox(height: 22),
            ],
            _sectionTitle('MOOD BALANCE',
                'Share of positive, neutral, and negative check-ins.'),
            pw.SizedBox(height: 10),
            _buildPosNegNeutralRow(positiveLogs, negativeLogs, totalLogs),
            pw.SizedBox(height: 22),
            _sectionTitle('RECENT MOOD LOGS  |  last $lookbackDays days',
                'Each check-in this user recorded, with mood, intensity and notes.'),
            pw.SizedBox(height: 10),
            _buildUserLogTable(logs, dayFmt),
          ],
        ),
      );
    }

    return pdf.save();
  }

  // ── Page chrome ────────────────────────────────────────────────────────────

  pw.Widget _buildPageHeader(String title, String subtitle) {
    return pw.Container(
      width: double.infinity,
      color: _golden,
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(title,
                  style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  )),
              pw.SizedBox(height: 3),
              pw.Text('Generated $subtitle',
                  style: const pw.TextStyle(
                      fontSize: 8, color: PdfColors.white)),
            ],
          ),
          pw.Container(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: pw.BoxDecoration(
              color: _withOpacity(_brownDark, 0.35),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text('ADMIN REPORT',
                style: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                )),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context ctx) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.brown100)),
      ),
      padding: const pw.EdgeInsets.only(top: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('MindMate - Confidential Admin Report',
              style: const pw.TextStyle(
                  fontSize: 7, color: PdfColors.grey500)),
          pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: const pw.TextStyle(
                  fontSize: 7, color: PdfColors.grey500)),
        ],
      ),
    );
  }

  pw.Widget _sectionTitle(String title, [String? description]) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _brownDark,
            )),
        pw.SizedBox(height: 4),
        pw.Container(height: 1.5, color: _golden),
        if (description != null) ...[
          pw.SizedBox(height: 5),
          pw.Text(description,
              style: const pw.TextStyle(
                  fontSize: 8, color: PdfColors.grey600)),
        ],
      ],
    );
  }

  // ── User profile header ────────────────────────────────────────────────────

  pw.Widget _buildUserProfileHeader(
      String name, String email, bool isActive, int totalLogs) {
    final statusColor = isActive ? _green : _errorRed;
    final statusLabel = isActive ? 'Active' : 'Suspended';
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(name,
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: _brownDark,
            )),
        pw.SizedBox(height: 4),
        pw.Text(email,
            style: const pw.TextStyle(
                fontSize: 9, color: PdfColors.grey600)),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            _infoChip(statusLabel, statusColor),
            pw.SizedBox(width: 8),
            _infoChip('$totalLogs logs', _brownDark),
          ],
        ),
      ],
    );
  }

  pw.Widget _infoChip(String text, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        color: _withOpacity(color, 0.12),
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: _withOpacity(color, 0.40)),
      ),
      child: pw.Text(text,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: color,
          )),
    );
  }

  // ── Risk card ──────────────────────────────────────────────────────────────

  pw.Widget _buildRiskCard(
    double riskScore,
    String riskLevel,
    PdfColor riskColor,
    String dominantMood,
    double negativeRatio,
  ) {
    final bgColor = _withOpacity(riskColor, 0.10);
    final borderColor = _withOpacity(riskColor, 0.40);
    final dividerColor = _withOpacity(riskColor, 0.35);

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: borderColor, width: 1.5),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text('${riskScore.toStringAsFixed(0)}%',
              style: pw.TextStyle(
                fontSize: 38,
                fontWeight: pw.FontWeight.bold,
                color: riskColor,
              )),
          pw.SizedBox(width: 16),
          pw.Container(width: 1, height: 50, color: dividerColor),
          pw.SizedBox(width: 16),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(riskLevel,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: riskColor,
                  )),
              pw.SizedBox(height: 5),
              pw.Text('Dominant mood:  $dominantMood',
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColors.grey700)),
              pw.SizedBox(height: 3),
              pw.Text(
                  'Negative ratio:  ${(negativeRatio * 100).toStringAsFixed(0)}%',
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColors.grey700)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Stat cards ─────────────────────────────────────────────────────────────

  pw.Widget _buildStatCards(Map<String, dynamic> report) {
    return _statGrid([
      ('Total Users', '${report['totalUsers'] ?? 0}', _golden),
      ('Active Users', '${report['activeUsers'] ?? 0}', _sage),
      ('Suspended', '${report['disabledUsers'] ?? 0}', _rose),
      ('Admins', '${report['adminUsers'] ?? 0}', _amber),
      ('Total Logs', '${report['totalLogs'] ?? 0}', _brownDark),
      ('Logs Today', '${report['logsToday'] ?? 0}', _terracotta),
      ('This Week', '${report['logsThisWeek'] ?? 0}', _peach),
      ('Avg / User', '${report['avgLogsPerUser'] ?? 0}', _taupe),
    ]);
  }

  pw.Widget _buildChatbotUsageCards(Map<String, dynamic> u) {
    return _statGrid([
      ('Sessions', '${u['totalSessions'] ?? 0}', _golden),
      ('Messages', '${u['totalMessages'] ?? 0}', _terracotta),
      ('Active Users', '${u['activeChatUsers'] ?? 0}', _sage),
      ('Sessions (7d)', '${u['sessionsThisWeek'] ?? 0}', _amber),
      ('Avg Msgs/Chat', '${u['avgMessagesPerSession'] ?? '0.0'}', _peach),
      ('Avg Min/Chat', '${u['avgSessionMinutes'] ?? '0.0'}', _brownDark),
    ], perRow: 3);
  }

  /// Per-user crisis flags (for the individual mood report): when flagged, when
  /// acknowledged, and how many times. Metadata only — no conversation content.
  pw.Widget _buildUserCrisisTable(List<Map<String, dynamic>> flags) {
    if (flags.isEmpty) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: _cream,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.brown100),
        ),
        child: pw.Center(
          child: pw.Text('No crisis flags for this user in this period.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        ),
      );
    }

    final fmt = DateFormat('dd MMM  HH:mm');
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.0), // Flagged
        1: pw.FlexColumnWidth(2.0), // Acknowledged
        2: pw.FlexColumnWidth(1.0), // Detections
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _brownDark),
          children: ['Flagged', 'Acknowledged', 'Detections']
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8, vertical: 7),
                    child: pw.Text(h,
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        )),
                  ))
              .toList(),
        ),
        ...flags.asMap().entries.map((entry) {
          final f = entry.value;
          final rowBg = entry.key.isEven ? _cream : PdfColors.white;
          final flaggedAt = f['flaggedAt'] as DateTime?;
          final ackAt = f['acknowledgedAt'] as DateTime?;
          final acknowledged = f['acknowledged'] == true;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: rowBg),
            children: [
              _cell(flaggedAt != null ? fmt.format(flaggedAt) : '-',
                  color: _errorRed),
              _cell(
                acknowledged
                    ? (ackAt != null ? fmt.format(ackAt) : 'Acknowledged')
                    : 'Pending',
                bold: true,
                color: acknowledged ? _green : _errorRed,
              ),
              _cell('${f['count'] ?? 1}'),
            ],
          );
        }),
      ],
    );
  }

  /// Crisis flags log: which user, when flagged, and when acknowledged.
  /// Metadata only — no conversation content is ever included.
  pw.Widget _buildCrisisFlagsTable(List<Map<String, dynamic>> flags) {
    if (flags.isEmpty) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: _cream,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.brown100),
        ),
        child: pw.Center(
          child: pw.Text('No crisis flags in this period.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        ),
      );
    }

    final fmt = DateFormat('dd MMM  HH:mm');
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.6), // User
        1: pw.FlexColumnWidth(2.4), // Email
        2: pw.FlexColumnWidth(1.6), // Flagged
        3: pw.FlexColumnWidth(1.7), // Acknowledged
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _brownDark),
          children: ['User', 'Email', 'Flagged', 'Acknowledged']
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8, vertical: 7),
                    child: pw.Text(h,
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        )),
                  ))
              .toList(),
        ),
        ...flags.asMap().entries.map((entry) {
          final f = entry.value;
          final rowBg = entry.key.isEven ? _cream : PdfColors.white;
          final flaggedAt = f['flaggedAt'] as DateTime?;
          final ackAt = f['acknowledgedAt'] as DateTime?;
          final acknowledged = f['acknowledged'] == true;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: rowBg),
            children: [
              _cell(_truncate((f['name'] as String?) ?? '', 18),
                  bold: true, color: _brownDark),
              _cell(_truncate((f['email'] as String?) ?? '', 28),
                  color: PdfColors.grey700),
              _cell(flaggedAt != null ? fmt.format(flaggedAt) : '-',
                  color: _errorRed),
              _cell(
                acknowledged
                    ? (ackAt != null ? fmt.format(ackAt) : 'Acknowledged')
                    : 'Pending',
                bold: true,
                color: acknowledged ? _green : _errorRed,
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _statGrid(List<(String, String, PdfColor)> stats, {int perRow = 4}) {
    final rows = <pw.Widget>[];
    for (int i = 0; i < stats.length; i += perRow) {
      final chunk = stats.sublist(i, (i + perRow).clamp(0, stats.length));
      rows.add(pw.Row(
        children: List.generate(chunk.length, (j) {
          final s = chunk[j];
          final c = s.$3;
          return pw.Expanded(
            child: pw.Container(
              margin: pw.EdgeInsets.only(
                  right: j < chunk.length - 1 ? 8 : 0, bottom: 10),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: _withOpacity(c, 0.10),
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: _withOpacity(c, 0.35)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(s.$2,
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: c,
                      )),
                  pw.SizedBox(height: 4),
                  pw.Text(s.$1,
                      style: const pw.TextStyle(
                          fontSize: 8, color: PdfColors.grey700)),
                ],
              ),
            ),
          );
        }),
      ));
    }

    return pw.Column(children: rows);
  }

  // ── Chart chrome helpers ───────────────────────────────────────────────────

  /// Soft cream "card" that every chart sits inside, for a cohesive warm look.
  pw.Widget _chartCard(pw.Widget child) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _withOpacity(_golden, 0.06),
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: _withOpacity(_brownDark, 0.12)),
      ),
      child: child,
    );
  }

  /// One row of the donut legend: a colored swatch, the mood name, and the
  /// count + percentage.
  pw.Widget _legendRow(PdfColor color, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 10,
            height: 10,
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: pw.BorderRadius.circular(3),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(label,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: _brownDark,
                )),
          ),
          pw.Text(value,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  // ── Mood breakdown donut ─────────────────────────────────────────────────────

  /// Donut + legend of the 5-mood distribution. Shared by the system report's
  /// "Mood Distribution" and the per-user report's "Mood Breakdown".
  pw.Widget _buildMoodDonut(Map<String, int> counts) {
    final total = _emotions.fold<int>(0, (sum, e) => sum + (counts[e] ?? 0));
    if (total == 0) {
      return _chartCard(pw.Text('No mood data available.',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)));
    }

    final present = _emotions.where((e) => (counts[e] ?? 0) > 0).toList();

    return _chartCard(pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.SizedBox(
          width: 130,
          height: 130,
          child: pw.Chart(
            grid: pw.PieGrid(),
            datasets: present.map((emotion) {
              final count = counts[emotion]!;
              return pw.PieDataSet(
                value: count.toDouble(),
                color: _emotionColors[emotion] ?? PdfColors.grey600,
                innerRadius: 28,
                borderColor: _cream,
                borderWidth: 1.5,
              );
            }).toList(),
          ),
        ),
        pw.SizedBox(width: 24),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: present.map((emotion) {
              final count = counts[emotion]!;
              final pct = (count / total * 100).round();
              return _legendRow(
                _emotionColors[emotion] ?? PdfColors.grey600,
                emotion,
                '$count ($pct%)',
              );
            }).toList(),
          ),
        ),
      ],
    ));
  }

  pw.Widget _buildDailyTrendChart(Map<String, int> dailyCounts) {
    final days = dailyCounts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (days.isEmpty) {
      return _chartCard(pw.Text('No data available.',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)));
    }

    final maxVal = days.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final yMax = (maxVal == 0 ? 4 : (maxVal * 1.2).ceil()).toDouble();

    final data = <pw.PointChartValue>[
      for (var i = 0; i < days.length; i++)
        pw.PointChartValue(i.toDouble(), days[i].value.toDouble()),
    ];

    // ~6 evenly-spaced x labels, always including the first and last day.
    final lastIndex = days.length - 1;
    final step = (days.length / 6).ceil().clamp(1, days.length);
    final xTicks = <int>{
      for (var i = 0; i <= lastIndex; i += step) i,
      lastIndex,
    }.toList()
      ..sort();

    return _chartCard(pw.SizedBox(
      height: 150,
      child: pw.Chart(
        grid: pw.CartesianGrid(
          xAxis: pw.FixedAxis<int>(
            xTicks,
            format: (v) => _formatDateKey(days[v.toInt()].key),
            divisions: false,
            textStyle: const pw.TextStyle(fontSize: 7, color: _brownDark),
          ),
          yAxis: pw.FixedAxis<int>(
            [0, (yMax / 2).round(), yMax.round()],
            divisions: true,
            divisionsColor: _withOpacity(_brownDark, 0.12),
            textStyle: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
        ),
        datasets: [
          pw.LineDataSet(
            data: data,
            isCurved: true,
            drawPoints: false,
            drawSurface: true,
            surfaceColor: _golden,
            surfaceOpacity: 0.25,
            color: _brownDark,
            lineColor: _brownDark,
            lineWidth: 1.5,
          ),
        ],
      ),
    ));
  }

  // ── Pos / Neg / Neutral ratio row ──────────────────────────────────────────

  pw.Widget _buildPosNegNeutralRow(int pos, int neg, int total) {
    final neutral = (total - pos - neg).clamp(0, total);
    final posRatio = total > 0 ? pos / total : 0.0;
    final negRatio = total > 0 ? neg / total : 0.0;
    final neutralRatio = total > 0 ? neutral / total : 0.0;

    return pw.Row(
      children: [
        pw.Expanded(
            child: _ratioChip('Positive', posRatio, _sage, pos)),
        pw.SizedBox(width: 8),
        pw.Expanded(
            child:
                _ratioChip('Neutral', neutralRatio, _taupe, neutral)),
        pw.SizedBox(width: 8),
        pw.Expanded(
            child: _ratioChip('Negative', negRatio, _rose, neg)),
      ],
    );
  }

  pw.Widget _ratioChip(
      String label, double ratio, PdfColor color, int count) {
    // Non-uniform border (thick top accent) cannot be combined with borderRadius
    // in the pdf package, so we use square corners intentionally here.
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: pw.BoxDecoration(
        color: _withOpacity(color, 0.10),
        border: pw.Border(
          top: pw.BorderSide(color: color, width: 3),
          left: pw.BorderSide(color: _withOpacity(color, 0.40)),
          right: pw.BorderSide(color: _withOpacity(color, 0.40)),
          bottom: pw.BorderSide(color: _withOpacity(color, 0.40)),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text('${(ratio * 100).toStringAsFixed(0)}%',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: color,
              )),
          pw.SizedBox(height: 3),
          pw.Text(label,
              style: const pw.TextStyle(
                  fontSize: 8, color: PdfColors.grey700)),
          pw.SizedBox(height: 2),
          pw.Text('$count logs',
              style: const pw.TextStyle(
                  fontSize: 7, color: PdfColors.grey500)),
        ],
      ),
    );
  }

  // ── At-risk users table ────────────────────────────────────────────────────

  pw.Widget _buildRiskUsersTable(List<Map<String, dynamic>> users) {
    if (users.isEmpty) {
      return pw.Text('No risk data available.',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600));
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.0),
        1: pw.FlexColumnWidth(2.5),
        2: pw.FlexColumnWidth(0.9),
        3: pw.FlexColumnWidth(1.1),
        4: pw.FlexColumnWidth(1.5),
        5: pw.FlexColumnWidth(0.7),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _brownDark),
          children: ['Name', 'Email', 'Risk', 'Level', 'Dominant', 'Logs']
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8, vertical: 7),
                    child: pw.Text(h,
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        )),
                  ))
              .toList(),
        ),
        ...users.asMap().entries.map((entry) {
          final u = entry.value;
          final score = (u['riskScore'] as num?)?.toDouble() ?? 0;
          final rc = _riskColor(score);
          final level = _riskLevel(score);
          final rowBg = entry.key.isEven ? _cream : PdfColors.white;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: rowBg),
            children: [
              _cell(_truncate((u['name'] as String?) ?? '', 22),
                  bold: true, color: _brownDark),
              _cell(_truncate((u['email'] as String?) ?? '', 30),
                  color: PdfColors.grey700),
              _cell('${score.toStringAsFixed(0)}%', bold: true, color: rc),
              _cell(level, bold: true, color: rc),
              _cell(_truncate(
                  (u['dominantNegativeMood'] as String?) ?? 'Mixed', 14)),
              _cell('${(u['totalLogs'] as num?)?.toInt() ?? 0}'),
            ],
          );
        }),
      ],
    );
  }

  // ── User mood-log table ────────────────────────────────────────────────────

  pw.Widget _buildUserLogTable(List<EmotionLog> logs, DateFormat dayFmt) {
    if (logs.isEmpty) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: _cream,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.brown100),
        ),
        child: pw.Center(
          child: pw.Text('No mood logs recorded in this period.',
              style: const pw.TextStyle(
                  fontSize: 9, color: PdfColors.grey600)),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.8),  // Date
        1: pw.FlexColumnWidth(1.3),  // Emotion
        2: pw.FlexColumnWidth(0.9),  // Intensity
        3: pw.FlexColumnWidth(0.9),  // Resolved
        4: pw.FlexColumnWidth(0.8),  // Mixed?
        5: pw.FlexColumnWidth(3.3),  // Notes
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _brownDark),
          children: [
            'Date', 'Emotion', 'Intensity', 'Resolved', 'Mixed?', 'Notes',
          ]
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8, vertical: 7),
                    child: pw.Text(h,
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        )),
                  ))
              .toList(),
        ),
        ...logs.asMap().entries.map((entry) {
          final log = entry.value;
          final ec = _emotionColors[log.emotionType] ?? PdfColors.grey600;
          final rowBg = entry.key.isEven ? _cream : PdfColors.white;
          final note = log.notes != null ? _truncate(log.notes!, 45) : '-';
          final mixed = log.isMixedMood ? 'Yes' : '-';
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: rowBg),
            children: [
              _cell(dayFmt.format(log.timestamp), color: PdfColors.grey800),
              _cell(log.emotionType, bold: true, color: ec),
              _cell('${log.intensityScore}/5',
                  align: pw.Alignment.center, color: PdfColors.grey800),
              _cell(log.resolvedScore.toStringAsFixed(1),
                  align: pw.Alignment.center, color: PdfColors.grey800),
              _cell(mixed,
                  align: pw.Alignment.center,
                  color: log.isMixedMood ? _amber : PdfColors.grey500),
              _cell(note, color: PdfColors.grey700),
            ],
          );
        }),
      ],
    );
  }

  // ── Shared table cell ──────────────────────────────────────────────────────

  pw.Widget _cell(
    String text, {
    bool bold = false,
    PdfColor color = PdfColors.grey800,
    pw.Alignment align = pw.Alignment.centerLeft,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Align(
        alignment: align,
        child: pw.Text(text,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            )),
      ),
    );
  }

  // ── Utility ────────────────────────────────────────────────────────────────

  String _riskLevel(double score) {
    if (score >= 80) return 'High';
    if (score >= 60) return 'Moderate';
    return 'Observe';
  }

  PdfColor _riskColor(double score) {
    if (score >= 80) return _errorRed;
    if (score >= 60) return _amber;
    return _brownDark;
  }

  String _truncate(String s, int max) =>
      s.length > max ? '${s.substring(0, max)}...' : s;

  String _formatDateKey(String key) {
    try {
      final dt = DateTime.parse(key);
      return DateFormat('dd MMM').format(dt);
    } catch (_) {
      return key;
    }
  }
}
