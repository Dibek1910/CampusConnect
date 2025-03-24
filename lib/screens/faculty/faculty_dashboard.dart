import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_connect/config/route.dart';
import 'package:campus_connect/models/appointment_model.dart';
import 'package:campus_connect/providers/auth_provider.dart';
import 'package:campus_connect/providers/faculty_provider.dart';
import 'package:campus_connect/widgets/button_widget.dart';

class FacultyDashboardScreen extends StatefulWidget {
  const FacultyDashboardScreen({Key? key}) : super(key: key);

  @override
  State<FacultyDashboardScreen> createState() => _FacultyDashboardScreenState();
}

class _FacultyDashboardScreenState extends State<FacultyDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    setState(() {
      _isLoading = true;
    });

    try {
      final facultyProvider =
          Provider.of<FacultyProvider>(context, listen: false);
      await facultyProvider.fetchFacultyAppointments();
    } catch (e) {
      print('Error loading appointments: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.logout();

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // Use pushNamedAndRemoveUntil to clear the navigation stack
      Navigator.of(context).pushNamedAndRemoveUntil(
          AppRouter.roleSelectionRoute, (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.error ?? 'Logout failed')),
      );
    }
  }

  Future<void> _updateAppointmentStatus(String appointmentId, String status,
      {String? reason}) async {
    final facultyProvider =
        Provider.of<FacultyProvider>(context, listen: false);
    final success = await facultyProvider.updateAppointmentStatus(
      appointmentId,
      status,
      reason: reason,
    );

    if (success) {
      _showSnackBar('Appointment $status successfully');
    } else {
      _showSnackBar(
          facultyProvider.error ?? 'Failed to update appointment status');
    }
  }

  void _showRejectDialog(String appointmentId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Enter reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateAppointmentStatus(
                appointmentId,
                'rejected',
                reason: reasonController.text,
              );
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _navigateToAppointmentRequests() {
    Navigator.of(context).pushNamed(AppRouter.appointmentRequestsRoute);
  }

  void _navigateToManageAvailability() {
    Navigator.of(context).pushNamed(AppRouter.availabilityManagementRoute);
  }

  void _navigateToProfile() {
    Navigator.of(context).pushNamed(AppRouter.facultyProfileRoute);
  }

  List<AppointmentModel> _filterAppointments(String status) {
    final facultyProvider = Provider.of<FacultyProvider>(context);
    return facultyProvider.appointments
        .where((appointment) => appointment.status == status)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final facultyProvider = Provider.of<FacultyProvider>(context);
    final facultyProfile = authProvider.facultyProfile;

    // Get department name correctly
    String departmentName = '';
    if (facultyProfile != null && facultyProfile.department != null) {
      if (facultyProfile.department is Map) {
        departmentName = facultyProfile.department['name'] ?? '';
      } else {
        departmentName = facultyProfile.department.toString();
      }
    }

    // Count pending appointments for badge
    final pendingAppointments = _filterAppointments('pending');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty Dashboard'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: _navigateToAppointmentRequests,
                tooltip: 'Appointment Requests',
              ),
              if (pendingAppointments.isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${pendingAppointments.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _navigateToProfile,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Accepted'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (facultyProfile != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${facultyProfile.name}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Department: $departmentName',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _navigateToManageAvailability,
                            icon: const Icon(Icons.schedule),
                            label: const Text('Manage Availability'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: facultyProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : facultyProvider.error != null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Error: ${facultyProvider.error}',
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
                                  _buildAppointmentList('pending'),
                                  _buildAppointmentList('accepted'),
                                  _buildAppointmentList('rejected'),
                                ],
                              ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAppointmentList(String status) {
    final appointments = _filterAppointments(status);

    return appointments.isEmpty
        ? Center(
            child: Text(
              'No $status appointments',
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
                                appointment.studentName.isNotEmpty
                                    ? appointment.studentName[0].toUpperCase()
                                    : 'S',
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
                                    appointment.studentName,
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
                            'Rejection Reason: ${appointment.cancelReason}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.red,
                            ),
                          ),
                        ],
                        if (appointment.status == 'pending') ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ButtonWidget(
                                  text: 'Accept',
                                  onPressed: () => _updateAppointmentStatus(
                                    appointment.id,
                                    'accepted',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ButtonWidget(
                                  text: 'Reject',
                                  onPressed: () =>
                                      _showRejectDialog(appointment.id),
                                  backgroundColor: Colors.red,
                                ),
                              ),
                            ],
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
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
