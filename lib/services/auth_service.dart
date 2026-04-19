import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
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

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // Create user document in Firestore if it's a new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createUserDocument(userCredential.user!);
      }

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
      userPassword: '',
    );
    
    try {
      print('--- Attempting to save user document to Firestore ---');
      await userDoc.set(newUser.toJson()).timeout(const Duration(seconds: 10));
      print('--- Successfully saved user document ---');
    } catch (e) {
      print('--- Firestore Error: $e ---');
      // We don't want to break the whole registration if Firestore hangs, 
      // so we catch and print the error instead of throwing.
    }
  }

  // Update user profile
  Future<void> updateUserProfile({String? name, int? age, String? gender}) async {
    try {
      final user = currentUser;
      if (user == null) throw 'No user logged in';

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
          print('--- Attempting to update user profile in Firestore ---');
          await _firestore.collection('users').doc(user.uid).update(updates).timeout(const Duration(seconds: 10));
          print('--- Successfully updated user profile ---');
        } catch (e) {
          print('--- Firestore Update Error: $e ---');
          // Catch and ignore timeout/offline errors so user is still allowed to navigate
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

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 10));

      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('--- getUserProfile Error: $e ---');
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
          .update({'settings.notificationPrefs': prefs})
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      print('--- Notification Prefs Update Error: $e ---');
    }
  }

  // Update reminder time in Firestore
  Future<void> updateReminderTime(String time) async {
    try {
      final user = currentUser;
      if (user == null) throw 'No user logged in';

      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({'settings.reminderTime': time})
          .timeout(const Duration(seconds: 10));
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
