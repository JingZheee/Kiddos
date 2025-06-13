import 'package:flutter/material.dart';
import '../models/survey/survey_model.dart';

class TargetAudienceSelectorWidget extends StatefulWidget {
  final TargetAudience selectedAudience;
  final List<int> selectedClassIds;
  final List<int> selectedStudentIds;
  final String selectedYearGroup;
  final Function(TargetAudience) onAudienceChanged;
  final Function(List<int>) onClassSelectionChanged;
  final Function(List<int>) onStudentSelectionChanged;
  final Function(String) onYearGroupChanged;

  const TargetAudienceSelectorWidget({
    super.key,
    required this.selectedAudience,
    required this.selectedClassIds,
    required this.selectedStudentIds,
    required this.selectedYearGroup,
    required this.onAudienceChanged,
    required this.onClassSelectionChanged,
    required this.onStudentSelectionChanged,
    required this.onYearGroupChanged,
  });

  @override
  State<TargetAudienceSelectorWidget> createState() => _TargetAudienceSelectorWidgetState();
}

class _TargetAudienceSelectorWidgetState extends State<TargetAudienceSelectorWidget> {
  // Mock data - in real app, this would come from a service
  final List<ClassModel> mockClasses = [
    ClassModel(id: 1, name: 'Nursery A', yearGroup: 'Nursery', teacherName: 'Ms. Johnson'),
    ClassModel(id: 2, name: 'Nursery B', yearGroup: 'Nursery', teacherName: 'Mr. Smith'),
    ClassModel(id: 3, name: 'Reception A', yearGroup: 'Reception', teacherName: 'Ms. Brown'),
    ClassModel(id: 4, name: 'Reception B', yearGroup: 'Reception', teacherName: 'Mrs. Davis'),
    ClassModel(id: 5, name: 'Year 1 A', yearGroup: 'Year 1', teacherName: 'Ms. Wilson'),
    ClassModel(id: 6, name: 'Year 1 B', yearGroup: 'Year 1', teacherName: 'Mr. Taylor'),
  ];

  final List<StudentModel> mockStudents = [
    StudentModel(id: 1, name: 'Alice Johnson', classId: 1, className: 'Nursery A'),
    StudentModel(id: 2, name: 'Bob Smith', classId: 1, className: 'Nursery A'),
    StudentModel(id: 3, name: 'Charlie Brown', classId: 2, className: 'Nursery B'),
    StudentModel(id: 4, name: 'Diana Davis', classId: 2, className: 'Nursery B'),
    StudentModel(id: 5, name: 'Emma Wilson', classId: 3, className: 'Reception A'),
    StudentModel(id: 6, name: 'Frank Taylor', classId: 3, className: 'Reception A'),
    StudentModel(id: 7, name: 'Grace Miller', classId: 4, className: 'Reception B'),
    StudentModel(id: 8, name: 'Henry Anderson', classId: 4, className: 'Reception B'),
    StudentModel(id: 9, name: 'Ivy Thompson', classId: 5, className: 'Year 1 A'),
    StudentModel(id: 10, name: 'Jack White', classId: 5, className: 'Year 1 A'),
    StudentModel(id: 11, name: 'Kate Lewis', classId: 6, className: 'Year 1 B'),
    StudentModel(id: 12, name: 'Liam Harris', classId: 6, className: 'Year 1 B'),
  ];

  List<String> get yearGroups => mockClasses
      .map((c) => c.yearGroup)
      .toSet()
      .toList()
      ..sort();

  List<ClassModel> get filteredClasses {
    if (widget.selectedAudience == TargetAudience.yearGroups && widget.selectedYearGroup.isNotEmpty) {
      return mockClasses.where((c) => c.yearGroup == widget.selectedYearGroup).toList();
    }
    return mockClasses;
  }

