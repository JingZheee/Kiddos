import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nursery_app/models/medications/medication_model.dart';

class MedicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'medications';

  // Fetch medications for a specific child
  Stream<List<Medication>> getMedicationsForChild(String childId) {
    return _firestore
        .collection(_collectionName)
        .where('childId', isEqualTo: childId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Medication.fromFirestore(doc.id, doc.data());
      }).toList();
    });
  }

  // Fetch medications for a parent (all their children)
  Stream<List<Medication>> getMedicationsForParent(List<String> childIds) {
    return _firestore
        .collection(_collectionName)
        .where('childId', whereIn: childIds)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Medication.fromFirestore(doc.id, doc.data());
      }).toList();
    });
  }

  // Fetch a single medication
  Future<Medication?> getMedication(String medicationId) async {
    try {
      final doc =
          await _firestore.collection(_collectionName).doc(medicationId).get();
      if (doc.exists) {
        return Medication.fromFirestore(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch medication: $e');
    }
  }

  // Update an existing medication
  Future<void> updateMedication({
    required String medicationId,
    required String medicationName,
    required String dosage,
    required String frequency,
    required String instructions,
    required MedicationStatus status,
  }) async {
    try {
      await _firestore.collection(_collectionName).doc(medicationId).update({
        'medicationName': medicationName,
        'dosage': dosage,
        'frequency': frequency,
        'instructions': instructions,
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update medication: $e');
    }
  }

  // Delete a medication
  Future<void> deleteMedication(String medicationId) async {
    try {
      await _firestore.collection(_collectionName).doc(medicationId).delete();
    } catch (e) {
      throw Exception('Failed to delete medication: $e');
    }
  }

  // Create a new medication
  Future<void> createMedication({
    required String childId,
    required String medicationName,
    required String dosage,
    required String frequency,
    required String instructions,
    required String reportedByUserId,
  }) async {
    try {
      final docRef = _firestore.collection(_collectionName).doc();

      final medication = Medication(
        id: docRef.id,
        childId: childId,
        medicationName: medicationName,
        dosage: dosage,
        frequency: frequency,
        startDate: DateTime.now(),
        instructions: instructions,
        reportedByUserId: reportedByUserId,
        status: MedicationStatus.active,
        createdAt: DateTime.now(),
      );

      await docRef.set(medication.toFirestoreMap());
    } catch (e) {
      throw Exception('Failed to create medication: $e');
    }
  }
}
