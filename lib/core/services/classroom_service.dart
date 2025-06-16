import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nursery_app/models/classroom/classroom.dart';
import 'package:nursery_app/models/timestamp/timestamp_model.dart';

class ClassroomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference _classroomsCollection;

  ClassroomService() {
    _classroomsCollection = _firestore.collection('classrooms');
  }

  // Create
  Future<void> createClassroom(Classroom classroom) async {
    await _classroomsCollection.doc(classroom.id).set(classroom.toFirestore());
  }

  // Read (single)
  Future<Classroom?> getClassroom(String id) async {
    DocumentSnapshot doc = await _classroomsCollection.doc(id).get();
    if (doc.exists) {
      return Classroom.fromFirestore(doc);
    }
    return null;
  }

  // Read (all)
  Stream<List<Classroom>> getClassrooms() {
    return _classroomsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Classroom.fromFirestore(doc)).toList();
    });
  }

  // Read (all by kindergarten)
  Stream<List<Classroom>> getClassroomsByKindergarten(String kindergartenId) {
    return _classroomsCollection
        .where('kindergartenId', isEqualTo: kindergartenId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Classroom.fromFirestore(doc)).toList();
    });
  }

  // Update
  Future<void> updateClassroom(Classroom classroom) async {
    await _classroomsCollection
        .doc(classroom.id)
        .update(classroom.toFirestore());
  }

  // Delete (soft delete)
  Future<void> deleteClassroom(String id) async {
    await _classroomsCollection.doc(id).update({
      'deletedAt': Timestamp.fromDate(Timestamps.now().deletedAt!),
    });
  }
}
