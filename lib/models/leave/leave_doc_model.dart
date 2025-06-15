import 'package:cloud_firestore/cloud_firestore.dart';

// Update the LeaveDoc model to focus on URLs:
class LeaveDoc {
  final String docID;
  final String leaveID;
  final String docName;
  final String? docURL; // Main URL field
  final String? mimeType;
  final int? fileSize;
  final DateTime uploadedAt;
  final String? uploadStatus; // 'completed', 'failed', 'pending'
  final String? error; // Error message if upload failed

  LeaveDoc({
    required this.docID,
    required this.leaveID,
    required this.docName,
    this.docURL,
    this.mimeType,
    this.fileSize,
    required this.uploadedAt,
    this.uploadStatus,
    this.error,
  });

  // Convert LeaveDoc to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'docID': docID,
      'leaveID': leaveID,
      'docName': docName,
      'docURL': docURL,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'uploadStatus': uploadStatus,
      'error': error,
    };
  }

  // Create LeaveDoc from Firestore document
  factory LeaveDoc.fromMap(Map<String, dynamic> map) {
    return LeaveDoc(
      docID: map['docID'] ?? '',
      leaveID: map['leaveID'] ?? '',
      docName: map['docName'] ?? '',
      docURL: map['docURL'],
      mimeType: map['mimeType'],
      fileSize: map['fileSize'],
      uploadedAt: (map['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      uploadStatus: map['uploadStatus'],
      error: map['error'],
    );
  }

  // Create LeaveDoc from Firestore DocumentSnapshot
  factory LeaveDoc.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['documentID'] = doc.id; // Use document ID as documentID
    return LeaveDoc.fromMap(data);
  }

  // Check if document is available (URL not null and upload completed)
  bool get isAvailable => docURL != null && uploadStatus == 'completed';

  // Check if document upload has failed
  bool get isFailed => uploadStatus == 'failed';

  // Check if download URL is a data URL (Base64)
  bool get isDataUrl => docURL?.startsWith('data:') == true;
}