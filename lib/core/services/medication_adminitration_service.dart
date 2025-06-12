import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/medications/medication_administration_model.dart';

class MedicationAdministrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'medication_administrations';

  // Create a new medication administration record
  Future<void> createMedicationAdministration({
    required String medicationId,
    required String administeredByUserId,
    String? notes,
    required String proofOfPhotoUrl,
  }) async {
    try {
      final docRef = _firestore.collection(_collectionName).doc();

      final administration = MedicationAdministration(
        id: docRef.id,
        medicationId: medicationId,
        administrationAt: DateTime.now(),
        administeredByUserId: administeredByUserId,
        notes: notes ?? '',
        proofOfPhotoUrl: proofOfPhotoUrl,
        createdAt: DateTime.now(),
      );

      await docRef.set(administration.toFirestoreMap());
    } catch (e) {
      throw Exception('Failed to create medication administration: $e');
    }
  }

  // Get all administrations for a specific medication
  Future<List<MedicationAdministration>> getMedicationAdministrations(
      String medicationId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('medicationId', isEqualTo: medicationId)
          .orderBy('administrationAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MedicationAdministration.fromFirestoreMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get medication administrations: $e');
    }
  }

  // Get a specific administration record
  Future<MedicationAdministration?> getMedicationAdministration(
      String administrationId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(administrationId)
          .get();

      if (!doc.exists) return null;
      return MedicationAdministration.fromFirestoreMap(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get medication administration: $e');
    }
  }

  // Update a medication administration record
  Future<void> updateMedicationAdministration({
    required String administrationId,
    String? notes,
    String? proofOfPhotoUrl,
  }) async {
    try {
      final updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (notes != null && notes.isNotEmpty) {
        updates['notes'] = FieldValue.arrayUnion([
          {
            'text': notes,
            'timestamp': FieldValue.serverTimestamp(),
            'photoUrl': proofOfPhotoUrl,
          }
        ]);
      }

      if (proofOfPhotoUrl != null && proofOfPhotoUrl.isNotEmpty) {
        updates['proofOfPhotoUrl'] = FieldValue.arrayUnion([
          {
            'photoUrl': proofOfPhotoUrl,
            'timestamp': FieldValue.serverTimestamp(),
          }
        ]);
      }

      await _firestore
          .collection(_collectionName)
          .doc(administrationId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update medication administration: $e');
    }
  }

  // Delete a medication administration record
  Future<void> deleteMedicationAdministration(String administrationId) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(administrationId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete medication administration: $e');
    }
  }
}
