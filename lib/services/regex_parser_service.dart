import '../models/receipt_scan_result.dart';

class RegexParserService {
  static const List<String> knownMerchants = [
    'WinMart+',
    'Highlands Coffee',
    'The Coffee House',
    'Trung Nguyên Legend',
    'Nhà Thuốc Long Châu',
    'Nhà Thuốc An Khang',
    'Nhà Sách Phương Nam',
    'Nhà Sách Fahasa',
    'CGV Cinemas',
    'Lotte Cinema',
    'Bách Hóa Xanh',
    'EVN Điện Lực',
    'KFC Vietnam',
    'ShopeeFood',
    'Grab Rides',
    'Pizza 4P\'s',
    'FamilyMart',
    '7-Eleven',
    'Circle K',
    'Co.opmart',
    'Lotte Mart',
    'McDonald\'s',
    'Pizza Hut',
    'GrabFood',
    'WinMart',
    'Phúc Long',
    'Starbucks',
    'Lotteria',
    'Jollibee',
    'Be Group',
    'Petrolimex',
    'GS25',
  ];

  static const List<String> headerBlacklistKeywords = [
    'hóa đơn',
    'hoa don',
    'phiếu thanh toán',
    'phieu thanh toan',
    'phiếu thu',
    'receipt',
    'tax invoice',
    'invoice',
    'bill',
    'địa chỉ',
    'dia chi',
    'đc:',
    'dc:',
    'address',
    'điện thoại',
    'tel:',
    'sđt:',
    'hotline:',
    'mst:',
    'mã số thuế',
    'wifi',
    'bàn:',
    'table:',
    'thu ngân',
    'cashier',
    'stt',
    'số:',
  ];

  /// Parses raw OCR text using heuristic regular expressions.
  static ReceiptScanResult parseReceiptText(String rawText) {
    if (rawText.trim().isEmpty) {
      return const ReceiptScanResult(
        rawText: '',
        confidenceScore: 0.0,
        parsingNotes: ['Dữ liệu OCR rỗng'],
      );
    }

    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final notes = <String>[];

    // 1. Extract Merchant Name
    final merchantResult = _extractMerchant(lines);
    if (merchantResult.merchant != null) {
      notes.add(
          'Phát hiện đơn vị bán: "${merchantResult.merchant}" (${merchantResult.method})');
    }

    // 2. Extract Total Monetary Amount
    final amountResult = _extractTotalAmount(lines);
    if (amountResult.amount != null) {
      notes.add(
          'Trích xuất tổng tiền: ${amountResult.amount} ${amountResult.currency} (Độ tin cậy: ${(amountResult.confidence * 100).toStringAsFixed(0)}%)');
    }

    // 3. Extract Transaction Date & Time
    final dateResult = _extractDate(lines);
    if (dateResult.date != null) {
      notes.add(
          'Trích xuất ngày GD: ${dateResult.date!.day.toString().padLeft(2, '0')}/${dateResult.date!.month.toString().padLeft(2, '0')}/${dateResult.date!.year}');
    }

    // 4. Suggest Category based on extracted info
    final suggestedCategory = _suggestCategory(
      merchantResult.merchant,
      lines,
    );
    notes.add('Gợi ý phân loại: $suggestedCategory');

    // 5. Calculate Aggregate Confidence Score
    double totalConfidence = 0.0;
    int factors = 0;

    if (amountResult.amount != null) {
      totalConfidence += amountResult.confidence;
      factors++;
    }
    if (merchantResult.merchant != null) {
      totalConfidence += merchantResult.confidence;
      factors++;
    }
    if (dateResult.date != null) {
      totalConfidence += 0.9;
      factors++;
    }

    final aggregateConfidence = factors > 0 ? (totalConfidence / factors) : 0.2;

    return ReceiptScanResult(
      merchantName: merchantResult.merchant,
      totalAmount: amountResult.amount,
      subtotal: amountResult.subtotal,
      taxAmount: amountResult.tax,
      transactionDate: dateResult.date ?? DateTime.now(),
      currency: amountResult.currency,
      rawText: rawText,
      suggestedCategoryId: suggestedCategory,
      confidenceScore: double.parse(aggregateConfidence.toStringAsFixed(2)),
      parsingNotes: notes,
    );
  }

