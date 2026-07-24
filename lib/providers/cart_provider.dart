import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../core/api/constants.dart';
import '../models/product.dart';

class CartItemModel {
  final String id;
  final Product product;
  final Map<String, dynamic>? shade; // can be null
  int quantity;
  final double unitPrice;

  CartItemModel({
    required this.id,
    required this.product,
    required this.quantity,
    required this.unitPrice,
    this.shade,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final productJson = json["product"] as Map<String, dynamic>? ?? {};
    final shadeJson = json["shade"] as Map<String, dynamic>?;

    return CartItemModel(
      id: (json["id"] ?? "").toString(),
      product: Product.fromJson(productJson),
      shade: shadeJson,
      quantity: (json["quantity"] as num?)?.toInt() ?? 1,
      unitPrice: (json["unitPrice"] as num?)?.toDouble() ?? 0,
    );
  }

  String? get shadeName => shade?["name"]?.toString();
}

class CartProvider extends ChangeNotifier {
  bool loading = false;
  String? error;

  List<CartItemModel> items = [];

  double get total {
    double t = 0;
    for (final it in items) {
      t += it.unitPrice * it.quantity;
    }
    return t;
  }

  void clearLocal() {
    items = [];
    error = null;
    notifyListeners();
  }

  /// ✅ Call this when user logs out or before showing cart for a guest
  void setGuestMode() {
    clearLocal();
  }

  Future<void> loadCart() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final res = await ApiClient.instance.dio.get(ApiConstants.cart);

      final data = res.data;

      final list = (data is Map)
          ? (data["items"] as List? ?? [])
          : (data as List? ?? []);

      items = list.map((e) => CartItemModel.fromJson(_asMap(e))).toList();
    } on DioException catch (e) {
      // ✅ IMPORTANT: if not logged in, backend will return 401/403
      // we MUST clear local cart so old items don't show.
      final status = e.response?.statusCode ?? 0;

      if (status == 401 || status == 403) {
        clearLocal();
        return;
      }

      final d = e.response?.data;
      final msg = (d is Map)
          ? (d["error"] ?? d["message"])?.toString()
          : null;

      error = msg ?? "Failed to load cart";
    } catch (_) {
      error = "Failed to load cart";
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> addToCart({
    required String productId,
    String? shadeId,
    int quantity = 1,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      await ApiClient.instance.dio.post(
        ApiConstants.cartItems,
        data: {
          "productId": productId,
          "shadeId": shadeId,
          "quantity": quantity,
        },
      );

      // refresh from backend
      await loadCart();
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;

      if (status == 401 || status == 403) {
        clearLocal();
        error = "Please login first";
      } else {
        final d = e.response?.data;
        final msg = (d is Map)
            ? (d["error"] ?? d["message"])?.toString()
            : null;
        error = msg ?? "Failed to add to cart";
      }
    } catch (_) {
      error = "Failed to add to cart";
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> removeItem(String cartItemId) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      await ApiClient.instance.dio.delete("${ApiConstants.cartItems}/$cartItemId");
      await loadCart();
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      if (status == 401 || status == 403) {
        clearLocal();
        return;
      }

      error = "Failed to remove item";
    } catch (_) {
      error = "Failed to remove item";
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return <String, dynamic>{};
  }
}






