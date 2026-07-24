import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class MakeupApi {
  static const String baseUrl = "https://makeup-recommender-backend-production.up.railway.app";

  static Future<Map<String, dynamic>> analyze(File image) async {
    final uri = Uri.parse("$baseUrl/api/analyze");
    final request = http.MultipartRequest("POST", uri);

    request.files.add(await http.MultipartFile.fromPath("photo", image.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
