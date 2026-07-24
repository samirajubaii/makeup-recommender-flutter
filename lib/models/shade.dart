class Shade {
  final String id;
  final String name;
  final String tone;
  final String undertone;

  Shade({
    required this.id,
    required this.name,
    required this.tone,
    required this.undertone,
  });

  factory Shade.fromJson(Map<String, dynamic> json) => Shade(
    id: json["id"],
    name: json["name"],
    tone: json["tone"],
    undertone: json["undertone"],
  );
}
