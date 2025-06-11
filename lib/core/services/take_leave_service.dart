import 'package:cloud_firestore/cloud_firestore.dart';

class TakeLeaveService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new leave request
  Future<void> submitLeaveRequest({
    required String studentId,
    required String parentId,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String? attachmentUrl,
  }) async {
    try {
      await _firestore.collection('leave_requests').add({
        'studentId': studentId,
        'parentId': parentId,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'reason': reason,
        'attachmentUrl': attachmentUrl,
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to submit leave request: $e');
    }
  }

  // Get leave requests for a specific student
  Stream<QuerySnapshot> getStudentLeaveRequests(String studentId) {
    return _firestore
        .collection('leave_requests')
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get leave requests for a specific parent
  Stream<QuerySnapshot> getParentLeaveRequests(String parentId) {
    return _firestore
        .collection('leave_requests')
        .where('parentId', isEqualTo: parentId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Update leave request status (for teachers/admins)
  Future<void> updateLeaveStatus({
    required String leaveId,
    required String status,
    String? remarks,
  }) async {
    try {
      await _firestore.collection('leave_requests').doc(leaveId).update({
        'status': status,
        'remarks': remarks,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update leave status: $e');
    }
  }

  // Cancel leave request (for parents)
  Future<void> cancelLeaveRequest(String leaveId) async {
    try {
      await _firestore.collection('leave_requests').doc(leaveId).update({
        'status': 'cancelled',
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to cancel leave request: $e');
    }
  }
}