import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final _storage = FlutterSecureStorage();

// Replace with your backend URL (production or local). For Android emulator use 10.0.2.2
const String BASE_URL = 'http://10.0.2.2:8080'; // if you run backend locally and using Android emulator
// If testing on a real device, use your PC's local IP: e.g. http://192.168.1.100:8080

Future<String?> getToken() async => await _storage.read(key: 'accessToken');
Future<void> setToken(String token) async => await _storage.write(key: 'accessToken', value: token);
Future<void> clearToken() async => await _storage.delete(key: 'accessToken');

class API {
  static Future<Map<String, dynamic>> get(String path) async {
    final token = await getToken();
    final url = Uri.parse('$BASE_URL$path');
    final resp = await http.get(url, headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token'
    });
    final body = _parseBody(resp);
    if (resp.statusCode >= 400) throw APIException(body, resp.statusCode);
    return body;
  }

  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> data) async {
    final token = await getToken();
    final url = Uri.parse('$BASE_URL$path');
    final resp = await http.post(url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token'
        },
        body: jsonEncode(data));
    final body = _parseBody(resp);
    if (resp.statusCode >= 400) throw APIException(body, resp.statusCode);
    return body;
  }

  static dynamic _parseBody(http.Response resp) {
    try {
      return jsonDecode(resp.body);
    } catch (e) {
      return {'raw': resp.body, 'status': resp.statusCode};
    }
  }
}

class APIException implements Exception {
  final dynamic body;
  final int status;
  APIException(this.body, this.status);

  @override
  String toString() => 'APIException($status): $body';
}
