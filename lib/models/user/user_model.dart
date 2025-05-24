import 'package:nursery_app/models/timestamp/timestamp_model.dart';
import 'package:nursery_app/models/user/user_role_model.dart';

class User {
  final int id;
  final String email;
  final String userName;
  final String? phoneNumber;
  final String? photoUrl;
  final int roleId;
  final UserRole? role;
  final Timestamps timestamps;

  User({
    required this.id,
    required this.email,
    required this.userName,
    this.phoneNumber,
    this.photoUrl,
    required this.roleId,
    this.role,
    required this.timestamps,
  });

  bool get isParent => role?.type == RoleType.parent;
  bool get isTeacher => role?.type == RoleType.teacher;
  bool get isAdmin => role?.type == RoleType.admin;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'user_name': userName,
      'phone_number': phoneNumber,
      'photo_url': photoUrl,
      'role_id': roleId,
      'timestamps': timestamps.toJson(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'],
      userName: map['user_name'],
      phoneNumber: map['phone_number'],
      photoUrl: map['photo_url'],
      roleId: map['role_id'],
      role: map['role'] != null ? UserRole.fromMap(map['role']) : null,
      timestamps: Timestamps.fromJson(map['timestamps']),
    );
  }

  User copyWith({
    int? id,
    String? email,
    String? userName,
    String? phoneNumber,
    String? photoUrl,
    int? roleId,
    UserRole? role,
    Timestamps? timestamps,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      userName: userName ?? this.userName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      roleId: roleId ?? this.roleId,
      role: role ?? this.role,
      timestamps: timestamps ?? this.timestamps,
    );
  }
}
