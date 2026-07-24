class User {
  final String id;
  final String name;
  final String email;
  final String role;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  bool get isAdmin => role.toLowerCase() == "admin";

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json["id"].toString(),
      name: json["name"]?.toString() ?? "",
      email: json["email"]?.toString() ?? "",
      role: (json["role"] ?? "user").toString(), // ✅ default user
    );
  }
}
