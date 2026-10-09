import 'category.dart';

enum TransactionType {
  expense,
  income,
  transfer,
}

class Expense {
  final String id;
  final String title;
  final double amount;
  final String categoryId;
  final DateTime date;
  final String? merchant;
  final String? receiptImagePath;
  final String? rawOcrText;
  final double confidenceScore; // 0.0 to 1.0 (from OCR & regex heuristic)
  final String? notes;
  final DateTime createdAt;
  final TransactionType type;
  final String walletId;
  final String? targetWalletId; // Used only when type == TransactionType.transfer

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.merchant,
    this.receiptImagePath,
    this.rawOcrText,
    this.confidenceScore = 1.0,
    this.notes,
    DateTime? createdAt,
    this.type = TransactionType.expense,
    this.walletId = 'cash',
    this.targetWalletId,
  }) : createdAt = createdAt ?? DateTime.now();

  ExpenseCategory get category => ExpenseCategory.getById(categoryId);

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;
  bool get isTransfer => type == TransactionType.transfer;

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    String? categoryId,
    DateTime? date,
    String? merchant,
    String? receiptImagePath,
    String? rawOcrText,
    double? confidenceScore,
    String? notes,
    DateTime? createdAt,
    TransactionType? type,
    String? walletId,
    String? targetWalletId,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      merchant: merchant ?? this.merchant,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      walletId: walletId ?? this.walletId,
      targetWalletId: targetWalletId ?? this.targetWalletId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category_id': categoryId,
      'date': date.toIso8601String(),
      'merchant': merchant,
      'receipt_image_path': receiptImagePath,
      'raw_ocr_text': rawOcrText,
      'confidence_score': confidenceScore,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'type': type.name,
      'wallet_id': walletId,
      'target_wallet_id': targetWalletId,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    final typeName = map['type'] as String? ?? 'expense';
    final parsedType = TransactionType.values.firstWhere(
      (t) => t.name == typeName,
      orElse: () => TransactionType.expense,
    );

    return Expense(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['category_id'] as String,
      date: DateTime.parse(map['date'] as String),
      merchant: map['merchant'] as String?,
      receiptImagePath: map['receipt_image_path'] as String?,
      rawOcrText: map['raw_ocr_text'] as String?,
      confidenceScore: (map['confidence_score'] as num?)?.toDouble() ?? 1.0,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      type: parsedType,
      walletId: map['wallet_id'] as String? ?? 'cash',
      targetWalletId: map['target_wallet_id'] as String?,
    );
  }
}
