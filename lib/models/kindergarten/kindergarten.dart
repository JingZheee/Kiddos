import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nursery_app/models/timestamp/timestamp_model.dart';

class Kindergarten extends Timestamps {
  final String id;
  final String name;
  final String? address;
  final String? contactPhone;
  final String? contactEmail;
  final String? description;

  Kindergarten({
    required this.id,
    required this.name,
    this.address,
    this.contactPhone,
    this.contactEmail,
    this.description,
    required super.createdAt,
    required super.updatedAt,
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
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Kindergarten copyWith({
    String? id,
    String? name,
    String? address,
    String? contactPhone,
    String? contactEmail,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Kindergarten(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
