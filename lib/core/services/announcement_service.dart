import '../../models/announcement/announcement_model.dart';
import '../../models/timestamp/timestamp_model.dart';

class AnnouncementService {
  // Dummy data storage - in-memory list
  static final List<Announcement> _dummyAnnouncements = [
    Announcement(
      id: '1',
      title: 'School Holiday Notice',
      content: 'Please note that the school will be closed next Friday for a public holiday. Regular classes will resume on Monday.',
      teacherId: 'teacher1',
      teacherName: 'Ms. Sarah Johnson',
      kindergartenId: 'kg1',
      priority: AnnouncementPriority.normal,
      status: AnnouncementStatus.published,
      notificationChannel: NotificationChannel.both,
      sendWhatsAppNotification: true,
      targetClassIds: ['class1', 'class2'],
      targetParentIds: ['parent1', 'parent2', 'parent3'],
      scheduledDateTime: null,
      publishedDateTime: DateTime.now().subtract(const Duration(hours: 2)),
      totalRecipients: 25,
      readCount: 18,
      attachmentUrls: [],
      timestamps: Timestamps.now(),
    ),
    Announcement(
      id: '2',
      title: 'Parent-Teacher Meeting',
      content: 'We will be conducting parent-teacher meetings next week. Please check your schedule and confirm your attendance.',
      teacherId: 'teacher1',
      teacherName: 'Ms. Sarah Johnson',
      kindergartenId: 'kg1',
      priority: AnnouncementPriority.high,
      status: AnnouncementStatus.published,
      notificationChannel: NotificationChannel.app,
      sendWhatsAppNotification: false,
      targetClassIds: ['class1'],
      targetParentIds: ['parent1', 'parent2'],
      scheduledDateTime: null,
      publishedDateTime: DateTime.now().subtract(const Duration(days: 1)),
      totalRecipients: 15,
      readCount: 12,
      attachmentUrls: [],
      timestamps: Timestamps.now(),
    ),
    Announcement(
      id: '3',
      title: 'Field Trip Permission',
      content: 'We are planning a field trip to the local zoo next month. Please sign and return the permission slip by Friday.',
      teacherId: 'teacher2',
      teacherName: 'Mr. David Wilson',
      kindergartenId: 'kg1',
      priority: AnnouncementPriority.urgent,
      status: AnnouncementStatus.draft,
      notificationChannel: NotificationChannel.both,
      sendWhatsAppNotification: true,
      targetClassIds: ['class2'],
      targetParentIds: [],
      scheduledDateTime: DateTime.now().add(const Duration(days: 2)),
      publishedDateTime: null,
      totalRecipients: 0,
      readCount: 0,
      attachmentUrls: [],
      timestamps: Timestamps.now(),
    ),
    Announcement(
      id: '4',
      title: 'Weekly Menu Update',
      content: 'This week\'s lunch menu has been updated. Please check the new healthy options available for your child.',
      teacherId: 'teacher1',
      teacherName: 'Ms. Sarah Johnson',
      kindergartenId: 'kg1',
      priority: AnnouncementPriority.normal,
      status: AnnouncementStatus.published,
      notificationChannel: NotificationChannel.app,
      sendWhatsAppNotification: false,
      targetClassIds: ['class1', 'class2'],
      targetParentIds: ['parent1', 'parent2', 'parent3', 'parent4'],
      scheduledDateTime: null,
      publishedDateTime: DateTime.now().subtract(const Duration(hours: 6)),
      totalRecipients: 30,
      readCount: 22,
      attachmentUrls: [],
      timestamps: Timestamps.now(),
    ),
  ];

  // Dummy read receipts storage
  static final Set<String> _readReceipts = {
    '1_parent1',
    '1_parent2',
    '2_parent1',
    '4_parent1',
    '4_parent2',
    '4_parent3',
  };

  // Create announcement
  Future<String> createAnnouncement(Announcement announcement) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newAnnouncement = announcement.copyWith(
      id: newId,
      timestamps: Timestamps.now(),
    );
    
