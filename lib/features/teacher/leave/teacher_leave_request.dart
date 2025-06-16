import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/leave/leave_request_model.dart';
import '../../../models/leave/leave_doc_model.dart';
import '../../../core/services/take_leave_service.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/document_viewer.dart';
import 'dart:convert';

class TeacherLeaveRequest extends StatefulWidget {
  const TeacherLeaveRequest({super.key});

  @override
  State<TeacherLeaveRequest> createState() => _TeacherLeaveRequestState();
}

class _TeacherLeaveRequestState extends State<TeacherLeaveRequest> {
  final TakeLeaveService _leaveService = TakeLeaveService();
  final Set<String> _selectedRequests = <String>{};
  bool _isSelectMode = false;
  bool _isProcessing = false;
  List<LeaveRequest>? _cachedRequests; // Cache for bulk selection

  void _showCommentDialog(LeaveRequest leave, LeaveStatus newStatus) {
    final commentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: newStatus == LeaveStatus.approved 
                      ? const Color(0xFF4CAF50).withOpacity(0.1)
                      : const Color(0xFFF44336).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  newStatus == LeaveStatus.approved 
                      ? Icons.check_circle_outline 
                      : Icons.cancel_outlined,
                  color: newStatus == LeaveStatus.approved 
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFF44336),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${newStatus == LeaveStatus.approved ? 'Approve' : 'Reject'} Request',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF7FAFC), Color(0xFFEDF2F7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 16, color: const Color(0xFF6B7280)),
                          const SizedBox(width: 6),
                          Text(
                            'Student ID:',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              leave.studentID,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2D3748),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.schedule_outlined, size: 16, color: const Color(0xFF6B7280)),
                          const SizedBox(width: 6),
                          Text(
                            'Duration:',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${leave.durationInDays} ${leave.durationInDays == 1 ? 'day' : 'days'}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2D3748),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.category_outlined, size: 16, color: const Color(0xFF6B7280)),
                          const SizedBox(width: 6),
                          Text(
                            'Type:',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                leave.leaveType.displayName,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Add Comment (Optional)',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4A5568),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: commentController,
                  decoration: InputDecoration(
                    hintText: 'Add your ${newStatus == LeaveStatus.approved ? 'approval' : 'rejection'} comments',
                    hintStyle: GoogleFonts.poppins(color: const Color(0xFF9CA3AF)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF7FAFC),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: GoogleFonts.poppins(),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6B7280),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateSingleLeaveStatus(leave.leaveID, newStatus, commentController.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: newStatus == LeaveStatus.approved 
                    ? const Color(0xFF4CAF50) 
                    : const Color(0xFFF44336),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    newStatus == LeaveStatus.approved ? Icons.check : Icons.close, 
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    newStatus == LeaveStatus.approved ? 'Approve' : 'Reject',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateSingleLeaveStatus(String leaveID, LeaveStatus status, String comment) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await _leaveService.updateLeaveStatus(
        leaveID: leaveID,
        status: status,
        comment: comment.isNotEmpty ? comment : null,
      );

      if (mounted) {
        // Clear cache to refresh data
        _cachedRequests = null;
        
        _showSnackBar(
          'Leave request ${status.displayName.toLowerCase()} successfully',
          status == LeaveStatus.approved ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', const Color(0xFFF44336));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _bulkAction(LeaveStatus status) {
    if (_selectedRequests.isEmpty) {
      _showSnackBar('Please select requests to process', const Color(0xFFFF9800));
      return;
    }
    _showBulkActionDialog(status);
  }

  void _showBulkActionDialog(LeaveStatus status) {
    final commentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: status == LeaveStatus.approved 
                      ? const Color(0xFF4CAF50).withOpacity(0.1)
                      : const Color(0xFFF44336).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  status == LeaveStatus.approved 
                      ? Icons.check_circle_outline 
                      : Icons.cancel_outlined,
                  color: status == LeaveStatus.approved 
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFF44336),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${status.displayName} ${_selectedRequests.length} Requests',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF7FAFC), Color(0xFFEDF2F7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'You are about to ${status.displayName.toLowerCase()} ${_selectedRequests.length} leave requests.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF4A5568),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Add Comment (Optional)',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4A5568),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  hintText: 'Add bulk ${status.displayName.toLowerCase()} comments',
                  hintStyle: GoogleFonts.poppins(color: const Color(0xFF9CA3AF)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF7FAFC),
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: GoogleFonts.poppins(),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6B7280),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _processBulkRequests(status, commentController.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: status == LeaveStatus.approved 
                    ? const Color(0xFF4CAF50) 
                    : const Color(0xFFF44336),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                '${status.displayName} All',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processBulkRequests(LeaveStatus status, String comment) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final futures = _selectedRequests.map((leaveID) => 
        _leaveService.updateLeaveStatus(
          leaveID: leaveID,
          status: status,
          comment: comment.isNotEmpty ? comment : null,
        )
      );

      await Future.wait(futures);

      if (mounted) {
        setState(() {
          _selectedRequests.clear();
          _isSelectMode = false;
          _cachedRequests = null;
        });

        _showSnackBar(
          'All selected requests ${status.displayName.toLowerCase()} successfully',
          status == LeaveStatus.approved ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error processing requests: $e', const Color(0xFFF44336));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Widget _buildDocumentPreviewCard(LeaveDoc document) {
    Color statusColor = document.isAvailable 
        ? Colors.green 
        : document.isFailed 
            ? Colors.red 
            : Colors.orange;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _viewDocumentFullScreen(document),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: statusColor.withOpacity(0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview area with hover effect
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Stack(
                    children: [
                      _buildDocumentPreview(document),
                      // Add a subtle overlay to indicate it's clickable
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      // View icon overlay
                      if (document.isAvailable)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.visibility,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Document info with better styling
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.docName ?? 'Unknown',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D3748),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _formatFileSize(document.fileSize ?? 0),
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                document.isAvailable 
                                    ? Icons.check_circle 
                                    : document.isFailed 
                                        ? Icons.error 
                                        : Icons.upload,
                                size: 8,
                                color: statusColor,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                document.isAvailable 
                                    ? 'Ready' 
                                    : document.isFailed 
                                        ? 'Failed' 
                                        : 'Processing',
                                style: GoogleFonts.poppins(
                                  fontSize: 7,
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentPreview(LeaveDoc document) {
    if (!document.isAvailable) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              document.isFailed ? Icons.error : Icons.upload_file,
              size: 32,
              color: document.isFailed ? Colors.red : Colors.orange,
            ),
            const SizedBox(height: 8),
            Text(
              document.isFailed ? 'Failed' : 'Processing...',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: document.isFailed ? Colors.red : Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Show file type icon for available documents
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getFileIcon(document.docName ?? ''),
            size: 32,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 4),
          Text(
            _getFileExtension(document.docName ?? '').toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = _getFileExtension(fileName).toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getFileExtension(String fileName) {
    if (fileName.isEmpty) return '';
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last : '';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _viewDocumentFullScreen(LeaveDoc document) {
    if (document.isAvailable && document.docURL != null) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => DocumentViewer(document: document),
      );
    } else if (document.isFailed) {
      _showSnackBar(
        'Document upload failed: ${document.error ?? 'Unknown error'}', 
        Colors.red
      );
    } else {
      _showSnackBar(
        'Document is still processing, please wait...', 
        Colors.orange
      );
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                color == const Color(0xFF4CAF50) ? Icons.check_circle : Icons.error,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: CustomAppBar(
        title: 'Student Leave Requests',
        actions: [
          if (_isSelectMode) ...[
            IconButton(
              onPressed: () => _bulkAction(LeaveStatus.approved),
              icon: const Icon(Icons.check_circle_outline),
              tooltip: 'Approve Selected',
            ),
            IconButton(
              onPressed: () => _bulkAction(LeaveStatus.rejected),
              icon: const Icon(Icons.cancel_outlined),
              tooltip: 'Reject Selected',
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _isSelectMode = false;
                  _selectedRequests.clear();
                });
              },
              icon: const Icon(Icons.close),
              tooltip: 'Cancel Selection',
            ),
          ] else ...[
            IconButton(
              onPressed: () {
                setState(() {
                  _isSelectMode = true;
                });
              },
              icon: const Icon(Icons.checklist),
              tooltip: 'Select Multiple',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Requests List
          Expanded(
            child: _isSelectMode && _cachedRequests != null
                ? _buildCachedRequestsList(_cachedRequests!)
                : StreamBuilder<List<LeaveRequest>>(
                    stream: _leaveService.getAllRequestsForFiltering(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return _buildErrorState(snapshot.error.toString());
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildLoadingState();
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return _buildEmptyState();
                      }

                      final allRequests = snapshot.data!;
                      
                      // Filter pending requests in memory to avoid composite index
                      final pendingRequests = allRequests
                          .where((r) => r.status == LeaveStatus.pending)
                          .toList();
                      
                      // Sort by creation date (newest first) in memory
                      pendingRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                      
                      // Cache the requests when entering select mode
                      if (_isSelectMode && _cachedRequests == null) {
                        _cachedRequests = pendingRequests;
                      }

                      if (pendingRequests.isEmpty) {
                        return _buildEmptyState();
                      }

                      return _buildRequestsList(pendingRequests);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF44336).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: Color(0xFFF44336),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading requests',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: GoogleFonts.poppins(
                color: const Color(0xFF6B7280),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() {}),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.1),
                  const Color(0xFF764BA2).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading requests...',
            style: GoogleFonts.poppins(
              color: const Color(0xFF6B7280),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4CAF50).withOpacity(0.1),
                  const Color(0xFF8BC34A).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 48,
              color: Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Pending Requests',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All leave requests have been processed',
            style: GoogleFonts.poppins(
              color: const Color(0xFF6B7280),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCachedRequestsList(List<LeaveRequest> requests) {
    return _buildRequestsList(requests);
  }

  Widget _buildRequestsList(List<LeaveRequest> requests) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final leave = requests[index];
        final isSelected = _selectedRequests.contains(leave.leaveID);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected 
                  ? AppTheme.primaryColor 
                  : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _isSelectMode
                  ? () {
                      setState(() {
                        if (isSelected) {
                          _selectedRequests.remove(leave.leaveID);
                        } else {
                          _selectedRequests.add(leave.leaveID);
                        }
                      });
                    }
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        if (_isSelectMode)
                          Container(
                            margin: const EdgeInsets.only(right: 16),
                            child: Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : const Color(0xFF9CA3AF),
                              size: 24,
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF9800).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.schedule,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'PENDING',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Flexible(
                          child: Text(
                            DateFormat('MMM dd, yyyy').format(leave.createdAt),
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF6B7280),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Student Info
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor.withOpacity(0.1),
                                const Color(0xFF764BA2).withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: Color(0xFF667EEA),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Student ID',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF6B7280),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                leave.studentID,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2D3748),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF2196F3).withOpacity(0.1),
                                  const Color(0xFF03DAC6).withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF2196F3).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  leave.leaveType.emoji, 
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    leave.leaveType.displayName,
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF2196F3),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Leave Period
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF7FAFC), Color(0xFFEDF2F7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined, 
                                      size: 16, 
                                      color: const Color(0xFF6B7280),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Leave Period',
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF6B7280),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${DateFormat('MMM dd').format(leave.startDate)} - ${DateFormat('MMM dd, yyyy').format(leave.endDate)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2D3748),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '${leave.durationInDays} ${leave.durationInDays == 1 ? 'day' : 'days'}',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Reason (only show if not null and not empty)
                    if (leave.reason != null && leave.reason!.trim().isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.notes_outlined, 
                                size: 16, 
                                color: const Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Reason',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF6B7280),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              leave.reason!,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                height: 1.5,
                                color: const Color(0xFF2D3748),
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Documents Section with Previews
                    StreamBuilder<List<LeaveDoc>>(
                      stream: _leaveService.getLeaveDocuments(leave.leaveID),
                      builder: (context, docSnapshot) {
                        if (docSnapshot.hasData && docSnapshot.data!.isNotEmpty) {
                          final documents = docSnapshot.data!;
                          return Column(
                            children: [
                              const SizedBox(height: 16),
                              _buildDocumentsSectionWithPreviews(documents),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    // Action Buttons
                    if (!_isSelectMode) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isProcessing 
                                  ? null 
                                  : () => _showCommentDialog(leave, LeaveStatus.rejected),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFF44336),
                                side: const BorderSide(
                                  color: Color(0xFFF44336),
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.close, size: 18),
                              label: Text(
                                'Reject',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isProcessing 
                                  ? null 
                                  : () => _showCommentDialog(leave, LeaveStatus.approved),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.check, size: 18),
                              label: Text(
                                'Approve',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDocumentsSectionWithPreviews(List<LeaveDoc> documents) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.attach_file_outlined,
              size: 16,
              color: const Color(0xFF2196F3),
            ),
            const SizedBox(width: 8),
            Text(
              'Attached Documents',
              style: GoogleFonts.poppins(
                color: const Color(0xFF6B7280),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${documents.length}',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF2196F3),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Document previews in a scrollable horizontal list
        Container(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: documents.length,
            itemBuilder: (context, index) {
              return Container(
                width: 140,
                margin: EdgeInsets.only(
                  right: index < documents.length - 1 ? 12 : 0,
                ),
                child: _buildDocumentPreviewCard(documents[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

