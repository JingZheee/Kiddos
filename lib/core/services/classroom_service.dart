import 'package:nursery_app/models/classroom/classroom.dart';
import 'package:nursery_app/models/timestamp/timestamp_model.dart';

class ClassroomService {
  // Dummy classroom data
  static final List<Classroom> _dummyClassrooms = [
    Classroom(
      id: 'class1',
      name: 'Little Stars (Age 3-4)',
      kindergartenId: 'kg1',
      timestamps: Timestamps.now(),
    ),
    Classroom(
      id: 'class2', 
      name: 'Bright Minds (Age 4-5)',
      kindergartenId: 'kg1',
      timestamps: Timestamps.now(),
    ),
    Classroom(
      id: 'class3',
      name: 'Creative Explorers (Age 5-6)',
      kindergartenId: 'kg1',
      timestamps: Timestamps.now(),
    ),
  ];

  // Create
  Future<void> createClassroom(Classroom classroom) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _dummyClassrooms.add(classroom);
  }

  // Read (single)
  Future<Classroom?> getClassroom(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _dummyClassrooms.firstWhere((classroom) => classroom.id == id);
    } catch (e) {
      return null;
    }
  }

  // Read (all)
  Stream<List<Classroom>> getClassrooms() async* {
    await Future.delayed(const Duration(milliseconds: 300));
    yield _dummyClassrooms;
  }

  // Read (all by kindergarten)
  Stream<List<Classroom>> getClassroomsByKindergarten(String kindergartenId) async* {
    await Future.delayed(const Duration(milliseconds: 300));
    final filteredClassrooms = _dummyClassrooms
        .where((classroom) => classroom.kindergartenId == kindergartenId)
        .toList();
    yield filteredClassrooms;
  }

  // Update
  Future<void> updateClassroom(Classroom classroom) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _dummyClassrooms.indexWhere((c) => c.id == classroom.id);
    if (index != -1) {
      _dummyClassrooms[index] = classroom;
    }
  }

  // Delete
  Future<void> deleteClassroom(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _dummyClassrooms.removeWhere((classroom) => classroom.id == id);
  }
}
