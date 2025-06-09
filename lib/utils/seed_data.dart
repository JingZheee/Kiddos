import 'package:nursery_app/models/classroom/classroom.dart';
import 'package:nursery_app/models/classroom/classroom_kindergarten.dart';
import 'package:nursery_app/models/classroom/classroom_teacher.dart';
import 'package:nursery_app/models/kindergarten/kindergarten.dart';
import 'package:nursery_app/models/student/student.dart';
import 'package:nursery_app/models/student/student_parent.dart';
import 'package:nursery_app/models/kindergarten/teacher_kindergarten.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp
import 'package:firebase_core/firebase_core.dart';

class SeedData {
  static final _uuid = const Uuid();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static List<Kindergarten> kindergartens = [];
  static List<Classroom> classrooms = [];
  static List<Student> students = [];
  static List<StudentParent> studentParents = [];
  static List<ClassroomTeacher> classroomTeachers = [];
  static List<TeacherKindergarten> teacherKindergartens = [];
  static List<ClassroomKindergarten> classroomKindergartens = [];

  static Future<void> generateSeedData() async {
    // Clear previous data
    kindergartens.clear();
    classrooms.clear();
    students.clear();
    studentParents.clear();
    classroomTeachers.clear();
    teacherKindergartens.clear();
    classroomKindergartens.clear();

    final now = DateTime.now();

    // Generate 3 Kindergartens
    for (int i = 0; i < 3; i++) {
      final kindergartenId = _uuid.v4();
      final kindergarten = Kindergarten(
        id: kindergartenId,
        name: 'Kindergarten ${i + 1}',
        address: 'Address ${i + 1}',
        contactPhone: '+1-${i}00-100-0000',
        contactEmail: 'kg${i + 1}@example.com',
        description: 'A wonderful place for kids to learn and grow.',
        createdAt: now,
        updatedAt: now,
      );
      kindergartens.add(kindergarten);
      await _firestore
          .collection('kindergartens')
          .doc(kindergarten.id)
          .set(kindergarten.toJson());

      // Generate 2 Classrooms per Kindergarten
      for (int j = 0; j < 2; j++) {
        final classroomId = _uuid.v4();
        final classroom = Classroom(
          id: classroomId,
          name: 'Classroom ${j + 1} - ${kindergarten.name}',
          createdAt: now,
          updatedAt: now,
        );
        classrooms.add(classroom);
        await _firestore
            .collection('classrooms')
            .doc(classroom.id)
            .set(classroom.toJson());

        // Associate Classroom with Kindergarten
        final classroomKindergarten = ClassroomKindergarten(
          classroomId: classroomId,
          kindergartenId: kindergartenId,
          createdAt: now,
          updatedAt: now,
        );
        classroomKindergartens.add(classroomKindergarten);
        await _firestore
            .collection('classroomKindergartens')
            .add(classroomKindergarten.toJson());

        // Generate 2 Teachers per Classroom (and associate with Kindergarten)
        for (int k = 0; k < 2; k++) {
          final teacherId = _uuid.v4(); // Placeholder for actual user ID
          final classroomTeacher = ClassroomTeacher(
            classroomId: classroomId,
            teacherId: teacherId,
            createdAt: now,
            updatedAt: now,
          );
          classroomTeachers.add(classroomTeacher);
          await _firestore
              .collection('classroomTeachers')
              .add(classroomTeacher.toJson());

          // Associate Teacher with Kindergarten
          final teacherKindergarten = TeacherKindergarten(
            teacherId: teacherId,
            kindergartenId: kindergartenId,
            createdAt: now,
            updatedAt: now,
          );
          teacherKindergartens.add(teacherKindergarten);
          await _firestore
              .collection('teacherKindergartens')
              .add(teacherKindergarten.toJson());
        }

        // Generate 10 Students per Classroom
        for (int s = 0; s < 10; s++) {
          final studentId = _uuid.v4();
          final student = Student(
            id: studentId,
            firstName: 'Student${s + 1}',
            lastName: '${classroom.name.replaceAll(' ', '')}',
            dateOfBirth: DateTime(2018, 1, s + 1),
            gender: s % 2 == 0 ? 'male' : 'female',
            kindergartenId: kindergartenId,
            classroomId: classroomId,
            admissionDate: now,
            profilePictureUrl:
                'https://example.com/student_profile_${s + 1}.png',
            createdAt: now,
            updatedAt: now,
          );
          students.add(student);
          await _firestore
              .collection('students')
              .doc(student.id)
              .set(student.toJson());

          // Generate 1 Parent per Student
          final parentId = _uuid.v4(); // Placeholder for actual user ID
          final studentParent = StudentParent(
            parentId: parentId,
            studentId: studentId,
            relationshipType: s % 2 == 0 ? 'mother' : 'father',
            createdAt: now,
            updatedAt: now,
          );
          studentParents.add(studentParent);
          await _firestore
              .collection('studentParents')
              .add(studentParent.toJson());
        }
      }
    }
  }

  static void printSeedData() {
    generateSeedData(); // Ensure data is generated before printing
    print('Generated Seed Data:');
    print('Kindergartens (${kindergartens.length}):');
    for (var k in kindergartens) {
      print('- ${k.name} (ID: ${k.id})');
    }
    print('\nClassrooms (${classrooms.length}):');
    for (var c in classrooms) {
      print('- ${c.name} (ID: ${c.id})');
    }
    print('\nStudents (${students.length}):');
    for (var s in students) {
      print(
          '- ${s.firstName} ${s.lastName} (ID: ${s.id}, KG: ${s.kindergartenId}, Classroom: ${s.classroomId})');
    }
    print('\nStudent Parents (${studentParents.length}):');
    for (var sp in studentParents) {
      print(
          '- Parent ID: ${sp.parentId}, Student ID: ${sp.studentId}, Type: ${sp.relationshipType}');
    }
    print('\nClassroom Teachers (${classroomTeachers.length}):');
    for (var ct in classroomTeachers) {
      print('- Classroom ID: ${ct.classroomId}, Teacher ID: ${ct.teacherId}');
    }
    print('\nTeacher Kindergartens (${teacherKindergartens.length}):');
    for (var tk in teacherKindergartens) {
      print(
          '- Teacher ID: ${tk.teacherId}, Kindergarten ID: ${tk.kindergartenId}');
    }
    print('\nClassroom Kindergartens (${classroomKindergartens.length}):');
    for (var ck in classroomKindergartens) {
      print(
          '- Classroom ID: ${ck.classroomId}, Kindergarten ID: ${ck.kindergartenId}');
    }
  }
}
