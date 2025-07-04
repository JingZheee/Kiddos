import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/announcement_service.dart';
import '../../../core/providers/user_provider.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../models/announcement/announcement_model.dart';

class ParentAnnouncementsScreen extends StatefulWidget {
  const ParentAnnouncementsScreen({super.key});

  @override
  State<ParentAnnouncementsScreen> createState() => _ParentAnnouncementsScreenState();
}

class _ParentAnnouncementsScreenState extends State<ParentAnnouncementsScreen> {
  final AnnouncementService _announcementService = AnnouncementService();
  List<Announcement> _announcements = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final kindergartenId = userProvider.userModel?.kindergartenId;

      if (kindergartenId != null) {
        // For demo purposes, get all published announcements for the kindergarten
        final announcements = await _announcementService.getPublishedAnnouncementsForKindergarten(kindergartenId).first;

        setState(() {
          _announcements = announcements;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading announcements: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Announcements',
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
              onPressed: _loadAnnouncements,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_announcements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: UIConstants.spacing16),
            Text(
              'No Announcements Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: UIConstants.spacing8),
            Text(
              'You\'ll see important updates from your child\'s teachers here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAnnouncements,
      child: ListView.builder(
        padding: const EdgeInsets.all(UIConstants.spacing16),
        itemCount: _announcements.length,
        itemBuilder: (context, index) {
          final announcement = _announcements[index];
          return _buildAnnouncementCard(announcement);
        },
      ),
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement) {
    return Card(
      margin: const EdgeInsets.only(bottom: UIConstants.spacing16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with priority and date
            Row(
              children: [
                _buildPriorityChip(announcement.priority),
                const Spacer(),
                Text(
                  _formatDate(announcement.publishedDateTime ?? announcement.timestamps.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: UIConstants.spacing12),

            // Title
            Text(
              announcement.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: UIConstants.spacing8),

            // Content
            Text(
              announcement.content,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: UIConstants.spacing12),

            // Footer with teacher name
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'From: ${announcement.teacherName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Spacer(),
                if (announcement.sendWhatsAppNotification)
                  Tooltip(
                    message: 'Also sent via WhatsApp',
                    child: Icon(
                      Icons.chat,
                      size: 16,
                      color: Colors.green[600],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChip(AnnouncementPriority priority) {
    Color color;
    String label;
    
    switch (priority) {
      case AnnouncementPriority.low:
        color = Colors.grey;
        label = 'Low';
        break;
      case AnnouncementPriority.normal:
        color = Colors.blue;
        label = 'Normal';
        break;
      case AnnouncementPriority.high:
        color = Colors.orange;
        label = 'High';
        break;
      case AnnouncementPriority.urgent:
        color = Colors.red;
        label = 'Urgent';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
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
}
