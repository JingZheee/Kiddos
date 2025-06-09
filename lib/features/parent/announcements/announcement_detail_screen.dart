import 'package:flutter/material.dart';
import 'package:nursery_app/core/constants/ui_constants.dart';
import 'package:nursery_app/models/announcement/announcement.dart';

class AnnouncementDetailScreen extends StatelessWidget {
  final Announcement announcement;

  const AnnouncementDetailScreen({
    super.key,
    required this.announcement,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(announcement.title),
      ),
      body: SingleChildScrollView(
        padding: UIConstants.paddingMedium,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              announcement.title,
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: UIConstants.spacing8),
            Text(
              'Published: ${announcement.publishDate.toDate().day}/${announcement.publishDate.toDate().month}/${announcement.publishDate.toDate().year}',
              style: textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: UIConstants.spacing16),
            Text(
              announcement.content,
              style: textTheme.bodyMedium,
            ),
            if (announcement.imageUrls.isNotEmpty) ...[
              const SizedBox(height: UIConstants.spacing16),
              ...announcement.imageUrls.map((url) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: UIConstants.spacing8),
                    child: Image.network(url),
                  )),
            ],
            if (announcement.documentUrls.isNotEmpty) ...[
              const SizedBox(height: UIConstants.spacing16),
              Text(
                'Attached Documents:',
                style: textTheme.titleSmall,
              ),
              ...announcement.documentUrls.map((url) => Padding(
                    padding: const EdgeInsets.only(top: UIConstants.spacing4),
                    child: InkWell(
                      onTap: () {
                        // TODO: Implement document opening logic
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening document...')),
                        );
                      },
                      child: Text(
                        url.split('/').last, // Display just the filename
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
