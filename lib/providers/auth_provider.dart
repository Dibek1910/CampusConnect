import 'package:flutter/material.dart';
import 'package:campus_connect/models/user_model.dart';
import 'package:campus_connect/models/student_model.dart';
import 'package:campus_connect/models/faculty_model.dart';
import 'package:campus_connect/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  StudentModel? _studentProfile;
  FacultyModel? _facultyProfile;
  bool _isLoading = false;
  String? _error;
  final AuthService _authService = AuthService();

  UserModel? get user => _user;
  StudentModel? get studentProfile => _studentProfile;
  FacultyModel? get facultyProfile => _facultyProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  String get userRole => _user?.role ?? '';

  // Initialize provider and check for existing session
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        await _fetchUserProfile();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Request OTP for login
  Future<bool> requestLoginOtp(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.requestLoginOtp(email);
      if (response.statusCode == 200) {
        return true;
      } else {
        _error = response.error ?? 'Failed to send OTP';
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

  // Verify OTP and login
  Future<bool> verifyLoginOtp(String email, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.verifyLoginOtp(email, otp);
      if (response.statusCode == 200) {
        await _fetchUserProfile();
        return true;
      } else {
        _error = response.error ?? 'Invalid OTP';
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

  // Register a student
  Future<Map<String, dynamic>?> registerStudent(
      Map<String, dynamic> userData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.registerStudent(userData);
      if (response.statusCode == 201) {
        return response.data;
      } else {
        _error = response.error ?? 'Registration failed';
        return null;
      }
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register a faculty
  Future<Map<String, dynamic>?> registerFaculty(
      Map<String, dynamic> userData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.registerFaculty(userData);
      if (response.statusCode == 201) {
        return response.data;
      } else {
        _error = response.error ?? 'Registration failed';
        return null;
      }
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Verify registration OTP
  Future<bool> verifyRegistrationOtp(String email, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.verifyRegistrationOtp(email, otp);
      if (response.statusCode == 200) {
        await _fetchUserProfile();
        return true;
      } else {
        _error = response.error ?? 'Invalid OTP';
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

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _user = null;
      _studentProfile = null;
      _facultyProfile = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch user profile
  Future<void> _fetchUserProfile() async {
    try {
      final response = await _authService.getUserProfile();
      if (response.statusCode == 200 && response.data != null) {
        final userData = response.data['data'];

        if (userData['user'] != null) {
          _user = UserModel.fromJson(userData['user']);

          if (_user!.role == 'student' && userData['profile'] != null) {
            _studentProfile = StudentModel.fromJson(userData['profile']);
          } else if (_user!.role == 'faculty' && userData['profile'] != null) {
            _facultyProfile = FacultyModel.fromJson(userData['profile']);
          }
        }
      } else {
        _error = response.error ?? 'Failed to fetch user profile';
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
