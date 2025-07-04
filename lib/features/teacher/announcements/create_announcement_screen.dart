import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/announcement_service.dart';
import '../../../core/services/classroom_service.dart';
import '../../../core/providers/user_provider.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../models/announcement/announcement_model.dart';
import '../../../models/classroom/classroom.dart';
import '../../../models/timestamp/timestamp_model.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  final String? announcementId;
  final String? duplicateId;

  const CreateAnnouncementScreen({
    super.key,
    this.announcementId,
    this.duplicateId,
  });

  @override
  State<CreateAnnouncementScreen> createState() => _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  final AnnouncementService _announcementService = AnnouncementService();
  final ClassroomService _classroomService = ClassroomService();
  
  bool _isLoading = false;
  bool _isEditing = false;
  
  // Form fields
  AnnouncementPriority _selectedPriority = AnnouncementPriority.normal;
  NotificationChannel _selectedChannel = NotificationChannel.app;
  bool _sendWhatsAppNotification = false;
  List<String> _selectedClassIds = [];
  DateTime? _scheduledDateTime;
  
  // Data
  List<Classroom> _availableClassrooms = [];
  Announcement? _originalAnnouncement;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.announcementId != null;
    _loadClassrooms();
    
    if (_isEditing) {
      _loadAnnouncementForEditing();
    } else if (widget.duplicateId != null) {
      _loadAnnouncementForDuplicating();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadClassrooms() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final kindergartenId = userProvider.userModel?.kindergartenId;
      
      if (kindergartenId != null) {
        final classrooms = await _classroomService.getClassroomsByKindergarten(kindergartenId).first;
        setState(() {
          _availableClassrooms = classrooms;
        });
      }
    } catch (e) {
      print('Error loading classrooms: $e');
    }
  }

  Future<void> _loadAnnouncementForEditing() async {
    if (widget.announcementId == null) return;
    
    try {
      setState(() => _isLoading = true);
      
      final announcement = await _announcementService.getAnnouncementById(widget.announcementId!);
      if (announcement != null) {
        setState(() {
          _originalAnnouncement = announcement;
          _titleController.text = announcement.title;
          _contentController.text = announcement.content;
          _selectedPriority = announcement.priority;
          _selectedChannel = announcement.notificationChannel;
          _sendWhatsAppNotification = announcement.sendWhatsAppNotification;
          _selectedClassIds = List.from(announcement.targetClassIds);
          _scheduledDateTime = announcement.scheduledDateTime;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading announcement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAnnouncementForDuplicating() async {
    if (widget.duplicateId == null) return;
    
    try {
      setState(() => _isLoading = true);
      
      final announcement = await _announcementService.getAnnouncementById(widget.duplicateId!);
      if (announcement != null) {
        setState(() {
          _titleController.text = 'Copy of ${announcement.title}';
          _contentController.text = announcement.content;
          _selectedPriority = announcement.priority;
          _selectedChannel = announcement.notificationChannel;
          _sendWhatsAppNotification = announcement.sendWhatsAppNotification;
          _selectedClassIds = List.from(announcement.targetClassIds);
          // Don't copy scheduled date for duplicates
          _scheduledDateTime = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading announcement for duplication: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _isEditing ? 'Edit Announcement' : 'Create Announcement',
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => _saveAnnouncement(isDraft: true),
            child: const Text(
              'Save Draft',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(UIConstants.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title field
            _buildSectionTitle('Announcement Details'),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'Enter announcement title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Title is required';
                }
                return null;
              },
              maxLength: 100,
            ),
            const SizedBox(height: UIConstants.spacing16),

            // Content field
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Content *',
                hintText: 'Enter announcement content',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Content is required';
                }
                return null;
              },
              maxLength: 1000,
            ),
            const SizedBox(height: UIConstants.spacing24),

            // Priority selection
            _buildSectionTitle('Priority Level'),
            _buildPrioritySelection(),
            const SizedBox(height: UIConstants.spacing24),

            // Target audience
            _buildSectionTitle('Target Audience'),
            _buildTargetAudienceSelection(),
            const SizedBox(height: UIConstants.spacing24),

            // Notification settings
            _buildSectionTitle('Notification Settings'),
            _buildNotificationSettings(),
            const SizedBox(height: UIConstants.spacing24),

            // Scheduling
            _buildSectionTitle('Scheduling'),
            _buildSchedulingSettings(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: UIConstants.spacing12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimaryColor,
        ),
      ),
    );
  }

  Widget _buildPrioritySelection() {
    return Column(
      children: AnnouncementPriority.values.map((priority) {
        return RadioListTile<AnnouncementPriority>(
          value: priority,
          groupValue: _selectedPriority,
          onChanged: (value) {
            setState(() {
              _selectedPriority = value!;
            });
          },
          title: Text(_getPriorityDisplayName(priority)),
          subtitle: Text(_getPriorityDescription(priority)),
          dense: true,
        );
      }).toList(),
    );
  }

  Widget _buildTargetAudienceSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Classes',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: UIConstants.spacing8),
        
        if (_availableClassrooms.isEmpty)
          const Text(
            'No classes available',
            style: TextStyle(color: AppTheme.textLightColor),
          )
        else ...[
          CheckboxListTile(
            value: _selectedClassIds.length == _availableClassrooms.length,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedClassIds = _availableClassrooms.map((c) => c.id).toList();
                } else {
                  _selectedClassIds.clear();
                }
              });
            },
            title: const Text('All Classes'),
            subtitle: Text('${_availableClassrooms.length} classes'),
            dense: true,
          ),
          const Divider(),
          ..._availableClassrooms.map((classroom) {
            return CheckboxListTile(
              value: _selectedClassIds.contains(classroom.id),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedClassIds.add(classroom.id);
                  } else {
                    _selectedClassIds.remove(classroom.id);
                  }
                });
              },
              title: Text(classroom.name),
              subtitle: Text('ID: ${classroom.id}'),
              dense: true,
            );
          }).toList(),
        ],
        
        if (_selectedClassIds.isNotEmpty) ...[
          const SizedBox(height: UIConstants.spacing8),
          Container(
            padding: const EdgeInsets.all(UIConstants.spacing12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: UIConstants.spacing8),
                Text(
                  '${_selectedClassIds.length} class${_selectedClassIds.length != 1 ? 'es' : ''} selected',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNotificationSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notification Channel',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: UIConstants.spacing8),
        
        ...NotificationChannel.values.map((channel) {
          return RadioListTile<NotificationChannel>(
            value: channel,
            groupValue: _selectedChannel,
            onChanged: (value) {
              setState(() {
                _selectedChannel = value!;
                if (value == NotificationChannel.whatsapp) {
                  _sendWhatsAppNotification = true;
                } else if (value == NotificationChannel.app) {
                  _sendWhatsAppNotification = false;
                }
              });
            },
            title: Row(
              children: [
                Icon(
                  channel == NotificationChannel.app 
                    ? Icons.notifications
                    : channel == NotificationChannel.whatsapp
                      ? Icons.chat
                      : Icons.all_inclusive,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(_getChannelDisplayName(channel)),
              ],
            ),
            dense: true,
          );
        }).toList(),
        
        const SizedBox(height: UIConstants.spacing16),
        
        SwitchListTile(
          value: _sendWhatsAppNotification,
          onChanged: (value) {
            setState(() {
              _sendWhatsAppNotification = value;
              if (value) {
                if (_selectedChannel == NotificationChannel.app) {
                  _selectedChannel = NotificationChannel.both;
                }
              }
            });
          },
          title: const Row(
            children: [
              Icon(Icons.chat, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text('Enable WhatsApp Notifications'),
            ],
          ),
          subtitle: const Text('Send automated WhatsApp messages for important updates'),
          dense: true,
        ),
        
        if (_sendWhatsAppNotification) ...[
          const SizedBox(height: UIConstants.spacing8),
          Container(
            padding: const EdgeInsets.all(UIConstants.spacing12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
              border: Border.all(
                color: Colors.green.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.green, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'WhatsApp Message Preview',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '🎓 ${_titleController.text.isEmpty ? '[Title]' : _titleController.text}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(_contentController.text.isEmpty ? '[Content]' : _contentController.text),
                const SizedBox(height: 8),
                const Text(
                  '- Kindergarten Management',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSchedulingSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          value: _scheduledDateTime != null,
          onChanged: (value) {
            setState(() {
              if (value) {
                _scheduledDateTime = DateTime.now().add(const Duration(hours: 1));
              } else {
                _scheduledDateTime = null;
              }
            });
          },
          title: const Text('Schedule for later'),
          subtitle: _scheduledDateTime != null
              ? Text('Scheduled for: ${_formatScheduledDate(_scheduledDateTime!)}')
              : const Text('Send immediately'),
          dense: true,
        ),
        
        if (_scheduledDateTime != null) ...[
          const SizedBox(height: UIConstants.spacing8),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Scheduled Time'),
            subtitle: Text(_formatScheduledDate(_scheduledDateTime!)),
            trailing: const Icon(Icons.edit),
            onTap: _selectScheduledDateTime,
            dense: true,
          ),
        ],
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(UIConstants.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => _saveAnnouncement(isDraft: true),
              child: const Text('Save Draft'),
            ),
          ),
          const SizedBox(width: UIConstants.spacing12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _saveAnnouncement(isDraft: false),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(_isEditing ? 'Update' : 'Publish'),
            ),
          ),
        ],
      ),
    );
  }

  String _getPriorityDisplayName(AnnouncementPriority priority) {
    switch (priority) {
      case AnnouncementPriority.low:
        return 'Low Priority';
      case AnnouncementPriority.normal:
        return 'Normal Priority';
      case AnnouncementPriority.high:
        return 'High Priority';
      case AnnouncementPriority.urgent:
        return 'Urgent';
    }
  }

  String _getPriorityDescription(AnnouncementPriority priority) {
    switch (priority) {
      case AnnouncementPriority.low:
        return 'General information, no urgency';
      case AnnouncementPriority.normal:
        return 'Standard announcement';
      case AnnouncementPriority.high:
        return 'Important information, requires attention';
      case AnnouncementPriority.urgent:
        return 'Urgent announcement, immediate attention required';
    }
  }

  String _formatScheduledDate(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy \'at\' h:mm a').format(dateTime);
  }

  Future<void> _selectScheduledDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledDateTime ?? DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _scheduledDateTime ?? DateTime.now().add(const Duration(hours: 1)),
        ),
      );

      if (time != null) {
        setState(() {
          _scheduledDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveAnnouncement({required bool isDraft}) async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedClassIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one class'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.userModel!;
      
      final announcement = Announcement(
        id: _isEditing ? _originalAnnouncement!.id : '',
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        teacherId: user.id,
        teacherName: user.userName,
        kindergartenId: user.kindergartenId!,
        priority: _selectedPriority,
        status: isDraft ? AnnouncementStatus.draft : AnnouncementStatus.published,
        notificationChannel: _selectedChannel,
        sendWhatsAppNotification: _sendWhatsAppNotification,
        targetClassIds: _selectedClassIds,
        targetParentIds: const [], // Will be calculated in service
        scheduledDateTime: _scheduledDateTime,
        publishedDateTime: isDraft ? null : DateTime.now(),
        totalRecipients: 0, // Will be calculated in service
        readCount: 0,
        attachmentUrls: const [],
        timestamps: _isEditing 
            ? _originalAnnouncement!.timestamps.copyWith(updatedAt: DateTime.now())
            : Timestamps.now(),
      );

      if (_isEditing) {
        await _announcementService.updateAnnouncement(announcement);
        if (!isDraft) {
          await _announcementService.publishAnnouncement(announcement.id);
        }
      } else {
        final announcementId = await _announcementService.createAnnouncement(announcement);
        if (!isDraft) {
          await _announcementService.publishAnnouncement(announcementId);
        }
      }

      if (mounted) {
        String message;
        if (isDraft) {
          message = _isEditing ? 'Announcement updated as draft' : 'Announcement saved as draft';
        } else {
          message = _isEditing ? 'Announcement updated and published' : 'Announcement published successfully!';
          
          // Show notification simulation for published announcements
          _showNotificationSimulation();
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
        
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving announcement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showNotificationSimulation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Notifications Sent!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📱 Push notifications sent to all parents'),
            if (_sendWhatsAppNotification) ...[
              const SizedBox(height: 8),
              const Text('💬 WhatsApp messages sent:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎓 ${_titleController.text}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(_contentController.text),
                    const SizedBox(height: 8),
                    const Text(
                      '- Kindergarten Management',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }

  String _getChannelDisplayName(NotificationChannel channel) {
    switch (channel) {
      case NotificationChannel.app:
        return 'App Only';
      case NotificationChannel.whatsapp:
        return 'WhatsApp Only';
      case NotificationChannel.both:
        return 'App + WhatsApp';
    }
  }
}
