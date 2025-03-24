class ProfileModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String? course;
  final String? branch;
  final int? currentYear;
  final int? currentSemester;
  final String? department;

  ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.course,
    this.branch,
    this.currentYear,
    this.currentSemester,
    this.department,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      course: json['course'],
      branch: json['branch'],
      currentYear: json['currentYear'],
      currentSemester: json['currentSemester'],
      department: json['department'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'course': course,
      'branch': branch,
      'currentYear': currentYear,
      'currentSemester': currentSemester,
      'department': department,
    };
  }
}
