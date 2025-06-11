import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

enum  Status {
  pending,
  approved,
  rejected,
}

enum LeaveType {
  casual,
  sick,
  vacation,
}

class LeaveRequest {
  final String leaveID;
  final String studentId;
  final String parentID;
  final DateFormat startDate;
  final DateFormat endDate;
  final Text reason;
  final DateTime createdAt;
  final DateTime reviewedAt;
  final Text comment;
  final Status status;
  final LeaveType leaveType;

  LeaveRequest({
    required this.leaveID,
    required this.studentId,
    required this.parentID,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.createdAt,
    required this.reviewedAt,
    required this.comment,
    required this.status,
    required this.leaveType,
  });
}


  