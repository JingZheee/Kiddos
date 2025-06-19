import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:go_router/go_router.dart';

import '../../../core/services/take_leave_service.dart';
import '../../../models/leave/leave_request_model.dart';
import '../../../models/leave/leave_doc_model.dart';
import '../../../widgets/document_viewer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/custom_app_bar.dart';

class ParentLeaveScreen extends StatefulWidget {
  const ParentLeaveScreen({Key? key}) : super(key: key);

  @override
  State<ParentLeaveScreen> createState() => _ParentLeaveScreenState();
}

class _ParentLeaveScreenState extends State<ParentLeaveScreen> {
  final TakeLeaveService _leaveService = TakeLeaveService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  String _selectedFilterStatus = 'all';
  String _searchQuery = '';
  final Map<String, bool> _expandedDocuments = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<LeaveRequest>>(
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
                
                // Filter by current user's requests
                final userRequests = allRequests
                    .where((request) => request.parentID == _currentUser!.uid)
                    .toList();

                if (userRequests.isEmpty) {
                  return _buildEmptyState();
                }

                return Column(
                  children: [
                    _buildSearchBar(),
                    _buildFilterChips(userRequests),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _buildRequestsList(_filterRequests(userRequests)),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return CustomAppBar(
      title: 'Leave Requests',
      userRole: 'parent',
      actions: [
        IconButton(
          onPressed: () => context.pushNamed('parent-request-leave'),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 20,
            ),
          ),
          tooltip: 'Request Leave',
        ),
      ],
    );
  }


  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search by student ID or leave type...',
          hintStyle: GoogleFonts.poppins(
            color: const Color(0xFF9CA3AF),
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF6B7280),
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Color(0xFF6B7280), size: 18),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        style: GoogleFonts.poppins(fontSize: 13),
      ),
    );
  }

  Widget _buildFilterChips(List<LeaveRequest> allRequests) {
    final statusCounts = <String, int>{
      'all': allRequests.length,
      'pending': allRequests.where((r) => r.status == LeaveStatus.pending).length,
      'approved': allRequests.where((r) => r.status == LeaveStatus.approved).length,
      'rejected': allRequests.where((r) => r.status == LeaveStatus.rejected).length,
      'cancelled': allRequests.where((r) => r.status == LeaveStatus.cancelled).length,
    };

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', 'all', statusCounts['all'] ?? 0),
            const SizedBox(width: 6),
            _buildFilterChip('Pending', 'pending', statusCounts['pending'] ?? 0),
            const SizedBox(width: 6),
            _buildFilterChip('Approved', 'approved', statusCounts['approved'] ?? 0),
            const SizedBox(width: 6),
            _buildFilterChip('Rejected', 'rejected', statusCounts['rejected'] ?? 0),
            const SizedBox(width: 6),
            _buildFilterChip('Cancelled', 'cancelled', statusCounts['cancelled'] ?? 0),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _selectedFilterStatus == value;
    Color chipColor;
    Color textColor;

    switch (value) {
      case 'pending':
        chipColor = isSelected ? const Color(0xFFFF9800) : const Color(0xFFFF9800).withOpacity(0.1);
        textColor = isSelected ? Colors.white : const Color(0xFFFF9800);
        break;
      case 'approved':
        chipColor = isSelected ? const Color(0xFF4CAF50) : const Color(0xFF4CAF50).withOpacity(0.1);
        textColor = isSelected ? Colors.white : const Color(0xFF4CAF50);
        break;
      case 'rejected':
        chipColor = isSelected ? const Color(0xFFF44336) : const Color(0xFFF44336).withOpacity(0.1);
        textColor = isSelected ? Colors.white : const Color(0xFFF44336);
        break;
      case 'cancelled':
        chipColor = isSelected ? const Color(0xFF9E9E9E) : const Color(0xFF9E9E9E).withOpacity(0.1);
        textColor = isSelected ? Colors.white : const Color(0xFF9E9E9E);
        break;
      default:
        chipColor = isSelected ?  AppTheme.primaryColor :  AppTheme.primaryColor.withOpacity(0.1);
        textColor = isSelected ? Colors.white :  AppTheme.primaryColor;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilterStatus = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: chipColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: textColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                count.toString(),
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<LeaveRequest> _filterRequests(List<LeaveRequest> requests) {
    List<LeaveRequest> filteredRequests = requests;

    // Filter by status
    if (_selectedFilterStatus != 'all') {
      final status = LeaveStatus.values.firstWhere(
        (s) => s.name == _selectedFilterStatus,
        orElse: () => LeaveStatus.pending,
      );
      filteredRequests = filteredRequests.where((r) => r.status == status).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filteredRequests = filteredRequests.where((request) {
        return request.studentID.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               request.leaveType.displayName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Sort by creation date (newest first)
    filteredRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return filteredRequests;
  }

  Widget _buildRequestsList(List<LeaveRequest> requests) {
    if (requests.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        return _buildRequestCard(requests[index]);
      },
    );
  }

  Widget _buildRequestCard(LeaveRequest request) {
    Color statusColor;
    IconData statusIcon;
    
    switch (request.status) {
      case LeaveStatus.pending:
        statusColor = const Color(0xFFFF9800);
        statusIcon = Icons.schedule;
        break;
      case LeaveStatus.approved:
        statusColor = const Color(0xFF4CAF50);
        statusIcon = Icons.check_circle;
        break;
      case LeaveStatus.rejected:
        statusColor = const Color(0xFFF44336);
        statusIcon = Icons.cancel;
        break;
      case LeaveStatus.cancelled:
        statusColor = const Color(0xFF9E9E9E);
        statusIcon = Icons.block;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row with Cancel Button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        request.status.displayName.toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Add Cancel Button for Pending Requests
                if (request.status == LeaveStatus.pending) ...[
                  TextButton(
                    onPressed: () => _showCancelDialog(request),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFF44336),
                      backgroundColor: const Color(0xFFF44336).withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: const Color(0xFFF44336).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF44336),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  DateFormat('MMM dd, yyyy').format(request.createdAt),
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

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
                    color: AppTheme.primaryColor,
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
                        request.studentID,
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
                Container(
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
                        request.leaveType.emoji,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        request.leaveType.displayName,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF2196F3),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Leave Period
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
                        const SizedBox(height: 6),
                        Text(
                          '${DateFormat('MMM dd').format(request.startDate)} - ${DateFormat('MMM dd, yyyy').format(request.endDate)}',
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryColor, Color(0xFF764BA2)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color:  AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${request.durationInDays} ${request.durationInDays == 1 ? 'day' : 'days'}',
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

            // Reason (optional field)
            if (request.reason != null && request.reason!.isNotEmpty) ...[
              const SizedBox(height: 16),
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      request.reason!,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        height: 1.4,
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
              stream: _leaveService.getLeaveDocuments(request.leaveID),
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

            // Comment section (if rejected, approved, or cancelled with comment)
            if (request.comment != null && request.comment!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.comment_outlined,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          request.status == LeaveStatus.cancelled 
                              ? 'Cancellation Note'
                              : 'Review Comment',
                          style: GoogleFonts.poppins(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      request.comment!,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF2D3748),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
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

  Widget _buildDocumentPreviewCard(LeaveDoc document) {
    Color statusColor = document.isAvailable 
        ? Colors.green 
        : document.isFailed 
            ? Colors.red 
            : Colors.orange;

    return GestureDetector(
      onTap: () => _viewDocumentFullScreen(document),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: statusColor.withOpacity(0.2),
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
            // Preview area
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
                child: _buildDocumentPreview(document),
              ),
            ),
            
            // Document info
            Padding(
              padding: const EdgeInsets.all(8),
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
                        child: Icon(
                          document.isAvailable 
                              ? Icons.check_circle 
                              : document.isFailed 
                                  ? Icons.error 
                                  : Icons.upload,
                          size: 10,
                          color: statusColor,
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
    );
  }

  Widget _buildDocumentPreview(LeaveDoc document) {
    if (!document.isAvailable) {
      return _buildPreviewPlaceholder(document);
    }

    final extension = _getFileExtension(document.docName ?? '').toLowerCase();

    // Handle data URLs (Base64)
    if (document.docURL?.startsWith('data:') == true) {
      return _buildDataUrlPreview(document);
    }

    // Handle different file types
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return _buildImagePreview(document);
      case 'pdf':
        return _buildPdfPreview();
      case 'doc':
      case 'docx':
        return _buildWordPreview();
      case 'txt':
        return _buildTextPreview();
      default:
        return _buildGenericPreview(document);
    }
  }

  Widget _buildDataUrlPreview(LeaveDoc document) {
    try {
      final dataUrl = document.docURL!;
      final parts = dataUrl.split(',');
      
      if (parts.length != 2) {
        return _buildPreviewPlaceholder(document);
      }

      final mimeType = parts[0].split(':')[1].split(';')[0];
      
      if (mimeType.startsWith('image/')) {
        final base64Data = parts[1];
        final bytes = base64Decode(base64Data);
        
        return Container(
          width: double.infinity,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildPreviewPlaceholder(document);
              },
            ),
          ),
        );
      } else {
        return _buildGenericPreview(document);
      }
    } catch (e) {
      return _buildPreviewPlaceholder(document);
    }
  }

  Widget _buildImagePreview(LeaveDoc document) {
    return Container(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        child: Image.network(
          document.docURL!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildPreviewPlaceholder(document);
          },
        ),
      ),
    );
  }

  Widget _buildPdfPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf,
            size: 40,
            color: const Color(0xFFF44336),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Container(
                  height: 15,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      children: [
                        Container(
                          height: 3,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          height: 3,
                          width: double.infinity * 0.8,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          height: 3,
                          width: double.infinity * 0.6,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description,
            size: 40,
            color: const Color(0xFF2196F3),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 60,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  height: 4,
                  width: double.infinity * 0.8,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  height: 4,
                  width: double.infinity * 0.6,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.text_snippet,
            size: 40,
            color: const Color(0xFF9C27B0),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 60,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: List.generate(8, (index) => 
                Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  height: 2,
                  width: double.infinity * (index % 2 == 0 ? 1 : 0.7),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericPreview(LeaveDoc document) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getDocumentIcon(document.docName ?? ''),
            size: 40,
            color: _getDocumentColor(document.docName ?? ''),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getDocumentColor(document.docName ?? '').withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _getFileExtension(document.docName ?? '').toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _getDocumentColor(document.docName ?? ''),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewPlaceholder(LeaveDoc document) {
    Color statusColor = document.isFailed ? Colors.red : Colors.grey;
    IconData statusIcon = document.isFailed ? Icons.error : Icons.description;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            statusIcon,
            size: 40,
            color: statusColor,
          ),
          const SizedBox(height: 8),
          Text(
            document.isFailed ? 'Failed' : 'Loading...',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  void _viewDocumentFullScreen(LeaveDoc document) {
    if (document.isAvailable) {
      showDialog(
        context: context,
        builder: (context) => DocumentViewer(document: document),
      );
    } else if (document.isFailed) {
      _showSnackBar('Document upload failed: ${document.error ?? 'Unknown error'}', Colors.red);
    } else {
      _showSnackBar('Document is still processing', Colors.orange);
    }
  }

  void _showCancelDialog(LeaveRequest request) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF44336).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.warning_outlined,
                  color: const Color(0xFFF44336),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Cancel Request',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to cancel this leave request?',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF4A5568),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request Details:',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Student: ${request.studentID}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                    Text(
                      'Period: ${DateFormat('MMM dd').format(request.startDate)} - ${DateFormat('MMM dd, yyyy').format(request.endDate)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                    Text(
                      'Type: ${request.leaveType.displayName}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFE69C)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outlined,
                      color: const Color(0xFF856404),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This action cannot be undone. You will need to submit a new request if needed.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF856404),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Keep Request',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelRequest(request);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF44336),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Cancel Request',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelRequest(LeaveRequest request) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      'Cancelling request...',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Cancel the request
      await _leaveService.cancelLeaveRequest(request.leaveID);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        _showSnackBar('Leave request cancelled successfully', const Color(0xFF4CAF50));
      }

    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error message
      if (mounted) {
        _showSnackBar('Error cancelling request: $e', const Color(0xFFF44336));
      }
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading requests...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading requests',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.red[500],
            ),
            textAlign: TextAlign.center,
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
          Icon(
            Icons.description_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No leave requests found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Submit your first leave request to see it here.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getFileExtension(String docName) {
    if (docName.isEmpty) return '';
    final parts = docName.split('.');
    return parts.length > 1 ? parts.last : '';
  }

  IconData _getDocumentIcon(String docName) {
    final extension = _getFileExtension(docName).toLowerCase();
    switch (extension) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'doc':
      case 'docx': return Icons.description;
      case 'txt': return Icons.text_snippet;
      case 'xls':
      case 'xlsx': return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp': return Icons.image;
      default: return Icons.insert_drive_file;
    }
  }

  Color _getDocumentColor(String docName) {
    final extension = _getFileExtension(docName).toLowerCase();
    switch (extension) {
      case 'pdf': return const Color(0xFFF44336);
      case 'doc':
      case 'docx': return const Color(0xFF2196F3);
      case 'txt': return const Color(0xFF9C27B0);
      case 'xls':
      case 'xlsx': return const Color(0xFF4CAF50);
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp': return const Color(0xFF4CAF50);
      default: return const Color(0xFF607D8B);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}