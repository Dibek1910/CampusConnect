class FacultyModel {
  final String id;
  final String userId;
  final String name;
  final String phoneNumber;
  final dynamic department; // Changed to dynamic to handle both String and Map
  final List<String> availabilities;
  final List<String> appointments;

  FacultyModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.phoneNumber,
    required this.department,
    required this.availabilities,
    required this.appointments,
  });

  factory FacultyModel.fromJson(Map<String, dynamic> json) {
    // Handle department which can be either a Map or a String
    dynamic departmentValue;
    if (json['department'] is Map) {
      departmentValue = json['department']['name'] ?? '';
    } else {
      departmentValue = json['department'] ?? '';
    }

    return FacultyModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['user'] is Map ? json['user']['_id'] : (json['user'] ?? ''),
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      department: departmentValue,
      availabilities: json['availabilities'] != null
          ? List<String>.from(json['availabilities'])
          : [],
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
      'phoneNumber': phoneNumber,
      'department': department.toString(),
      'availabilities': availabilities,
      'appointments': appointments,
    };
  }
}
