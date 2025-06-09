import 'package:flutter/material.dart';
import 'package:nursery_app/core/constants/ui_constants.dart';
import 'package:nursery_app/core/services/announcement/announcement_service.dart';
import 'package:nursery_app/models/announcement/announcement.dart';
import 'package:go_router/go_router.dart';

class AnnouncementManagementScreen extends StatefulWidget {
  const AnnouncementManagementScreen({
    super.key,
  });

  @override
  State<AnnouncementManagementScreen> createState() =>
      _AnnouncementManagementScreenState();
}

class _AnnouncementManagementScreenState
    extends State<AnnouncementManagementScreen> {
  final AnnouncementService _announcementService = AnnouncementService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.go('/teacher/dashboard/announcements/create');
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Announcement>>(
        stream: _announcementService.getAnnouncements(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No announcements published yet.'));
          }

          final announcements = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(UIConstants.spacing16),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final announcement = announcements[index];
              return AnnouncementManagementCard(
                announcement: announcement,
                announcementService: _announcementService,
              );
            },
          );
        },
      ),
    );
  }
}

class AnnouncementManagementCard extends StatelessWidget {
  final Announcement announcement;
  final AnnouncementService announcementService;

  const AnnouncementManagementCard({
    super.key,
    required this.announcement,
    required this.announcementService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: UIConstants.spacing16),
      child: Padding(
        padding: UIConstants.paddingMedium,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              announcement.title,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: UIConstants.spacing4),
            Text(
              announcement.content,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: UIConstants.spacing8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Published: ${announcement.publishDate.toDate().day}/${announcement.publishDate.toDate().month}/${announcement.publishDate.toDate().year}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        context.goNamed(
                          'teacher-edit-announcement',
                          extra: announcement,
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(announcement.isArchived
                          ? Icons.unarchive
                          : Icons.archive),
                      onPressed: () async {
                        await announcementService.archiveAnnouncement(
                          announcement.id,
                          !announcement.isArchived,
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              announcement.isArchived
                                  ? 'Announcement unarchived.'
                                  : 'Announcement archived.',
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        final bool? confirm = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) => AlertDialog(
                            title: const Text('Confirm Deletion'),
                            content: Text(
                                'Are you sure you want to delete "${announcement.title}"?'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          try {
                            await announcementService
                                .deleteAnnouncement(announcement.id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Announcement deleted successfully!')),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Failed to delete announcement: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
