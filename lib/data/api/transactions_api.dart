import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/transaction.dart';
import 'api_base.dart';

class TransactionsApi {
  TransactionsApi(this._base, {http.Client? client})
      : _client = client ?? http.Client();

  final ApiBase _base;
  final http.Client _client;

  Uri _uri(String path) => _base.uri(path);

  Future<List<TransactionModel>> listTransactions() async {
    final res = await _client.get(
      _uri('/api/transactions'),
      headers: await _base.headers(),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
          'GET /api/transactions failed: ${res.statusCode} ${res.body}');
    }

    final decoded = jsonDecode(res.body);

    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((e) => TransactionModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    throw Exception('Unexpected response: ${res.body}');
  }

  Future<String> createTransaction({
    required String type,
    required int amount,
    String? category,
    String? note,
    String? occurredAt,
  }) async {
    final body = jsonEncode({
      'type': type,
      'amount': amount,
      if (category != null) 'category': category,
      if (note != null) 'note': note,
      if (occurredAt != null) 'occurredAt': occurredAt,
    });

    final res = await _client.post(
      _uri('/api/transactions'),
      headers: await _base.headers(),
      body: body,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
          'POST /api/transactions failed: ${res.statusCode} ${res.body}');
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
      if (type != null) 'type': type,
      if (amount != null) 'amount': amount,
      if (category != null) 'category': category,
      if (note != null) 'note': note,
      if (occurredAt != null) 'occurredAt': occurredAt,
    });

    final res = await _client.put(
      _uri('/api/transactions/$id'),
      headers: await _base.headers(),
      body: body,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
          'PUT /api/transactions/$id failed: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> deleteTransaction(String id) async {
    final res = await _client.delete(
      _uri('/api/transactions/$id'),
      headers: await _base.headers(),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
          'DELETE /api/transactions/$id failed: ${res.statusCode} ${res.body}');
    }
  }
}
