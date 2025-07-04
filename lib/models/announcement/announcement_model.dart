import 'package:cloud_firestore/cloud_firestore.dart';
import '../timestamp/timestamp_model.dart';

enum AnnouncementPriority {
  low,
  normal,
  high,
  urgent,
}

enum AnnouncementStatus {
  draft,
  published,
  archived,
}

enum NotificationChannel {
  app,
  whatsapp,
  both,
}

class Announcement {
  final String id;
  final String title;
  final String content;
  final String teacherId;
  final String teacherName;
  final String kindergartenId;
  final AnnouncementPriority priority;
  final AnnouncementStatus status;
  final NotificationChannel notificationChannel;
  final bool sendWhatsAppNotification;
  final List<String> targetClassIds;
  final List<String> targetParentIds;
  final DateTime? scheduledDateTime;
  final DateTime? publishedDateTime;
  final int totalRecipients;
  final int readCount;
  final List<String> attachmentUrls;
  final Timestamps timestamps;

  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.teacherId,
    required this.teacherName,
    required this.kindergartenId,
    required this.priority,
    required this.status,
    required this.notificationChannel,
    required this.sendWhatsAppNotification,
    required this.targetClassIds,
    required this.targetParentIds,
    this.scheduledDateTime,
    this.publishedDateTime,
    this.totalRecipients = 0,
    this.readCount = 0,
    this.attachmentUrls = const [],
    required this.timestamps,
  });

  factory Announcement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Announcement(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      kindergartenId: data['kindergartenId'] ?? '',
      priority: AnnouncementPriority.values.firstWhere(
        (e) => e.name == data['priority'],
        orElse: () => AnnouncementPriority.normal,
      ),
      status: AnnouncementStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => AnnouncementStatus.draft,
      ),
      notificationChannel: NotificationChannel.values.firstWhere(
        (e) => e.name == data['notificationChannel'],
        orElse: () => NotificationChannel.app,
      ),
      sendWhatsAppNotification: data['sendWhatsAppNotification'] ?? false,
      targetClassIds: List<String>.from(data['targetClassIds'] ?? []),
      targetParentIds: List<String>.from(data['targetParentIds'] ?? []),
      scheduledDateTime: data['scheduledDateTime'] != null
          ? (data['scheduledDateTime'] as Timestamp).toDate()
          : null,
      publishedDateTime: data['publishedDateTime'] != null
          ? (data['publishedDateTime'] as Timestamp).toDate()
          : null,
      totalRecipients: data['totalRecipients'] ?? 0,
      readCount: data['readCount'] ?? 0,
      attachmentUrls: List<String>.from(data['attachmentUrls'] ?? []),
      timestamps: data['timestamps'] != null
          ? Timestamps.fromJson(data['timestamps'])
          : _timestampsFromFirestore(data),
    );
  }

  static Timestamps _timestampsFromFirestore(Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    final updatedAt = data['updatedAt'];
    final now = DateTime.now();

    return Timestamps(
      createdAt: createdAt is Timestamp ? createdAt.toDate() : now,
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : now,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'kindergartenId': kindergartenId,
      'priority': priority.name,
      'status': status.name,
      'notificationChannel': notificationChannel.name,
      'sendWhatsAppNotification': sendWhatsAppNotification,
      'targetClassIds': targetClassIds,
      'targetParentIds': targetParentIds,
      'scheduledDateTime': scheduledDateTime != null
          ? Timestamp.fromDate(scheduledDateTime!)
          : null,
      'publishedDateTime': publishedDateTime != null
          ? Timestamp.fromDate(publishedDateTime!)
          : null,
      'totalRecipients': totalRecipients,
      'readCount': readCount,
      'attachmentUrls': attachmentUrls,
      'createdAt': Timestamp.fromDate(timestamps.createdAt),
      'updatedAt': Timestamp.fromDate(timestamps.updatedAt),
    };
  }

  Announcement copyWith({
    String? id,
    String? title,
    String? content,
    String? teacherId,
    String? teacherName,
    String? kindergartenId,
    AnnouncementPriority? priority,
    AnnouncementStatus? status,
    NotificationChannel? notificationChannel,
    bool? sendWhatsAppNotification,
    List<String>? targetClassIds,
    List<String>? targetParentIds,
    DateTime? scheduledDateTime,
    DateTime? publishedDateTime,
    int? totalRecipients,
    int? readCount,
    List<String>? attachmentUrls,
    Timestamps? timestamps,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      kindergartenId: kindergartenId ?? this.kindergartenId,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      notificationChannel: notificationChannel ?? this.notificationChannel,
      sendWhatsAppNotification: sendWhatsAppNotification ?? this.sendWhatsAppNotification,
      targetClassIds: targetClassIds ?? this.targetClassIds,
      targetParentIds: targetParentIds ?? this.targetParentIds,
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      publishedDateTime: publishedDateTime ?? this.publishedDateTime,
      totalRecipients: totalRecipients ?? this.totalRecipients,
      readCount: readCount ?? this.readCount,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      timestamps: timestamps ?? this.timestamps,
    );
  }

  bool get isPublished => status == AnnouncementStatus.published;
  bool get isDraft => status == AnnouncementStatus.draft;
  bool get isArchived => status == AnnouncementStatus.archived;
  bool get isScheduled => scheduledDateTime != null && !isPublished;
  bool get requiresWhatsApp => sendWhatsAppNotification || notificationChannel == NotificationChannel.whatsapp || notificationChannel == NotificationChannel.both;
  
  double get readPercentage {
    if (totalRecipients == 0) return 0.0;
    return (readCount / totalRecipients * 100);
  }

  String get priorityDisplayName {
    switch (priority) {
      case AnnouncementPriority.low:
        return 'Low Priority';
      case AnnouncementPriority.normal:
        return 'Normal';
      case AnnouncementPriority.high:
        return 'High Priority';
      case AnnouncementPriority.urgent:
        return 'Urgent';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case AnnouncementStatus.draft:
        return 'Draft';
      case AnnouncementStatus.published:
        return 'Published';
      case AnnouncementStatus.archived:
        return 'Archived';
    }
  }

  String get channelDisplayName {
    switch (notificationChannel) {
      case NotificationChannel.app:
        return 'App Only';
      case NotificationChannel.whatsapp:
        return 'WhatsApp Only';
      case NotificationChannel.both:
        return 'App + WhatsApp';
    }
  }

  @override
  String toString() {
    return 'Announcement(id: $id, title: $title, status: $status, priority: $priority)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Announcement && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Extensions for easier UI usage
extension AnnouncementPriorityExtension on AnnouncementPriority {
  String get emoji {
    switch (this) {
      case AnnouncementPriority.low:
        return '📝';
      case AnnouncementPriority.normal:
        return '📢';
      case AnnouncementPriority.high:
        return '⚠️';
      case AnnouncementPriority.urgent:
        return '🚨';
    }
  }

  bool get isImportant => this == AnnouncementPriority.high || this == AnnouncementPriority.urgent;
}

extension AnnouncementStatusExtension on AnnouncementStatus {
  String get emoji {
    switch (this) {
      case AnnouncementStatus.draft:
        return '📝';
      case AnnouncementStatus.published:
        return '📢';
      case AnnouncementStatus.archived:
        return '📁';
    }
  }
}

extension NotificationChannelExtension on NotificationChannel {
  String get emoji {
    switch (this) {
      case NotificationChannel.app:
        return '📱';
      case NotificationChannel.whatsapp:
        return '💬';
      case NotificationChannel.both:
        return '📱💬';
    }
  }
}
