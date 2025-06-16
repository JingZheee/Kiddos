import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../models/leave/leave_request_model.dart';
import '../../models/leave/leave_doc_model.dart';

class TakeLeaveService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> submitLeaveRequest({
    required String studentID,
    required String parentID,
    required LeaveType leaveType,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
    List<PlatformFile>? attachments,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Create the leave request document first
      final leaveRequestRef = _firestore.collection('leave_requests').doc();
      final leaveID = leaveRequestRef.id;

      print('Creating leave request with ID: $leaveID');

      // Create leave request data
      final leaveRequest = LeaveRequest(
        leaveID: leaveID,
        studentID: studentID,
        parentID: parentID,
        leaveType: leaveType,
        startDate: startDate,
        endDate: endDate,
        reason: reason ?? '',
        status: LeaveStatus.pending,
        createdAt: DateTime.now(),
        reviewedAt: DateTime.now(),
      );

      // Save the leave request
      await leaveRequestRef.set(leaveRequest.toMap());
      print('Leave request saved successfully');

      // Handle file uploads
      if (attachments != null && attachments.isNotEmpty) {
        print('Processing ${attachments.length} documents...');
        
        for (int i = 0; i < attachments.length; i++) {
          final file = attachments[i];
          print('Processing document ${i + 1}: ${file.name}');
          
          try {
            if (file.bytes == null || file.bytes!.isEmpty) {
              print('Skipping file ${file.name} - no bytes available');
              continue;
            }

            // Upload file and get URL
            final documentUrl = await _uploadFileAndGetUrl(file, leaveID);
            
            print('File processed successfully: $documentUrl');

            // Save document metadata to Firestore
            final docData = {
              'docID': _firestore.collection('leave_documents').doc().id,
              'leaveID': leaveID,
              'docName': file.name,
              'fileSize': file.bytes!.length,
              'downloadURL': documentUrl,
              'mimeType': _getMimeType(file.name),
              'uploadedAt': FieldValue.serverTimestamp(),
              'uploadStatus': 'completed',
            };

            await _firestore.collection('leave_documents').add(docData);
            print('Document metadata saved: ${file.name}');
            
          } catch (e) {
            print('Error processing document ${file.name}: $e');
            
            // Save failed document info
            final docData = {
              'docID': _firestore.collection('leave_documents').doc().id,
              'leaveID': leaveID,
              'docName': file.name,
              'fileSize': file.bytes!.length,
              'downloadURL': null,
              'mimeType': _getMimeType(file.name),
              'uploadedAt': FieldValue.serverTimestamp(),
              'uploadStatus': 'failed',
              'error': e.toString(),
            };

            await _firestore.collection('leave_documents').add(docData);
            print('Failed document metadata saved: ${file.name}');
          }
        }
      }

      print('Leave request submission completed');
      
    } catch (e) {
      print('Error in submitLeaveRequest: $e');
      throw Exception('Failed to submit leave request: $e');
    }
  }

  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  // Simple file upload method
  Future<String> _uploadFileAndGetUrl(PlatformFile file, String leaveID) async {
    try {
      // For now, generate a mock URL (replace with actual file hosting service)
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate upload time
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = file.name.replaceAll(' ', '_').replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '');
      
      // Generate a mock URL (replace this with actual file hosting service)
      final mockUrl = 'https://mock-storage.example.com/documents/$leaveID/${timestamp}_$fileName';
      
      print('Mock URL generated: $mockUrl');
      return mockUrl;
      
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  Future<void> updateLeaveStatus({
    required String leaveID,
    required LeaveStatus status,
    String? comment,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('leave_requests').doc(leaveID).update({
        'status': status.name,
        'comment': comment,
        'reviewedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error updating leave status: $e');
      rethrow;
    }
  }

  Stream<List<LeaveRequest>> getLeaveRequests({LeaveStatus? status}) {
    Query query = _firestore.collection('leave_requests');
    
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }
    
    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LeaveRequest.fromDocument(doc))
            .toList());
  }

  Stream<List<LeaveRequest>> getUserLeaveRequests(String parentID) {
    return _firestore
        .collection('leave_requests')
        .where('parentID', isEqualTo: parentID)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LeaveRequest.fromDocument(doc))
            .toList());
  }

  Stream<List<LeaveDoc>> getLeaveDocuments(String leaveID) {
    try {
      print('Getting documents for leaveID: $leaveID');
      
      return _firestore
          .collection('leave_documents')
          .snapshots()
          .map((snapshot) {
        print('All documents snapshot received: ${snapshot.docs.length} docs');
        
        final allDocs = snapshot.docs.map((doc) {
          final data = doc.data();
          return LeaveDoc(
            docID: doc.id,
            leaveID: data['leaveID'] ?? '',
            docName: data['docName'] ?? '',
            docURL: data['downloadURL'] ?? '',
            uploadedAt: (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
        }).toList();
        
        // Filter by leaveID in memory
        final filteredDocs = allDocs.where((doc) => doc.leaveID == leaveID).toList();
        
        // Sort by uploadedAt (newest first)
        filteredDocs.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
        
        print('Filtered documents for leaveID $leaveID: ${filteredDocs.length} docs');
        
        return filteredDocs;
      });
    } catch (e) {
      print('Error in getLeaveDocuments: $e');
      return Stream.error(e);
    }
  }

  Future<void> deleteLeaveRequest(String leaveID) async {
    try {
      // Delete associated documents first
      final docsSnapshot = await _firestore
          .collection('leave_documents')
          .where('leaveID', isEqualTo: leaveID)
          .get();

      // Delete files from storage and document records
      for (QueryDocumentSnapshot doc in docsSnapshot.docs) {
        final leaveDoc = LeaveDoc.fromDocument(doc);
        
        // Delete from storage
        try {
          if (leaveDoc.docURL != null && leaveDoc.docURL!.isNotEmpty) {
            await _storage.refFromURL(leaveDoc.docURL!).delete();
          }
        } catch (e) {
          print('Error deleting file from storage: $e');
        }
        
        // Delete document record
        await doc.reference.delete();
      }

      // Delete the leave request
      await _firestore.collection('leave_requests').doc(leaveID).delete();
    } catch (e) {
      print('Error deleting leave request: $e');
      rethrow;
    }
  }

  Future<void> deleteLeaveDocument(String docID, String docURL) async {
    try {
      // Delete from storage
      await _storage.refFromURL(docURL).delete();
      
      // Delete document record
      await _firestore.collection('leave_documents').doc(docID).delete();
    } catch (e) {
      print('Error deleting document: $e');
      rethrow;
    }
  }

  Future<Map<String, int>> getLeaveStatistics({String? parentID, String? studentID}) async {
    try {
      Query query = _firestore.collection('leave_requests');
      
      if (parentID != null) {
        query = query.where('parentID', isEqualTo: parentID);
      } else if (studentID != null) {
        query = query.where('studentID', isEqualTo: studentID);
      }

      final snapshot = await query.get();
      final requests = snapshot.docs.map((doc) => LeaveRequest.fromDocument(doc)).toList();

      return {
        'total': requests.length,
        'pending': requests.where((r) => r.status == LeaveStatus.pending).length,
        'approved': requests.where((r) => r.status == LeaveStatus.approved).length,
        'rejected': requests.where((r) => r.status == LeaveStatus.rejected).length,
      };
    } catch (e) {
      print('Error getting statistics: $e');
      return {'total': 0, 'pending': 0, 'approved': 0, 'rejected': 0};
    }
  }

  // Helper method to pick files
  Future<List<PlatformFile>?> pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'gif'],
      );

      if (result != null) {
        return result.files;
      }
    } catch (e) {
      print('Error picking files: $e');
    }
    return null;
  }

  Stream<List<LeaveRequest>> getAllRequestsForFiltering() {
    return _firestore
        .collection('leave_requests')
        .limit(200) // Add reasonable limit
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => LeaveRequest.fromDocument(doc))
              .toList();
        });
  }

  Future<void> cancelLeaveRequest(String leaveID) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get the leave request to verify it belongs to the user and is pending
      final leaveDoc = await _firestore.collection('leave_requests').doc(leaveID).get();
      
      if (!leaveDoc.exists) {
        throw Exception('Leave request not found');
      }

      final leaveData = leaveDoc.data()!;
      
      // Verify the request belongs to the current user
      if (leaveData['parentID'] != user.uid) {
        throw Exception('You can only cancel your own requests');
      }

      // Verify the request is still pending
      if (leaveData['status'] != 'pending') {
        throw Exception('Only pending requests can be cancelled');
      }

      // Update the status to cancelled
      await _firestore.collection('leave_requests').doc(leaveID).update({
        'status': 'cancelled',
        'reviewedAt': FieldValue.serverTimestamp(),
        'comment': 'Cancelled by parent',
      });

      print('Leave request $leaveID cancelled successfully');
      
    } catch (e) {
      print('Error cancelling leave request: $e');
      throw Exception('Failed to cancel leave request: $e');
    }
  }
}