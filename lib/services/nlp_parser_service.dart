import '../models/expense.dart';

class ParsedNlpTransaction {
  final String title;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String walletId;
  final String? targetWalletId;
  final double confidence;
  final String explanation;

  ParsedNlpTransaction({
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.walletId,
    this.targetWalletId,
    required this.confidence,
    required this.explanation,
  });
}

class NlpParserService {
  /// Parse natural Vietnamese text into structured transaction parameters
  static ParsedNlpTransaction parse(String rawInput) {
    final input = rawInput.trim();
    final lower = input.toLowerCase();

    // 1. Detect Transfer between Wallets
    if (lower.contains('chuyển') &&
        (lower.contains('sang') || lower.contains('vào') || lower.contains('từ'))) {
      final amount = _extractAmount(lower);
      String srcWallet = 'bank';
      String targetWallet = 'momo';

      // Parse target wallet
      if (lower.contains('sang momo') || lower.contains('vào momo')) {
        targetWallet = 'momo';
      } else if (lower.contains('sang ngân hàng') || lower.contains('vào ngân hàng') ||
          lower.contains('sang vcb') || lower.contains('vào vcb')) {
        targetWallet = 'bank';
      } else if (lower.contains('sang tiền mặt') || lower.contains('vào tiền mặt')) {
        targetWallet = 'cash';
      }

      // Parse source wallet
      if (lower.contains('từ tiền mặt')) {
        srcWallet = 'cash';
      } else if (lower.contains('từ ngân hàng') || lower.contains('từ vcb') || lower.contains('từ mb')) {
        srcWallet = 'bank';
      } else if (lower.contains('từ momo')) {
        srcWallet = 'momo';
      } else {
        // Fallback: choose opposite of target
        srcWallet = (targetWallet == 'momo') ? 'bank' : 'momo';
      }

      return ParsedNlpTransaction(
        title: 'Chuyển tiền nội bộ',
        amount: amount > 0 ? amount : 100000.0,
        type: TransactionType.transfer,
        categoryId: 'other',
        walletId: srcWallet,
        targetWalletId: targetWallet,
        confidence: 0.95,
        explanation: 'Nhận diện chuyển tiền giữa các ví (không tính vào thu/chi)',
      );
    }

    // 2. Detect Income vs Expense
    bool isIncome = false;
    final incomeKeywords = [
      'nhận lương', 'lương', 'thưởng', 'thu nhập', 'học bổng',
      'tiền về', 'tiền thưởng', 'bán hàng', 'thu được', 'được cho'
    ];
    for (final kw in incomeKeywords) {
      if (lower.contains(kw)) {
        isIncome = true;
        break;
      }
    }

    // 3. Extract Amount
    final amount = _extractAmount(lower);

    // 4. Detect Category
    String categoryId = isIncome ? 'income_salary' : 'food';
    String title = input;

    if (!isIncome) {
      if (lower.contains('xăng') || lower.contains('grab') || lower.contains('xe bus') ||
          lower.contains('vé xe') || lower.contains('gửi xe') || lower.contains('đi lại')) {
        categoryId = 'transport';
        title = 'Đi lại / Xăng xe';
      } else if (lower.contains('siêu thị') || lower.contains('winmart') || lower.contains('coop') ||
          lower.contains('tạp hóa') || lower.contains('rau củ') || lower.contains('thịt')) {
        categoryId = 'groceries';
        title = 'Đi siêu thị & Đi chợ';
      } else if (lower.contains('sách') || lower.contains('học phí') || lower.contains('khóa học') ||
          lower.contains('bút') || lower.contains('giáo trình')) {
        categoryId = 'education';
        title = 'Học tập & Giáo trình';
      } else if (lower.contains('điện') || lower.contains('nước') || lower.contains('internet') ||
          lower.contains('tiền nhà') || lower.contains('wifi')) {
        categoryId = 'utilities';
        title = 'Hóa đơn & Tiện ích';
      } else if (lower.contains('phim') || lower.contains('cgv') || lower.contains('game') ||
          lower.contains('du lịch') || lower.contains('bida')) {
        categoryId = 'entertainment';
        title = 'Giải trí & Phim ảnh';
      } else if (lower.contains('quần áo') || lower.contains('giày') || lower.contains('shopee') ||
          lower.contains('mua sắm') || lower.contains('tiki')) {
        categoryId = 'shopping';
        title = 'Mua sắm cá nhân';
      } else if (lower.contains('thuốc') || lower.contains('bệnh viện') || lower.contains('long châu')) {
        categoryId = 'health';
        title = 'Y tế & Sức khỏe';
      } else {
        categoryId = 'food';
        title = input.isNotEmpty ? input : 'Chi tiêu ăn uống';
      }
    } else {
      title = input.isNotEmpty ? input : 'Thu nhập';
    }

    // 5. Detect Wallet
    String walletId = 'cash';
    if (lower.contains('ngân hàng') || lower.contains('vcb') || lower.contains('mb') ||
        lower.contains('ck') || lower.contains('chuyển khoản')) {
      walletId = 'bank';
    } else if (lower.contains('momo') || lower.contains('zalopay') || lower.contains('viettel')) {
      walletId = 'momo';
    } else if (lower.contains('tiền mặt')) {
      walletId = 'cash';
    }

    return ParsedNlpTransaction(
      title: title,
      amount: amount > 0 ? amount : 50000.0,
      type: isIncome ? TransactionType.income : TransactionType.expense,
      categoryId: categoryId,
      walletId: walletId,
      confidence: 0.92,
      explanation: 'AI NLP nhận diện cú pháp tự nhiên: '
          'Loại: ${isIncome ? "Thu nhập" : "Chi tiêu"} • Ví: $walletId • Số tiền: ${amount.toStringAsFixed(0)} ₫',
    );
  }

  static double _extractAmount(String text) {
    // Patterns like: 45k, 45 k, 45 nghìn, 45 ngàn, 45.000, 45000, 3.5tr, 3tr5, 3 triệu
    final trMatch = RegExp(r'(\d+([.,]\d+)?)\s*(tr|triệu)').firstMatch(text);
    if (trMatch != null) {
      final numStr = trMatch.group(1)!.replaceAll(',', '.');
      return (double.tryParse(numStr) ?? 0.0) * 1000000.0;
    }

    final trSplitMatch = RegExp(r'(\d+)tr(\d+)').firstMatch(text);
    if (trSplitMatch != null) {
      final tr = double.tryParse(trSplitMatch.group(1)!) ?? 0.0;
      final decimals = double.tryParse(trSplitMatch.group(2)!) ?? 0.0;
      return (tr * 1000000.0) + (decimals * 100000.0);
    }

    final kMatch = RegExp(r'(\d+([.,]\d+)?)\s*(k|nghìn|ngàn|kđ)').firstMatch(text);
    if (kMatch != null) {
      final numStr = kMatch.group(1)!.replaceAll(',', '.');
      return (double.tryParse(numStr) ?? 0.0) * 1000.0;
    }

    final pureNumberMatch = RegExp(r'(\d{1,3}([.,]\d{3})+|\b\d{4,9}\b)').firstMatch(text);
    if (pureNumberMatch != null) {
      final clean = pureNumberMatch.group(1)!.replaceAll(RegExp(r'[.,]'), '');
      return double.tryParse(clean) ?? 0.0;
    }

    return 0.0;
  }
}
