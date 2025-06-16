import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nursery_app/core/constants/ui_constants.dart';
import 'package:nursery_app/core/theme/app_theme.dart';
import 'package:nursery_app/core/services/student_service.dart';
import 'package:nursery_app/core/services/student_parent_service.dart';
import 'package:nursery_app/models/student/student.dart';
import 'package:nursery_app/models/student/student_parent.dart';
import 'package:nursery_app/models/timestamp/timestamp_model.dart';
import 'package:nursery_app/core/providers/user_provider.dart';

class StudentSelectionScreen extends StatefulWidget {
  final String kindergartenId;

  const StudentSelectionScreen({super.key, required this.kindergartenId});

  @override
  State<StudentSelectionScreen> createState() => _StudentSelectionScreenState();
}

class _StudentSelectionScreenState extends State<StudentSelectionScreen> {
  final StudentService _studentService = StudentService();
  final StudentParentService _studentParentService = StudentParentService();
  List<Student> _allStudents = [];
  List<Student> _filteredStudents = [];
  final List<Student> _selectedStudents = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterStudents);
    _fetchStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      _studentService.getStudents().listen((students) {
        // Filter students by kindergartenId
        _allStudents = students
            .where((student) => student.kindergartenId == widget.kindergartenId)
            .toList();
        _filterStudents(); // Apply search filter
        setState(() {
          _isLoading = false;
        });
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load students: $e';
        _isLoading = false;
      });
    }
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStudents = _allStudents.where((student) {
        return student.firstName.toLowerCase().contains(query) ||
            student.lastName.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _toggleStudentSelection(Student student) {
    setState(() {
      if (_selectedStudents.contains(student)) {
        _selectedStudents.remove(student);
      } else {
        _selectedStudents.add(student);
      }
    });
  }

  Future<void> _registerSelectedStudents() async {
    if (_selectedStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one student.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final userProvider = context.read<UserProvider>();
    final currentUserId = userProvider.currentUserId;

    if (currentUserId == null) {
      setState(() {
        _errorMessage = 'User not logged in.';
        _isLoading = false;
      });
      return;
    }

    try {
      for (final student in _selectedStudents) {
        final studentParent = StudentParent(
          parentId: currentUserId,
          studentId: student.id,
          relationshipType:
              'guardian', // Default relationship type, can be expanded
          timestamps: Timestamps.now(),
        );
        await _studentParentService.createStudentParent(studentParent);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Students registered successfully!')),
        );
        // Optionally navigate away or clear selection
        setState(() {
          _selectedStudents.clear();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to register students: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Students'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(UIConstants.spacing16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Students',
                hintText: 'Enter student name',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
                ),
              ),
            ),
          ),
          _isLoading
              ? const Expanded(
                  child: Center(child: CircularProgressIndicator()))
              : _errorMessage != null
                  ? Expanded(
                      child: Center(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    )
                  : Expanded(
                      child: _filteredStudents.isEmpty
                          ? const Center(child: Text('No students found.'))
                          : ListView.builder(
                              itemCount: _filteredStudents.length,
                              itemBuilder: (context, index) {
                                final student = _filteredStudents[index];
                                final isSelected =
                                    _selectedStudents.contains(student);
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: UIConstants.spacing16,
                                      vertical: UIConstants.spacing8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      child: Text(student.firstName[0]),
                                    ),
                                    title: Text(
                                        '${student.firstName} ${student.lastName}'),
                                    subtitle: Text('ID: ${student.id}'),
                                    trailing: isSelected
                                        ? const Icon(Icons.check_circle,
                                            color: AppTheme.primaryColor)
                                        : const Icon(
                                            Icons.radio_button_unchecked),
                                    onTap: () =>
                                        _toggleStudentSelection(student),
                                  ),
                                );
                              },
                            ),
                    ),
          if (_selectedStudents.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(UIConstants.spacing16),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _registerSelectedStudents,
                style: ElevatedButton.styleFrom(
                  minimumSize:
                      const Size.fromHeight(50), // Make button full width
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Register ${_selectedStudents.length} Student(s)'),
              ),
            ),
        ],
      ),
    );
  }
}
