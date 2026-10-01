import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_expense_tracker/services/regex_parser_service.dart';

void main() {
  group('RegexParserService Heuristic Engine Tests', () {
    test('1. Highlands Coffee Receipt Parsing', () {
      const receiptText = '''
HIGHLANDS COFFEE
Tầng 1 Tòa Nhà FPT, Ngũ Hành Sơn, Đà Nẵng
HÓA ĐƠN BÁN HÀNG
Ngày: 01/10/2026 08:30:15
1. Phin Sữa Đá L          45.000
2. Trà Sen Vàng L         55.000
3. Bánh Chuối             29.000
------------------------------------
TỔNG CỘNG: 129.000 VND
Tiền khách đưa: 200.000 VND
Tiền thừa: 71.000 VND
      ''';

      final result = RegexParserService.parseReceiptText(receiptText);

      expect(result.merchantName, equals('Highlands Coffee'));
      expect(result.totalAmount, equals(129000));
      expect(result.currency, equals('VND'));
      expect(result.transactionDate?.day, equals(1));
      expect(result.transactionDate?.month, equals(10));
      expect(result.transactionDate?.year, equals(2026));
      expect(result.suggestedCategoryId, equals('food'));
      expect(result.confidenceScore, greaterThanOrEqualTo(0.9));
    });

    test('2. WinMart+ Grocery Receipt Parsing with "THÀNH TIỀN"', () {
      const receiptText = '''
WINMART+ NAM KỲ KHỞI NGHĨA
Đà Nẵng
PHIẾU THANH TOÁN
Ngày: 29/09/2026 19:12
- Sữa tươi TH True Milk 1L    36.000
- Ức gà phi lê 500g           45.000
- Rau cải ngọt Đà Lạt 300g    15.000
- Trứng gà Ta 10 quả          38.000
------------------------------------
THÀNH TIỀN: 134.000 đ
Thanh toán: VNPAY-QR
      ''';

      final result = RegexParserService.parseReceiptText(receiptText);

      expect(result.merchantName, equals('WinMart+'));
      expect(result.totalAmount, equals(134000));
      expect(result.suggestedCategoryId, equals('groceries'));
      expect(result.transactionDate?.day, equals(29));
      expect(result.transactionDate?.month, equals(9));
      expect(result.transactionDate?.year, equals(2026));
    });

    test('3. Natural Vietnamese Date: "Ngày 28 tháng 09 năm 2026"', () {
      const receiptText = '''
NHÀ SÁCH FAHASA ĐÀ NẴNG
300 Lê Duẩn, Đà Nẵng
HÓA ĐƠN BÁN LẺ
Ngày 28 tháng 09 năm 2026
1. Giáo trình Flutter Cross-Platform   185.000
2. Bút bi Pilot G2                      25.000
------------------------------------
TỔNG CỘNG: 210.000 VNĐ
      ''';

      final result = RegexParserService.parseReceiptText(receiptText);

      expect(result.merchantName, equals('Nhà Sách Fahasa'));
      expect(result.totalAmount, equals(210000));
      expect(result.suggestedCategoryId, equals('education'));
      expect(result.transactionDate?.day, equals(28));
      expect(result.transactionDate?.month, equals(9));
      expect(result.transactionDate?.year, equals(2026));
    });

    test('4. Cash Tendered & Change Disambiguation', () {
      const receiptText = '''
CIRCLE K VIETNAM #108
RECEIPT / PHIẾU THU
Date: 27/09/2026 23:45
1  Mì Trộn Trứng Xúc Xích    32.000
1  Trà Sữa Thái Xanh          22.000
------------------------------------
TOTAL: 54.000 VND
CASH TENDERED: 500.000 VND
CHANGE: 446.000 VND
      ''';

      final result = RegexParserService.parseReceiptText(receiptText);

      // Must pick TOTAL (54,000) instead of CASH TENDERED (500,000) or CHANGE (446,000)
      expect(result.totalAmount, equals(54000));
      expect(result.suggestedCategoryId, equals('groceries'));
    });

    test('5. Empty or Noisy String Handling', () {
      final emptyResult = RegexParserService.parseReceiptText('');
      expect(emptyResult.totalAmount, isNull);
      expect(emptyResult.confidenceScore, equals(0.0));

      final noisyResult = RegexParserService.parseReceiptText('--- *** !!! ???');
      expect(noisyResult.totalAmount, isNull);
    });
  });
}
