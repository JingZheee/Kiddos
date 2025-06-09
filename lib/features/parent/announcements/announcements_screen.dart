import 'package:flutter/material.dart';
import 'package:nursery_app/core/constants/ui_constants.dart';
import 'package:nursery_app/core/services/announcement/announcement_service.dart';
import 'package:nursery_app/models/announcement/announcement.dart';
import 'package:nursery_app/features/parent/announcements/announcement_detail_screen.dart';
import 'package:go_router/go_router.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({
    super.key,
  });

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AnnouncementService _announcementService = AnnouncementService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Current'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Current Announcements Tab
          StreamBuilder<List<Announcement>>(
            stream: _announcementService.getParentAnnouncements(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No current announcements.'));
              }

              final announcements = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(UIConstants.spacing16),
                itemCount: announcements.length,
                itemBuilder: (context, index) {
                  final announcement = announcements[index];
                  return AnnouncementCard(announcement: announcement);
                },
              );
            },
          ),
          // Past Announcements Tab
          StreamBuilder<List<Announcement>>(
            stream: _announcementService.getAnnouncements().map(
                (announcements) =>
                    announcements.where((a) => a.isArchived).toList()),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No past announcements.'));
              }

              final announcements = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(UIConstants.spacing16),
                itemCount: announcements.length,
                itemBuilder: (context, index) {
                  final announcement = announcements[index];
                  return AnnouncementCard(announcement: announcement);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class AnnouncementCard extends StatelessWidget {
  final Announcement announcement;

  const AnnouncementCard({
    super.key,
    required this.announcement,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: UIConstants.spacing16),
      child: InkWell(
        onTap: () {
          context.pushNamed(
            'parent-announcement-detail',
            extra: announcement,
          );
        },
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
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  '${announcement.publishDate.toDate().day}/${announcement.publishDate.toDate().month}/${announcement.publishDate.toDate().year}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
