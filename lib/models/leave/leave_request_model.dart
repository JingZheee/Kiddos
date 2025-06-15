import 'package:cloud_firestore/cloud_firestore.dart';

enum LeaveStatus {
  pending,
  approved,
  rejected,
  cancelled; // Add this

  String get displayName {
    switch (this) {
      case LeaveStatus.pending:
        return 'Pending';
      case LeaveStatus.approved:
        return 'Approved';
      case LeaveStatus.rejected:
        return 'Rejected';
      case LeaveStatus.cancelled:
        return 'Cancelled';
    }
  }
}

enum LeaveType {
  sick,
  vacation,
  family,
  medical,
  emergency,
  personal,
  other,
}

class LeaveRequest {
  final String leaveID;
  final String studentID;
  final String parentID;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final LeaveStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? comment;
  final LeaveType leaveType;

  LeaveRequest({
    required this.leaveID,
    required this.studentID,
    required this.parentID,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
    this.comment,
    required this.leaveType,
  });

  // Convert LeaveRequest to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'leaveID': leaveID,
      'studentID': studentID,
      'parentID': parentID,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'reason': reason,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'comment': comment,
      'leaveType': leaveType.name,
    };
  }

  // Create LeaveRequest from Firestore document
  factory LeaveRequest.fromMap(Map<String, dynamic> map) {
    return LeaveRequest(
      leaveID: map['leaveID'] ?? '',
      studentID: map['studentID'] ?? '',
      parentID: map['parentID'] ?? '',
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      reason: map['reason'] ?? '',
      status: LeaveStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => LeaveStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      reviewedAt: map['reviewedAt'] != null 
          ? (map['reviewedAt'] as Timestamp).toDate() 
          : null,
      comment: map['comment'],
      leaveType: LeaveType.values.firstWhere(
        (e) => e.name == map['leaveType'],
        orElse: () => LeaveType.other,
      ),
    );
  }

  // Create LeaveRequest from Firestore DocumentSnapshot
  factory LeaveRequest.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['leaveID'] = doc.id; // Use document ID as leaveID
    return LeaveRequest.fromMap(data);
  }

  // Copy with method for updating fields
  LeaveRequest copyWith({
    String? leaveID,
    String? studentID,
    String? parentID,
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
    LeaveStatus? status,
    DateTime? createdAt,
    DateTime? reviewedAt,
    String? comment,
    LeaveType? leaveType,
  }) {
    return LeaveRequest(
      leaveID: leaveID ?? this.leaveID,
      studentID: studentID ?? this.studentID,
      parentID: parentID ?? this.parentID,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      comment: comment ?? this.comment,
      leaveType: leaveType ?? this.leaveType,
    );
  }

  // Calculate leave duration in days
  int get durationInDays {
    return endDate.difference(startDate).inDays + 1;
  }

  // Check if leave is currently active
  bool get isActive {
    final now = DateTime.now();
    return status == LeaveStatus.approved &&
           now.isAfter(startDate.subtract(const Duration(days: 1))) &&
           now.isBefore(endDate.add(const Duration(days: 1)));
  }

  // Check if leave is in the future
  bool get isFuture {
    final now = DateTime.now();
    return startDate.isAfter(now);
  }

  // Check if leave is in the past
  bool get isPast {
    final now = DateTime.now();
    return endDate.isBefore(now);
  }

  @override
  String toString() {
    return 'LeaveRequest(leaveID: $leaveID, studentID: $studentID, parentID: $parentID, startDate: $startDate, endDate: $endDate, reason: $reason, status: $status, createdAt: $createdAt, reviewedAt: $reviewedAt, comment: $comment, leaveType: $leaveType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeaveRequest && other.leaveID == leaveID;
  }

  @override
  int get hashCode => leaveID.hashCode;
}

// Extension methods for enum display
extension LeaveStatusExtension on LeaveStatus {
  String get displayName {
    switch (this) {
      case LeaveStatus.pending:
        return 'Pending';
      case LeaveStatus.approved:
        return 'Approved';
      case LeaveStatus.rejected:
        return 'Rejected';
      case LeaveStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get emoji {
    switch (this) {
      case LeaveStatus.pending:
        return '⏳';
      case LeaveStatus.approved:
        return '✅';
      case LeaveStatus.rejected:
        return '❌';
      case LeaveStatus.cancelled:
        return '🚫';
    }
  }
}

extension LeaveTypeExtension on LeaveType {
  String get displayName {
    switch (this) {
      case LeaveType.sick:
        return 'Sick Leave';
      case LeaveType.vacation:
        return 'Vacation';
      case LeaveType.family:
        return 'Family Leave';
      case LeaveType.medical:
        return 'Medical Leave';
      case LeaveType.emergency:
        return 'Emergency Leave';
      case LeaveType.personal:
        return 'Personal Leave';
      case LeaveType.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case LeaveType.sick:
        return '🤒';
      case LeaveType.vacation:
        return '🏖️';
      case LeaveType.family:
        return '👨‍👩‍👧‍👦';
      case LeaveType.medical:
        return '🏥';
      case LeaveType.emergency:
        return '🚨';
      case LeaveType.personal:
        return '👤';
      case LeaveType.other:
        return '📝';
    }
  }
}


