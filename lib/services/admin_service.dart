import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import '../models/user_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _usersCollection = 'users';

  // Get all users
  Stream<List<UserModel>> getAllUsers() {
    return _firestore.collection(_usersCollection).snapshots().map((snapshot) {
      final users = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return UserModel.fromJson(data);
      }).toList();

      users.sort((a, b) {
        final aTime = a.lastLogin ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.lastLogin ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      return users;
    });
  }

  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc =
          await _firestore.collection(_usersCollection).doc(userId).get();
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data()!;
      data['id'] = doc.id;
      return UserModel.fromJson(data);
    } catch (e) {
      developer.log('getUserById failed: $e', name: 'AdminService', level: 900);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserUsageStats(String userId) async {
    final userDoc =
        await _firestore.collection(_usersCollection).doc(userId).get();
    final emotionSnapshot = await _firestore
        .collection('emotions')
        .where('userID', isEqualTo: userId)
        .get();

    DateTime? lastActive;
    final userData = userDoc.data();
    if (userData != null) {
      final userModel = UserModel.fromJson({...userData, 'id': userDoc.id});
      lastActive = userModel.lastLogin;
    }

    return {
      'moodLogs': emotionSnapshot.docs.length,
      'lastActive': lastActive,
    };
  }

  // Update user role
  Future<void> updateUserRole(String userId, String role) async {
    await _firestore.collection(_usersCollection).doc(userId).update({
      'role': role,
    });
  }

  Future<void> setUserDisabled(String userId, bool isDisabled) async {
    await _firestore.collection(_usersCollection).doc(userId).set({
      'isDisabled': isDisabled,
    }, SetOptions(merge: true));
  }

  Future<void> resetPasswordForEmail(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  // Delete user (requires appropriate admin rules)
  Future<void> deleteUser(String userId) async {
    // You would typically handle Authentication deletion in Cloud Functions
    await _firestore.collection(_usersCollection).doc(userId).delete();
  }

  // Generate usage report
  Future<Map<String, dynamic>> generateUsageReport() async {
    // Collect aggregated data
    final usersSnapshot = await _firestore.collection(_usersCollection).get();
    final emotionsSnapshot = await _firestore.collection('emotions').get();

    final users = usersSnapshot.docs
        .map((doc) => UserModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();

    final activeUsers = users.where((u) => !u.isDisabled).length;
    final disabledUsers = users.where((u) => u.isDisabled).length;
    final adminUsers = users.where((u) => u.role == 'admin').length;

    return {
      'totalUsers': usersSnapshot.docs.length,
      'activeUsers': activeUsers,
      'disabledUsers': disabledUsers,
      'adminUsers': adminUsers,
      'totalLogs': emotionsSnapshot.docs.length,
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }
}
