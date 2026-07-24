import 'product.dart';
import 'shade.dart';

class CartItem {
  final String id;
  final int quantity;
  final double unitPrice;
  final Product product;
  final Shade? shade;

  CartItem({
    required this.id,
    required this.quantity,
    required this.unitPrice,
    required this.product,
    this.shade,
  });

  double get lineTotal => unitPrice * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json["id"].toString(),
      quantity: (json["quantity"] as num?)?.toInt() ?? 1,
      unitPrice: (json["unitPrice"] as num?)?.toDouble() ?? 0.0,
      product: Product.fromJson(
        (json["product"] as Map).cast<String, dynamic>(),
      ),
      shade: json["shade"] == null
          ? null
          : Shade.fromJson(
        (json["shade"] as Map).cast<String, dynamic>(),
      ),
    );
  }
}


