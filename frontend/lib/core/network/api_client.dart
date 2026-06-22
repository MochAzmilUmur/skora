import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:skora/core/utils/logger.dart';

class ApiClient {
  // Gunakan IP address komputer untuk device fisik, localhost untuk emulator
  static String get baseUrl {
    if (Platform.isAndroid) {
      // Untuk device fisik Android, gunakan IP komputer
      return 'http://192.168.1.19:8080/api';
    }
    // Untuk emulator atau platform lain
    return 'http://localhost:8080/api';
  }

  static Future<http.Response> get(String endpoint) async {
    final url = '$baseUrl$endpoint';
    AppLogger.api('GET', url);
    
    final response = await http.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );
    
    AppLogger.api('GET', url, statusCode: response.statusCode, data: response.body);
    return response;
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    final url = '$baseUrl$endpoint';
    AppLogger.api('POST', url, data: data);
    
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    
    AppLogger.api('POST', url, statusCode: response.statusCode, data: response.body);
    return response;
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> data) async {
    final url = '$baseUrl$endpoint';
    AppLogger.api('PUT', url, data: data);
    
    final response = await http.put(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    
    AppLogger.api('PUT', url, statusCode: response.statusCode, data: response.body);
    return response;
  }

  static Future<http.Response> delete(String endpoint) async {
    final url = '$baseUrl$endpoint';
    AppLogger.api('DELETE', url);
    
    final response = await http.delete(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );
    
    AppLogger.api('DELETE', url, statusCode: response.statusCode);
    return response;
  }
}
