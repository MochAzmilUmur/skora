import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:skora/core/services/auth_storage_service.dart';
import 'package:skora/core/utils/logger.dart';

class ApiClient {
  /// Base URL penuh dari .env, trailing slash dihapus.
  ///  "http://192.168.1.6:8080/api" 
  ///"https://skora-backend.example.com/api"
  static String get baseUrl {
    final raw = dotenv.env['API_URL'] ?? '';
    assert(raw.isNotEmpty, 'API_URL wajib diisi di file .env');
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  /// Origin server tanpa path — dipakai untuk resolve URL gambar/upload.
  static String get serverBaseUrl {
    final uri = Uri.parse(baseUrl);
    return '${uri.scheme}://${uri.authority}';
  }

  /// Skema WebSocket yang sesuai: ws:// untuk http://, wss:// untuk https://
  static String get wsScheme =>
      Uri.parse(baseUrl).scheme == 'https' ? 'wss' : 'ws';

  static String resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '$serverBaseUrl${path.startsWith('/') ? path : '/$path'}';
  }

  // Gabungkan baseUrl + endpoint tanpa double-slash
  static String _buildUrl(String endpoint) {
    final clean = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return '$baseUrl$clean';
  }

  static Future<Map<String, String>> _headers() async {
    final token = await AuthStorageService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(String endpoint) async {
    final url = _buildUrl(endpoint);
    AppLogger.api('GET', url);
    final response = await http.get(Uri.parse(url), headers: await _headers());
    AppLogger.api('GET', url, statusCode: response.statusCode, data: response.body);
    return response;
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    final url = _buildUrl(endpoint);
    AppLogger.api('POST', url, data: data);
    final response = await http.post(Uri.parse(url), headers: await _headers(), body: jsonEncode(data));
    AppLogger.api('POST', url, statusCode: response.statusCode, data: response.body);
    return response;
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> data) async {
    final url = _buildUrl(endpoint);
    AppLogger.api('PUT', url, data: data);
    final response = await http.put(Uri.parse(url), headers: await _headers(), body: jsonEncode(data));
    AppLogger.api('PUT', url, statusCode: response.statusCode, data: response.body);
    return response;
  }

  static Future<http.Response> patch(String endpoint, Map<String, dynamic> data) async {
    final url = _buildUrl(endpoint);
    AppLogger.api('PATCH', url, data: data);
    final response = await http.patch(Uri.parse(url), headers: await _headers(), body: jsonEncode(data));
    AppLogger.api('PATCH', url, statusCode: response.statusCode, data: response.body);
    return response;
  }

  static Future<http.Response> delete(String endpoint) async {
    final url = _buildUrl(endpoint);
    AppLogger.api('DELETE', url);
    final response = await http.delete(Uri.parse(url), headers: await _headers());
    AppLogger.api('DELETE', url, statusCode: response.statusCode);
    return response;
  }

  static Future<http.Response> uploadMultipart(
    String endpoint,
    File file, {
    String fieldName = 'file',
  }) async {
    final url = _buildUrl(endpoint);
    AppLogger.api('MULTIPART', url, data: {'file': file.path});

    final token = await AuthStorageService.getToken();
    final request = http.MultipartRequest('POST', Uri.parse(url));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    request.files.add(await http.MultipartFile.fromPath(fieldName, file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    AppLogger.api('MULTIPART', url, statusCode: response.statusCode, data: response.body);
    return response;
  }
}
