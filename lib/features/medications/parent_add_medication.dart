import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../core/services/medication_service.dart';
import '../../core/providers/user_provider.dart';

class ParentAddMedicationScreen extends StatefulWidget {
  const ParentAddMedicationScreen({super.key});

  @override
  State<ParentAddMedicationScreen> createState() =>
      _ParentAddMedicationScreenState();
}

class _ParentAddMedicationScreenState extends State<ParentAddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _medicationNameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _medicationService = MedicationService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _medicationNameController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Add Medication',
        showBackButton: true,
        userRole: 'parent',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    TextFormField(
                      controller: _medicationNameController,
                      decoration: const InputDecoration(
                        labelText: 'Medication Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter medication name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dosageController,
                      decoration: const InputDecoration(
                        labelText: 'Dosage',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter dosage';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _frequencyController,
                      decoration: const InputDecoration(
                        labelText: 'Frequency',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter frequency';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _instructionsController,
                      decoration: const InputDecoration(
                        labelText: 'Instructions',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter instructions';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Add Medication'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final currentUserId = userProvider.currentUserId;

        if (currentUserId == null) {
          throw Exception('User not logged in');
        }

        // TODO: Replace with actual child ID selection
        const childId = 'child1'; // This should come from a child selector

        await _medicationService.createMedication(
          childId: childId,
          medicationName: _medicationNameController.text,
          dosage: _dosageController.text,
          frequency: _frequencyController.text,
          instructions: _instructionsController.text,
          reportedByUserId: currentUserId,
        );

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}
