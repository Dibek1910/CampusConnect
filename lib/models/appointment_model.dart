class AppointmentModel {
  final String id;
  final String studentId;
  final String studentName;
  final String facultyId;
  final String facultyName;
  final String availabilityId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String purpose;
  final String status;
  final String? cancelReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppointmentModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.facultyId,
    required this.facultyName,
    required this.availabilityId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.purpose,
    required this.status,
    this.cancelReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    print('Parsing appointment JSON: $json');

    // Handle different possible field names and formats
    String id = '';
    if (json.containsKey('_id')) {
      id = json['_id'] ?? '';
    } else if (json.containsKey('id')) {
      id = json['id'] ?? '';
    }

    String studentId = '';
    String studentName = '';
    if (json.containsKey('student')) {
      if (json['student'] is Map) {
        studentId = json['student']['_id'] ?? '';
        studentName = json['student']['name'] ?? '';
      } else {
        studentId = json['student'] ?? '';
      }
    } else {
      studentId = json['studentId'] ?? '';
      studentName = json['studentName'] ?? '';
    }

    String facultyId = '';
    String facultyName = '';
    if (json.containsKey('faculty')) {
      if (json['faculty'] is Map) {
        facultyId = json['faculty']['_id'] ?? '';
        facultyName = json['faculty']['name'] ?? '';
      } else {
        facultyId = json['faculty'] ?? '';
      }
    } else {
      facultyId = json['facultyId'] ?? '';
      facultyName = json['facultyName'] ?? '';
    }

    String availabilityId = '';
    if (json.containsKey('availability')) {
      if (json['availability'] is Map) {
        availabilityId = json['availability']['_id'] ?? '';
      } else {
        availabilityId = json['availability'] ?? '';
      }
    } else {
      availabilityId = json['availabilityId'] ?? '';
    }

    DateTime date;
    try {
      date =
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now();
    } catch (e) {
      print('Error parsing date: $e');
      date = DateTime.now();
    }

    return AppointmentModel(
      id: id,
      studentId: studentId,
      studentName: studentName,
      facultyId: facultyId,
      facultyName: facultyName,
      availabilityId: availabilityId,
      date: date,
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      purpose: json['purpose'] ?? '',
      status: json['status'] ?? 'pending',
      cancelReason: json['cancelReason'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'studentId': studentId,
      'studentName': studentName,
      'facultyId': facultyId,
      'facultyName': facultyName,
      'availabilityId': availabilityId,
      'date': date.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'purpose': purpose,
      'status': status,
      'cancelReason': cancelReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
