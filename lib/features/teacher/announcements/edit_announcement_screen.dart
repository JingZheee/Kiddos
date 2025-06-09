import 'package:flutter/material.dart';
import 'package:nursery_app/models/announcement/announcement.dart';
import 'package:nursery_app/core/constants/ui_constants.dart';
import 'package:nursery_app/core/services/announcement/announcement_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class EditAnnouncementScreen extends StatefulWidget {
  final Announcement announcement;

  const EditAnnouncementScreen({
    super.key,
    required this.announcement,
  });

  @override
  State<EditAnnouncementScreen> createState() => _EditAnnouncementScreenState();
}

class _EditAnnouncementScreenState extends State<EditAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final AnnouncementService _announcementService = AnnouncementService();

  late List<String> _selectedAudience;
  late bool _isGlobal;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.announcement.title);
    _contentController =
        TextEditingController(text: widget.announcement.content);
    _selectedAudience = List.from(widget.announcement.audience);
    _isGlobal = widget.announcement.isGlobal;
    _selectedDate = widget.announcement.publishDate.toDate();
    _selectedTime =
        TimeOfDay.fromDateTime(widget.announcement.publishDate.toDate());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _updateAnnouncement() async {
    if (_formKey.currentState!.validate()) {
      final updatedAnnouncement = widget.announcement.copyWith(
        title: _titleController.text,
        content: _contentController.text,
        publishDate: _selectedDate != null && _selectedTime != null
            ? Timestamp.fromDate(DateTime(
                _selectedDate!.year,
                _selectedDate!.month,
                _selectedDate!.day,
                _selectedTime!.hour,
                _selectedTime!.minute,
              ))
            : Timestamp.now(),
        audience: _selectedAudience.isEmpty ? ['all'] : _selectedAudience,
        isGlobal: _isGlobal,
        // imageUrls and documentUrls are not handled in this basic edit screen
      );

      try {
        await _announcementService.updateAnnouncement(updatedAnnouncement);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement updated successfully!')),
        );
        context.pop(); // Go back to the management screen
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update announcement: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Announcement'),
      ),
      body: Padding(
        padding: UIConstants.paddingMedium,
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: UIConstants.spacing16),
              TextFormField(
                controller: _contentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter content';
                  }
                  return null;
                },
              ),
              const SizedBox(height: UIConstants.spacing16),
              Text('Publication Date & Time:',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: UIConstants.spacing8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null && pickedDate != _selectedDate) {
                          setState(() {
                            _selectedDate = pickedDate;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_selectedDate == null
                          ? 'Select Date'
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                    ),
                  ),
                  const SizedBox(width: UIConstants.spacing8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime ?? TimeOfDay.now(),
                        );
                        if (pickedTime != null && pickedTime != _selectedTime) {
                          setState(() {
                            _selectedTime = pickedTime;
                          });
                        }
                      },
                      icon: const Icon(Icons.access_time),
                      label: Text(_selectedTime == null
                          ? 'Select Time'
                          : _selectedTime!.format(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: UIConstants.spacing16),
              Text('Target Audience:',
                  style: Theme.of(context).textTheme.titleSmall),
              Wrap(
                spacing: UIConstants.spacing8,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedAudience.contains('all'),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedAudience = ['all'];
                        } else {
                          _selectedAudience = [];
                        }
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('Parents'),
                    selected: _selectedAudience.contains('parents'),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedAudience.add('parents');
                          _selectedAudience.remove('all');
                        } else {
                          _selectedAudience.remove('parents');
                        }
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('Teachers'),
                    selected: _selectedAudience.contains('teachers'),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedAudience.add('teachers');
                          _selectedAudience.remove('all');
                        } else {
                          _selectedAudience.remove('teachers');
                        }
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: UIConstants.spacing16),
              Row(
                children: [
                  Checkbox(
                    value: _isGlobal,
                    onChanged: (bool? value) {
                      setState(() {
                        _isGlobal = value ?? false;
                      });
                    },
                  ),
                  const Text(
                      'Global Announcement (visible to all kindergartens)'),
                ],
              ),
              const SizedBox(height: UIConstants.spacing24),
              ElevatedButton(
                onPressed: _updateAnnouncement,
                style: ElevatedButton.styleFrom(
                  minimumSize:
                      const Size.fromHeight(UIConstants.buttonHeightMedium),
                ),
                child: const Text('Update Announcement'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
