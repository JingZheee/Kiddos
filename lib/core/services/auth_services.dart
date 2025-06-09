import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nursery_app/models/user/user_model.dart' as app_user;

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  static bool get isLoggedIn => _auth.currentUser != null;

  // Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  // Get current user email
  static String? get currentUserEmail => _auth.currentUser?.email;

  // Register new user
  static Future<AuthResult> registerUser({
    required String email,
    required String password,
    required String name,
    required String roleId,
    String? kindergartenId,
  }) async {
    try {
      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(name.trim());

      // Create user object with validation
      final user = app_user.User.forFirebaseRegistration(
        uid: userCredential.user!.uid,
        email: email,
        name: name,
        roleId: roleId,
        kindergartenId: kindergartenId,
      );

      // Validate user data
      final validationError = user.validateForRegistration();
      if (validationError != null) {
        // Delete the Firebase Auth user if validation fails
        await userCredential.user?.delete();
        return AuthResult.failure(validationError);
      }

      // Store user data in Firestore using the model
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(user.toFirestoreMap());

      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      return AuthResult.failure(
          'An unexpected error occurred during registration');
    }
  }

  // Simple login - just authenticate with Firebase Auth
  // UserProvider will handle data loading via auth state listener
  static Future<AuthResult> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred during login');
    }
  }

  // Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // Send password reset email
  static Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      // Don't expose specific errors about whether account exists
      // Just show a generic error message for security
      if (e.code == 'invalid-email') {
        return AuthResult.failure('Please enter a valid email address');
      } else {
        return AuthResult.failure(
            'Error sending password reset email. Please try again later.');
      }
    } catch (e) {
      return AuthResult.failure('An error occurred. Please try again later');
    }
  }

  // Get user data from Firestore
  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  // Helper method to get user-friendly error messages
  static String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists with this email address';
      case 'invalid-email':
        return 'The email address is not valid';
      case 'weak-password':
        return 'The password is too weak. Please use a stronger password';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled';
      case 'user-not-found':
        return 'No user found with this email address';
      case 'wrong-password':
        return 'Incorrect password';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later';
      default:
        return e.message ?? 'An authentication error occurred';
    }
  }
}

// Result class for auth operations
class AuthResult {
  final bool isSuccess;
  final String? errorMessage;

  AuthResult._({required this.isSuccess, this.errorMessage});

  factory AuthResult.success() => AuthResult._(isSuccess: true);
  factory AuthResult.failure(String message) =>
      AuthResult._(isSuccess: false, errorMessage: message);
}
