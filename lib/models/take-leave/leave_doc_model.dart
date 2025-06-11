import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveDoc{
  final String documentID;
  final String leaveID;
  final String docName;
  final String docUrl;
  final DateTime uploadedAt;

  LeaveDoc({
    required this.documentID,
    required this.leaveID,
    required this.docName,
    required this.docUrl,
    required this.uploadedAt,
  });
}