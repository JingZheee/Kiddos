import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nursery_app/models/classroom/classroom_teacher.dart';

class ClassroomTeacherService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<ClassroomTeacher>> getClassroomTeachers() {
    return _db.collection('classroomTeachers').snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => ClassroomTeacher.fromFirestore(doc))
            .toList());
  }

  Future<void> createClassroomTeacher(ClassroomTeacher classroomTeacher) async {
    await _db
        .collection('classroomTeachers')
        .add(classroomTeacher.toFirestore());
  }

  Future<void> updateClassroomTeacher(ClassroomTeacher classroomTeacher) async {
    await _db
        .collection('classroomTeachers')
        .doc(classroomTeacher.id)
        .update(classroomTeacher.toFirestore());
  }

  Future<void> deleteClassroomTeacher(String id) async {
    // Soft delete example
    await _db
        .collection('classroomTeachers')
        .doc(id)
        .update({'deletedAt': Timestamp.now()});
  }
}
