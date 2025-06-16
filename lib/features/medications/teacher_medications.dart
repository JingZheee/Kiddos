import 'package:flutter/material.dart';
import '../../core/routing/app_navigation.dart';
import '../../core/services/medication_service.dart';
import '../../models/medications/medication_model.dart';
import '../../widgets/custom_app_bar.dart';

class TeacherMedicationScreen extends StatefulWidget {
  const TeacherMedicationScreen({super.key});

  @override
  State<TeacherMedicationScreen> createState() =>
      _TeacherMedicationScreenState();
}

class _TeacherMedicationScreenState extends State<TeacherMedicationScreen> {
  final MedicationService _medicationService = MedicationService();

  // Group medications by childId
  Map<String, List<Medication>> _groupMedicationsByChild(
      List<Medication> medications) {
    final Map<String, List<Medication>> groupedMedications = {};

    for (var medication in medications) {
      if (!groupedMedications.containsKey(medication.childId)) {
        groupedMedications[medication.childId] = [];
      }
      groupedMedications[medication.childId]!.add(medication);
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
      body: StreamBuilder<List<Medication>>(
        stream: _medicationService.getAllMedications(),
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
          final groupedMedications = _groupMedicationsByChild(medications);

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupedMedications.length,
            itemBuilder: (context, index) {
              final childId = groupedMedications.keys.elementAt(index);
              final childMedications = groupedMedications[childId]!;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  title: Text(
                    childId,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    '${childMedications.length} medication${childMedications.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  children: childMedications.map((medication) {
                    return ListTile(
                      title: Text(
                        medication.medicationName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        AppNavigation.goToTeacherEditMedication(
                            context, medication.id);
                      },
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
