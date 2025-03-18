import 'package:flutter/material.dart';
import 'package:campus_connect/models/availability_model.dart';

class TimeSlotWidget extends StatefulWidget {
  final AvailabilityModel availability;
  final VoidCallback onDelete;
  final Function(Map<String, dynamic>) onUpdate;

  const TimeSlotWidget({
    Key? key,
    required this.availability,
    required this.onDelete,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<TimeSlotWidget> createState() => _TimeSlotWidgetState();
}

class _TimeSlotWidgetState extends State<TimeSlotWidget> {
  bool _isEditing = false;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _startTimeController =
        TextEditingController(text: widget.availability.startTime);
    _endTimeController =
        TextEditingController(text: widget.availability.endTime);
    _isActive = widget.availability.isAvailable;
  }

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _showTimePickerDialog(TextEditingController controller) async {
    // Parse the current time
    final timeParts = controller.text.split(':');
    final initialHour = int.tryParse(timeParts[0]) ?? 9;
    final initialMinute = int.tryParse(timeParts[1]) ?? 0;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      final hour = pickedTime.hour.toString().padLeft(2, '0');
      final minute = pickedTime.minute.toString().padLeft(2, '0');
      controller.text = '$hour:$minute';
    }
  }

  void _saveChanges() {
    // Validate time format
    final RegExp timeRegex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
    if (!timeRegex.hasMatch(_startTimeController.text) ||
        !timeRegex.hasMatch(_endTimeController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter time in HH:MM format')),
      );
      return;
    }

    // Validate end time is after start time
    final startTimeParts = _startTimeController.text.split(':');
    final endTimeParts = _endTimeController.text.split(':');

    final startHour = int.parse(startTimeParts[0]);
    final startMinute = int.parse(startTimeParts[1]);
    final endHour = int.parse(endTimeParts[0]);
    final endMinute = int.parse(endTimeParts[1]);

    if (endHour < startHour ||
        (endHour == startHour && endMinute <= startMinute)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    final slotData = {
      'startTime': _startTimeController.text,
      'endTime': _endTimeController.text,
      'isActive': _isActive,
    };

    widget.onUpdate(slotData);
    setState(() {
      _isEditing = false;
    });
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Slot'),
        content: const Text('Are you sure you want to delete this time slot?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _isEditing
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _startTimeController,
                          decoration: InputDecoration(
                            labelText: 'Start Time',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.access_time),
                              onPressed: () =>
                                  _showTimePickerDialog(_startTimeController),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _endTimeController,
                          decoration: InputDecoration(
                            labelText: 'End Time',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.access_time),
                              onPressed: () =>
                                  _showTimePickerDialog(_endTimeController),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Active:'),
                      Switch(
                        value: _isActive,
                        onChanged: (value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isEditing = false;
                            // Reset to original values
                            _startTimeController.text =
                                widget.availability.startTime;
                            _endTimeController.text =
                                widget.availability.endTime;
                            _isActive = widget.availability.isAvailable;
                          });
                        },
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: _saveChanges,
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.availability.startTime} - ${widget.availability.endTime}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.availability.isAvailable
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.availability.isAvailable
                                  ? 'Active'
                                  : 'Inactive',
                              style: TextStyle(
                                color: widget.availability.isAvailable
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _confirmDelete,
                  ),
                ],
              ),
      ),
    );
  }
}
