import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

import '../core/api/api_client.dart';
import '../core/api/constants.dart';
import '../models/user.dart';
import 'cart_provider.dart';

class AuthProvider extends ChangeNotifier {
  User? user;
  bool isLoading = false;

  bool get isAuthed => user != null;
  bool get isAdmin => user?.isAdmin == true;

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _auth(ApiConstants.register, {
      "name": name,
      "email": email,
      "password": password,
    });
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _auth(ApiConstants.login, {
      "email": email,
      "password": password,
    });
  }

  Future<void> _auth(String path, Map<String, dynamic> body) async {
    isLoading = true;
    notifyListeners();

    try {
      final res = await ApiClient.instance.dio.post(path, data: body);

      final token = res.data["token"]?.toString();
      final userJson = res.data["user"];

      if (token == null || token.isEmpty) {
        throw Exception("Auth failed: token missing");
      }
      if (userJson is! Map) {
        throw Exception("Auth failed: user missing");
      }

      await ApiClient.instance.saveToken(token);
      ApiClient.instance.setAuthToken(token);

      user = User.fromJson(userJson.map((k, v) => MapEntry(k.toString(), v)));
    } on DioException catch (e) {
      final d = e.response?.data;

      String? msg;
      if (d is Map) {
        msg = (d["message"] ?? d["error"])?.toString();
      } else if (d is String) {
        msg = d;
      }

      // ✅ throw clean text (no "Exception:" prefix)
      throw (msg?.isNotEmpty == true ? msg! : "Auth failed");
    }finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ✅ IMPORTANT: context required so we clear cart provider too
  Future<void> logout(BuildContext context) async {
    await ApiClient.instance.clearToken();
    ApiClient.instance.setAuthToken(null);

    user = null;

    // ✅ Clear cart when logging out so it never shows old items
    context.read<CartProvider>().clearLocal();
    context.read<CartProvider>().setGuestMode(); // ✅ ensure guest mode state

    notifyListeners();
  }
}

