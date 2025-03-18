import 'package:campus_connect/models/user_model.dart';

class StudentModel {
  final String id;
  final String userId;
  final String name;
  final String registrationNumber;
  final String course;
  final String branch;
  final int currentYear;
  final int currentSemester;
  final String phoneNumber;
  final List<String> appointments;

  StudentModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.registrationNumber,
    required this.course,
    required this.branch,
    required this.currentYear,
    required this.currentSemester,
    required this.phoneNumber,
    required this.appointments,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['user'] ?? '',
      name: json['name'] ?? '',
      registrationNumber: json['registrationNumber'] ?? '',
      course: json['course'] ?? '',
      branch: json['branch'] ?? '',
      currentYear: json['currentYear'] ?? 0,
      currentSemester: json['currentSemester'] ?? 0,
      phoneNumber: json['phoneNumber'] ?? '',
      appointments: json['appointments'] != null
          ? List<String>.from(json['appointments'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'name': name,
      'registrationNumber': registrationNumber,
      'course': course,
      'branch': branch,
      'currentYear': currentYear,
      'currentSemester': currentSemester,
      'phoneNumber': phoneNumber,
      'appointments': appointments,
    };
  }
}
