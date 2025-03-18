class DepartmentModel {
  final String id;
  final String name;
  final String? description;
  final List<String> faculty;

  DepartmentModel({
    required this.id,
    required this.name,
    this.description,
    this.faculty = const [],
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      faculty:
          json['faculty'] != null ? List<String>.from(json['faculty']) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'faculty': faculty,
    };
  }
}
