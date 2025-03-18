import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_connect/config/route.dart';
import 'package:campus_connect/providers/auth_provider.dart';
import 'package:campus_connect/providers/faculty_provider.dart';
import 'package:campus_connect/providers/appointment_provider.dart';
import 'package:campus_connect/widgets/faculty_card.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({Key? key}) : super(key: key);

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Load faculty list
    await _loadFacultyList();

    // Load student appointments
    final appointmentProvider =
        Provider.of<AppointmentProvider>(context, listen: false);
    await appointmentProvider.fetchStudentAppointments();
  }

  Future<void> _loadFacultyList() async {
    final facultyProvider =
        Provider.of<FacultyProvider>(context, listen: false);
    await facultyProvider.fetchFacultyList();
  }

  Future<void> _searchFaculty(String query) async {
    if (query.isEmpty) {
      await _loadFacultyList();
      return;
    }

    final facultyProvider =
        Provider.of<FacultyProvider>(context, listen: false);
    await facultyProvider.searchFaculty(query);
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    Navigator.of(context).pushReplacementNamed(AppRouter.roleSelectionRoute);
  }

  void _navigateToFacultyDetail(String facultyId, String facultyName) {
    Navigator.of(context).pushNamed(
      AppRouter.facultyDetailRoute,
      arguments: {
        'facultyId': facultyId,
        'facultyName': facultyName,
      },
    );
  }

  void _navigateToAppointmentHistory() {
    Navigator.of(context).pushNamed(AppRouter.appointmentHistoryRoute);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final facultyProvider = Provider.of<FacultyProvider>(context);
    final appointmentProvider = Provider.of<AppointmentProvider>(context);
    final studentProfile = authProvider.studentProfile;

    // Get upcoming appointments for the badge
    final upcomingAppointments = appointmentProvider.getUpcomingAppointments();

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search faculty...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                autofocus: true,
                onChanged: _searchFaculty,
              )
            : const Text('Faculty List'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _loadFacultyList();
                }
              });
            },
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: _navigateToAppointmentHistory,
                tooltip: 'Appointment History',
              ),
              if (upcomingAppointments.isNotEmpty)
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
                      '${upcomingAppointments.length}',
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
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (studentProfile != null)
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${studentProfile.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${studentProfile.course} - ${studentProfile.branch}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Year ${studentProfile.currentYear}, Semester ${studentProfile.currentSemester}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: facultyProvider.isLoading || appointmentProvider.isLoading
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
                                onPressed: _loadData,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : facultyProvider.facultyList.isEmpty
                          ? const Center(
                              child: Text(
                                'No faculty members found',
                                style: TextStyle(fontSize: 16),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadData,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: facultyProvider.facultyList.length,
                                itemBuilder: (context, index) {
                                  final faculty =
                                      facultyProvider.facultyList[index];
                                  return FacultyCard(
                                    faculty: faculty,
                                    onTap: () => _navigateToFacultyDetail(
                                      faculty.id,
                                      faculty.name,
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
