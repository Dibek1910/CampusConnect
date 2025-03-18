import 'package:flutter/material.dart';
import 'package:campus_connect/models/faculty_model.dart';
import 'package:campus_connect/models/appointment_model.dart';
import 'package:campus_connect/models/availability_model.dart';
import 'package:campus_connect/services/api_service.dart';

class FacultyProvider extends ChangeNotifier {
  List<FacultyModel> _facultyList = [];
  List<AppointmentModel> _appointments = [];
  List<AvailabilityModel> _availabilities = [];
  FacultyModel? _selectedFaculty;
  bool _isLoading = false;
  String? _error;

  List<FacultyModel> get facultyList => _facultyList;
  List<AppointmentModel> get appointments => _appointments;
  List<AvailabilityModel> get availabilities => _availabilities;
  FacultyModel? get selectedFaculty => _selectedFaculty;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch all faculty members
  Future<void> fetchFacultyList() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/students/faculty');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        _facultyList = (data as List)
            .map((faculty) => FacultyModel.fromJson(faculty))
            .toList();
      } else {
        _error = response.error ?? 'Failed to fetch faculty list';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search faculty by name or department
  Future<void> searchFaculty(String query) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // First fetch all faculty if the list is empty
      if (_facultyList.isEmpty) {
        await fetchFacultyList();
      }

      // Then filter the list client-side
      if (query.isNotEmpty) {
        final lowercaseQuery = query.toLowerCase();
        _facultyList = _facultyList.where((faculty) {
          return faculty.name.toLowerCase().contains(lowercaseQuery) ||
              faculty.department
                  .toString()
                  .toLowerCase()
                  .contains(lowercaseQuery);
        }).toList();
      } else {
        // If query is empty, reload the full list
        await fetchFacultyList();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch faculty details by ID
  Future<void> fetchFacultyDetails(String facultyId) async {
    _isLoading = true;
    _error = null;
    _selectedFaculty = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/faculty/$facultyId');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        _selectedFaculty = FacultyModel.fromJson(data);
      } else {
        _error = response.error ?? 'Failed to fetch faculty details';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch faculty availability
  Future<void> fetchFacultyAvailability(String facultyId) async {
    _isLoading = true;
    _error = null;
    _availabilities = [];
    notifyListeners();

    try {
      final response =
          await ApiService.get('/students/faculty/$facultyId/availability');

      print('API Response: ${response.statusCode}');
      print('API Data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];

        if (data != null && data is List) {
          print('Availability data length: ${data.length}');

          _availabilities = data
              .map((availability) {
                try {
                  return AvailabilityModel.fromJson(availability);
                } catch (e) {
                  print('Error parsing availability: $e');
                  print('Availability data: $availability');
                  return null;
                }
              })
              .whereType<AvailabilityModel>()
              .toList();

          print('Parsed availabilities: ${_availabilities.length}');
        } else {
          print('Data is null or not a list: $data');
          _error = 'Invalid availability data format';
        }
      } else {
        _error = response.error ?? 'Failed to fetch faculty availability';
      }
    } catch (e) {
      print('Exception in fetchFacultyAvailability: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch faculty appointments
  Future<void> fetchFacultyAppointments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/appointments/faculty');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        _appointments = (data as List)
            .map((appointment) => AppointmentModel.fromJson(appointment))
            .toList();
      } else {
        _error = response.error ?? 'Failed to fetch appointments';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update appointment status (approve/reject)
  Future<bool> updateAppointmentStatus(String appointmentId, String status,
      {String? reason}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final body = {
        'status': status,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      };

      final response =
          await ApiService.put('/appointments/$appointmentId/status', body);
      if (response.statusCode == 200) {
        // Update the local appointment list
        await fetchFacultyAppointments();
        return true;
      } else {
        _error = response.error ?? 'Failed to update appointment status';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
