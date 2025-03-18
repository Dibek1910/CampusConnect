import 'package:flutter/material.dart';
import 'package:campus_connect/models/availability_model.dart';
import 'package:campus_connect/services/api_service.dart';

class AvailabilityProvider extends ChangeNotifier {
  List<AvailabilityModel> _availabilities = [];
  bool _isLoading = false;
  String? _error;

  List<AvailabilityModel> get availabilities => _availabilities;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch faculty availabilities
  Future<void> fetchFacultyAvailabilities() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/faculty/availability');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        _availabilities = (data as List)
            .map((availability) => AvailabilityModel.fromJson(availability))
            .toList();
      } else {
        _error = response.error ?? 'Failed to fetch availabilities';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add availability slot
  Future<bool> addAvailabilitySlot(Map<String, dynamic> slotData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.post('/faculty/availability', slotData);
      if (response.statusCode == 201) {
        await fetchFacultyAvailabilities();
        return true;
      } else {
        _error = response.error ?? 'Failed to add availability slot';
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

  // Update availability slot
  Future<bool> updateAvailabilitySlot(
      String slotId, Map<String, dynamic> slotData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response =
          await ApiService.put('/faculty/availability/$slotId', slotData);
      if (response.statusCode == 200) {
        await fetchFacultyAvailabilities();
        return true;
      } else {
        _error = response.error ?? 'Failed to update availability slot';
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

  // Delete availability slot
  Future<bool> deleteAvailabilitySlot(String slotId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.delete('/faculty/availability/$slotId');
      if (response.statusCode == 200) {
        await fetchFacultyAvailabilities();
        return true;
      } else {
        _error = response.error ?? 'Failed to delete availability slot';
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
