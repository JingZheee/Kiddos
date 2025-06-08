import 'package:nursery_app/models/timestamp/timestamp_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum RoleType {
  parent,
  teacher,
  admin,
}

class UserRole {
  final String id;
  final String roleName;
  final Timestamps timestamps;

  UserRole({
    required this.id,
    required this.roleName,
    required this.timestamps,
  });

  // Convert RoleType to roleName
  static String roleTypeToName(RoleType type) {
    return type.toString().split('.').last;
  }

  // Convert roleName to RoleType
  static RoleType nameToRoleType(String name) {
    return RoleType.values.firstWhere(
      (type) => type.toString().split('.').last == name,
      orElse: () => RoleType.parent,
    );
  }

  // Get the RoleType for this role
  RoleType get type => nameToRoleType(roleName);

  // Create a UserRole from a RoleType
  static UserRole fromRoleType(RoleType type, {required String id, required Timestamps timestamps}) {
    return UserRole(
      id: id,
      roleName: roleTypeToName(type),
      timestamps: timestamps,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roleName': roleName,
      'timestamps': timestamps.toJson(),
    };
  }

  factory UserRole.fromMap(Map<String, dynamic> map) {
    // Handle different field name formats (Firebase vs local storage)
    final id = map['id'] as String;
    final roleName = map['roleName'] ?? map['role_name'] as String;
    
    // Handle timestamps - either as a timestamps object or separate createdAt/updatedAt fields
    Timestamps timestamps;
    if (map['timestamps'] != null) {
      // Standard format
      timestamps = Timestamps.fromJson(map['timestamps']);
    } else if (map['createdAt'] != null && map['updatedAt'] != null) {
      // Firebase format with separate timestamp fields
      final createdAt = map['createdAt'];
      final updatedAt = map['updatedAt'];
      
      timestamps = Timestamps(
        createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.parse(createdAt),
        updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : DateTime.parse(updatedAt),
      );
    } else {
      // Fallback to current time
      timestamps = Timestamps.now();
    }
    
    return UserRole(
      id: id,
      roleName: roleName,
      timestamps: timestamps,
    );
  }

  UserRole copyWith({
    String? id,
    String? roleName,
    Timestamps? timestamps,
  }) {
    return UserRole(
      id: id ?? this.id,
      roleName: roleName ?? this.roleName,
      timestamps: timestamps ?? this.timestamps,
    );
  }
} 