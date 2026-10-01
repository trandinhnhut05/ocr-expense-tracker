class ReceiptItem {
  final String name;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const ReceiptItem({
    required this.name,
    this.quantity = 1,
    required this.unitPrice,
    required this.totalPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }
}

class ReceiptScanResult {
  final String? merchantName;
  final double? totalAmount;
  final double? subtotal;
  final double? taxAmount;
  final DateTime? transactionDate;
  final String currency; // 'VND', 'USD', etc.
  final List<ReceiptItem> items;
  final String rawText;
  final String? suggestedCategoryId;
  final double confidenceScore; // Aggregate confidence [0.0 - 1.0]
  final List<String> parsingNotes;

  const ReceiptScanResult({
    this.merchantName,
    this.totalAmount,
    this.subtotal,
    this.taxAmount,
    this.transactionDate,
    this.currency = 'VND',
    this.items = const [],
    required this.rawText,
    this.suggestedCategoryId,
    this.confidenceScore = 0.0,
    this.parsingNotes = const [],
  });

  bool get isValid => totalAmount != null && totalAmount! > 0;

  ReceiptScanResult copyWith({
    String? merchantName,
    double? totalAmount,
    double? subtotal,
    double? taxAmount,
    DateTime? transactionDate,
    String? currency,
    List<ReceiptItem>? items,
    String? rawText,
    String? suggestedCategoryId,
    double? confidenceScore,
    List<String>? parsingNotes,
  }) {
    return ReceiptScanResult(
      merchantName: merchantName ?? this.merchantName,
      totalAmount: totalAmount ?? this.totalAmount,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      transactionDate: transactionDate ?? this.transactionDate,
      currency: currency ?? this.currency,
      items: items ?? this.items,
      rawText: rawText ?? this.rawText,
      suggestedCategoryId: suggestedCategoryId ?? this.suggestedCategoryId,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      parsingNotes: parsingNotes ?? this.parsingNotes,
    );
  }
}