  // =========================================================================
  // HEURISTIC 1: MERCHANT NAME EXTRACTION
  // =========================================================================
  static _MerchantExtractionResult _extractMerchant(List<String> lines) {
    final searchLines = lines.take(6).toList();

    // Check against known merchants dictionary with case-insensitive matching
    for (final line in searchLines) {
      for (final known in knownMerchants) {
        if (line.toLowerCase().contains(known.toLowerCase())) {
          return _MerchantExtractionResult(
            merchant: known,
            confidence: 0.98,
            method: 'Từ điển thương hiệu đã đăng ký',
          );
        }
      }
    }

    // Heuristic: First clean non-blacklisted title-case or uppercase line
    for (final line in searchLines) {
      final lower = line.toLowerCase();
      final isBlacklisted = headerBlacklistKeywords.any((kw) => lower.contains(kw));

      if (!isBlacklisted && line.length >= 3 && !RegExp(r'^\d+$').hasMatch(line)) {
        // Exclude lines with only symbols or phone numbers
        if (!RegExp(r'^(?:0|\+84)\d{8,11}$').hasMatch(line.replaceAll(' ', ''))) {
          // Clean up line
          final cleaned = line
              .replaceAll(RegExp(r'^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$', unicode: true), '')
              .trim();
          if (cleaned.length >= 3) {
            return _MerchantExtractionResult(
              merchant: cleaned,
              confidence: 0.82,
              method: 'Heuristic tiêu đề hóa đơn',
            );
          }
        }
      }
    }

    return const _MerchantExtractionResult(
      merchant: 'Hóa đơn bán lẻ',
      confidence: 0.5,
      method: 'Giá trị mặc định',
    );
  }

  // =========================================================================
  // HEURISTIC 2: MONETARY TOTAL EXTRACTION
  // =========================================================================
  static _AmountExtractionResult _extractTotalAmount(List<String> lines) {
    // Regex for matching Total labels
    final totalKeywordsRegex = RegExp(
      r'(?:TỔNG\s*CỘNG|TONG\s*CONG|THÀNH\s*TIỀN|THANH\s*TIEN|TỔNG\s*TIỀN|TONG\s*TIEN|CẦN\s*THANH\s*TOÁN|CAN\s*THANH\s*TOAN|TIỀN\s*THANH\s*TOÁN|TIEN\s*THANH\s*TOAN|GRAND\s*TOTAL|NET\s*AMOUNT|TOTAL\s*DUE|AMOUNT\s*DUE|BALANCE\s*DUE|TOTAL|TỔNG)\b',
      caseSensitive: false,
    );

    // Negative keywords: Avoid capturing cash given or change
    final negativeKeywordsRegex = RegExp(
      r'(?:TIỀN\s*KHÁCH\s*ĐƯA|TIEN\s*KHACH\s*DUA|TIỀN\s*THỪA|TIEN\s*THUA|TIỀN\s*THỐI|TIEN\s*THOI|CHANGE|CASH\s*TENDERED|GIẢM\s*GIÁ|DISCOUNT|TAX|VAT|TIỀN\s*TÍCH\s*LŨY)',
      caseSensitive: false,
    );

    double? detectedTotal;
    double? detectedSubtotal;
    double? detectedTax;
    String detectedCurrency = 'VND';
    double confidence = 0.0;

    // Search from bottom up, because grand totals typically sit near bottom
    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i];

      // Check negative keywords first
      if (negativeKeywordsRegex.hasMatch(line)) {
        continue;
      }

