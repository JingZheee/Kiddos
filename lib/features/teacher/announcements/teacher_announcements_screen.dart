import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/announcement_service.dart';
import '../../../core/providers/user_provider.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../models/announcement/announcement_model.dart';

class TeacherAnnouncementsScreen extends StatefulWidget {
  const TeacherAnnouncementsScreen({super.key});

  @override
  State<TeacherAnnouncementsScreen> createState() => _TeacherAnnouncementsScreenState();
}

class _TeacherAnnouncementsScreenState extends State<TeacherAnnouncementsScreen>
    with SingleTickerProviderStateMixin {
  final AnnouncementService _announcementService = AnnouncementService();
  late TabController _tabController;
  
  String _searchQuery = '';
  AnnouncementStatus? _statusFilter;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final teacherId = userProvider.userModel?.id ?? '';
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Announcements',
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToCreateAnnouncement(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.list, size: 16)),
            Tab(text: 'Published', icon: Icon(Icons.published_with_changes, size: 16)),
            Tab(text: 'Drafts', icon: Icon(Icons.drafts, size: 16)),
            Tab(text: 'Stats', icon: Icon(Icons.analytics, size: 16)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAnnouncementsList(teacherId, null),
          _buildAnnouncementsList(teacherId, AnnouncementStatus.published),
          _buildAnnouncementsList(teacherId, AnnouncementStatus.draft),
          _buildStatsTab(teacherId),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateAnnouncement(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAnnouncementsList(String teacherId, AnnouncementStatus? statusFilter) {
    return StreamBuilder<List<Announcement>>(
      stream: _announcementService.getTeacherAnnouncements(teacherId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading announcements',
                  style: TextStyle(fontSize: 18, color: AppTheme.textSecondaryColor),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(fontSize: 14, color: Colors.red[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        List<Announcement> announcements = snapshot.data ?? [];
        
        // Apply filters
        if (statusFilter != null) {
          announcements = announcements.where((a) => a.status == statusFilter).toList();
        }
        
        if (_searchQuery.isNotEmpty) {
          announcements = announcements.where((a) =>
              a.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              a.content.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();
        }

        if (announcements.isEmpty) {
          return _buildEmptyState(statusFilter);
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {}); // Trigger rebuild to refresh stream
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(UIConstants.spacing16),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              return _buildAnnouncementCard(announcements[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement) {
    return Card(
      margin: const EdgeInsets.only(bottom: UIConstants.spacing12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _viewAnnouncementDetails(announcement),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(UIConstants.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and priority
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(announcement.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          announcement.status.emoji,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          announcement.statusDisplayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(announcement.priority),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          announcement.priority.emoji,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          announcement.priorityDisplayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (action) => _handleAnnouncementAction(action, announcement),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Row(
                        children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('Edit')],
                      )),
                      if (announcement.isDraft)
                        const PopupMenuItem(value: 'publish', child: Row(
                          children: [Icon(Icons.publish, size: 16), SizedBox(width: 8), Text('Publish')],
                        )),
                      if (announcement.isPublished)
                        const PopupMenuItem(value: 'archive', child: Row(
                          children: [Icon(Icons.archive, size: 16), SizedBox(width: 8), Text('Archive')],
                        )),
                      const PopupMenuItem(value: 'duplicate', child: Row(
                        children: [Icon(Icons.copy, size: 16), SizedBox(width: 8), Text('Duplicate')],
                      )),
                      const PopupMenuItem(value: 'delete', child: Row(
                        children: [Icon(Icons.delete, size: 16, color: Colors.red), SizedBox(width: 8), Text('Delete')],
                      )),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: UIConstants.spacing12),
              
              // Title
              Text(
                announcement.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: UIConstants.spacing8),
              
              // Content preview
              Text(
                announcement.content,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: UIConstants.spacing12),
              
              // Footer with metadata
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: AppTheme.textLightColor),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(announcement.timestamps.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLightColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.people, size: 14, color: AppTheme.textLightColor),
                  const SizedBox(width: 4),
                  Text(
                    '${announcement.totalRecipients} recipients',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLightColor,
                    ),
                  ),
                  if (announcement.isPublished && announcement.totalRecipients > 0) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.visibility, size: 14, color: AppTheme.textLightColor),
                    const SizedBox(width: 4),
                    Text(
                      '${announcement.readPercentage.toInt()}% read',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textLightColor,
                      ),
                    ),
                  ],
                ],
              ),
              
              // Notification channels
              if (announcement.requiresWhatsApp) ...[
                const SizedBox(height: UIConstants.spacing8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            announcement.notificationChannel.emoji,
                            style: const TextStyle(fontSize: 10),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            announcement.channelDisplayName,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AnnouncementStatus? statusFilter) {
    String title;
    String subtitle;
    IconData icon;
    
    switch (statusFilter) {
      case AnnouncementStatus.published:
        title = 'No Published Announcements';
        subtitle = 'Your published announcements will appear here';
        icon = Icons.published_with_changes;
        break;
      case AnnouncementStatus.draft:
        title = 'No Draft Announcements';
        subtitle = 'Create draft announcements to review before publishing';
        icon = Icons.drafts;
        break;
      default:
        title = 'No Announcements Yet';
        subtitle = 'Create your first announcement to communicate with parents';
        icon = Icons.campaign;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppTheme.textLightColor),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textLightColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreateAnnouncement(),
            icon: const Icon(Icons.add),
            label: const Text('Create Announcement'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: UIConstants.spacing24,
                vertical: UIConstants.spacing12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab(String teacherId) {
    final userProvider = Provider.of<UserProvider>(context);
    final kindergartenId = userProvider.userModel?.kindergartenId ?? '';
    
    return FutureBuilder<Map<String, dynamic>>(
      future: _announcementService.getAnnouncementStats(teacherId, kindergartenId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data ?? {};
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(UIConstants.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Announcement Statistics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: UIConstants.spacing16),
              
              // Overview cards
              Row(
                children: [
                  Expanded(child: _buildStatCard(
                    'Total Announcements',
                    '${stats['totalAnnouncements'] ?? 0}',
                    Icons.campaign,
                    AppTheme.primaryColor,
                  )),
                  const SizedBox(width: UIConstants.spacing12),
                  Expanded(child: _buildStatCard(
                    'Published',
                    '${stats['publishedCount'] ?? 0}',
                    Icons.published_with_changes,
                    Colors.green,
                  )),
                ],
              ),
              const SizedBox(height: UIConstants.spacing12),
              
              Row(
                children: [
                  Expanded(child: _buildStatCard(
                    'Drafts',
                    '${stats['draftCount'] ?? 0}',
                    Icons.drafts,
                    Colors.orange,
                  )),
                  const SizedBox(width: UIConstants.spacing12),
                  Expanded(child: _buildStatCard(
                    'Read Rate',
                    '${(stats['readRate'] ?? 0.0).toInt()}%',
                    Icons.visibility,
                    Colors.blue,
                  )),
                ],
              ),
              const SizedBox(height: UIConstants.spacing24),
              
              // Detailed stats
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(UIConstants.spacing16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Engagement Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: UIConstants.spacing12),
                      
                      _buildStatRow('Total Reads', '${stats['totalReads'] ?? 0}'),
                      _buildStatRow('Total Recipients', '${stats['totalRecipients'] ?? 0}'),
                      
                      const SizedBox(height: UIConstants.spacing16),
                      
                      // Read rate progress bar
                      const Text(
                        'Overall Read Rate',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: UIConstants.spacing8),
                      
                      LinearProgressIndicator(
                        value: (stats['readRate'] ?? 0.0) / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          (stats['readRate'] ?? 0.0) > 70 ? Colors.green : 
                          (stats['readRate'] ?? 0.0) > 40 ? Colors.orange : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(AnnouncementStatus status) {
    switch (status) {
      case AnnouncementStatus.draft:
        return Colors.grey;
      case AnnouncementStatus.published:
        return Colors.green;
      case AnnouncementStatus.archived:
        return Colors.orange;
    }
  }

  Color _getPriorityColor(AnnouncementPriority priority) {
    switch (priority) {
      case AnnouncementPriority.low:
        return Colors.blue;
      case AnnouncementPriority.normal:
        return AppTheme.primaryColor;
      case AnnouncementPriority.high:
        return Colors.orange;
      case AnnouncementPriority.urgent:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Announcements'),
        content: TextField(
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
            Navigator.pop(context);
          },
          decoration: const InputDecoration(
            hintText: 'Enter search term...',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Announcements'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All'),
              leading: Radio<AnnouncementStatus?>(
                value: null,
                groupValue: _statusFilter,
                onChanged: (value) {
                  setState(() {
                    _statusFilter = value;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ...AnnouncementStatus.values.map((status) => ListTile(
              title: Text(status.name.toUpperCase()),
              leading: Radio<AnnouncementStatus?>(
                value: status,
                groupValue: _statusFilter,
                onChanged: (value) {
                  setState(() {
                    _statusFilter = value;
                  });
                  Navigator.pop(context);
                },
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _handleAnnouncementAction(String action, Announcement announcement) async {
    switch (action) {
      case 'edit':
        // Navigate to edit announcement
        context.push('/teacher/dashboard/announcements/edit/${announcement.id}');
        break;
      case 'publish':
        await _publishAnnouncement(announcement);
        break;
      case 'archive':
        await _archiveAnnouncement(announcement);
        break;
      case 'duplicate':
        await _duplicateAnnouncement(announcement);
        break;
      case 'delete':
        await _deleteAnnouncement(announcement);
        break;
    }
  }

  Future<void> _publishAnnouncement(Announcement announcement) async {
    try {
      await _announcementService.publishAnnouncement(announcement.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement published successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to publish announcement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _archiveAnnouncement(Announcement announcement) async {
    try {
      await _announcementService.archiveAnnouncement(announcement.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement archived successfully!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to archive announcement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _duplicateAnnouncement(Announcement announcement) async {
    // Navigate to create with pre-filled data
    context.push('/teacher/dashboard/announcements/duplicate/${announcement.id}');
  }

  Future<void> _deleteAnnouncement(Announcement announcement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: Text('Are you sure you want to delete "${announcement.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _announcementService.deleteAnnouncement(announcement.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Announcement deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete announcement: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _viewAnnouncementDetails(Announcement announcement) {
    context.push('/teacher/dashboard/announcements/detail/${announcement.id}');
  }

  void _navigateToCreateAnnouncement() {
    context.push('/teacher/dashboard/announcements/create');
  }
}
