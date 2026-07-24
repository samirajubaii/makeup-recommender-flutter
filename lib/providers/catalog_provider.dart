import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../core/api/constants.dart';
import '../models/product.dart';
import '../models/brand.dart';
import '../models/category.dart';

class CatalogProvider extends ChangeNotifier {
  bool isLoading = false;

  List<Product> products = [];
  List<Brand> brands = [];
  List<Category> categories = [];

  // We will store selected NAMES because backend filters by name
  String? selectedBrandName;
  String? selectedCategoryName;
  String searchText = "";

  Future<void> init() async {
    await Future.wait([
      fetchBrands(),
      fetchCategories(),
    ]);
    await fetchProducts();
  }

  Future<void> fetchBrands() async {
    try {
      final res = await ApiClient.instance.dio.get(ApiConstants.brands);
      brands = (res.data as List).map((e) => Brand.fromJson(e)).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchCategories() async {
    try {
      final res = await ApiClient.instance.dio.get(ApiConstants.categories);
      categories = (res.data as List).map((e) => Category.fromJson(e)).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchProducts() async {
    isLoading = true;
    notifyListeners();

    try {
      final res = await ApiClient.instance.dio.get(
        ApiConstants.products,
        queryParameters: {
          if (searchText.trim().isNotEmpty) "search": searchText.trim(),
          if (selectedBrandName != null) "brand": selectedBrandName,
          if (selectedCategoryName != null) "category": selectedCategoryName,
        },
      );

      // backend returns List
      products = (res.data as List).map((e) => Product.fromJson(e)).toList();
    } on DioException catch (e) {
      // If your backend still returns 404 when empty, treat it as empty list:
      if (e.response?.statusCode == 404) {
        products = [];
      } else {
        rethrow;
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setBrandName(String? name) async {
    selectedBrandName = name;
    await fetchProducts();
  }

  Future<void> setCategoryName(String? name) async {
    selectedCategoryName = name;
    await fetchProducts();
  }

  Future<void> setSearch(String text) async {
    searchText = text;
    await fetchProducts();
  }

  Future<void> clearAll() async {
    selectedBrandName = null;
    selectedCategoryName = null;
    searchText = "";
    await fetchProducts();
  }
}
