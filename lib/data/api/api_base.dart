import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiBase {
  ApiBase({http.Client? client}) : client = client ?? http.Client();

  final http.Client client;

  // Web chạy localhost; Android emulator dùng 10.0.2.2
  String get baseUrl => kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080';

  Uri uri(String path) => Uri.parse('$baseUrl$path');

  Future<String> getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Chưa đăng nhập Firebase.');
    }

    final String? token = await user.getIdToken(true);

    if (token == null || token.isEmpty) {
      throw Exception('Không lấy được Firebase ID token.');
    }

    return token;
  }


  Future<Map<String, String>> headers() async {
    final token = await getIdToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };
  }

  // Helper: decode JSON response
  dynamic decodeBody(String body) => jsonDecode(body);
}
