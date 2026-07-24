import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../core/api/constants.dart';
import '../models/product.dart';

class ProductProvider extends ChangeNotifier {
  bool isLoading = false;
  List<Product> products = [];
  Product? selected;

  // OPTIONAL: still usable if you want to fetch product list from here
  // Your backend expects: search, brand, category (by NAME)
  Future<void> fetchProducts({
    String? search,
    String? brand,
    String? category,
    double? minPrice,
    double? maxPrice,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      final res = await ApiClient.instance.dio.get(
        ApiConstants.products,
        queryParameters: {
          if (search != null && search.trim().isNotEmpty) "search": search.trim(),
          if (brand != null && brand.trim().isNotEmpty) "brand": brand.trim(),
          if (category != null && category.trim().isNotEmpty) "category": category.trim(),
          if (minPrice != null) "minPrice": minPrice,
          if (maxPrice != null) "maxPrice": maxPrice,
        },
      );

      products = (res.data as List).map((e) => Product.fromJson(e)).toList();
    } on DioException catch (e) {
      // if backend returns 404 for empty, treat it as empty list
      if (e.response?.statusCode == 404) {
        products = [];
      } else {
        throw Exception(e.response?.data?["error"] ?? "Failed to load products");
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProductDetails(String id) async {
    isLoading = true;
    selected = null;
    notifyListeners();

    try {
      final res = await ApiClient.instance.dio.get("${ApiConstants.products}/$id");
      selected = Product.fromJson(res.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?["error"] ?? "Failed to load product");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
