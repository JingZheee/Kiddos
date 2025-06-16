import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nursery_app/models/student/student_parent.dart';

class StudentParentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<StudentParent>> getStudentParents() {
    return _db.collection('studentParents').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => StudentParent.fromFirestore(doc)).toList());
  }

  Future<void> createStudentParent(StudentParent studentParent) async {
    await _db.collection('studentParents').add(studentParent.toFirestore());
  }

  Future<void> updateStudentParent(StudentParent studentParent) async {
    await _db
        .collection('studentParents')
        .doc(studentParent.id)
        .update(studentParent.toFirestore());
  }

  Future<void> deleteStudentParent(String id) async {
    // Soft delete example
    await _db
        .collection('studentParents')
        .doc(id)
        .update({'deletedAt': Timestamp.now()});
  }
}
