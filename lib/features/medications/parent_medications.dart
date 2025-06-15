import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routing/app_navigation.dart';
import '../../widgets/custom_app_bar.dart';
import '../../core/services/medication_service.dart';
import '../../models/medications/medication_model.dart';
import '../../core/providers/user_provider.dart';

class ParentMedicationsScreen extends StatefulWidget {
  const ParentMedicationsScreen({super.key});

  @override
  State<ParentMedicationsScreen> createState() =>
      _ParentMedicationScreenState();
}

class _ParentMedicationScreenState extends State<ParentMedicationsScreen> {
  final MedicationService _medicationService = MedicationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Medications',
        showBackButton: true,
        userRole: 'parent',
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUserId = userProvider.currentUserId;

    if (currentUserId == null) {
      return const Center(
        child: Text('Please log in to view medications'),
      );
    }

    // TODO: Replace with actual child IDs from user's children
    final childIds = [
      'child1',
      'child2'
    ]; 

    
    return StreamBuilder<List<Medication>>(
      stream: _medicationService.getMedicationsForParent(childIds),
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

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  AppNavigation.goToParentAddMedication(context);
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Medication'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            if (medications.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'No medications added yet',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: medications.length,
                  itemBuilder: (context, index) {
                    final medication = medications[index];
                    return InkWell(
                      onTap: () {
                        AppNavigation.goToParentEditMedication(
                            context, medication.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ClipRRect(
                                  child: Image.memory(
                                    base64Decode(medication.photoUrl),
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              ListTile(
                                title: Text(
                                  medication.medicationName,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
