import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _usersCollection = 'users';

  // Get all users
  Stream<List<UserModel>> getAllUsers() {
    return _firestore.collection(_usersCollection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return UserModel.fromJson(data);
      }).toList();
    });
  }

  // Update user role
  Future<void> updateUserRole(String userId, String role) async {
    await _firestore.collection(_usersCollection).doc(userId).update({
      'role': role,
    });
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
    
    return {
      'totalUsers': usersSnapshot.docs.length,
      'totalLogs': emotionsSnapshot.docs.length,
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }
}
