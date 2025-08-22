import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiApiClient {
  final http.Client _client;
  final String _apiKey;
  final String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  GeminiApiClient(this._client, this._apiKey);

  Future<Map<String, dynamic>> postContent(
    String model,
    Map<String, dynamic> requestBody,
  ) async {
    final url = Uri.parse('$_baseUrl/$model:generateContent?key=$_apiKey');

    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('API 호출 실패 (${response.statusCode}): ${utf8.decode(response.bodyBytes)}');
    }
  }
}