      if (totalKeywordsRegex.hasMatch(line)) {
        final amountCandidate = _extractNumberFromLine(line);
        if (amountCandidate != null && amountCandidate.value > 0) {
          detectedTotal = amountCandidate.value;
          detectedCurrency = amountCandidate.currency;
          confidence = line.toUpperCase().contains('TỔNG CỘNG') ||
                  line.toUpperCase().contains('GRAND TOTAL')
              ? 0.98
              : 0.88;
          break;
        }

        // If amount was not in the same line, check immediate next line
        if (i + 1 < lines.length) {
          final nextLineCandidate = _extractNumberFromLine(lines[i + 1]);
          if (nextLineCandidate != null && nextLineCandidate.value > 0) {
            detectedTotal = nextLineCandidate.value;
            detectedCurrency = nextLineCandidate.currency;
            confidence = 0.85;
            break;
          }
        }
      }
    }

    // Fallback: If no explicit total label matched, search for the maximum plausible numeric amount
    if (detectedTotal == null) {
      double maxVal = 0.0;
      for (final line in lines) {
        if (negativeKeywordsRegex.hasMatch(line)) continue;
        final candidate = _extractNumberFromLine(line);
        if (candidate != null &&
            candidate.value > maxVal &&
            candidate.value < 100000000) {
          // Plausible single receipt <= 100M VND
          maxVal = candidate.value;
          detectedCurrency = candidate.currency;
        }
      }
      if (maxVal > 0) {
        detectedTotal = maxVal;
        confidence = 0.65;
      }
    }

    return _AmountExtractionResult(
      amount: detectedTotal,
      subtotal: detectedSubtotal,
      tax: detectedTax,
      currency: detectedCurrency,
      confidence: confidence,
    );
  }

  static _ExtractedNumber? _extractNumberFromLine(String line) {
    // Check for USD format: $12.50 or 12.50 USD
    final usdMatch = RegExp(r'\$\s*([0-9]+(?:\.[0-9]{2})?)').firstMatch(line) ??
        RegExp(r'([0-9]+\.[0-9]{2})\s*(?:USD)').firstMatch(line);
    if (usdMatch != null) {
      final val = double.tryParse(usdMatch.group(1)!);
      if (val != null) {
        return _ExtractedNumber(value: val, currency: 'USD');
      }
    }

    // Check for VND format: 150.000 or 150,000 or 150 000 with optional đ/VND
    // Exclude phone numbers, dates (01/10/2026), tax codes
    final vndPattern = RegExp(
      r'([0-9]{1,3}(?:[.,\s][0-9]{3})+(?:\s*(?:đ|d|VND|VNĐ))?)',
      caseSensitive: false,
    );

    final matches = vndPattern.allMatches(line);
    for (final match in matches) {
      final rawMatch = match.group(1)!;
      // Strip currency tags and delimiters
      final cleanDigits = rawMatch
          .replaceAll(RegExp(r'[\s.,đdVNDvndVNĐ]'), '')
          .trim();
      final val = double.tryParse(cleanDigits);
      if (val != null && val >= 1000) {
        // Reasonable VND amount >= 1,000đ
        return _ExtractedNumber(value: val, currency: 'VND');
      }
    }

    // Also handle plain numbers with no thousands separator if labeled
    final plainPattern = RegExp(r'\b([0-9]{4,9})\b');
    final plainMatch = plainPattern.firstMatch(line);
    if (plainMatch != null) {
      final val = double.tryParse(plainMatch.group(1)!);
      if (val != null && val >= 1000) {
        return _ExtractedNumber(value: val, currency: 'VND');
      }
    }

    return null;
  }

  // =========================================================================
  // HEURISTIC 3: TRANSACTION DATE & TIME EXTRACTION
  // =========================================================================
  static _DateExtractionResult _extractDate(List<String> lines) {
    // Pattern 1: DD/MM/YYYY or DD-MM-YYYY or DD.MM.YYYY
    final ddmmyyyy = RegExp(
      r'\b(0?[1-9]|[12][0-9]|3[01])[/\-.](0?[1-9]|1[012])[/\-.](20\d\d)\b',
    );

    // Pattern 2: YYYY/MM/DD or YYYY-MM-DD
    final yyyymmdd = RegExp(
      r'\b(20\d\d)[/\-.](0?[1-9]|1[012])[/\-.](0?[1-9]|[12][0-9]|3[01])\b',
    );

    // Pattern 3: Natural Vietnamese: Ngày 01 tháng 10 năm 2026
    final naturalVi = RegExp(
      r'(?:ngày|ngay)\s*(0?[1-9]|[12][0-9]|3[01])\s*(?:tháng|thang)\s*(0?[1-9]|1[012])\s*(?:năm|nam)\s*(20\d\d)',
      caseSensitive: false,
    );

    // Time pattern: HH:mm or HH:mm:ss
    final timePattern = RegExp(r'\b([01]?[0-9]|2[0-3]):([0-5][0-9])(?::([0-5][0-9]))?\b');

    DateTime? foundDate;
    int hour = 12;
    int minute = 0;

    for (final line in lines) {
      // Find time if not found
      final timeMatch = timePattern.firstMatch(line);
      if (timeMatch != null) {
        hour = int.parse(timeMatch.group(1)!);
        minute = int.parse(timeMatch.group(2)!);
      }

      final natMatch = naturalVi.firstMatch(line);
      if (natMatch != null) {
        final d = int.parse(natMatch.group(1)!);
        final m = int.parse(natMatch.group(2)!);
        final y = int.parse(natMatch.group(3)!);
        foundDate = DateTime(y, m, d, hour, minute);
        break;
      }

      final ddmmyyyyMatch = ddmmyyyy.firstMatch(line);
      if (ddmmyyyyMatch != null) {
        final d = int.parse(ddmmyyyyMatch.group(1)!);
        final m = int.parse(ddmmyyyyMatch.group(2)!);
        final y = int.parse(ddmmyyyyMatch.group(3)!);
        foundDate = DateTime(y, m, d, hour, minute);
        break;
      }

      final yyyymmddMatch = yyyymmdd.firstMatch(line);
      if (yyyymmddMatch != null) {
        final y = int.parse(yyyymmddMatch.group(1)!);
        final m = int.parse(yyyymmddMatch.group(2)!);
        final d = int.parse(yyyymmddMatch.group(3)!);
        foundDate = DateTime(y, m, d, hour, minute);
        break;
      }
    }

    return _DateExtractionResult(date: foundDate);
  }

  // =========================================================================
  // HEURISTIC 4: CATEGORY AUTO-CLASSIFICATION
  // =========================================================================
  static String _suggestCategory(String? merchant, List<String> lines) {
    final m = (merchant ?? '').toLowerCase();
    final corpus = '$m ${lines.join(' ')}'.toLowerCase();

    // 1. Direct Merchant-Based Priority Mapping
    if (RegExp(r'(?:nhà thuốc|pharmacy|long châu|an khang)').hasMatch(m)) {
      return 'health';
    }
    if (RegExp(r'(?:winmart|vinmart|circle k|7-eleven|familymart|gs25|bách hóa xanh|co\.op|lotte mart)').hasMatch(m)) {
      return 'groceries';
    }
    if (RegExp(r'(?:fahasa|phương nam|nhà sách|vku)').hasMatch(m)) {
      return 'education';
    }
    if (RegExp(r'(?:cgv|lotte cinema|bida|karaoke)').hasMatch(m)) {
      return 'entertainment';
    }
    if (RegExp(r'(?:highlands|phúc long|coffee house|trung nguyên|starbucks|kfc|lotteria|jollibee|pizza|shopeefood)').hasMatch(m)) {
      return 'food';
    }
    if (RegExp(r'(?:grab|be group|gojek|petrolimex)').hasMatch(m)) {
      return 'transport';
    }
    if (RegExp(r'(?:evn|điện lực|nước sạch)').hasMatch(m)) {
      return 'utilities';
    }

    // 2. Keyword-Based Fallback Mapping across entire receipt
    if (RegExp(r'(?:nhà thuốc|pharmacy|bệnh viện|phòng khám|thuốc|khẩu trang|y tế|bác sĩ|vitamin|panadol)')
        .hasMatch(corpus)) {
      return 'health';
    }

    if (RegExp(r'(?:winmart|vinmart|co\.op|bách hóa|siêu thị|circle k|7-eleven|familymart|gs25|grocery|mart|rau|thịt|sữa|trứng|dầu ăn)')
        .hasMatch(corpus)) {
      return 'groceries';
    }

    if (RegExp(r'(?:cafe|cà phê|coffee|trà|tea|phở|cơm|bún|bánh|lẩu|nướng|highland|phúc long|starbucks|kfc|lotteria|pizza|jollibee|shopeefood|thức uống|ẩm thực)')
        .hasMatch(corpus)) {
      return 'food';
    }

    if (RegExp(r'(?:cgv|lotte cinema|phim|cinema|movie|vé xem phim|karaoke|bida|game|billiard)')
        .hasMatch(corpus)) {
      return 'entertainment';
    }

    if (RegExp(r'(?:vku|đại học|trường|nhà sách|fahasa|phương nam|sách|giáo trình|photo|in ấn|học phí|bút|vở|study)')
        .hasMatch(corpus)) {
      return 'education';
    }

    if (RegExp(r'(?:grab|\bbe\b|gojek|taxi|xăng|petrolimex|bến xe|vé xe|gửi xe|parking|vận tải|toll)')
        .hasMatch(corpus)) {
      return 'transport';
    }

    if (RegExp(r'(?:điện lực|evn|nước sạch|cấp nước|viettel|vinaphone|mobifone|fpt|internet|tiền điện|tiền nước|cước internet)')
        .hasMatch(corpus)) {
      return 'utilities';
    }

    if (RegExp(r'(?:shopee|lazada|tiki|uniqlo|zara|quần áo|thời trang|giày|dép|mỹ phẩm|son|retail|store)')
        .hasMatch(corpus)) {
      return 'shopping';
    }

    return 'other';
  }
}

// Supporting heuristic internal records
class _MerchantExtractionResult {
  final String? merchant;
  final double confidence;
  final String method;

  const _MerchantExtractionResult({
    this.merchant,
    required this.confidence,
    required this.method,
  });
}

class _AmountExtractionResult {
  final double? amount;
  final double? subtotal;
  final double? tax;
  final String currency;
  final double confidence;

  const _AmountExtractionResult({
    this.amount,
    this.subtotal,
    this.tax,
    required this.currency,
    required this.confidence,
  });
}

class _ExtractedNumber {
  final double value;
  final String currency;

  const _ExtractedNumber({required this.value, required this.currency});
}

class _DateExtractionResult {
  final DateTime? date;

  const _DateExtractionResult({this.date});
}
