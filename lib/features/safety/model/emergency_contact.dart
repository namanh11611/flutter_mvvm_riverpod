class EmergencyContact {
  final String id;
  final String userId;
  final String name;
  final String phoneNumber;
  final String email;
  final DateTime createdAt;

  const EmergencyContact({
    required this.id,
    required this.userId,
    required this.name,
    required this.phoneNumber,
    required this.email,
    required this.createdAt,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'phoneNumber': phoneNumber,
        'email': email,
        'createdAt': createdAt.toIso8601String(),
      };
}
