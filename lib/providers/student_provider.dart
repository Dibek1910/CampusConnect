import 'package:flutter/material.dart';
import 'package:campus_connect/models/student_model.dart';
import 'package:campus_connect/services/api_service.dart';

class StudentProvider extends ChangeNotifier {
  List<StudentModel> _students = [];
  bool _isLoading = false;
  String? _error;

  List<StudentModel> get students => _students;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchStudents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/students');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        _students = (data as List)
            .map((student) => StudentModel.fromJson(student))
            .toList();
      } else {
        _error = response.error ?? 'Failed to fetch students';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
