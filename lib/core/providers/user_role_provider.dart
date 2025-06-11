import 'package:flutter/foundation.dart';
import 'package:nursery_app/models/user/user_role_model.dart';
import 'package:nursery_app/core/services/user_role_service.dart';

enum UserRoleLoadingState {
  initial,
  loading,
  loaded,
  error,
}

class UserRoleProvider extends ChangeNotifier {
  final UserRoleService _userRoleService = UserRoleService();
  
  List<UserRole> _roles = [];
  UserRoleLoadingState _loadingState = UserRoleLoadingState.initial;
  String? _errorMessage;
  bool _isInitialized = false;

  // Getters
  List<UserRole> get roles => _roles;
  UserRoleLoadingState get loadingState => _loadingState;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _loadingState == UserRoleLoadingState.loading;
  bool get hasError => _loadingState == UserRoleLoadingState.error;
  bool get isInitialized => _isInitialized;

  /// Check if service has cached data
  bool get hasCachedData => _userRoleService.hasCachedData;
  
  /// Get cache timestamp
  DateTime? get cacheTimestamp => _userRoleService.cacheTimestamp;
  
  /// Get cached roles count
  int get cachedRolesCount => _userRoleService.cachedRolesCount;

  /// Get role by RoleType
  UserRole? getRoleByType(RoleType type) {
    try {
      return _roles.firstWhere((role) => role.type == type);
    } catch (e) {
      return null;
    }
  }

  /// Get parent role
  UserRole? get parentRole => getRoleByType(RoleType.parent);
  
  /// Get teacher role
  UserRole? get teacherRole => getRoleByType(RoleType.teacher);
  
  /// Get admin role
  UserRole? get adminRole => getRoleByType(RoleType.admin);

  /// Initialize user roles - call this on app startup
  Future<void> initializeRoles() async {
    if (_isInitialized) return;

    _setLoadingState(UserRoleLoadingState.loading);
    
    try {
      _roles = await _userRoleService.fetchAndCacheUserRoles();
      _setLoadingState(UserRoleLoadingState.loaded);
      _isInitialized = true;
      _errorMessage = null;
    } catch (e) {
      _setLoadingState(UserRoleLoadingState.error);
      _errorMessage = e.toString();
      
      // Try to load from cache as fallback
      try {
        _roles = await _userRoleService.getCachedRoles();
        if (_roles.isNotEmpty) {
          _setLoadingState(UserRoleLoadingState.loaded);
          _isInitialized = true;
          _errorMessage = 'Using cached data - ${e.toString()}';
        }
      } catch (cacheError) {
        _errorMessage = 'Failed to load roles: $e';
      }
    }
  }

  /// Refresh roles from Firebase
  Future<void> refreshRoles() async {
    _setLoadingState(UserRoleLoadingState.loading);
    
    try {
      _roles = await _userRoleService.refreshUserRoles();
      _setLoadingState(UserRoleLoadingState.loaded);
      _errorMessage = null;
    } catch (e) {
      _setLoadingState(UserRoleLoadingState.error);
      _errorMessage = e.toString();
    }
  }

  /// Load roles from cache only
  Future<void> loadCachedRoles() async {
    try {
      _roles = await _userRoleService.getCachedRoles();
      if (_roles.isNotEmpty) {
        _setLoadingState(UserRoleLoadingState.loaded);
        _isInitialized = true;
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading cached roles: $e');
      }
    }
  }

  /// Create or update a role
  Future<bool> createOrUpdateRole(UserRole role) async {
    try {
      final updatedRole = await _userRoleService.createOrUpdateRole(role);
      
      // Update local list
      final index = _roles.indexWhere((r) => r.id == role.id);
      if (index != -1) {
        _roles[index] = updatedRole;
      } else {
        _roles.add(updatedRole);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete a role
  Future<bool> deleteRole(int roleId) async {
    try {
      await _userRoleService.deleteRole(roleId);
      
      // Remove from local list
      _roles.removeWhere((role) => role.id == roleId);
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Check if a role exists
  bool roleExists(RoleType type) {
    return getRoleByType(type) != null;
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset provider state
  void reset() {
    _roles = [];
    _loadingState = UserRoleLoadingState.initial;
    _errorMessage = null;
    _isInitialized = false;
    notifyListeners();
  }

  /// Clear all cache data (useful for logout)
  void clearAllCache() {
    UserRoleService.clearAllCache();
    reset();
  }

  void _setLoadingState(UserRoleLoadingState state) {
    _loadingState = state;
    notifyListeners();
  }
} 