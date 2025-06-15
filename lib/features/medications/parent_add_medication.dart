import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nursery_app/core/theme/app_theme.dart';
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
  bool _isSaving = false;
  String? _errorMessage;
  File? _imageFile;
  final ImagePicker _imagePicker = ImagePicker();
  @override
  void dispose() {
    _medicationNameController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  //pick image from camera or gallery
  Future<void> _pickImage() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final pickedImage = await _imagePicker.pickImage(source: source);
      if (pickedImage != null) {
        setState(() {
          _imageFile = File(pickedImage.path);
        });
      }
    }
  }

  //encode image to base64
  Future<String?> _encodeImageToBase64() async {
    if (_imageFile == null) return null;
    final bytes = await _imageFile!.readAsBytes();
    return base64Encode(bytes);
  }

  //submit form to create medication
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
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

        String? photoUrl;
          if (_imageFile == null) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Error'),
                content: const Text('Failed to encode photo. Please try again.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
            return;
          }
        if (_imageFile != null) {
          photoUrl = await _encodeImageToBase64();
        }

        await _medicationService.createMedication(
          childId: childId,
          medicationName: _medicationNameController.text,
          dosage: _dosageController.text,
          frequency: _frequencyController.text,
          instructions: _instructionsController.text,
          reportedByUserId: currentUserId,
          photoUrl: photoUrl!,
        );

        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Success'),
              content: const Text('Medication added successfully'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
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
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Stack(
                children: [
                  SingleChildScrollView(
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
                      if (_imageFile == null) ...[
                        InkWell(
                          onTap: _pickImage,
                          child: Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: AppTheme.primaryColor,
                                width: 3,
                                style: BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt_outlined,
                                  size: 32,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Upload or Take Photo',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (_imageFile != null) ...[
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickImage,
                          child: Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _imageFile!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
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
                  if (_isSaving)
                    Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
    );
  }
}
