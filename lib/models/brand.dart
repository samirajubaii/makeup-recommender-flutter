class Brand {
  final String id;
  final String name;
  final String? logoUrl;

  Brand({required this.id, required this.name, this.logoUrl});

  factory Brand.fromJson(Map<String, dynamic> json) => Brand(
    id: json["id"],
    name: json["name"],
    logoUrl: json["logoUrl"],
  );
}
