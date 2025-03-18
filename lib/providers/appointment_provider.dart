import 'package:flutter/material.dart';
import 'package:campus_connect/models/appointment_model.dart';
import 'package:campus_connect/services/api_service.dart';

class AppointmentProvider extends ChangeNotifier {
  List<AppointmentModel> _appointments = [];
  bool _isLoading = false;
  String? _error;

  List<AppointmentModel> get appointments => _appointments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch student appointments
  Future<void> fetchStudentAppointments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/appointments/student');
      print('Student appointments response: ${response.statusCode}');
      print('Student appointments data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data != null && data is List) {
          _appointments = data
              .map((appointment) {
                try {
                  return AppointmentModel.fromJson(appointment);
                } catch (e) {
                  print('Error parsing appointment: $e');
                  print('Appointment data: $appointment');
                  return null;
                }
              })
              .whereType<AppointmentModel>()
              .toList();

          print('Parsed student appointments: ${_appointments.length}');
        } else {
          print('Data is null or not a list: $data');
          _error = 'Invalid appointment data format';
        }
      } else {
        _error = response.error ?? 'Failed to fetch appointments';
      }
    } catch (e) {
      print('Exception in fetchStudentAppointments: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Book an appointment
  Future<bool> bookAppointment(Map<String, dynamic> appointmentData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('Booking appointment with data: $appointmentData');
      final response = await ApiService.post('/appointments', appointmentData);
      print('Book appointment response: ${response.statusCode}');
      print('Book appointment data: ${response.data}');

      if (response.statusCode == 201) {
        await fetchStudentAppointments();
        return true;
      } else {
        _error = response.error ?? 'Failed to book appointment';
        return false;
      }
    } catch (e) {
      print('Exception in bookAppointment: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cancel an appointment
  Future<bool> cancelAppointment(String appointmentId, {String? reason}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final body =
          reason != null && reason.isNotEmpty ? {'reason': reason} : {};
      print('Cancelling appointment $appointmentId with reason: $reason');

      final response =
          await ApiService.put('/appointments/$appointmentId/cancel', body);
      print('Cancel appointment response: ${response.statusCode}');
      print('Cancel appointment data: ${response.data}');

      if (response.statusCode == 200) {
        await fetchStudentAppointments();
        return true;
      } else {
        _error = response.error ?? 'Failed to cancel appointment';
        return false;
      }
    } catch (e) {
      print('Exception in cancelAppointment: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get filtered appointments by status
  List<AppointmentModel> getFilteredAppointments(String status) {
    return _appointments
        .where((appointment) => appointment.status == status)
        .toList();
  }

  // Get upcoming appointments (accepted status and future date)
  List<AppointmentModel> getUpcomingAppointments() {
    final now = DateTime.now();
    return _appointments
        .where((appointment) =>
            appointment.status == 'accepted' &&
            (appointment.date.isAfter(now) ||
                (appointment.date.day == now.day &&
                    appointment.date.month == now.month &&
                    appointment.date.year == now.year)))
        .toList();
  }

  // Get past appointments (completed, cancelled, or rejected)
  List<AppointmentModel> getPastAppointments() {
    final now = DateTime.now();
    return _appointments
        .where((appointment) =>
            (appointment.status == 'completed' ||
                appointment.status == 'cancelled' ||
                appointment.status == 'rejected') ||
            (appointment.date.isBefore(now) &&
                !(appointment.date.day == now.day &&
                    appointment.date.month == now.month &&
                    appointment.date.year == now.year)))
        .toList();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
