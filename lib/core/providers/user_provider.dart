import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nursery_app/core/services/auth_services.dart';
import 'package:nursery_app/models/user/user_model.dart' as app_user;
import 'package:nursery_app/core/providers/user_role_provider.dart';
import 'package:nursery_app/models/user/user_role_model.dart';

class UserProvider extends ChangeNotifier {
  // Private fields
  User? _firebaseUser;
  app_user.User? _userModel;
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isRegistering = false;
  StreamSubscription<User?>? _authStateSubscription;
  final UserRoleProvider? _userRoleProvider;

  // Getters
  User? get firebaseUser => _firebaseUser;
  app_user.User? get userModel => _userModel;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _firebaseUser != null;
  bool get isInitialized => _isInitialized;
  String? get currentUserId => _firebaseUser?.uid;
  String? get currentUserEmail => _firebaseUser?.email;
  String? get currentUserName => _userModel?.userName ?? _firebaseUser?.displayName;
  String? get currentUserRole => _userModel?.roleId;
  UserRoleProvider? get userRoleProvider => _userRoleProvider;

  UserProvider([this._userRoleProvider]) {
    _initializeProvider();
  }

  // Initialize the provider and listen to auth state changes
  void _initializeProvider() {
    _setLoading(true);
    
    // Listen to Firebase Auth state changes
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen(
      _onAuthStateChanged,
      onError: (error) {
        debugPrint('Auth state error: $error');
        _setLoading(false);
      },
    );
  }

  // Handle auth state changes
  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;
    
    try {
      if (user != null) {
        // Skip loading data if we're in the middle of registration
        // The registerUser method will handle loading data explicitly
        if (!_isRegistering) {
          // User is logged in, fetch their data
          await _loadUserData(user.uid);
        }
      } else {
        // User is logged out, clear data
        _clearUserData();
      }
    } catch (e) {
      debugPrint('Error in _onAuthStateChanged: $e');
      // Clear user data if there's an error
      _clearUserData();
    } finally {
      // Always ensure loading is stopped and initialized is set
      _isInitialized = true;
      if (!_isRegistering) {
        _setLoading(false);
      }
    }
  }

  // Load user data from Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      final userData = await AuthService.getUserData(uid);
      
      if (userData != null) {
        // Get the roleId from user data
        final roleId = userData['roleId']?.toString();
        
        // Always create the user model first
        _userModel = app_user.User.fromFirestore(uid, userData);
        
        // Try to enhance with role data if available
        if (roleId != null && roleId.isNotEmpty && _userRoleProvider != null) {
          UserRole? userRole;
          try {
            userRole = _userRoleProvider!.roles.firstWhere(
              (role) => role.id == roleId,
            );
            
            // Re-create user model with role data
            final userDataWithRole = Map<String, dynamic>.from(userData);
            userDataWithRole['role'] = userRole.toMap();
            _userModel = app_user.User.fromFirestore(uid, userDataWithRole);
            
          } catch (e) {
            // Fallback: try to match by role name
            try {
              if (roleId == 'parent' || roleId == 'teacher' || roleId == 'admin') {
                userRole = _userRoleProvider!.roles.firstWhere(
                  (role) => role.roleName.toLowerCase() == roleId.toLowerCase(),
                );
                
                // Re-create user model with role data
                final userDataWithRole = Map<String, dynamic>.from(userData);
                userDataWithRole['role'] = userRole.toMap();
                _userModel = app_user.User.fromFirestore(uid, userDataWithRole);
              }
            } catch (e2) {
              // Continue with user model without role data
            }
          }
        }
      } else {
        _userModel = null;
        debugPrint('User data not found in Firestore for uid: $uid');
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
              _userModel = null;
      }
      
      notifyListeners();
  }

  // Clear user data
  void _clearUserData() {
    _userModel = null;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  // Register new user
  Future<AuthResult> registerUser({
    required String email,
    required String password,
    required String name,
    required String roleId,
  }) async {
    _isRegistering = true;
    _setLoading(true);
    
    try {
      final result = await AuthService.registerUser(
        email: email,
        password: password,
        name: name,
        roleId: roleId,
      );
      
      if (result.isSuccess && _firebaseUser != null) {
        // Registration succeeded, now load the user data explicitly
        await _loadUserData(_firebaseUser!.uid);
      }
      
      return result;
    } catch (e) {
      rethrow;
    } finally {
      _isRegistering = false;
      _setLoading(false);
    }
  }

  // Login user
  Future<AuthResult> loginUser({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    
    try {
      final result = await AuthService.loginUser(
        email: email,
        password: password,
      );
      
      // Only keep loading if login succeeded
      // Auth state listener will handle setting loading to false on success
      if (!result.isSuccess) {
        _setLoading(false);
      }
      
      return result;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    _setLoading(true);
    await AuthService.signOut();
    // Auth state listener will handle clearing the data
  }

  // Send password reset email
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    return await AuthService.sendPasswordResetEmail(email);
  }

  // Refresh user data
  Future<void> refreshUserData() async {
    if (_firebaseUser != null) {
      _setLoading(true);
      await _loadUserData(_firebaseUser!.uid);
      _setLoading(false);
    }
  }

  // Update user profile (you might want to add this to AuthService too)
  Future<bool> updateUserProfile({
    String? name,
    String? phoneNumber,
    // Add other fields as needed
  }) async {
    if (_firebaseUser == null || _userModel == null) return false;

    try {
      _setLoading(true);
      
      // Update Firebase Auth display name if provided
      if (name != null && name != _firebaseUser!.displayName) {
        await _firebaseUser!.updateDisplayName(name);
      }

      // Update Firestore document
      final updatedData = <String, dynamic>{};
      if (name != null) updatedData['name'] = name;
      if (phoneNumber != null) updatedData['phoneNumber'] = phoneNumber;
      updatedData['updatedAt'] = DateTime.now().toIso8601String();

      if (updatedData.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_firebaseUser!.uid)
            .update(updatedData);
        
        // Refresh user data to get the updated information
        await _loadUserData(_firebaseUser!.uid);
      }
      
      return true;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
} 