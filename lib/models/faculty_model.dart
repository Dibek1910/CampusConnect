class FacultyModel {
  final String id;
  final String name;
  final dynamic department;
  final String phoneNumber;
  final String? email;
  final String? profilePicture;

  FacultyModel({
    required this.id,
    required this.name,
    required this.department,
    required this.phoneNumber,
    this.email,
    this.profilePicture,
  });

  factory FacultyModel.fromJson(Map<String, dynamic> json) {
    return FacultyModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      department: json['department'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'],
      profilePicture: json['profilePicture'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'department': department,
      'phoneNumber': phoneNumber,
      'email': email,
      'profilePicture': profilePicture,
    };
  }

  // Helper method to get department name
  String getDepartmentName() {
    if (department == null) {
      return '';
    }

    if (department is Map) {
      return department['name'] ?? '';
    } else if (department is String) {
      return department;
    }

    return department.toString();
  }
}
