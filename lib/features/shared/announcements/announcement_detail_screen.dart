import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/announcement_service.dart';
import '../../../core/providers/user_provider.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../models/announcement/announcement_model.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final String announcementId;

  const AnnouncementDetailScreen({
    super.key,
    required this.announcementId,
  });

  @override
  State<AnnouncementDetailScreen> createState() => _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  final AnnouncementService _announcementService = AnnouncementService();
  Announcement? _announcement;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isTeacher = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _loadAnnouncement();
  }

  void _checkUserRole() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _isTeacher = userProvider.userModel?.isTeacher ?? false;
  }

  Future<void> _loadAnnouncement() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final announcement = await _announcementService.getAnnouncementById(widget.announcementId);
      
      setState(() {
        _announcement = announcement;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading announcement: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Announcement Details',
        actions: _isTeacher && _announcement != null ? [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'duplicate',
                child: Row(
                  children: [
                    Icon(Icons.copy),
                    SizedBox(width: 8),
                    Text('Duplicate'),
                  ],
                ),
              ),
              if (_announcement?.status == AnnouncementStatus.published)
                const PopupMenuItem(
                  value: 'archive',
                  child: Row(
                    children: [
                      Icon(Icons.archive),
                      SizedBox(width: 8),
                      Text('Archive'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ] : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: UIConstants.spacing16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: UIConstants.spacing16),
            ElevatedButton(
              onPressed: _loadAnnouncement,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_announcement == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.announcement,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: UIConstants.spacing16),
            Text(
              'Announcement Not Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(UIConstants.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: UIConstants.spacing24),
          _buildContent(),
          const SizedBox(height: UIConstants.spacing24),
          _buildMetadata(),
          if (_isTeacher) ...[
            const SizedBox(height: UIConstants.spacing24),
            _buildTeacherStats(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(UIConstants.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildPriorityChip(_announcement!.priority),
              const Spacer(),
              _buildStatusChip(_announcement!.status),
            ],
          ),
          const SizedBox(height: UIConstants.spacing12),
          Text(
            _announcement!.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: UIConstants.spacing8),
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                'By ${_announcement!.teacherName}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.access_time,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                _formatDate(_announcement!.publishedDateTime ?? _announcement!.timestamps.createdAt),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(UIConstants.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Content',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: UIConstants.spacing12),
          Text(
            _announcement!.content,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadata() {
    return Container(
      padding: const EdgeInsets.all(UIConstants.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: UIConstants.spacing12),
          _buildMetadataRow(
            'Notification Channel',
            _getChannelDisplayName(_announcement!.notificationChannel),
          ),
          if (_announcement!.sendWhatsAppNotification)
            _buildMetadataRow(
              'WhatsApp',
              'Enabled',
              icon: Icons.chat,
              iconColor: Colors.green,
            ),
          _buildMetadataRow(
            'Target Classes',
            '${_announcement!.targetClassIds.length} class${_announcement!.targetClassIds.length != 1 ? 'es' : ''}',
          ),
          if (_announcement!.scheduledDateTime != null)
            _buildMetadataRow(
              'Scheduled for',
              _formatDate(_announcement!.scheduledDateTime!),
            ),
        ],
      ),
    );
  }

  Widget _buildTeacherStats() {
    return Container(
      padding: const EdgeInsets.all(UIConstants.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Statistics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: UIConstants.spacing12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Recipients',
                  _announcement!.totalRecipients.toString(),
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: UIConstants.spacing12),
              Expanded(
                child: _buildStatCard(
                  'Read',
                  _announcement!.readCount.toString(),
                  Icons.mark_email_read,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(UIConstants.spacing12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value, {IconData? icon, Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: UIConstants.spacing8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          if (icon != null) ...[
            Icon(icon, size: 16, color: iconColor ?? Colors.grey[600]),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(AnnouncementPriority priority) {
    Color color;
    String label;
    
    switch (priority) {
      case AnnouncementPriority.low:
        color = Colors.grey;
        label = 'Low Priority';
        break;
      case AnnouncementPriority.normal:
        color = Colors.blue;
        label = 'Normal Priority';
        break;
      case AnnouncementPriority.high:
        color = Colors.orange;
        label = 'High Priority';
        break;
      case AnnouncementPriority.urgent:
        color = Colors.red;
        label = 'Urgent';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusChip(AnnouncementStatus status) {
    Color color;
    String label;
    IconData icon;
    
    switch (status) {
      case AnnouncementStatus.draft:
        color = Colors.grey;
        label = 'Draft';
        icon = Icons.edit;
        break;
      case AnnouncementStatus.published:
        color = Colors.green;
        label = 'Published';
        icon = Icons.check_circle;
        break;
      case AnnouncementStatus.archived:
        color = Colors.orange;
        label = 'Archived';
        icon = Icons.archive;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
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

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        context.push('/teacher/dashboard/announcements/edit/${_announcement!.id}');
        break;
      case 'duplicate':
        context.push('/teacher/dashboard/announcements/duplicate/${_announcement!.id}');
        break;
      case 'archive':
        _archiveAnnouncement();
        break;
      case 'delete':
        _confirmDelete();
        break;
    }
  }

  void _archiveAnnouncement() async {
    try {
      await _announcementService.archiveAnnouncement(_announcement!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement archived successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error archiving announcement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: Text(
          'Are you sure you want to delete "${_announcement!.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAnnouncement();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteAnnouncement() async {
    try {
      await _announcementService.deleteAnnouncement(_announcement!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting announcement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
