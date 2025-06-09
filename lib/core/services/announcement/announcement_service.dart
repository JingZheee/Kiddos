import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nursery_app/models/announcement/announcement.dart';

class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new announcement
  Future<void> createAnnouncement(Announcement announcement) async {
    await _firestore
        .collection('announcements')
        .add(announcement.toFirestore());
  }

  // Get all announcements (for admin/teacher)
  Stream<List<Announcement>> getAnnouncements() {
    return _firestore
        .collection('announcements')
        .orderBy('publishDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Announcement.fromFirestore(doc))
          .toList();
    });
  }

  // Get announcements for parents (not archived)
  Stream<List<Announcement>> getParentAnnouncements() {
    return _firestore
        .collection('announcements')
        .where('isArchived', isEqualTo: false)
        .where('isGlobal',
            isEqualTo: true) // Parents should see global announcements
        // .where('kindergartenId', isEqualTo: currentKindergartenId) // Future: filter by user's kindergarten
        .orderBy('publishDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Announcement.fromFirestore(doc))
          .toList();
    });
  }

  // Update an existing announcement
  Future<void> updateAnnouncement(Announcement announcement) async {
    await _firestore
        .collection('announcements')
        .doc(announcement.id)
        .update(announcement.toFirestore());
  }

  // Delete an announcement
  Future<void> deleteAnnouncement(String announcementId) async {
    await _firestore.collection('announcements').doc(announcementId).delete();
  }

  // Archive an announcement
  Future<void> archiveAnnouncement(
      String announcementId, bool isArchived) async {
    await _firestore.collection('announcements').doc(announcementId).update({
      'isArchived': isArchived,
    });
  }
}
