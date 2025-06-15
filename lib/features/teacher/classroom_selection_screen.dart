import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nursery_app/core/constants/ui_constants.dart';
import 'package:nursery_app/core/theme/app_theme.dart';
import 'package:nursery_app/core/services/classroom_service.dart';
import 'package:nursery_app/core/services/classroom_teacher_service.dart';
import 'package:nursery_app/models/classroom/classroom.dart';
import 'package:nursery_app/models/classroom/classroom_teacher.dart';
import 'package:nursery_app/models/timestamp/timestamp_model.dart';
import 'package:nursery_app/core/providers/user_provider.dart';

class ClassroomSelectionScreen extends StatefulWidget {
  final String kindergartenId;

  const ClassroomSelectionScreen({super.key, required this.kindergartenId});

  @override
  State<ClassroomSelectionScreen> createState() =>
      _ClassroomSelectionScreenState();
}

class _ClassroomSelectionScreenState extends State<ClassroomSelectionScreen> {
  final ClassroomService _classroomService = ClassroomService();
  final ClassroomTeacherService _classroomTeacherService =
      ClassroomTeacherService();
  List<Classroom> _allClassrooms = [];
  List<Classroom> _filteredClassrooms = [];
  final List<Classroom> _selectedClassrooms = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterClassrooms);
    _fetchClassrooms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchClassrooms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      _classroomService
          .getClassroomsByKindergarten(widget.kindergartenId)
          .listen((classrooms) {
        _allClassrooms = classrooms;
        _filterClassrooms(); // Apply search filter
        setState(() {
          _isLoading = false;
        });
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load classrooms: $e';
        _isLoading = false;
      });
    }
  }

  void _filterClassrooms() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredClassrooms = _allClassrooms.where((classroom) {
        return classroom.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _toggleClassroomSelection(Classroom classroom) {
    setState(() {
      if (_selectedClassrooms.contains(classroom)) {
        _selectedClassrooms.remove(classroom);
      } else {
        _selectedClassrooms.add(classroom);
      }
    });
  }

  Future<void> _registerSelectedClassrooms() async {
    if (_selectedClassrooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one classroom.')),
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
      for (final classroom in _selectedClassrooms) {
        final classroomTeacher = ClassroomTeacher(
          classroomId: classroom.id,
          teacherId: currentUserId,
          timestamps: Timestamps.now(),
        );
        await _classroomTeacherService.createClassroomTeacher(classroomTeacher);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Classrooms registered successfully!')),
        );
        // Optionally navigate away or clear selection
        setState(() {
          _selectedClassrooms.clear();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to register classrooms: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Classrooms'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(UIConstants.spacing16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Classrooms',
                hintText: 'Enter classroom name',
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
                      child: _filteredClassrooms.isEmpty
                          ? const Center(child: Text('No classrooms found.'))
                          : ListView.builder(
                              itemCount: _filteredClassrooms.length,
                              itemBuilder: (context, index) {
                                final classroom = _filteredClassrooms[index];
                                final isSelected =
                                    _selectedClassrooms.contains(classroom);
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: UIConstants.spacing16,
                                      vertical: UIConstants.spacing8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      child: Text(classroom.name[0]),
                                    ),
                                    title: Text(classroom.name),
                                    subtitle: Text('ID: ${classroom.id}'),
                                    trailing: isSelected
                                        ? const Icon(Icons.check_circle,
                                            color: AppTheme.primaryColor)
                                        : const Icon(
                                            Icons.radio_button_unchecked),
                                    onTap: () =>
                                        _toggleClassroomSelection(classroom),
                                  ),
                                );
                              },
                            ),
                    ),
          if (_selectedClassrooms.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(UIConstants.spacing16),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _registerSelectedClassrooms,
                style: ElevatedButton.styleFrom(
                  minimumSize:
                      const Size.fromHeight(50), // Make button full width
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Register ${_selectedClassrooms.length} Classroom(s)'),
              ),
            ),
        ],
      ),
    );
  }
}
