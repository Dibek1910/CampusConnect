import 'package:campus_connect/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Request OTP for login
  Future<ApiResponse> requestLoginOtp(String email) async {
    return await ApiService.post('/auth/login', {
      'email': email,
    });
  }

  // Verify OTP and login
  Future<ApiResponse> verifyLoginOtp(String email, String otp) async {
    final response = await ApiService.post('/auth/verify/login', {
      'email': email,
      'otp': otp,
    });

    if (response.statusCode == 200 && response.data != null) {
      // Save token to shared preferences
      final prefs = await SharedPreferences.getInstance();
      final data = response.data['data'];
      await prefs.setString('token', data['token']);
      await prefs.setString('role', data['role']);
      await prefs.setString('userId', data['userId']);
    }

    return response;
  }

  // Register a student
  Future<ApiResponse> registerStudent(Map<String, dynamic> userData) async {
    return await ApiService.post('/auth/register/student', userData);
  }

  // Register a faculty
  Future<ApiResponse> registerFaculty(Map<String, dynamic> userData) async {
    return await ApiService.post('/auth/register/faculty', userData);
  }

  // Verify registration OTP
  Future<ApiResponse> verifyRegistrationOtp(String email, String otp) async {
    final response = await ApiService.post('/auth/verify/registration', {
      'email': email,
      'otp': otp,
    });

    if (response.statusCode == 200 && response.data != null) {
      // Save token to shared preferences
      final prefs = await SharedPreferences.getInstance();
      final data = response.data['data'];
      await prefs.setString('token', data['token']);
      await prefs.setString('role', data['role']);
      await prefs.setString('userId', data['userId']);
    }

    return response;
  }

  // Get allowed branches for students
  Future<ApiResponse> getAllowedBranches() async {
    return await ApiService.get('/auth/branches');
  }

  // Get allowed departments for faculty
  Future<ApiResponse> getAllowedDepartments() async {
    return await ApiService.get('/auth/departments');
  }

  // Get user profile
  Future<ApiResponse> getUserProfile() async {
    return await ApiService.get('/auth/me');
  }

  // Logout
  Future<ApiResponse> logout() async {
    try {
      // First make the API call while the token is still valid
      final response = await ApiService.post('/auth/logout', {});

      // Then clear local storage regardless of API response
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('role');
      await prefs.remove('userId');

      return response;
    } catch (e) {
      print('Error during logout: $e');
      // Still clear local storage even if API call fails
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('role');
      await prefs.remove('userId');

      return ApiResponse(
        statusCode: 500,
        data: null,
        error: 'Error during logout: $e',
      );
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  // Get user role
  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  // Add functions for OTP generation and verification
  Future<ApiResponse> generateOtp(String email) async {
    return await ApiService.post(
        '/auth/profile-update/send-otp', {"email": email});
  }

  Future<ApiResponse> verifyOtp(String email, String otp) async {
    return await ApiService.post(
        '/auth/profile-update/verify-otp', {"email": email, "otp": otp});
  }
}
