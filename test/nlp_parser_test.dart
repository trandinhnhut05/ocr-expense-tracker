import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_expense_tracker/models/expense.dart';
import 'package:ocr_expense_tracker/services/nlp_parser_service.dart';

void main() {
  group('NlpParserService Tests', () {
    test('1. Parse natural expense "Ăn trưa 45k bằng tiền mặt"', () {
      final res = NlpParserService.parse('Ăn trưa 45k bằng tiền mặt');
      expect(res.type, TransactionType.expense);
      expect(res.amount, 45000.0);
      expect(res.categoryId, 'food');
      expect(res.walletId, 'cash');
    });

    test('2. Parse salary income "Nhận lương 15 triệu vào ngân hàng"', () {
      final res = NlpParserService.parse('Nhận lương 15 triệu vào ngân hàng');
      expect(res.type, TransactionType.income);
      expect(res.amount, 15000000.0);
      expect(res.walletId, 'bank');
    });

    test('3. Parse gas expense "Đổ xăng xe máy 60k Momo"', () {
      final res = NlpParserService.parse('Đổ xăng xe máy 60k Momo');
      expect(res.type, TransactionType.expense);
      expect(res.amount, 60000.0);
      expect(res.categoryId, 'transport');
      expect(res.walletId, 'momo');
    });

    test('4. Parse internal transfer "Chuyển 500k từ ngân hàng sang Momo"', () {
      final res = NlpParserService.parse('Chuyển 500k từ ngân hàng sang Momo');
      expect(res.type, TransactionType.transfer);
      expect(res.amount, 500000.0);
      expect(res.walletId, 'bank');
      expect(res.targetWalletId, 'momo');
    });
  });
}
