import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiResponse {
  final int statusCode;
  final dynamic data;
  final String? error;

  ApiResponse({
    required this.statusCode,
    required this.data,
    this.error,
  });
}

class ApiService {
  static String get baseUrl {
    // For web
    if (kIsWeb) {
      return 'http://localhost:5001/api';
    }

    // For Android emulator
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5001/api';
    }

    // For iOS simulator
    if (Platform.isIOS) {
      return 'http://localhost:5001/api';
    }

    // Default fallback
    return 'http://localhost:5001/api';
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<ApiResponse> get(String endpoint) async {
    try {
      final headers = await _getHeaders();

      print('Making GET request to: $baseUrl$endpoint');
      print('Headers: $headers');

      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      return _processResponse(response);
    } catch (e) {
      print('Network error in GET request: $e');
      return ApiResponse(
        statusCode: 500,
        data: null,
        error: 'Network error: $e',
      );
    }
  }

  static Future<ApiResponse> post(String endpoint, dynamic body) async {
    try {
      final headers = await _getHeaders();

      print('Making POST request to: $baseUrl$endpoint');
      print('Headers: $headers');
      print('Body: $body');

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      return _processResponse(response);
    } catch (e) {
      print('Network error in POST request: $e');
      return ApiResponse(
        statusCode: 500,
        data: null,
        error: 'Network error: $e',
      );
    }
  }

  static Future<ApiResponse> put(String endpoint, dynamic body) async {
    try {
      final headers = await _getHeaders();

      print('Making PUT request to: $baseUrl$endpoint');
      print('Headers: $headers');
      print('Body: $body');

      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      return _processResponse(response);
    } catch (e) {
      print('Network error in PUT request: $e');
      return ApiResponse(
        statusCode: 500,
        data: null,
        error: 'Network error: $e',
      );
    }
  }

  static Future<ApiResponse> delete(String endpoint) async {
    try {
      final headers = await _getHeaders();

      print('Making DELETE request to: $baseUrl$endpoint');
      print('Headers: $headers');

      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      return _processResponse(response);
    } catch (e) {
      print('Network error in DELETE request: $e');
      return ApiResponse(
        statusCode: 500,
        data: null,
        error: 'Network error: $e',
      );
    }
  }

  static ApiResponse _processResponse(http.Response response) {
    try {
      final dynamic data =
          response.body.isNotEmpty ? jsonDecode(response.body) : null;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(
          statusCode: response.statusCode,
          data: data,
        );
      } else {
        String errorMessage = 'Unknown error occurred';
        if (data != null && data is Map<String, dynamic>) {
          if (data.containsKey('message')) {
            errorMessage = data['message'];
          } else if (data.containsKey('error')) {
            errorMessage = data['error'];
          }
        }

        return ApiResponse(
          statusCode: response.statusCode,
          data: null,
          error: errorMessage,
        );
      }
    } catch (e) {
      print('Error processing response: $e');
      return ApiResponse(
        statusCode: response.statusCode,
        data: null,
        error: 'Failed to process response: $e',
      );
    }
  }

  // Faculty availability management
  static Future<ApiResponse> setAvailability(
      String facultyId, List<Map<String, dynamic>> slots) {
    return post('/faculty/set-availability',
        {"facultyId": facultyId, "availableSlots": slots});
  }

  // Fetch faculty availability
  static Future<ApiResponse> fetchAvailability(String facultyId) {
    return get('/faculty/$facultyId/availability');
  }

  // Book appointment
  static Future<ApiResponse> bookAppointment(
      Map<String, dynamic> appointmentData) {
    return post('/appointments/book', appointmentData);
  }
}
