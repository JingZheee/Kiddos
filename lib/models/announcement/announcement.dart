import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final Timestamp publishDate;
  final List<String> audience; // e.g., ['parents', 'teachers', 'all']
  final List<String> imageUrls;
  final List<String> documentUrls;
  final bool isArchived;
  final String? kindergartenId;
  final bool isGlobal;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.publishDate,
    this.audience = const [],
    this.imageUrls = const [],
    this.documentUrls = const [],
    this.isArchived = false,
    this.kindergartenId,
    this.isGlobal = false,
  });

  factory Announcement.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Announcement(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      publishDate: data['publishDate'] ?? Timestamp.now(),
      audience: List<String>.from(data['audience'] ?? []),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      documentUrls: List<String>.from(data['documentUrls'] ?? []),
      isArchived: data['isArchived'] ?? false,
      kindergartenId: data['kindergartenId'],
      isGlobal: data['isGlobal'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'publishDate': publishDate,
      'audience': audience,
      'imageUrls': imageUrls,
      'documentUrls': documentUrls,
      'isArchived': isArchived,
      'kindergartenId': kindergartenId,
      'isGlobal': isGlobal,
    };
  }

  Announcement copyWith({
    String? id,
    String? title,
    String? content,
    String? authorId,
    String? authorName,
    Timestamp? publishDate,
    List<String>? audience,
    List<String>? imageUrls,
    List<String>? documentUrls,
    bool? isArchived,
    String? kindergartenId,
    bool? isGlobal,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      publishDate: publishDate ?? this.publishDate,
      audience: audience ?? this.audience,
      imageUrls: imageUrls ?? this.imageUrls,
      documentUrls: documentUrls ?? this.documentUrls,
      isArchived: isArchived ?? this.isArchived,
      kindergartenId: kindergartenId ?? this.kindergartenId,
      isGlobal: isGlobal ?? this.isGlobal,
    );
  }
}
