import 'package:flutter/material.dart';

class DateRangePickerWidget extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime?) onStartDateChanged;
  final Function(DateTime?) onEndDateChanged;

  const DateRangePickerWidget({
    super.key,
    this.startDate,
    this.endDate,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
  });

  @override
  State<DateRangePickerWidget> createState() => _DateRangePickerWidgetState();
}

class _DateRangePickerWidgetState extends State<DateRangePickerWidget> {
  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select Start Date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      widget.onStartDateChanged(picked);
      
      // If end date is before start date, clear it
      if (widget.endDate != null && widget.endDate!.isBefore(picked)) {
        widget.onEndDateChanged(null);
      }
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime firstDate = widget.startDate ?? DateTime.now();
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.endDate ?? firstDate.add(const Duration(days: 7)),
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select End Date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      widget.onEndDateChanged(picked);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select Date';
    return '${date.day}/${date.month}/${date.year}';
  }

  int _getDaysDifference() {
    if (widget.startDate == null || widget.endDate == null) return 0;
    return widget.endDate!.difference(widget.startDate!).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Survey Duration',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start Date',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectStartDate,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: widget.startDate != null 
                                ? Theme.of(context).primaryColor 
                                : Colors.grey.shade500,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _formatDate(widget.startDate),
                            style: TextStyle(
                              color: widget.startDate != null 
                                  ? Colors.black87 
                                  : Colors.grey.shade500,
                              fontWeight: widget.startDate != null 
                                  ? FontWeight.w500 
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'End Date',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: widget.startDate != null ? _selectEndDate : null,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: widget.startDate != null 
                              ? Colors.grey.shade300 
                              : Colors.grey.shade200,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: widget.startDate != null 
                            ? Colors.white 
                            : Colors.grey.shade50,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: widget.endDate != null 
                                ? Theme.of(context).primaryColor 
                                : Colors.grey.shade400,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            widget.startDate != null 
                                ? _formatDate(widget.endDate) 
                                : 'Select start date first',
                            style: TextStyle(
                              color: widget.startDate != null 
                                  ? (widget.endDate != null ? Colors.black87 : Colors.grey.shade500)
                                  : Colors.grey.shade400,
                              fontWeight: widget.endDate != null 
                                  ? FontWeight.w500 
                                  : FontWeight.normal,
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
        const SizedBox(height: 16),
        if (widget.startDate != null && widget.endDate != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Survey Duration: ${_getDaysDifference()} days',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'From ${_formatDate(widget.startDate)} to ${_formatDate(widget.endDate)}',
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else if (widget.startDate != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_outlined,
                  color: Colors.orange.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please select an end date to complete the survey duration',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Select start and end dates for your survey',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        // Quick duration buttons
        Text(
          'Quick Duration',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildQuickDurationButton('1 Day', 1),
            _buildQuickDurationButton('3 Days', 3),
            _buildQuickDurationButton('1 Week', 7),
            _buildQuickDurationButton('2 Weeks', 14),
            _buildQuickDurationButton('1 Month', 30),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickDurationButton(String label, int days) {
    return OutlinedButton(
      onPressed: () {
        final now = DateTime.now();
        final startDate = DateTime(now.year, now.month, now.day);
        final endDate = startDate.add(Duration(days: days));
        
        widget.onStartDateChanged(startDate);
        widget.onEndDateChanged(endDate);
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}
