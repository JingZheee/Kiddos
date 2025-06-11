import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/take_leave_service.dart';
import 'package:intl/intl.dart';

class ParentLeaveScreen extends StatefulWidget {
  const ParentLeaveScreen({super.key});

  @override
  State<ParentLeaveScreen> createState() => _ParentLeaveScreenState();
}

class _ParentLeaveScreenState extends State<ParentLeaveScreen> {
  final TakeLeaveService _leaveService = TakeLeaveService();
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _dateError;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  bool _validateDates() {
    if (_startDate == null || _endDate == null) {
      setState(() {
        _dateError = 'Both start and end dates are required';
      });
      return false;
    }

    if (_endDate!.isBefore(_startDate!)) {
      setState(() {
        _dateError = 'End date cannot be before start date';
      });
      return false;
    }

    if (_startDate!.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      setState(() {
        _dateError = 'Cannot select past dates';
      });
      return false;
    }

    setState(() {
      _dateError = null;
    });
    return true;
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      selectableDayPredicate: (DateTime date) {
        // Disable weekends
        return date.weekday != DateTime.saturday && 
               date.weekday != DateTime.sunday;
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
        _validateDates();
      });
    }
  }

  Future<void> _submitLeaveRequest() async {
    if (!_validateDates()) {
      return;
    }

    if (_formKey.currentState!.validate()) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _leaveService.submitLeaveRequest(
            studentId: 'student_id',
            parentId: user.uid,
            startDate: _startDate!,
            endDate: _endDate!,
            reason: _reasonController.text.trim(),
          );
          _resetForm();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Leave request submitted successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error submitting leave request: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _resetForm() {
    _reasonController.clear();
    setState(() {
      _startDate = null;
      _endDate = null;
      _dateError = null;
    });
    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Requests'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: const Text('Start Date *'),
                            subtitle: Text(_startDate == null 
                              ? 'Select date' 
                              : DateFormat('MMM dd, yyyy').format(_startDate!)),
                            onTap: () => _selectDate(context, true),
                            trailing: const Icon(Icons.calendar_today),
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: const Text('End Date *'),
                            subtitle: Text(_endDate == null 
                              ? 'Select date' 
                              : DateFormat('MMM dd, yyyy').format(_endDate!)),
                            onTap: () => _selectDate(context, false),
                            trailing: const Icon(Icons.calendar_today),
                          ),
                        ),
                      ],
                    ),
                    if (_dateError != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          _dateError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Reason for Leave *',
                        border: OutlineInputBorder(),
                        hintText: 'Please provide a detailed reason',
                      ),
                      maxLines: 3,
                      maxLength: 500,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a reason';
                        }
                        if (value.trim().length > 500) {
                          return 'Reason cannot exceed 500 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        onPressed: _submitLeaveRequest,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(200, 45),
                        ),
                        child: const Text('Submit Leave Request'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Leave History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: _leaveService.getParentLeaveRequests(user?.uid ?? ''),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No leave requests found',
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final leave = snapshot.data!.docs[index].data() 
                          as Map<String, dynamic>;
                      final startDate = (leave['startDate'] as Timestamp).toDate();
                      final endDate = (leave['endDate'] as Timestamp).toDate();
                      final status = leave['status'] as String;
                      final reason = leave['reason'] as String;
                      final remarks = leave['remarks'] as String?;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ExpansionTile(
                          title: Text(
                            reason,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${DateFormat('MMM dd').format(startDate)} - '
                            '${DateFormat('MMM dd').format(endDate)}',
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Reason: $reason'),
                                  const SizedBox(height: 8),
                                  if (remarks != null) ...[
                                    Text('Remarks: $remarks'),
                                    const SizedBox(height: 8),
                                  ],
                                  Text(
                                    'Duration: ${endDate.difference(startDate).inDays + 1} days',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green.shade100;
      case 'pending':
        return Colors.orange.shade100;
      case 'rejected':
        return Colors.red.shade100;
      case 'cancelled':
        return Colors.grey.shade100;
      default:
        return Colors.grey.shade100;
    }
  }
}