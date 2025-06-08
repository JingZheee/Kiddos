import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nursery_app/models/user/user_role_model.dart';
import 'package:nursery_app/models/timestamp/timestamp_model.dart';

class UserRoleService {
  static const int _cacheExpiryHours = 24; // Cache for 24 hours

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'user_roles';

  // In-memory cache
  static List<UserRole>? _cachedRoles;
  static DateTime? _lastFetchTime;

  /// Fetch user roles from Firebase and cache them
  Future<List<UserRole>> fetchAndCacheUserRoles() async {
    try {
      // Check if cache is still valid
      if (_cachedRoles != null && _isCacheValid()) {
        return List.from(_cachedRoles!);
      }
      
      // Fetch from Firebase
      final querySnapshot = await _firestore.collection(_collectionName).get();
      
      final roles = querySnapshot.docs.map((doc) {
        final data = doc.data();
        
        return UserRole.fromMap({
          'id': doc.id, // Use the Firebase document ID
          ...data
        });
      }).toList();

      // Cache the fetched roles
      _cacheRoles(roles);
      
      return roles;
    } catch (e) {
      
      // Return cached roles if available, even if expired
      if (_cachedRoles != null && _cachedRoles!.isNotEmpty) {
        return List.from(_cachedRoles!);
      }
      
      // Return default roles if no cache and fetch failed
      return _getDefaultRoles();
    }
  }

  /// Get a specific user role by RoleType
  Future<UserRole?> getRoleByType(RoleType type) async {
    final roles = await fetchAndCacheUserRoles();
    try {
      return roles.firstWhere((role) => role.type == type);
    } catch (e) {
      return null;
    }
  }

  /// Get all cached user roles without fetching from Firebase
  Future<List<UserRole>> getCachedRoles() async {
    if (_cachedRoles != null) {
      return List.from(_cachedRoles!);
    }
    return [];
  }

  /// Force refresh user roles from Firebase
  Future<List<UserRole>> refreshUserRoles() async {
    _clearCache();
    return await fetchAndCacheUserRoles();
  }

  /// Check if a role exists by RoleType
  Future<bool> roleExists(RoleType type) async {
    final role = await getRoleByType(type);
    return role != null;
  }

  /// Create or update a user role in Firebase
  Future<UserRole> createOrUpdateRole(UserRole role) async {
    try {
      await _firestore.collection(_collectionName).doc(role.id.toString()).set(role.toMap());
      
      // Update cache
      await refreshUserRoles();
      
      return role;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a user role from Firebase
  Future<void> deleteRole(int roleId) async {
    try {
      await _firestore.collection(_collectionName).doc(roleId.toString()).delete();
      
      // Update cache
      await refreshUserRoles();
    } catch (e) {
      rethrow;
    }
  }

  /// Check if cache is valid
  bool _isCacheValid() {
    if (_lastFetchTime == null) return false;
    
    final now = DateTime.now();
    final difference = now.difference(_lastFetchTime!);
    
    return difference.inHours < _cacheExpiryHours;
  }

  /// Cache roles in memory
  void _cacheRoles(List<UserRole> roles) {
    _cachedRoles = List.from(roles);
    _lastFetchTime = DateTime.now();
  }

  /// Clear in-memory cache
  void _clearCache() {
    _cachedRoles = null;
    _lastFetchTime = null;
  }

  /// Get default roles when no data is available
  List<UserRole> _getDefaultRoles() {
    final now = Timestamps.now();
    final defaultRoles = [
      UserRole.fromRoleType(RoleType.parent, id: '1', timestamps: now),
      UserRole.fromRoleType(RoleType.teacher, id: '2', timestamps: now),
      UserRole.fromRoleType(RoleType.admin, id: '3', timestamps: now),
    ];
    
    // Cache the default roles
    _cacheRoles(defaultRoles);
    
    return defaultRoles;
  }

  /// Check if any data is cached
  bool get hasCachedData => _cachedRoles != null && _cachedRoles!.isNotEmpty;

  /// Get the cache timestamp
  DateTime? get cacheTimestamp => _lastFetchTime;

  /// Get the number of cached roles
  int get cachedRolesCount => _cachedRoles?.length ?? 0;

  /// Clear all cached data (useful for logout)
  static void clearAllCache() {
    _cachedRoles = null;
    _lastFetchTime = null;
  }
} 