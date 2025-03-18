import 'package:flutter/material.dart';
import 'package:campus_connect/services/api_service.dart';

class DepartmentModel {
  final String id;
  final String name;
  final String? description;

  DepartmentModel({
    required this.id,
    required this.name,
    this.description,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
    );
  }
}

class DepartmentProvider extends ChangeNotifier {
  List<DepartmentModel> _departments = [];
  bool _isLoading = false;
  String? _error;

  List<DepartmentModel> get departments => _departments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch all departments
  Future<void> fetchDepartments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/departments');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        _departments = (data as List)
            .map((department) => DepartmentModel.fromJson(department))
            .toList();
      } else {
        _error = response.error ?? 'Failed to fetch departments';
      }
    } catch (e) {
      _error = e.toString();
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
