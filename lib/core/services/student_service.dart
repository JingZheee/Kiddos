import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nursery_app/models/student/student.dart';
import 'package:nursery_app/models/timestamp/timestamp_model.dart';

class StudentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference _studentsCollection;

  StudentService() {
    _studentsCollection = _firestore.collection('students');
  }

  // Create
  Future<void> createStudent(Student student) async {
    await _studentsCollection.doc(student.id).set(student.toFirestore());
  }

  // Read (single)
  Future<Student?> getStudent(String id) async {
    DocumentSnapshot doc = await _studentsCollection.doc(id).get();
    if (doc.exists) {
      return Student.fromFirestore(doc);
    }
    return null;
  } 
  
  //get student id for parent
  Future<List<Map<String, String>>> getStudentNameForParent(List<String> studentIds) async {
    final students = await _studentsCollection
        .where(FieldPath.documentId, whereIn: studentIds)
        .get();
    return students.docs.map((doc) => {
      'id': doc.id,
      'firstName': doc.get('firstName') as String,
    }).toList();
  }

  // Read (all)
  Stream<List<Student>> getStudents() {
    return _studentsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Student.fromFirestore(doc)).toList();
    });
  }

  // Update
  Future<void> updateStudent(Student student) async {
    await _studentsCollection.doc(student.id).update(student.toFirestore());
  }

  // Delete (soft delete)
  Future<void> deleteStudent(String id) async {
    await _studentsCollection.doc(id).update({
      'deletedAt': Timestamp.fromDate(Timestamps.now().deletedAt!),
    });
  }
}