  List<StudentModel> get filteredStudents {
    if (widget.selectedClassIds.isNotEmpty) {
      return mockStudents.where((s) => widget.selectedClassIds.contains(s.classId)).toList();
    }
    return mockStudents;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Audience',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildAudienceOptions(),
        const SizedBox(height: 16),
        _buildAudienceDetails(),
      ],
    );
  }

  Widget _buildAudienceOptions() {
    return Column(
      children: [
        RadioListTile<TargetAudience>(
          value: TargetAudience.allStudents,
          groupValue: widget.selectedAudience,
          onChanged: (value) {
            if (value != null) {
              widget.onAudienceChanged(value);
              widget.onClassSelectionChanged([]);
              widget.onStudentSelectionChanged([]);
              widget.onYearGroupChanged('');
            }
          },
          title: const Text('All Students'),
          subtitle: const Text('Send to all students in the kindergarten'),
        ),
        RadioListTile<TargetAudience>(
          value: TargetAudience.specificClasses,
          groupValue: widget.selectedAudience,
          onChanged: (value) {
            if (value != null) {
              widget.onAudienceChanged(value);
              widget.onStudentSelectionChanged([]);
              widget.onYearGroupChanged('');
            }
          },
          title: const Text('Specific Classes'),
          subtitle: const Text('Choose specific classes to send the survey to'),
        ),
        RadioListTile<TargetAudience>(
          value: TargetAudience.yearGroups,
          groupValue: widget.selectedAudience,
          onChanged: (value) {
            if (value != null) {
              widget.onAudienceChanged(value);
              widget.onClassSelectionChanged([]);
              widget.onStudentSelectionChanged([]);
            }
          },
          title: const Text('Year Groups'),
          subtitle: const Text('Target specific year groups (e.g., all Reception students)'),
        ),
        RadioListTile<TargetAudience>(
          value: TargetAudience.individualStudents,
          groupValue: widget.selectedAudience,
          onChanged: (value) {
            if (value != null) {
              widget.onAudienceChanged(value);
              widget.onYearGroupChanged('');
            }
          },
          title: const Text('Individual Students'),
          subtitle: const Text('Select specific students to receive the survey'),
        ),
      ],
    );
  }

  Widget _buildAudienceDetails() {
    switch (widget.selectedAudience) {
      case TargetAudience.allStudents:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            children: [
              Icon(
                Icons.group,
                color: Colors.blue.shade600,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'Survey will be sent to all students',
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${mockStudents.length} students total',
                style: TextStyle(
                  color: Colors.blue.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );

      case TargetAudience.specificClasses:
        return _buildClassSelector();

      case TargetAudience.yearGroups:
        return _buildYearGroupSelector();

      case TargetAudience.individualStudents:
        return _buildStudentSelector();
    }
  }

  Widget _buildClassSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Classes',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: mockClasses.map((classModel) {
              final isSelected = widget.selectedClassIds.contains(classModel.id);
              return CheckboxListTile(
                value: isSelected,
                onChanged: (selected) {
                  final updatedSelection = List<int>.from(widget.selectedClassIds);
                  if (selected == true) {
                    updatedSelection.add(classModel.id);
                  } else {
                    updatedSelection.remove(classModel.id);
                  }
                  widget.onClassSelectionChanged(updatedSelection);
                },
                title: Text(classModel.name),
                subtitle: Text('${classModel.yearGroup} • ${classModel.teacherName}'),
                secondary: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    classModel.yearGroup,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (widget.selectedClassIds.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${widget.selectedClassIds.length} classes selected',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildYearGroupSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Year Group',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: yearGroups.map((yearGroup) {
              final classesInGroup = mockClasses.where((c) => c.yearGroup == yearGroup).length;
              final studentsInGroup = mockStudents.where((s) => 
                mockClasses.any((c) => c.id == s.classId && c.yearGroup == yearGroup)
              ).length;
              
              return RadioListTile<String>(
                value: yearGroup,
                groupValue: widget.selectedYearGroup,
                onChanged: (value) {
                  if (value != null) {
                    widget.onYearGroupChanged(value);
                  }
                },
                title: Text(yearGroup),
                subtitle: Text('$classesInGroup classes • $studentsInGroup students'),
              );
            }).toList(),
          ),
        ),
        if (widget.selectedYearGroup.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${widget.selectedYearGroup} selected',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStudentSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Students',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 300,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            itemCount: mockStudents.length,
            itemBuilder: (context, index) {
              final student = mockStudents[index];
              final isSelected = widget.selectedStudentIds.contains(student.id);
              
              return CheckboxListTile(
                value: isSelected,
                onChanged: (selected) {
                  final updatedSelection = List<int>.from(widget.selectedStudentIds);
                  if (selected == true) {
                    updatedSelection.add(student.id);
                  } else {
                    updatedSelection.remove(student.id);
                  }
                  widget.onStudentSelectionChanged(updatedSelection);
                },
                title: Text(student.name),
                subtitle: Text(student.className),
                secondary: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Text(
                    student.name.split(' ').map((n) => n[0]).join(),
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.selectedStudentIds.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${widget.selectedStudentIds.length} students selected',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// Mock models for demonstration
class ClassModel {
  final int id;
  final String name;
  final String yearGroup;
  final String teacherName;

  ClassModel({
    required this.id,
    required this.name,
    required this.yearGroup,
    required this.teacherName,
  });
}

class StudentModel {
  final int id;
  final String name;
  final int classId;
  final String className;

  StudentModel({
    required this.id,
    required this.name,
    required this.classId,
    required this.className,
  });
}
