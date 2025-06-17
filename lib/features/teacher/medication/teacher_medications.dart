import 'package:flutter/material.dart';
import 'package:nursery_app/core/providers/user_provider.dart';
import 'package:nursery_app/core/services/student_service.dart';
import 'package:provider/provider.dart';
import '../../../core/routing/app_navigation.dart';
import '../../../core/services/medication_service.dart';
import '../../../models/medications/medication_model.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/show_error_message.dart';

class TeacherMedicationScreen extends StatefulWidget {
  const TeacherMedicationScreen({super.key});

  @override
  State<TeacherMedicationScreen> createState() =>
      _TeacherMedicationScreenState();
}

class _TeacherMedicationScreenState extends State<TeacherMedicationScreen> {
  final MedicationService _medicationService = MedicationService();
  final StudentService _studentService = StudentService();
  bool _isLoading = false;
  Stream<List<Medication>>? _medications;
  @override
  void initState() {
    super.initState();
    setState(() {
      _isLoading = true;
    });
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUserId = userProvider.currentUserId;
    if (currentUserId == null) {
      const ShowErrorMessage(errorMessage: 'User not logged in.');
      return;
    }
    _medications = _medicationService.getMedicationsForTeacher(currentUserId);
    if (_medications == null) {
      const ShowErrorMessage(errorMessage: 'Error fetching medications');
    }
    setState(() {
      _isLoading = false;
    });
  }

  // Group medications by studentId
  Future<Map<String, List<Medication>>> _groupMedicationsByChild(
      List<Medication> medications) async {
    final Map<String, List<Medication>> groupedMedications = {};

    for (var medication in medications) {
      final studentName = await _studentService
          .getStudent(medication.studentId)
          .then((student) => student?.firstName);
      if (!groupedMedications.containsKey(studentName)) {
        groupedMedications[studentName!] = [];
      }
      groupedMedications[studentName]!.add(medication);
    }

    return groupedMedications;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Children Medications',
        showBackButton: true,
        userRole: 'teacher',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Medication>>(
              stream: _medications,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final medications = snapshot.data ?? [];

                if (medications.isEmpty) {
                  return const Center(
                    child: Text('No medications found'),
                  );
                }
                // Group medications by child
                return FutureBuilder<Map<String, List<Medication>>>(
                  future: _groupMedicationsByChild(medications),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final groupedMedications = snapshot.data ?? {};

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: groupedMedications.length,
                      itemBuilder: (context, index) {
                        final studentId =
                            groupedMedications.keys.elementAt(index);
                        final childMedications = groupedMedications[studentId]!;

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ExpansionTile(
                              backgroundColor: Colors.grey[50],
                              collapsedBackgroundColor: Colors.white,
                              collapsedIconColor: Colors.grey[600],
                              iconColor: Colors.grey[600],
                              maintainState: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                              ),
                              collapsedShape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                              ),
                              title: Text(
                                studentId,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black87,
                                ),
                              ),
                              subtitle: Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${childMedications.length} medication${childMedications.length > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              children: childMedications.map((medication) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border(
                                      top: BorderSide(
                                        color: Colors.grey[200]!,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 8,
                                    ),
                                    title: Text(
                                      medication.medicationName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Dosage: ${medication.dosage}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.chevron_right,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                    onTap: () {
                                      AppNavigation.goToTeacherEditMedication(
                                          context, medication.id);
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