    _dummyAnnouncements.add(newAnnouncement);
    return newId;
  }

  // Update announcement
  Future<void> updateAnnouncement(Announcement announcement) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    
    final index = _dummyAnnouncements.indexWhere((a) => a.id == announcement.id);
    if (index != -1) {
      _dummyAnnouncements[index] = announcement.copyWith(
        timestamps: announcement.timestamps.copyWith(updatedAt: DateTime.now()),
      );
    }
  }

  // Publish announcement
  Future<void> publishAnnouncement(String announcementId) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    
    final index = _dummyAnnouncements.indexWhere((a) => a.id == announcementId);
    if (index != -1) {
      final announcement = _dummyAnnouncements[index];
      final updatedAnnouncement = announcement.copyWith(
        status: AnnouncementStatus.published,
        publishedDateTime: DateTime.now(),
        totalRecipients: _calculateTotalRecipients(announcement),
        timestamps: announcement.timestamps.copyWith(updatedAt: DateTime.now()),
      );
      
      _dummyAnnouncements[index] = updatedAnnouncement;
      
      // Simulate sending notifications
      _simulateNotifications(updatedAnnouncement);
    }
  }

  // Get announcements for teacher
  Stream<List<Announcement>> getTeacherAnnouncements(String teacherId) async* {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
    
    final teacherAnnouncements = _dummyAnnouncements
        .where((announcement) => announcement.teacherId == teacherId)
        .toList()
      ..sort((a, b) => (b.timestamps.createdAt).compareTo(a.timestamps.createdAt));
    
    yield teacherAnnouncements;
  }

  // Get announcements for kindergarten
  Stream<List<Announcement>> getKindergartenAnnouncements(String kindergartenId) async* {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
    
    final kindergartenAnnouncements = _dummyAnnouncements
        .where((announcement) => 
            announcement.kindergartenId == kindergartenId && 
            announcement.status == AnnouncementStatus.published)
        .toList()
      ..sort((a, b) => (b.publishedDateTime ?? DateTime.now()).compareTo(a.publishedDateTime ?? DateTime.now()));
    
    yield kindergartenAnnouncements;
  }

  // Get announcements for parent
  Stream<List<Announcement>> getAnnouncementsForParent({
    required String parentId,
    required String kindergartenId,
  }) async* {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
    
    final parentAnnouncements = _dummyAnnouncements
        .where((announcement) => 
            announcement.kindergartenId == kindergartenId && 
            announcement.status == AnnouncementStatus.published &&
            (announcement.targetParentIds.isEmpty || announcement.targetParentIds.contains(parentId)))
        .toList()
      ..sort((a, b) => (b.publishedDateTime ?? DateTime.now()).compareTo(a.publishedDateTime ?? DateTime.now()));
    
    yield parentAnnouncements;
  }

  // Get all published announcements for a kindergarten (fallback for demo)
  Stream<List<Announcement>> getPublishedAnnouncementsForKindergarten(String kindergartenId) async* {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
    
    final publishedAnnouncements = _dummyAnnouncements
        .where((announcement) => 
            announcement.kindergartenId == kindergartenId && 
            announcement.status == AnnouncementStatus.published)
        .toList()
      ..sort((a, b) => (b.publishedDateTime ?? DateTime.now()).compareTo(a.publishedDateTime ?? DateTime.now()));
    
    yield publishedAnnouncements;
  }

  // Delete announcement
  Future<void> deleteAnnouncement(String announcementId) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    
    _dummyAnnouncements.removeWhere((announcement) => announcement.id == announcementId);
  }

  // Archive announcement
  Future<void> archiveAnnouncement(String announcementId) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    
    final index = _dummyAnnouncements.indexWhere((a) => a.id == announcementId);
    if (index != -1) {
      _dummyAnnouncements[index] = _dummyAnnouncements[index].copyWith(
        status: AnnouncementStatus.archived,
        timestamps: _dummyAnnouncements[index].timestamps.copyWith(updatedAt: DateTime.now()),
      );
    }
  }

  // Get announcement by ID
  Future<Announcement?> getAnnouncementById(String announcementId) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
    
    try {
      return _dummyAnnouncements.firstWhere((announcement) => announcement.id == announcementId);
    } catch (e) {
      return null;
    }
  }

  // Mark announcement as read by parent
  Future<void> markAnnouncementAsRead(String announcementId, String parentId) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
    
    final readReceiptKey = '${announcementId}_$parentId';
    _readReceipts.add(readReceiptKey);
    
    // Update read count in announcement
    final index = _dummyAnnouncements.indexWhere((a) => a.id == announcementId);
    if (index != -1) {
      final announcement = _dummyAnnouncements[index];
      _dummyAnnouncements[index] = announcement.copyWith(
        readCount: announcement.readCount + 1,
      );
    }
  }

  // Get read status for announcement
  Future<bool> isAnnouncementRead(String announcementId, String parentId) async {
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
    
    final readReceiptKey = '${announcementId}_$parentId';
    return _readReceipts.contains(readReceiptKey);
  }

  // Private helper methods
  int _calculateTotalRecipients(Announcement announcement) {
    // Simplified calculation for dummy data
    if (announcement.targetParentIds.isNotEmpty) {
      return announcement.targetParentIds.length;
    } else if (announcement.targetClassIds.isNotEmpty) {
      // Assume 10 parents per class for demo
      return announcement.targetClassIds.length * 10;
    } else {
      // All parents in kindergarten - assume 50 for demo
      return 50;
    }
  }

  void _simulateNotifications(Announcement announcement) {
    // Simulate sending notifications - just print for demo
    print('📢 Sending ${announcement.notificationChannel.name} notifications for: ${announcement.title}');
    if (announcement.sendWhatsAppNotification) {
      print('📱 WhatsApp notification sent to ${announcement.totalRecipients} recipients');
    }
    print('📧 In-app notification sent to ${announcement.totalRecipients} recipients');
  }



  // Get announcement statistics
  Future<Map<String, dynamic>> getAnnouncementStats(String teacherId, String kindergartenId) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    
    final teacherAnnouncements = _dummyAnnouncements
        .where((a) => a.teacherId == teacherId && a.kindergartenId == kindergartenId)
        .toList();

    int totalAnnouncements = teacherAnnouncements.length;
    int publishedCount = 0;
    int draftCount = 0;
    int totalReads = 0;
    int totalRecipients = 0;

    for (final announcement in teacherAnnouncements) {
      switch (announcement.status) {
        case AnnouncementStatus.published:
          publishedCount++;
          totalReads += announcement.readCount;
          totalRecipients += announcement.totalRecipients;
          break;
        case AnnouncementStatus.draft:
          draftCount++;
          break;
        case AnnouncementStatus.archived:
          // Archived announcements don't count in main stats
          break;
      }
    }

    return {
      'totalAnnouncements': totalAnnouncements,
      'publishedCount': publishedCount,
      'draftCount': draftCount,
      'readRate': totalRecipients > 0 ? (totalReads / totalRecipients * 100) : 0.0,
      'totalReads': totalReads,
      'totalRecipients': totalRecipients,
    };
  }
}
