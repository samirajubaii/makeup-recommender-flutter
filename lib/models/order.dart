class Order {
  final String id;
  final String status;
  final double total;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.status,
    required this.total,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json["id"],
    status: json["status"],
    total: (json["total"] as num).toDouble(),
    createdAt: DateTime.parse(json["createdAt"]),
  );
}
