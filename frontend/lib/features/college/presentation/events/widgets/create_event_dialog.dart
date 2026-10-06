import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/theme/app_theme.dart';

class CreateEventDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onEventCreated;
  final Map<String, dynamic>? initialData;

  const CreateEventDialog({
    super.key,
    required this.onEventCreated,
    this.initialData,
  });

  @override
  State<CreateEventDialog> createState() => _CreateEventDialogState();
}

class _CreateEventDialogState extends State<CreateEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _venueController = TextEditingController();
  final _maxParticipantsController = TextEditingController();

  String _selectedType = 'hackathon';
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isOnline = false;
  bool _requiresRegistration = true;
  bool _provideCertificate = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      final data = widget.initialData!;
      _titleController.text = data['title'] ?? '';
      _descriptionController.text = data['description'] ?? '';
      _selectedType = data['event_type'] ?? 'hackathon';
      _isOnline = data['is_online'] == true;
      _venueController.text = _isOnline ? '' : (data['venue'] ?? '');
      _maxParticipantsController.text = (data['max_participants'] ?? 0)
          .toString();
      _requiresRegistration = data['requires_approval'] == true;
      _provideCertificate = data['provide_certificate'] == true;

      if (data['start_date'] != null) {
        final start = DateTime.parse(data['start_date']);
        _startDate = start;
        _startTime = TimeOfDay.fromDateTime(start);
      }
      if (data['end_date'] != null) {
        final end = DateTime.parse(data['end_date']);
        _endDate = end;
        _endTime = TimeOfDay.fromDateTime(end);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.initialData != null
                      ? 'Edit Event'
                      : 'Create New Event',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event Type
                      Text(
                        'Event Type',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedType,
                            isExpanded: true,
                            items:
                                [
                                  {
                                    'value': 'hackathon',
                                    'label': '🏆 Hackathon',
                                  },
                                  {'value': 'workshop', 'label': '🔧 Workshop'},
                                  {
                                    'value': 'guest_lecture',
                                    'label': '🎤 Guest Lecture',
                                  },
                                  {
                                    'value': 'competition',
                                    'label': '🏅 Competition',
                                  },
                                  {'value': 'seminar', 'label': '📚 Seminar'},
                                  {'value': 'webinar', 'label': '💻 Webinar'},
                                ].map((item) {
                                  return DropdownMenuItem<String>(
                                    value: item['value'],
                                    child: Text(item['label']!),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedType = value!);
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Event Title
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Event Title',
                          hintText: 'Enter event title',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter event title';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Describe your event',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter event description';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Date and Time
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start Date & Time',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: _selectStartDate,
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            _startDate != null
                                                ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                                : 'Select Date',
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: InkWell(
                                        onTap: _selectStartTime,
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            _startTime != null
                                                ? _startTime!.format(context)
                                                : 'Select Time',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
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
                                  'End Date & Time',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: _selectEndDate,
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            _endDate != null
                                                ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                                : 'Select Date',
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: InkWell(
                                        onTap: _selectEndTime,
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            _endTime != null
                                                ? _endTime!.format(context)
                                                : 'Select Time',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Online/Offline Toggle
                      Row(
                        children: [
                          Switch(
                            value: _isOnline,
                            onChanged: (value) {
                              setState(() => _isOnline = value);
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isOnline ? 'Online Event' : 'Offline Event',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Venue (if offline)
                      if (!_isOnline) ...[
                        TextFormField(
                          controller: _venueController,
                          decoration: const InputDecoration(
                            labelText: 'Venue',
                            hintText: 'Enter venue location',
                          ),
                          validator: (value) {
                            if (!_isOnline &&
                                (value == null || value.isEmpty)) {
                              return 'Please enter venue';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Max Participants
                      TextFormField(
                        controller: _maxParticipantsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Maximum Participants',
                          hintText: 'Enter max number of participants',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter max participants';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Additional Options
                      CheckboxListTile(
                        title: const Text('Requires Registration'),
                        value: _requiresRegistration,
                        onChanged: (value) {
                          setState(() => _requiresRegistration = value!);
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),

                      CheckboxListTile(
                        title: const Text('Provide Certificate'),
                        value: _provideCertificate,
                        onChanged: (value) {
                          setState(() => _provideCertificate = value!);
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: _createEvent,
                  child: Text(
                    widget.initialData != null
                        ? 'Update Event'
                        : 'Create Event',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _startDate = date);
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _endDate = date);
    }
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _startTime = time);
    }
  }

  Future<void> _selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _endTime = time);
    }
  }

  void _createEvent() {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null ||
          _endDate == null ||
          _startTime == null ||
          _endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select all dates and times')),
        );
        return;
      }

      // Combine date and time
      final startDateTime = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );

      final endDateTime = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        _endTime!.hour,
        _endTime!.minute,
      );

      final eventData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'event_type': _selectedType,
        'start_date': startDateTime.toIso8601String(),
        'end_date': endDateTime.toIso8601String(),
        'is_online': _isOnline,
        'venue': _isOnline ? 'Online' : _venueController.text,
        'max_participants': int.parse(_maxParticipantsController.text),
        'requires_approval': _requiresRegistration,
        'provide_certificate': _provideCertificate,
        'status': 'published',
        'is_published': true,
        'created_by': Supabase.instance.client.auth.currentUser?.id,
      };

      widget.onEventCreated(eventData);
      Navigator.pop(context);
    }
  }
}
