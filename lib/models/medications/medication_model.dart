import 'package:cloud_firestore/cloud_firestore.dart';

enum MedicationStatus {
  active,
  discontinued,
  completed,
}

class Medication {
  final String id;
  final String childId;
  final String medicationName;
  final String dosage;
  final String frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final String instructions;
  final String reportedByUserId;
  final MedicationStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Medication({
    required this.id,
    required this.childId,
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.instructions,
    required this.reportedByUserId,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  // Create from Firebase document
  factory Medication.fromFirestore(String uid, Map<String, dynamic> data) {
    return Medication(
      id: uid,
      childId: data['childId'],
      medicationName: data['medicationName'],
      dosage: data['dosage'],
      frequency: data['frequency'],
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      instructions: data['instructions'],
      reportedByUserId: data['reportedByUserId'],
      status: MedicationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => MedicationStatus.active,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'childId': childId,
      'medicationName': medicationName,
      'dosage': dosage,
      'frequency': frequency,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'instructions': instructions,
      'reportedByUserId': reportedByUserId,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}
