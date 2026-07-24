import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../core/api/constants.dart';

class AdminProvider extends ChangeNotifier {
  bool loading = false;
  String? error;

  List<Map<String, dynamic>> brands = [];
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> products = [];

  Future<void> loadAll() async {
    await Future.wait([
      loadBrands(),
      loadCategories(),
      loadProducts(),
    ]);
  }

  Future<void> loadBrands() async {
    await _wrap(() async {
      final res = await ApiClient.instance.dio.get(ApiConstants.brands);
      brands = _asList(res.data);
    });
  }

  Future<void> loadCategories() async {
    await _wrap(() async {
      final res = await ApiClient.instance.dio.get(ApiConstants.categories);
      categories = _asList(res.data);
    });
  }

  Future<void> loadProducts() async {
    await _wrap(() async {
      final res = await ApiClient.instance.dio.get(ApiConstants.products);
      products = _asList(res.data);
    });
  }

  Future<void> createBrand({required String name, String? logoUrl}) async {
    await _wrap(() async {
      await ApiClient.instance.dio.post(
        ApiConstants.adminBrands,
        data: {"name": name, "logoUrl": logoUrl},
      );
      await loadBrands();
    });
  }

  Future<void> deleteBrand(String id) async {
    await _wrap(() async {
      await ApiClient.instance.dio.delete("${ApiConstants.adminBrands}/$id");
      await loadBrands();
      await loadProducts();
    });
  }

  Future<void> createCategory({required String name}) async {
    await _wrap(() async {
      await ApiClient.instance.dio.post(
        ApiConstants.adminCategories,
        data: {"name": name},
      );
      await loadCategories();
    });
  }

  Future<void> deleteCategory(String id) async {
    await _wrap(() async {
      await ApiClient.instance.dio.delete("${ApiConstants.adminCategories}/$id");
      await loadCategories();
      await loadProducts();
    });
  }

  // ✅ Shade model (simple map)
  Map<String, dynamic> _shade({
    required String name,
    required String tone,
    required String undertone,
  }) {
    return {
      "name": name.trim(),
      "tone": tone.trim(),
      "undertone": undertone.trim(),
    };
  }

  /// ✅ Option A: create product WITH shades in one request
  Future<void> createProduct({
    required String name,
    required double price,
    required String brandId,
    required String categoryId,
    int stock = 0,
    String? imageUrl,
    String? description,
    String? finish, // "MATTE" | "NATURAL" | "DEWY"
    bool suitableForAllSkinTypes = false,

    // ✅ NEW
    List<Map<String, String>> shades = const [],
  }) async {
    await _wrap(() async {
      await ApiClient.instance.dio.post(
        ApiConstants.adminProducts,
        data: {
          "name": name,
          "price": price,
          "stock": stock,
          "brandId": brandId,
          "categoryId": categoryId,
          "imageUrl": imageUrl,
          "description": description,
          "finish": finish,
          "suitableForAllSkinTypes": suitableForAllSkinTypes,

          // ✅ send shades if provided
          if (shades.isNotEmpty)
            "shades": shades
                .map((s) => _shade(
              name: s["name"] ?? "",
              tone: s["tone"] ?? "",
              undertone: s["undertone"] ?? "",
            ))
                .toList(),
        },
      );

      await loadProducts();
    });
  }

  /// ✅ Option B: add shades AFTER product creation
  Future<void> addShades({
    required String productId,
    required List<Map<String, String>> shades,
  }) async {
    await _wrap(() async {
      await ApiClient.instance.dio.post(
        "${ApiConstants.adminProducts}/$productId/shades",
        data: {
          "shades": shades
              .map((s) => _shade(
            name: s["name"] ?? "",
            tone: s["tone"] ?? "",
            undertone: s["undertone"] ?? "",
          ))
              .toList(),
        },
      );

      await loadProducts();
    });
  }

  /// ✅ delete a single shade (you already added this route backend)
  Future<void> deleteShade({
    required String productId,
    required String shadeId,
  }) async {
    await _wrap(() async {
      await ApiClient.instance.dio.delete(
        "${ApiConstants.adminProducts}/$productId/shades/$shadeId",
      );
      await loadProducts();
    });
  }

  Future<void> deleteProduct(String id) async {
    await _wrap(() async {
      await ApiClient.instance.dio.delete("${ApiConstants.adminProducts}/$id");
      await loadProducts();
    });
  }

  // helpers
  Future<void> _wrap(Future<void> Function() fn) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      await fn();
    } on DioException catch (e) {
      final d = e.response?.data;
      error = (d is Map ? (d["error"] ?? d["message"])?.toString() : null) ??
          e.message ??
          "Request failed";
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _asList(dynamic v) {
    if (v is List) {
      return v.map((e) => _asMap(e)).toList();
    }
    return [];
  }

  Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return <String, dynamic>{};
  }
}


