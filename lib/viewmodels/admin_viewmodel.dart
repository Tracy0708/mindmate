import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/admin_service.dart';
import '../services/report_pdf_service.dart';

class AdminViewModel extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  final List<UserModel> _users = [];
  Map<String, dynamic>? _usageReport;
  bool _isLoading = false;
  String? _errorMessage;

  List<UserModel> get users => _users;
  Map<String, dynamic>? get usageReport => _usageReport;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Stream<List<UserModel>> getUsersStream() {
    return _adminService.getAllUsers();
  }

  Future<UserModel?> getUserById(String userId) {
    return _adminService.getUserById(userId);
  }

  Future<Map<String, dynamic>> getUserUsageStats(String userId) {
    return _adminService.getUserUsageStats(userId);
  }

  Future<List<Map<String, dynamic>>> getMoodRiskUsers({
    int lookbackDays = 21,
    int limit = 12,
  }) {
    return _adminService.getMoodRiskUsers(
      lookbackDays: lookbackDays,
      limit: limit,
    );
  }

  Future<Map<String, dynamic>> getPlatformEmotionStats({
    int lookbackDays = 21,
  }) {
    return _adminService.getPlatformEmotionStats(lookbackDays: lookbackDays);
  }

  /// AI chatbot usage analytics — aggregate metadata only (no conversation content).
  Future<Map<String, dynamic>> getChatbotUsageStats({
    int lookbackDays = 21,
  }) {
    return _adminService.getChatbotUsageStats(lookbackDays: lookbackDays);
  }

  /// Unacknowledged crisis flags for the admin follow-up queue (no transcripts).
  Stream<List<Map<String, dynamic>>> getCrisisFlags({int limit = 50}) {
    return _adminService.getCrisisFlags(limit: limit);
  }

  Future<void> acknowledgeCrisisFlag(String flagId) {
    return _adminService.acknowledgeCrisisFlag(flagId);
  }

  Future<void> generateReport() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _usageReport = await _adminService.generateUsageReport();
    } catch (e) {
      _errorMessage = "Failed to generate report: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Uint8List> exportSystemReport({int lookbackDays = 21}) async {
    final results = await Future.wait([
      _adminService.generateUsageReport(),
      _adminService.getPlatformEmotionStats(lookbackDays: lookbackDays),
      _adminService.getMoodRiskUsers(lookbackDays: lookbackDays, limit: 20),
      _adminService.getChatbotUsageStats(lookbackDays: lookbackDays),
      _adminService.getCrisisFlagLog(lookbackDays: lookbackDays),
    ]);
    return ReportPdfService().generateSystemReportPdf(
      usageReport: results[0] as Map<String, dynamic>,
      platformEmotionStats: results[1] as Map<String, dynamic>,
      moodRiskUsers: results[2] as List<Map<String, dynamic>>,
      chatbotUsage: results[3] as Map<String, dynamic>,
      crisisFlags: results[4] as List<Map<String, dynamic>>,
      lookbackDays: lookbackDays,
    );
  }

  Future<Uint8List> exportAllUsersMoodReport({int lookbackDays = 21}) async {
    final riskUsers = await _adminService.getMoodRiskUsers(
      lookbackDays: lookbackDays,
      limit: 100,
    );
    final capped = riskUsers.take(50).toList();
    final logsPerUser = await Future.wait(
      capped.map((u) => _adminService.getUserEmotionLogs(
            u['userId'] as String,
            lookbackDays: lookbackDays,
          )),
    );
    final flagsPerUser = await Future.wait(
      capped.map((u) => _adminService.getCrisisFlagsForUser(
            u['userId'] as String,
            lookbackDays: lookbackDays,
          )),
    );
    final usersWithLogs = List.generate(
      capped.length,
      (i) => (
        riskUser: capped[i],
        logs: logsPerUser[i],
        crisisFlags: flagsPerUser[i],
      ),
    );
    return ReportPdfService().generateUserMoodReportPdf(
      usersWithLogs: usersWithLogs,
      lookbackDays: lookbackDays,
    );
  }

  Future<Uint8List> exportSingleUserMoodReport(
    Map<String, dynamic> riskUser, {
    int lookbackDays = 21,
  }) async {
    final userId = riskUser['userId'] as String;
    final logs = await _adminService.getUserEmotionLogs(
      userId,
      lookbackDays: lookbackDays,
    );
    final flags = await _adminService.getCrisisFlagsForUser(
      userId,
      lookbackDays: lookbackDays,
    );
    return ReportPdfService().generateUserMoodReportPdf(
      usersWithLogs: [(riskUser: riskUser, logs: logs, crisisFlags: flags)],
      lookbackDays: lookbackDays,
    );
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _adminService.deleteUser(userId);
    } catch (e) {
      _errorMessage = "Failed to delete user: $e";
      notifyListeners();
    }
  }

  Future<void> setUserDisabled(String userId, bool isDisabled) async {
    try {
      await _adminService.setUserDisabled(userId, isDisabled);
    } catch (e) {
      _errorMessage = "Failed to update user status: $e";
      notifyListeners();
    }
  }

  Future<void> resetPasswordForEmail(String email) async {
    try {
      await _adminService.resetPasswordForEmail(email);
    } catch (e) {
      _errorMessage = "Failed to send reset email: $e";
      notifyListeners();
    }
  }

  Future<void> createUser({
    required String name,
    required String email,
    required String password,
    int? age,
    String? gender,
  }) async {
    try {
      await _adminService.createUser(
        name: name,
        email: email,
        password: password,
        age: age,
        gender: gender,
      );
    } catch (e) {
      _errorMessage = "Failed to create user: $e";
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateUserProfile(
    String userId, {
    String? name,
    int? age,
    String? gender,
  }) async {
    try {
      await _adminService.updateUserProfile(userId,
          name: name, age: age, gender: gender);
    } catch (e) {
      _errorMessage = "Failed to update user: $e";
      notifyListeners();
      rethrow;
    }
  }
}
