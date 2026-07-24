import 'shade.dart';

class Product {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final double price;
  final int stock;

  final String brandId;
  final String categoryId;

  final String? finish;
  final bool suitableForAllSkinTypes;

  final List<Shade> shades;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.brandId,
    required this.categoryId,
    this.description,
    this.imageUrl,
    this.finish,
    required this.suitableForAllSkinTypes,
    required this.shades,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json["id"],
    name: json["name"],
    description: json["description"],
    imageUrl: json["imageUrl"],
    price: (json["price"] as num).toDouble(),
    stock: (json["stock"] as num).toInt(),
    brandId: json["brandId"],
    categoryId: json["categoryId"],
    finish: json["finish"],
    suitableForAllSkinTypes: json["suitableForAllSkinTypes"] == true,
    shades: (json["shades"] as List? ?? [])
        .map((e) => Shade.fromJson(e))
        .toList(),
  );
}
