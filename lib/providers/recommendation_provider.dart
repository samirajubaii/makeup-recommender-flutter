import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../core/api/constants.dart';

class RecommendationProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;

  String? tone;
  String? undertone;
  String? skinType;

  // These match your UI:
  List<Map<String, dynamic>> foundations = [];
  List<Map<String, dynamic>> concealers = [];

  String toAbsoluteImageUrl(String? url) {
    if (url == null) return "";
    final u = url.trim();
    if (u.isEmpty) return "";
    if (u.startsWith("http://") || u.startsWith("https://")) return u;
    if (u.startsWith("/")) return "${ApiConstants.baseUrl}$u";
    return "${ApiConstants.baseUrl}/$u";
  }

  Future<void> analyzeFace({
    required File image,
    required String skinTypeValue,
  }) async {
    isLoading = true;
    error = null;
    tone = null;
    undertone = null;
    skinType = null;
    foundations = [];
    concealers = [];
    notifyListeners();

    try {
      // ✅ MUST match backend: upload.single("photo")
      final form = FormData.fromMap({
        "photo": await MultipartFile.fromFile(
          image.path,
          filename: image.path.split("/").last,
        ),
        "skinType": skinTypeValue.toLowerCase(),
      });

      final res = await ApiClient.instance.dio.post(
        ApiConstants.analyze, // "/api/analyze"
        data: form,
        options: Options(contentType: "multipart/form-data"),
      );

      final data = res.data;

      if (data is! Map) {
        throw Exception("Unexpected response format");
      }

      final map = _asMap(data);

      tone = map["tone"]?.toString();
      undertone = map["undertone"]?.toString();
      skinType = map["skinType"]?.toString();

      final rec = map["recommendations"];
      if (rec is Map) {
        final recMap = _asMap(rec);

        final f = recMap["foundations"];
        final c = recMap["concealers"];

        if (f is List) {
          foundations = f.map((e) => _asMap(e)).toList();
        }
        if (c is List) {
          concealers = c.map((e) => _asMap(e)).toList();
        }
      }

      notifyListeners();
    } on DioException catch (e) {
      final d = e.response?.data;
      final msg = (d is Map)
          ? ((_asMap(d)["error"] ?? _asMap(d)["message"])?.toString())
          : null;
      error = msg ?? "Failed to analyze face";
      notifyListeners();
    } catch (e) {
      error = e.toString().replaceFirst("Exception: ", "");
      notifyListeners();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return <String, dynamic>{};
  }
}


