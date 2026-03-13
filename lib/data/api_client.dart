import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'models/transaction.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  // Web chạy trên máy bạn => backend cũng localhost
  // Nếu sau này chạy Android emulator: đổi thành http://10.0.2.2:8080
  final String baseUrl = kIsWeb
      ? 'http://localhost:8080'
      : 'http://10.0.2.2:8080';

  final http.Client _client;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<String> _getIdToken() async {
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

  Future<Map<String, String>> _headers() async {
    final token = await _getIdToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };
  }

  // -------- Transactions --------

  Future<List<TransactionModel>> listTransactions() async {
    final res = await _client.get(
      _uri('/api/transactions'),
      headers: await _headers(),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('GET /api/transactions failed: ${res.statusCode} ${res.body}');
    }

    final decoded = jsonDecode(res.body);

    // Backend trả List<Map>
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((e) => TransactionModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    // Nếu backend trả object lạ
    throw Exception('Unexpected response: ${res.body}');
  }

  Future<TransactionModel> getTransaction(String id) async {
    final res = await _client.get(
      _uri('/api/transactions/$id'),
      headers: await _headers(),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('GET /api/transactions/$id failed: ${res.statusCode} ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    return TransactionModel.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<String> createTransaction({
    required String type,
    required int amount,
    String? category,
    String? note,
    String? occurredAt,
  }) async {
    final body = jsonEncode({
      "type": type,
      "amount": amount,
      if (category != null) "category": category,
      if (note != null) "note": note,
      if (occurredAt != null) "occurredAt": occurredAt,
    });

    final res = await _client.post(
      _uri('/api/transactions'),
      headers: await _headers(),
      body: body,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('POST /api/transactions failed: ${res.statusCode} ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    return (decoded['id'] ?? '').toString();
  }

  Future<void> updateTransaction(
      String id, {
        String? type,
        int? amount,
        String? category,
        String? note,
        String? occurredAt,
      }) async {
    final body = jsonEncode({
      if (type != null) "type": type,
      if (amount != null) "amount": amount,
      if (category != null) "category": category,
      if (note != null) "note": note,
      if (occurredAt != null) "occurredAt": occurredAt,
    });

    final res = await _client.put(
      _uri('/api/transactions/$id'),
      headers: await _headers(),
      body: body,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('PUT /api/transactions/$id failed: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> deleteTransaction(String id) async {
    final res = await _client.delete(
      _uri('/api/transactions/$id'),
      headers: await _headers(),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('DELETE /api/transactions/$id failed: ${res.statusCode} ${res.body}');
    }
  }
}