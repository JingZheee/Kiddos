import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:insta_image_viewer/insta_image_viewer.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:convert';
import '../../../core/services/medication_adminitration_service.dart';
import '../../../core/services/medication_service.dart';
import '../../../models/medications/medication_model.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/theme/app_theme.dart';

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
  final MedicationAdministrationService _medicationAdministrationService =
      MedicationAdministrationService();
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
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Original Medication Image
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
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
                ),
                const SizedBox(height: 24),

                // Medication Details
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _medication!.medicationName,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                        ),
                        const SizedBox(height: 20),
                        _buildDetailRow('Dosage', _medication!.dosage),
                        const SizedBox(height: 12),
                        _buildDetailRow('Frequency', _medication!.frequency),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          'Status',
                          _medication!.status.toString().split('.').last,
                          isStatus: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Status Update
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Update Status',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<MedicationStatus>(
                          value: _selectedStatus,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: AppTheme.primaryColor),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          items: MedicationStatus.values.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(
                                status.toString().split('.').last,
                                style: const TextStyle(color: Colors.black87),
                              ),
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
                const SizedBox(height: 24),

                // Notes
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notes',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Add any observations or notes...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: AppTheme.primaryColor),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Photo Upload
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Proof Photo',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        if (_selectedImage != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: InstaImageViewer(
                              backgroundColor: Colors.black,
                              child: Image.file(
                                _selectedImage!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
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
                            backgroundColor: Colors.grey[50],
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Error Message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                const SizedBox(height: 24),

                // Record Medication Administration Button
                ElevatedButton(
                  onPressed:
                      _isLoading ? null : _createMedicationAdministration,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Record Medication Administration',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isStatus = false}) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isStatus ? AppTheme.primaryColor : Colors.black87,
            fontWeight: isStatus ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
