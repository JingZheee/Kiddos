import 'package:nursery_app/models/timestamp/timestamp_model.dart';
import 'package:nursery_app/models/user/user_role_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String email;
  final String userName;
  final String? phoneNumber;
  final String? photoUrl;
  final String roleId;
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

  // Factory constructor for Firebase registration
  factory User.forFirebaseRegistration({
    required String uid,
    required String email,
    required String name,
    required String roleId,
    String? phoneNumber,
    String? photoUrl,
  }) {
    return User(
      id: uid,
      email: email,
      userName: name,
      phoneNumber: phoneNumber,
      photoUrl: photoUrl,
      roleId: roleId,
      timestamps: Timestamps.now(),
    );
  }

  // Create from Firebase document
  factory User.fromFirestore(String uid, Map<String, dynamic> data) {
    return User(
      id: uid,
      email: data['email'] ?? '',
      userName: data['name'] ?? data['userName'] ?? '',
      phoneNumber: data['phoneNumber'],
      photoUrl: data['photoUrl'],
      roleId: data['roleId']?.toString() ?? '',
      role: data['role'] != null ? UserRole.fromMap(data['role']) : null,
      timestamps: data['timestamps'] != null 
          ? Timestamps.fromJson(data['timestamps'])
          : _timestampsFromFirestore(data),
    );
  }

  // Helper method to create timestamps from Firestore data
  static Timestamps _timestampsFromFirestore(Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    final updatedAt = data['updatedAt'];
    final now = DateTime.now();
    
    return Timestamps(
      createdAt: createdAt is Timestamp ? createdAt.toDate() : now,
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : now,
    );
  }

  // Convert to Firestore map (optimized for Firebase)
  Map<String, dynamic> toFirestoreMap() {
    return {
      'email': email,
      'name': userName,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'roleId': roleId,
      'createdAt': Timestamp.fromDate(timestamps.createdAt),
      'updatedAt': Timestamp.fromDate(timestamps.updatedAt),
    };
  }

  // Validation method
  String? validateForRegistration() {
    if (email.isEmpty) return 'Email is required';
    if (userName.isEmpty) return 'Name is required';
    if (roleId.isEmpty) return 'Role is required';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      return 'Invalid email format';
    }
    return null; // No errors
  }

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
      id: map['id']?.toString() ?? '',
      email: map['email'] ?? '',
      userName: map['user_name'] ?? '',
      phoneNumber: map['phone_number'],
      photoUrl: map['photo_url'],
      roleId: map['role_id']?.toString() ?? '',
      role: map['role'] != null ? UserRole.fromMap(map['role']) : null,
      timestamps: Timestamps.fromJson(map['timestamps']),
    );
  }

  User copyWith({
    String? id,
    String? email,
    String? userName,
    String? phoneNumber,
    String? photoUrl,
    String? roleId,
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
