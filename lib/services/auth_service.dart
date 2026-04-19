import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:developer' as developer;
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Initialize Google Sign-In (call once at app startup)
  static Future<void> initializeGoogleSignIn() async {
    await GoogleSignIn.instance.initialize();
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailPassword(
      String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _handlePostLoginState(credential.user!);
      return credential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailPassword(
      String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      await _createUserDocument(userCredential.user!);

      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with Google (google_sign_in v7 API)
  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();

      final credential = GoogleAuthProvider.credential(
        idToken: googleUser.authentication.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // Create user document in Firestore if it's a new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createUserDocument(userCredential.user!);
      }

      await _handlePostLoginState(userCredential.user!);

      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        GoogleSignIn.instance.signOut(),
      ]);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(User user) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final UserModel newUser = UserModel(
      userID: user.uid,
      userName: user.displayName ?? 'User',
      userEmail: user.email!,
      role: 'user',
      isDisabled: false,
      lastLogin: DateTime.now(),
    );

    try {
      developer.log('Saving user document to Firestore', name: 'AuthService');
      await userDoc.set(newUser.toJson()).timeout(const Duration(seconds: 10));
      developer.log('User document saved successfully', name: 'AuthService');
    } catch (e) {
      developer.log('Firestore error: $e', name: 'AuthService', level: 900);
      rethrow; // Propagate error so caller knows registration had issues
    }
  }

  Future<void> _handlePostLoginState(User user) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final snapshot = await userDoc.get().timeout(const Duration(seconds: 10));

    if (!snapshot.exists || snapshot.data() == null) {
      await userDoc.set(
        {
          'userID': user.uid,
          'userName': user.displayName ?? 'User',
          'userEmail': user.email ?? '',
          'role': 'user',
          'isDisabled': false,
          'lastLogin': Timestamp.now(),
        },
        SetOptions(merge: true),
      );
      return;
    }

    final profile = UserModel.fromJson(snapshot.data()!);
    if (profile.isDisabled) {
      await signOut();
      throw Exception('This account has been disabled by an administrator.');
    }

    await userDoc.set(
      {'lastLogin': Timestamp.now()},
      SetOptions(merge: true),
    );
  }

  Future<UserModel?> getUserProfileById(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get()
          .timeout(const Duration(seconds: 10));

      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } on TimeoutException {
      return null;
    } catch (e) {
      developer.log('getUserProfileById error: $e',
          name: 'AuthService', level: 900);
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(
      {String? name, int? age, String? gender}) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No user logged in');

      final updates = <String, dynamic>{};
      if (name != null) {
        final trimmedName = name.trim();
        if (trimmedName.isNotEmpty) {
          updates['name'] = trimmedName;
          updates['userName'] = trimmedName;
          await user.updateDisplayName(trimmedName);
        }
      }
      if (age != null) {
        updates['age'] = age;
      }
      if (gender != null) {
        updates['gender'] = gender;
      }

      if (updates.isNotEmpty) {
        try {
          developer.log('Updating user profile in Firestore',
              name: 'AuthService');
          await _firestore
              .collection('users')
              .doc(user.uid)
              .update(updates)
              .timeout(const Duration(seconds: 10));
          developer.log('User profile updated successfully',
              name: 'AuthService');
        } on TimeoutException {
          developer.log('Firestore update timed out',
              name: 'AuthService', level: 900);
          throw Exception('Update timed out. Please try again.');
        } catch (e) {
          developer.log('Firestore update error: $e',
              name: 'AuthService', level: 900);
          throw Exception('Failed to update profile: $e');
        }
      }
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Get user profile from Firestore
  Future<UserModel?> getUserProfile() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      developer.log('Fetching user profile from Firestore',
          name: 'AuthService');
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 10));

      if (doc.exists && doc.data() != null) {
        developer.log('User profile fetched successfully', name: 'AuthService');
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } on TimeoutException {
      developer.log('getUserProfile timed out',
          name: 'AuthService', level: 900);
      return null;
    } catch (e) {
      developer.log('getUserProfile error: $e',
          name: 'AuthService', level: 900);
      return null;
    }
  }

  // Update notification preferences in Firestore
  Future<void> updateNotificationPrefs(Map<String, bool> prefs) async {
    try {
      final user = currentUser;
      if (user == null) throw 'No user logged in';

      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({'settings.notificationPrefs': prefs}).timeout(
              const Duration(seconds: 10));
    } catch (e) {
      print('--- Notification Prefs Update Error: $e ---');
    }
  }

  // Update reminder time in Firestore
  Future<void> updateReminderTime(String time) async {
    try {
      final user = currentUser;
      if (user == null) throw 'No user logged in';

      await _firestore.collection('users').doc(user.uid).update(
          {'settings.reminderTime': time}).timeout(const Duration(seconds: 10));
    } catch (e) {
      print('--- Reminder Time Update Error: $e ---');
    }
  }

  // Handle authentication exceptions
  String _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email';
        case 'wrong-password':
          return 'Wrong password';
        case 'email-already-in-use':
          return 'Email is already registered';
        case 'invalid-email':
          return 'Invalid email address';
        case 'weak-password':
          return 'Password is too weak';
        default:
          return 'Authentication failed: ${e.message}';
      }
    }
    return e.toString();
  }
}
