import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_connect/providers/appointment_provider.dart';
import 'package:campus_connect/widgets/button_widget.dart';
import 'package:campus_connect/widgets/input_field.dart';

class BookAppointmentScreen extends StatefulWidget {
  final String facultyId;
  final String facultyName;
  final String availabilityId;
  final String day;
  final DateTime date;
  final String startTime;
  final String endTime;

  const BookAppointmentScreen({
    Key? key,
    required this.facultyId,
    required this.facultyName,
    required this.availabilityId,
    required this.day,
    required this.date,
    required this.startTime,
    required this.endTime,
  }) : super(key: key);

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _purposeController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _purposeController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _bookAppointment() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      final appointmentProvider =
          Provider.of<AppointmentProvider>(context, listen: false);

      final appointmentData = {
        'facultyId': widget.facultyId,
        'availabilityId': widget.availabilityId,
        'date': widget.date.toIso8601String(),
        'purpose': _purposeController.text,
      };

      final success =
          await appointmentProvider.bookAppointment(appointmentData);

      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorSnackBar(
            appointmentProvider.error ?? 'Failed to book appointment');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Appointment Booked'),
        content: const Text(
          'Your appointment request has been sent to the faculty. You will be notified once it is approved or rejected.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to faculty detail
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointmentProvider = Provider.of<AppointmentProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                margin: const EdgeInsets.only(bottom: 24),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Appointment Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow('Faculty', widget.facultyName),
                      _buildDetailRow('Date', _formatDate(widget.date)),
                      _buildDetailRow('Day', widget.day),
                      _buildDetailRow(
                          'Time', '${widget.startTime} - ${widget.endTime}'),
                    ],
                  ),
                ),
              ),
              InputField(
                label: 'Purpose of Appointment',
                hint: 'Briefly describe the purpose of your appointment',
                controller: _purposeController,
                maxLines: 5,
                minLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the purpose of your appointment';
                  }
                  if (value.length < 10) {
                    return 'Purpose should be at least 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ButtonWidget(
                text: 'Book Appointment',
                onPressed: _bookAppointment,
                isLoading: _isSubmitting,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
