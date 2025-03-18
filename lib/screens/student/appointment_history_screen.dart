import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_connect/models/appointment_model.dart';
import 'package:campus_connect/providers/appointment_provider.dart';
import 'package:campus_connect/widgets/button_widget.dart';

class AppointmentHistoryScreen extends StatefulWidget {
  const AppointmentHistoryScreen({Key? key}) : super(key: key);

  @override
  State<AppointmentHistoryScreen> createState() =>
      _AppointmentHistoryScreenState();
}

class _AppointmentHistoryScreenState extends State<AppointmentHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAppointments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    final appointmentProvider =
        Provider.of<AppointmentProvider>(context, listen: false);
    await appointmentProvider.fetchStudentAppointments();
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    final reasonController = TextEditingController();

    final reason = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to cancel this appointment?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (reason != null) {
      final appointmentProvider =
          Provider.of<AppointmentProvider>(context, listen: false);
      final success = await appointmentProvider.cancelAppointment(
        appointmentId,
        reason: reason.isNotEmpty ? reason : null,
      );

      if (success) {
        _showSnackBar('Appointment cancelled successfully');
      } else {
        _showSnackBar(
            appointmentProvider.error ?? 'Failed to cancel appointment');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointmentProvider = Provider.of<AppointmentProvider>(context);
    final upcomingAppointments = appointmentProvider.getUpcomingAppointments();
    final pastAppointments = appointmentProvider.getPastAppointments();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: appointmentProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : appointmentProvider.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: ${appointmentProvider.error}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAppointments,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAppointmentList(upcomingAppointments,
                        isUpcoming: true),
                    _buildAppointmentList(pastAppointments, isUpcoming: false),
                  ],
                ),
    );
  }

  Widget _buildAppointmentList(List<AppointmentModel> appointments,
      {required bool isUpcoming}) {
    return appointments.isEmpty
        ? Center(
            child: Text(
              isUpcoming ? 'No upcoming appointments' : 'No past appointments',
              style: const TextStyle(fontSize: 16),
            ),
          )
        : RefreshIndicator(
            onRefresh: _loadAppointments,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appointment = appointments[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.2),
                              child: Text(
                                appointment.facultyName.isNotEmpty
                                    ? appointment.facultyName[0].toUpperCase()
                                    : 'F',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appointment.facultyName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Date: ${appointment.date.toString().split(' ')[0]}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(appointment.status)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                appointment.status.capitalize(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getStatusColor(appointment.status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Time: ${appointment.startTime} - ${appointment.endTime}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Purpose: ${appointment.purpose}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        if (appointment.status == 'rejected' &&
                            appointment.cancelReason != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Reason: ${appointment.cancelReason}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.red,
                            ),
                          ),
                        ],
                        if (appointment.status == 'accepted' && isUpcoming) ...[
                          const SizedBox(height: 16),
                          ButtonWidget(
                            text: 'Cancel Appointment',
                            onPressed: () => _cancelAppointment(appointment.id),
                            backgroundColor: Colors.red,
                            isOutlined: true,
                            width: double.infinity,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
