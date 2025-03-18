import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:campus_connect/config/route.dart';
import 'package:campus_connect/models/availability_model.dart';
import 'package:campus_connect/providers/faculty_provider.dart';
import 'package:campus_connect/widgets/button_widget.dart';

class FacultyDetailScreen extends StatefulWidget {
  final String facultyId;
  final String facultyName;

  const FacultyDetailScreen({
    Key? key,
    required this.facultyId,
    required this.facultyName,
  }) : super(key: key);

  @override
  State<FacultyDetailScreen> createState() => _FacultyDetailScreenState();
}

class _FacultyDetailScreenState extends State<FacultyDetailScreen> {
  // Sort days of week in order starting from Monday
  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFacultyAvailability();
    });
  }

  Future<void> _loadFacultyAvailability() async {
    final facultyProvider =
        Provider.of<FacultyProvider>(context, listen: false);
    await facultyProvider.fetchFacultyAvailability(widget.facultyId);
  }

  // Maps day of week to corresponding date
  DateTime _getDateForDay(String day) {
    final now = DateTime.now();
    final currentDayOfWeek = now.weekday; // 1 for Monday, 7 for Sunday
    final targetDayOfWeek =
        _daysOfWeek.indexOf(day) + 1; // Adjust to match DateTime.weekday

    int daysToAdd = targetDayOfWeek - currentDayOfWeek;
    if (daysToAdd < 0) {
      daysToAdd += 7; // Next week
    }

    return DateTime(now.year, now.month, now.day + daysToAdd);
  }

  void _navigateToBookAppointment(AvailabilityModel availability) {
    final date = _getDateForDay(availability.day);

    Navigator.of(context).pushNamed(
      AppRouter.bookAppointmentRoute,
      arguments: {
        'facultyId': widget.facultyId,
        'facultyName': widget.facultyName,
        'availabilityId': availability.id,
        'day': availability.day,
        'date': date,
        'startTime': availability.startTime,
        'endTime': availability.endTime,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final facultyProvider = Provider.of<FacultyProvider>(context);
    final availabilities = facultyProvider.availabilities;

    // Debug print to check availabilities
    print('Available slots: ${availabilities.length}');
    for (var availability in availabilities) {
      print(
          'Slot: ${availability.day} ${availability.startTime}-${availability.endTime} isAvailable: ${availability.isAvailable}');
    }

    // Group availabilities by day
    Map<String, List<AvailabilityModel>> availabilitiesByDay = {};

    for (var day in _daysOfWeek) {
      availabilitiesByDay[day] = [];
    }

    for (var availability in availabilities) {
      if (availabilitiesByDay.containsKey(availability.day)) {
        availabilitiesByDay[availability.day]!.add(availability);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.facultyName),
      ),
      body: facultyProvider.isLoading
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
                        onPressed: _loadFacultyAvailability,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFacultyAvailability,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available Time Slots',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Select a time slot to book an appointment',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 24),
                        availabilities.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 32.0),
                                      child: Text(
                                        'No availability slots found for this faculty',
                                        style: TextStyle(fontSize: 16),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: _loadFacultyAvailability,
                                      child: const Text('Refresh'),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _daysOfWeek.length,
                                itemBuilder: (context, index) {
                                  final day = _daysOfWeek[index];
                                  final dayAvailabilities =
                                      availabilitiesByDay[day] ?? [];

                                  if (dayAvailabilities.isEmpty) {
                                    return const SizedBox.shrink();
                                  }

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 16,
                                        ),
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.1),
                                        child: Text(
                                          day,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: dayAvailabilities
                                            .map((availability) {
                                          return InkWell(
                                            onTap: availability.isAvailable
                                                ? () =>
                                                    _navigateToBookAppointment(
                                                        availability)
                                                : null,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 8,
                                                horizontal: 16,
                                              ),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color:
                                                      availability.isAvailable
                                                          ? Theme.of(context)
                                                              .primaryColor
                                                          : Colors.grey,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                color: availability.isAvailable
                                                    ? Colors.transparent
                                                    : Colors.grey
                                                        .withOpacity(0.1),
                                              ),
                                              child: Text(
                                                '${availability.startTime} - ${availability.endTime}',
                                                style: TextStyle(
                                                  color:
                                                      availability.isAvailable
                                                          ? Theme.of(context)
                                                              .primaryColor
                                                          : Colors.grey,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
