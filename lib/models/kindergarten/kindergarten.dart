import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nursery_app/models/timestamp/timestamp_model.dart';

class Kindergarten {
  final String id;
  final String name;
  final String? address;
  final String? contactPhone;
  final String? contactEmail;
  final String? description;
  final Timestamps timestamps;

  Kindergarten({
    required this.id,
    required this.name,
    this.address,
    this.contactPhone,
    this.contactEmail,
    this.description,
    required this.timestamps,
  });

  factory Kindergarten.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Kindergarten(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'],
      contactPhone: data['contactPhone'],
      contactEmail: data['contactEmail'],
      description: data['description'],
      timestamps: data['timestamps'] != null
          ? Timestamps.fromJson(data['timestamps'])
          : _timestampsFromFirestore(data as Map<String, dynamic>),
    );
  }

  static Timestamps _timestampsFromFirestore(Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    final updatedAt = data['updatedAt'];
    final now = DateTime.now();

    return Timestamps(
      createdAt: createdAt is Timestamp ? createdAt.toDate() : now,
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : now,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'description': description,
      'createdAt': Timestamp.fromDate(timestamps.createdAt),
      'updatedAt': Timestamp.fromDate(timestamps.updatedAt),
      if (timestamps.deletedAt != null)
        'deletedAt': Timestamp.fromDate(timestamps.deletedAt!),
    };
  }

  Kindergarten copyWith({
    String? id,
    String? name,
    String? address,
    String? contactPhone,
    String? contactEmail,
    String? description,
    Timestamps? timestamps,
  }) {
    return Kindergarten(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      description: description ?? this.description,
      timestamps: timestamps ?? this.timestamps,
    );
  }
}
