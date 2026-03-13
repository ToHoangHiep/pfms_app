class TransactionModel {
  final String id;
  final String type; // "income" | "expense"
  final int amount;
  final String? category;
  final String? note;
  final String? occurredAt; // ISO string

  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    this.category,
    this.note,
    this.occurredAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      amount: (json['amount'] is int)
          ? json['amount'] as int
          : int.tryParse((json['amount'] ?? '0').toString()) ?? 0,
      category: json['category']?.toString(),
      note: json['note']?.toString(),
      occurredAt: json['occurredAt']?.toString(),
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      "type": type,
      "amount": amount,
      if (category != null) "category": category,
      if (note != null) "note": note,
      if (occurredAt != null) "occurredAt": occurredAt,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    // update dạng partial: chỉ gửi field nào có
    return {
      "amount": amount,
      if (category != null) "category": category,
      if (note != null) "note": note,
      if (occurredAt != null) "occurredAt": occurredAt,
      if (type.isNotEmpty) "type": type,
    };
  }
}