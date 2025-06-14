import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:insta_image_viewer/insta_image_viewer.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:convert';
import '../../core/services/medication_adminitration_service.dart';
import '../../core/services/medication_service.dart';
import '../../models/medications/medication_model.dart';
import '../../widgets/custom_app_bar.dart';
import '../../core/providers/user_provider.dart';
import '../../core/theme/app_theme.dart';

class TeacherUpdateMedicationsScreen extends StatefulWidget {
  const TeacherUpdateMedicationsScreen({super.key, required this.medicationId});
  final String medicationId;

  @override
  State<TeacherUpdateMedicationsScreen> createState() =>
      _TeacherUpdateMedicationsScreenState();
}

class _TeacherUpdateMedicationsScreenState
    extends State<TeacherUpdateMedicationsScreen> {
  final MedicationService _medicationService = MedicationService();
  final MedicationAdministrationService _medicationAdministrationService = MedicationAdministrationService();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  File? _selectedImage;
  bool _isLoading = false;
  String? _errorMessage;
  Medication? _medication;
  MedicationStatus _selectedStatus = MedicationStatus.active;
  String? _currentUserId;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadMedication();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      _currentUserId = userProvider.currentUserId;
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadMedication() async {
    try {
      final medication =
          await _medicationService.getMedication(widget.medicationId);
      if (medication != null) {
        setState(() {
          _medication = medication;
          _selectedStatus = medication.status;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading medication: $e';
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<String?> _encodeImage() async {
    if (_selectedImage == null) return null;

    try {
      // Read the image file as bytes
      final bytes = await _selectedImage!.readAsBytes();

      return base64Encode(bytes);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error encoding image: $e';
      });
      return null;
    }
  }

  Future<void> _createMedicationAdministration() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate that a photo has been taken
    if (_selectedImage == null) {
      setState(() {
        _errorMessage =
            'Please take a photo as proof of medication administration';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? photoUrl;
      if (_selectedImage != null) {
        photoUrl = await _encodeImage();
        if (photoUrl == null) {
          throw Exception('Failed to encode photo. Please try again.');
        }
      }

      await _medicationAdministrationService.createMedicationAdministration(
        medicationId: widget.medicationId,
        administeredByUserId: _currentUserId!,
        notes: _notesController.text,
        proofOfPhotoUrl: photoUrl!,
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

  @override
  Widget build(BuildContext context) {
    if (_medication == null) {
      return const Scaffold(
        appBar: CustomAppBar(
          title: 'Update Medication',
          showBackButton: true,
          userRole: 'teacher',
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Update Medication',
        showBackButton: true,
        userRole: 'teacher',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: InstaImageViewer(
                      child: Image.memory(
                        base64Decode(_medication!.photoUrl),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Medication Details
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Medication Details',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Text('Name: ${_medication!.medicationName}'),
                      Text('Dosage: ${_medication!.dosage}'),
                      Text('Frequency: ${_medication!.frequency}'),
                      Text(
                          'Current Status: ${_medication!.status.toString().split('.').last}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Status Update
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Update Status',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<MedicationStatus>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          // labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: MedicationStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status.toString().split('.').last),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedStatus = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notes',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Add notes (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Photo Upload
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Proof Photo',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      if (_selectedImage != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImage!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.camera_alt),
                        label: Text(_selectedImage == null
                            ? 'Take Photo'
                            : 'Retake Photo'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Error Message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              // Record Medication Administration Button
              ElevatedButton(
                onPressed: _isLoading ? null : _createMedicationAdministration,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Record Medication Administration'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
