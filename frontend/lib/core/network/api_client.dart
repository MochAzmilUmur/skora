import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:skora/core/services/auth_storage_service.dart';
import 'package:skora/core/utils/logger.dart';

class ApiClient {
  static String get _host {
    if (Platform.isAndroid) {
      return dotenv.env['API_HOST_DEVICE'] ?? '192.168.1.19';
    }
    return dotenv.env['API_HOST_EMULATOR'] ?? 'localhost';
  }

  static String get _port => dotenv.env['API_PORT'] ?? '8080';

  static String get baseUrl => 'http://$_host:$_port/api';
  static String get serverBaseUrl => 'http://$_host:$_port';

  static String resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return '$serverBaseUrl$path';
  }

  static Future<Map<String, String>> _headers() async {
    final token = await AuthStorageService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(String endpoint) async {
    final url = '$baseUrl$endpoint';
    AppLogger.api('GET', url);
    final response = await http.get(Uri.parse(url), headers: await _headers());
    AppLogger.api('GET', url, statusCode: response.statusCode, data: response.body);
    return response;
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    final url = '$baseUrl$endpoint';
    AppLogger.api('POST', url, data: data);
    final response = await http.post(Uri.parse(url), headers: await _headers(), body: jsonEncode(data));
    AppLogger.api('POST', url, statusCode: response.statusCode, data: response.body);
    return response;
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> data) async {
    final url = '$baseUrl$endpoint';
    AppLogger.api('PUT', url, data: data);
    final response = await http.put(Uri.parse(url), headers: await _headers(), body: jsonEncode(data));
    AppLogger.api('PUT', url, statusCode: response.statusCode, data: response.body);
    return response;
  }

  static Future<http.Response> patch(String endpoint, Map<String, dynamic> data) async {
    final url = '$baseUrl$endpoint';
    AppLogger.api('PATCH', url, data: data);
    final response = await http.patch(Uri.parse(url), headers: await _headers(), body: jsonEncode(data));
    AppLogger.api('PATCH', url, statusCode: response.statusCode, data: response.body);
    return response;
  }

  static Future<http.Response> delete(String endpoint) async {
    final url = '$baseUrl$endpoint';
    AppLogger.api('DELETE', url);
    final response = await http.delete(Uri.parse(url), headers: await _headers());
    AppLogger.api('DELETE', url, statusCode: response.statusCode);
    return response;
  }

  static Future<http.Response> uploadMultipart(String endpoint, File file, {String fieldName = 'file'}) async {
    final url = '$baseUrl$endpoint';
    AppLogger.api('MULTIPART', url, data: {'file': file.path});

    final token = await AuthStorageService.getToken();
    final request = http.MultipartRequest('POST', Uri.parse(url));

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final multipartFile = await http.MultipartFile.fromPath(fieldName, file.path);
    request.files.add(multipartFile);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    AppLogger.api('MULTIPART', url, statusCode: response.statusCode, data: response.body);
    return response;
  }
}
