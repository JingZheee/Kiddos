import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nursery_app/models/kindergarten/kindergarten.dart';
import 'package:nursery_app/models/timestamp/timestamp_model.dart';

class KindergartenService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference _kindergartensCollection;

  KindergartenService() {
    _kindergartensCollection = _firestore.collection('kindergartens');
  }

  // Create
  Future<void> createKindergarten(Kindergarten kindergarten) async {
    await _kindergartensCollection
        .doc(kindergarten.id)
        .set(kindergarten.toFirestore());
  }

  // Read (single)
  Future<Kindergarten?> getKindergarten(String id) async {
    DocumentSnapshot doc = await _kindergartensCollection.doc(id).get();
    if (doc.exists) {
      return Kindergarten.fromFirestore(doc);
    }
    return null;
  }

  // Read (all)
  Stream<List<Kindergarten>> getKindergartens() {
    return _kindergartensCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Kindergarten.fromFirestore(doc))
          .toList();
    });
  }

  // Update
  Future<void> updateKindergarten(Kindergarten kindergarten) async {
    await _kindergartensCollection
        .doc(kindergarten.id)
        .update(kindergarten.toFirestore());
  }

  // Delete (soft delete)
  Future<void> deleteKindergarten(String id) async {
    await _kindergartensCollection.doc(id).update({
      'deletedAt': Timestamp.fromDate(Timestamps.now().deletedAt!),
    });
  }
}
