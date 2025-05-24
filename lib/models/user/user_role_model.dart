import 'package:nursery_app/models/timestamp/timestamp_model.dart';

enum RoleType {
  parent,
  teacher,
  admin,
}

class UserRole {
  final int id;
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
  static UserRole fromRoleType(RoleType type, {required int id, required Timestamps timestamps}) {
    return UserRole(
      id: id,
      roleName: roleTypeToName(type),
      timestamps: timestamps,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role_name': roleName,
      'timestamps': timestamps.toJson(),
    };
  }

  factory UserRole.fromMap(Map<String, dynamic> map) {
    return UserRole(
      id: map['id'],
      roleName: map['role_name'],
      timestamps: Timestamps.fromJson(map['timestamps']),
    );
  }

  UserRole copyWith({
    int? id,
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