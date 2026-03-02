import 'package:flutter/foundation.dart';

class AppLogger {
  static void log(String message, {String tag = 'APP'}) {
    if (kDebugMode) {
      print('[$tag] $message');
    }
  }

  static void error(String message, {String tag = 'ERROR', Object? error}) {
    if (kDebugMode) {
      print('[$tag] $message');
      if (error != null) print('Error details: $error');
    }
  }

  static void api(String method, String endpoint, {int? statusCode, dynamic data}) {
    if (kDebugMode) {
      print('[API] $method $endpoint ${statusCode != null ? '- Status: $statusCode' : ''}');
      if (data != null) print('Data: $data');
    }
  }
}
