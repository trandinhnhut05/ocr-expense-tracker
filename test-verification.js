/**
 * =========================================================================
 * MINI-PROJECT 3: REGEX HEURISTIC PARSER VERIFICATION & BENCHMARK SUITE
 * Course: Cross-Platform Mobile App Development (VKU)
 * Student: Trần Đình Nhứt - MSSV: 23IT203
 * Description: Mirrors the Dart RegexParserService logic in Node.js
 * to verify heuristic accuracy across 10 real-world receipt test cases.
 * =========================================================================
 */

const knownMerchants = [
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

const headerBlacklist = [
  'hóa đơn', 'hoa don', 'phiếu thanh toán', 'phieu thanh toan',
  'phiếu thu', 'receipt', 'tax invoice', 'invoice', 'bill',
  'địa chỉ', 'dia chi', 'đc:', 'dc:', 'address', 'điện thoại',
  'tel:', 'sđt:', 'hotline:', 'mst:', 'mã số thuế', 'wifi',
  'bàn:', 'table:', 'thu ngân', 'cashier', 'stt', 'số:'
];

function parseReceipt(rawText) {
  if (!rawText || !rawText.trim()) {
    return { merchant: null, amount: null, date: null, category: 'other', confidence: 0 };
  }

  const lines = rawText.split('\n').map(l => l.trim()).filter(l => l.length > 0);

  // 1. Merchant Extraction
  let detectedMerchant = null;
  let merchantConfidence = 0.5;
  const searchLines = lines.slice(0, 6);

  for (const line of searchLines) {
    for (const known of knownMerchants) {
      if (line.toLowerCase().includes(known.toLowerCase())) {
        detectedMerchant = known;
        merchantConfidence = 0.98;
        break;
      }
    }
    if (detectedMerchant) break;
  }

  if (!detectedMerchant) {
    for (const line of searchLines) {
      const lower = line.toLowerCase();
      const isBlacklisted = headerBlacklist.some(kw => lower.includes(kw));
      if (!isBlacklisted && line.length >= 3 && !/^\d+$/.test(line) && !/^(?:0|\+84)\d{8,11}$/.test(line.replace(/\s+/g, ''))) {
        const cleaned = line.replace(/^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$/gu, '').trim();
        if (cleaned.length >= 3) {
          detectedMerchant = cleaned;
          merchantConfidence = 0.82;
          break;
        }
      }
    }
  }

  // 2. Monetary Total Extraction
  const totalKeywordsRegex = /(?:TỔNG\s*CỘNG|TONG\s*CONG|THÀNH\s*TIỀN|THANH\s*TIEN|TỔNG\s*TIỀN|TONG\s*TIEN|CẦN\s*THANH\s*TOÁN|CAN\s*THANH\s*TOAN|TIỀN\s*THANH\s*TOÁN|TIEN\s*THANH\s*TOAN|GRAND\s*TOTAL|NET\s*AMOUNT|TOTAL\s*DUE|AMOUNT\s*DUE|BALANCE\s*DUE|TOTAL|TỔNG)\b/i;
  const negativeKeywordsRegex = /(?:TIỀN\s*KHÁCH\s*ĐƯA|TIEN\s*KHACH\s*DUA|TIỀN\s*THỪA|TIEN\s*THUA|TIỀN\s*THỐI|TIEN\s*THOI|CHANGE|CASH\s*TENDERED|GIẢM\s*GIÁ|DISCOUNT|TAX|VAT)/i;

  let detectedTotal = null;
  let amountConfidence = 0.0;

  function extractNumber(str) {
    const usd = str.match(/\$\s*([0-9]+(?:\.[0-9]{2})?)/) || str.match(/([0-9]+\.[0-9]{2})\s*USD/i);
    if (usd) return parseFloat(usd[1]);

    const vndMatches = [...str.matchAll(/([0-9]{1,3}(?:[.,\s][0-9]{3})+(?:\s*(?:đ|d|VND|VNĐ))?)/gi)];
    for (const m of vndMatches) {
      const clean = m[1].replace(/[\s.,đdVNDvndVNĐ]/g, '');
      const val = parseFloat(clean);
      if (val >= 1000) return val;
    }

    const plain = str.match(/\b([0-9]{4,9})\b/);
    if (plain) {
      const val = parseFloat(plain[1]);
      if (val >= 1000) return val;
    }
    return null;
  }

  for (let i = lines.length - 1; i >= 0; i--) {
    const line = lines[i];
    if (negativeKeywordsRegex.test(line)) continue;

    if (totalKeywordsRegex.test(line)) {
      const val = extractNumber(line);
      if (val) {
        detectedTotal = val;
        amountConfidence = line.toUpperCase().includes('TỔNG CỘNG') || line.toUpperCase().includes('GRAND TOTAL') ? 0.98 : 0.88;
        break;
      }
      if (i + 1 < lines.length) {
        const nextVal = extractNumber(lines[i + 1]);
        if (nextVal) {
          detectedTotal = nextVal;
          amountConfidence = 0.85;
          break;
        }
      }
    }
  }

  if (!detectedTotal) {
    let max = 0;
    for (const line of lines) {
      if (negativeKeywordsRegex.test(line)) continue;
      const v = extractNumber(line);
      if (v && v > max && v < 100000000) max = v;
    }
    if (max > 0) {
      detectedTotal = max;
      amountConfidence = 0.65;
    }
  }

  // 3. Date Extraction
  let detectedDate = null;
  const ddmmyyyy = /\b(0?[1-9]|[12][0-9]|3[01])[/\-.](0?[1-9]|1[012])[/\-.](20\d\d)\b/;
  const naturalVi = /(?:ngày|ngay)\s*(0?[1-9]|[12][0-9]|3[01])\s*(?:tháng|thang)\s*(0?[1-9]|1[012])\s*(?:năm|nam)\s*(20\d\d)/i;

  for (const line of lines) {
    const nat = line.match(naturalVi);
    if (nat) {
      detectedDate = `${nat[1].padStart(2, '0')}/${nat[2].padStart(2, '0')}/${nat[3]}`;
      break;
    }
    const ddm = line.match(ddmmyyyy);
    if (ddm) {
      detectedDate = `${ddm[1].padStart(2, '0')}/${ddm[2].padStart(2, '0')}/${ddm[3]}`;
      break;
    }
  }

  // 4. Category Classification
  const m = (detectedMerchant || '').toLowerCase();
  const corpus = `${m} ${lines.join(' ')}`.toLowerCase();
  let category = 'other';

  // Merchant Precedence
  if (/(?:nhà thuốc|pharmacy|long châu|an khang)/.test(m)) {
    category = 'health';
  } else if (/(?:winmart|vinmart|circle k|7-eleven|familymart|gs25|bách hóa xanh|co\.op|lotte mart)/.test(m)) {
    category = 'groceries';
  } else if (/(?:fahasa|phương nam|nhà sách|vku)/.test(m)) {
    category = 'education';
  } else if (/(?:cgv|lotte cinema|bida|karaoke)/.test(m)) {
    category = 'entertainment';
  } else if (/(?:highlands|phúc long|coffee house|trung nguyên|starbucks|kfc|lotteria|jollibee|pizza|shopeefood)/.test(m)) {
    category = 'food';
  } else if (/(?:grab|be group|gojek|petrolimex)/.test(m)) {
    category = 'transport';
  } else if (/(?:evn|điện lực|nước sạch)/.test(m)) {
    category = 'utilities';
  } else {
    // Keyword Fallback
    if (/(?:nhà thuốc|pharmacy|bệnh viện|phòng khám|thuốc|khẩu trang|y tế|bác sĩ|vitamin|panadol)/.test(corpus)) {
      category = 'health';
    } else if (/(?:winmart|vinmart|co\.op|bách hóa|siêu thị|circle k|7-eleven|familymart|gs25|grocery|mart|rau|thịt|sữa|trứng|dầu ăn)/.test(corpus)) {
      category = 'groceries';
    } else if (/(?:cafe|cà phê|coffee|trà|tea|phở|cơm|bún|bánh|lẩu|nướng|highland|phúc long|starbucks|kfc|lotteria|pizza|jollibee|shopeefood|thức uống|ẩm thực)/.test(corpus)) {
      category = 'food';
    } else if (/(?:cgv|lotte cinema|phim|cinema|movie|vé xem phim|karaoke|bida|game|billiard)/.test(corpus)) {
      category = 'entertainment';
    } else if (/(?:vku|đại học|trường|nhà sách|fahasa|phương nam|sách|giáo trình|photo|in ấn|học phí|bút|vở|study)/.test(corpus)) {
      category = 'education';
    } else if (/(?:grab|\bbe\b|gojek|taxi|xăng|petrolimex|bến xe|vé xe|gửi xe|parking|vận tải|toll)/.test(corpus)) {
      category = 'transport';
    } else if (/(?:điện lực|evn|nước sạch|cấp nước|viettel|vinaphone|mobifone|fpt|internet|tiền điện|tiền nước|cước internet)/.test(corpus)) {
      category = 'utilities';
    } else if (/(?:shopee|lazada|tiki|uniqlo|zara|quần áo|thời trang|giày|dép|mỹ phẩm|son|retail|store)/.test(corpus)) {
      category = 'shopping';
    }
  }

  const confidence = ((merchantConfidence + amountConfidence + (detectedDate ? 0.9 : 0.3)) / 3).toFixed(2);

  return {
    merchant: detectedMerchant,
    amount: detectedTotal,
    date: detectedDate,
    category,
    confidence: parseFloat(confidence)
  };
}

// =========================================================================
// TEST SUITE: 10 REAL-WORLD RECEIPTS
// =========================================================================
const testCases = [
  {
    name: '1. Highlands Coffee (FPT City Đà Nẵng)',
    text: `HIGHLANDS COFFEE
Tầng 1 Tòa Nhà FPT, Ngũ Hành Sơn, Đà Nẵng
HÓA ĐƠN BÁN HÀNG
Ngày: 01/10/2026 08:30:15
1. Phin Sữa Đá L          45.000
2. Trà Sen Vàng L         55.000
3. Bánh Chuối             29.000
------------------------------------
TỔNG CỘNG: 129.000 VND
Tiền khách đưa: 200.000 VND
Tiền thừa: 71.000 VND`,
    expected: { merchant: 'Highlands Coffee', amount: 129000, date: '01/10/2026', category: 'food' }
  },
  {
    name: '2. WinMart+ Siêu Thị',
    text: `WINMART+ NAM KỲ KHỞI NGHĨA
Đà Nẵng
PHIẾU THANH TOÁN
Ngày: 29/09/2026 19:12
- Sữa tươi TH True Milk 1L    36.000
- Ức gà phi lê 500g           45.000
- Trứng gà Ta 10 quả          38.000
- Rau cải ngọt Đà Lạt 300g    15.000
------------------------------------
THÀNH TIỀN: 134.000 đ
Thanh toán: VNPAY-QR`,
    expected: { merchant: 'WinMart+', amount: 134000, date: '29/09/2026', category: 'groceries' }
  },
  {
    name: '3. Nhà Sách Fahasa (Natural Vi Date)',
    text: `NHÀ SÁCH FAHASA ĐÀ NẴNG
300 Lê Duẩn, Đà Nẵng
HÓA ĐƠN BÁN LẺ
Ngày 28 tháng 09 năm 2026
1. Giáo trình Flutter Cross-Platform   185.000
2. Bút bi Pilot G2                      25.000
------------------------------------
TỔNG CỘNG: 210.000 VNĐ`,
    expected: { merchant: 'Nhà Sách Fahasa', amount: 210000, date: '28/09/2026', category: 'education' }
  },
  {
    name: '4. Circle K (Cash & Change Negative Lookahead)',
    text: `CIRCLE K VIETNAM #108
RECEIPT / PHIẾU THU
Date: 27/09/2026 23:45
1  Mì Trộn Trứng Xúc Xích    32.000
1  Trà Sữa Thái Xanh          22.000
------------------------------------
TOTAL: 54.000 VND
CASH TENDERED: 500.000 VND
CHANGE: 446.000 VND`,
    expected: { merchant: 'Circle K', amount: 54000, date: '27/09/2026', category: 'groceries' }
  },
  {
    name: '5. Grab Rides Chuyến Đi KTX',
    text: `GRAB RIDES
Biên lai điện tử chuyến đi
Ngày: 26/09/2026 14:10
Từ: Ký túc xá VKU
Đến: Trung tâm Hành chính Đà Nẵng
------------------------------------
TỔNG TIỀN: 48.000 VND`,
    expected: { merchant: 'Grab Rides', amount: 48000, date: '26/09/2026', category: 'transport' }
  },
  {
    name: '6. CGV Cinema Vé Phim Cuối Tuần',
    text: `CGV CINEMAS VINCOM DA NANG
PHIẾU THANH TOÁN VÉ PHIM
Ngày: 25/09/2026 19:30
2 Vé 2D Phim Hoạt Hình   220.000
------------------------------------
TỔNG CỘNG: 220.000 đ`,
    expected: { merchant: 'CGV Cinemas', amount: 220000, date: '25/09/2026', category: 'entertainment' }
  },
  {
    name: '7. EVN Tiền Điện Sinh Hoạt',
    text: `EVN ĐIỆN LỰC MIỀN TRUNG
THÔNG BÁO TIỀN ĐIỆN THÁNG 9/2026
Ngày: 24/09/2026
Số công tơ: 9812401
Điện năng tiêu thụ: 180 kWh
TỔNG TIỀN THANH TOÁN: 450.000 VND`,
    expected: { merchant: 'EVN Điện Lực', amount: 450000, date: '24/09/2026', category: 'utilities' }
  },
  {
    name: '8. Nhà Thuốc Long Châu (Thuốc & Vitamin)',
    text: `HỆ THỐNG NHÀ THUỐC LONG CHÂU
HÓA ĐƠN BÁN LẺ
Ngày: 22/09/2026 10:15
1. Panadol Extra 1 Vỉ          25.000
2. Viên sủi Berocca Cam        90.000
------------------------------------
THÀNH TIỀN: 115.000 VND`,
    expected: { merchant: 'Nhà Thuốc Long Châu', amount: 115000, date: '22/09/2026', category: 'health' }
  },
  {
    name: '9. Phúc Long Coffee & Tea',
    text: `PHÚC LONG COFFEE & TEA
Chi nhánh Đà Nẵng
PHIẾU THANH TOÁN
Ngày: 20/09/2026 15:40
1. Trà Đào Cam Sả L    65.000
2. Bánh Mì Phúc Long   35.000
------------------------------------
TỔNG CỘNG: 100.000 VND`,
    expected: { merchant: 'Phúc Long', amount: 100000, date: '20/09/2026', category: 'food' }
  },
  {
    name: '10. Cửa Hàng Chưa Đăng Ký (Heuristic Title Fallback)',
    text: `TIỆM CƠM GÀ BÀ BUỘI
22 Phan Chu Trinh, Đà Nẵng
HÓA ĐƠN TÍNH TIỀN
Ngày: 18/09/2026
1. Cơm gà xé đĩa lớn   60.000
2. Nước trà đá          5.000
------------------------------------
TỔNG CỘNG: 65.000 đ`,
    expected: { merchant: 'TIỆM CƠM GÀ BÀ BUỘI', amount: 65000, date: '18/09/2026', category: 'food' }
  }
];

console.log('================================================================');
console.log('  MINI-PROJECT 3: AUTOMATED OCR REGEX HEURISTIC VERIFICATION   ');
console.log('  Sinh viên: Trần Đình Nhứt - MSSV: 23IT203 (Lớp 23IT) - VKU    ');
console.log('================================================================\n');

let passedCases = 0;
const startTime = Date.now();

testCases.forEach((tc, idx) => {
  const result = parseReceipt(tc.text);
  const merchantOk = result.merchant === tc.expected.merchant;
  const amountOk = result.amount === tc.expected.amount;
  const dateOk = result.date === tc.expected.date;
  const catOk = result.category === tc.expected.category;
  const allPass = merchantOk && amountOk && dateOk && catOk;

  if (allPass) passedCases++;

  const statusSymbol = allPass ? '✅ PASS' : '❌ FAIL';
  console.log(`[Test ${idx + 1}/10] ${tc.name} -> ${statusSymbol}`);
  console.log(`   - Merchant: ${result.merchant} ${merchantOk ? '✓' : `(Exp: ${tc.expected.merchant})`}`);
  console.log(`   - Amount:   ${result.amount} VND ${amountOk ? '✓' : `(Exp: ${tc.expected.amount})`}`);
  console.log(`   - Date:     ${result.date} ${dateOk ? '✓' : `(Exp: ${tc.expected.date})`}`);
  console.log(`   - Category: ${result.category} ${catOk ? '✓' : `(Exp: ${tc.expected.category})`}`);
  console.log(`   - AI Score: ${(result.confidence * 100).toFixed(0)}%\n`);
});

const duration = Date.now() - startTime;
const successRate = ((passedCases / testCases.length) * 100).toFixed(1);

console.log('----------------------------------------------------------------');
console.log(`  KẾT QUẢ KIỂM THỬ: ${passedCases}/${testCases.length} Test Cases Thành Công (${successRate}%)`);
console.log(`  Thời gian thực thi: ${duration} ms (Trung bình: ${(duration / testCases.length).toFixed(2)} ms/hóa đơn)`);
console.log('================================================================\n');

if (passedCases === testCases.length) {
  console.log('🎉 TẤT CẢ TEST CASES HEURISTIC ĐẠT 100% TIÊU CHÍ BÀI TOÁN!');
  process.exit(0);
} else {
  console.log('⚠️ Có test case chưa khớp kỳ vọng.');
  process.exit(1);
}
