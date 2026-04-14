import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/admin_service.dart';

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

  Future<void> deleteUser(String userId) async {
    try {
      await _adminService.deleteUser(userId);
    } catch (e) {
      _errorMessage = "Failed to delete user: $e";
      notifyListeners();
    }
  }
}
