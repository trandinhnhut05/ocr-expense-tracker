/**
 * VKU Mini-Project 3: Interactive CustomPainter & Regex Parser Simulator
 * Student: Trần Đình Nhứt - MSSV: 23IT203
 */

// Category Palette matching Flutter ExpenseCategory
const categories = {
  food: { name: 'Ăn uống & Cà phê', color: '#FF5722' },
  groceries: { name: 'Siêu thị & Tạp hóa', color: '#4CAF50' },
  shopping: { name: 'Mua sắm & Đồ dùng', color: '#E91E63' },
  transport: { name: 'Di chuyển & Xăng xe', color: '#2196F3' },
  utilities: { name: 'Điện nước & Hóa đơn', color: '#FFC107' },
  entertainment: { name: 'Giải trí & Phim ảnh', color: '#9C27B0' },
  education: { name: 'Học tập & Sách vở', color: '#00BCD4' },
  health: { name: 'Sức khỏe & Thuốc men', color: '#009688' },
  other: { name: 'Chi tiêu khác', color: '#78909C' }
};

// Preset Receipts
const sampleReceipts = [
  {
    merchant: 'Highlands Coffee',
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
Tiền thừa: 71.000 VND`
  },
  {
    merchant: 'WinMart+',
    text: `WINMART+ NAM KỲ KHỞI NGHĨA
Đà Nẵng
PHIẾU THANH TOÁN
Ngày: 29/09/2026 19:12
- Sữa tươi TH True Milk 1L    36.000
- Ức gà phi lê 500g           45.000
- Rau cải ngọt Đà Lạt 300g    15.000
- Trứng gà Ta 10 quả          38.000
------------------------------------
THÀNH TIỀN: 134.000 đ
Thanh toán: VNPAY-QR`
  },
  {
    merchant: 'Nhà Sách Fahasa',
    text: `NHÀ SÁCH FAHASA ĐÀ NẴNG
300 Lê Duẩn, Đà Nẵng
HÓA ĐƠN BÁN LẺ
Ngày 28 tháng 09 năm 2026
1. Giáo trình Flutter Cross-Platform   185.000
2. Bút bi Pilot G2                      25.000
------------------------------------
TỔNG CỘNG: 210.000 VNĐ`
  },
  {
    merchant: 'Circle K',
    text: `CIRCLE K VIETNAM #108
RECEIPT / PHIẾU THU
Date: 27/09/2026 23:45
1  Mì Trộn Trứng Xúc Xích    32.000
1  Trà Sữa Thái Xanh          22.000
------------------------------------
TOTAL: 54.000 VND
CASH TENDERED: 500.000 VND
CHANGE: 446.000 VND`
  },
  {
    merchant: 'Grab Rides',
    text: `GRAB RIDES
Biên lai điện tử chuyến đi
Ngày: 26/09/2026 14:10
Từ: Ký túc xá VKU
Đến: Trung tâm Hành chính Đà Nẵng
------------------------------------
TỔNG TIỀN: 48.000 VND`
  },
  {
    merchant: 'CGV Cinemas',
    text: `CGV CINEMAS VINCOM DA NANG
PHIẾU THANH TOÁN VÉ PHIM
Ngày: 25/09/2026 19:30
2 Vé 2D Phim Hoạt Hình   220.000
------------------------------------
TỔNG CỘNG: 220.000 đ`
  },
  {
    merchant: 'EVN Điện Lực',
    text: `EVN ĐIỆN LỰC MIỀN TRUNG
THÔNG BÁO TIỀN ĐIỆN THÁNG 9/2026
Ngày: 24/09/2026
Số công tơ: 9812401
Điện năng tiêu thụ: 180 kWh
TỔNG TIỀN THANH TOÁN: 450.000 VND`
  },
  {
    merchant: 'Nhà Thuốc Long Châu',
    text: `HỆ THỐNG NHÀ THUỐC LONG CHÂU
HÓA ĐƠN BÁN LẺ
Ngày: 22/09/2026 10:15
1. Panadol Extra 1 Vỉ          25.000
2. Viên sủi Berocca Cam        90.000
------------------------------------
THÀNH TIỀN: 115.000 VND`
  }
];

// Initial Transactions (State)
let expenses = [
  { id: '1', title: 'Highlands Coffee - Phin Sữa Đá', amount: 85000, category: 'food', date: '01/10/2026', method: 'ML Kit OCR', confidence: 0.98 },
  { id: '2', title: 'WinMart+ Mua đồ tươi', amount: 245000, category: 'groceries', date: '30/09/2026', method: 'ML Kit OCR', confidence: 0.96 },
  { id: '3', title: 'Grab Rides Đi Thư Viện', amount: 32000, category: 'transport', date: '29/09/2026', method: 'ML Kit OCR', confidence: 0.95 },
  { id: '4', title: 'Nhà Sách Fahasa Sách Flutter', amount: 198000, category: 'education', date: '28/09/2026', method: 'ML Kit OCR', confidence: 0.97 },
  { id: '5', title: 'Circle K Ăn Nhẹ', amount: 54000, category: 'groceries', date: '27/09/2026', method: 'ML Kit OCR', confidence: 0.94 },
  { id: '6', title: 'CGV Cinemas Xem Phim', amount: 220000, category: 'entertainment', date: '25/09/2026', method: 'ML Kit OCR', confidence: 0.99 },
  { id: '7', title: 'EVN Điện Lực Tiền Điện', amount: 450000, category: 'utilities', date: '24/09/2026', method: 'ML Kit OCR', confidence: 0.96 },
  { id: '8', title: 'Nhà Thuốc Long Châu Thuốc Cảm', amount: 115000, category: 'health', date: '22/09/2026', method: 'ML Kit OCR', confidence: 0.98 }
];

let selectedPieCategory = null;
let currentParsed = null;
let barMode = 'monthly';
let hoveredBarIndex = null;

// Currency Formatter
function formatVND(val) {
  return new Intl.NumberFormat('vi-VN').format(Math.round(val)) + ' ₫';
}

// =========================================================================
// REGEX HEURISTIC PARSER (Mirrors Dart RegexParserService)
// =========================================================================
const knownMerchants = [
  'WinMart+', 'Highlands Coffee', 'The Coffee House', 'Trung Nguyên Legend',
  'Nhà Thuốc Long Châu', 'Nhà Thuốc An Khang', 'Nhà Sách Phương Nam', 'Nhà Sách Fahasa',
  'CGV Cinemas', 'Lotte Cinema', 'Bách Hóa Xanh', 'EVN Điện Lực', 'KFC Vietnam',
  'ShopeeFood', 'Grab Rides', 'Pizza 4P\'s', 'FamilyMart', '7-Eleven', 'Circle K',
  'Co.opmart', 'Lotte Mart', 'McDonald\'s', 'Pizza Hut', 'GrabFood', 'WinMart',
  'Phúc Long', 'Starbucks', 'Lotteria', 'Jollibee', 'Be Group', 'Petrolimex', 'GS25'
];

function runRegexParser(rawText) {
  const lines = rawText.split('\n').map(l => l.trim()).filter(l => l.length > 0);
  const logs = [];

  // 1. Merchant Extraction
  let detectedMerchant = null;
  let merchantConfidence = 0.5;
  const searchLines = lines.slice(0, 6);

  for (const line of searchLines) {
    for (const known of knownMerchants) {
      if (line.toLowerCase().includes(known.toLowerCase())) {
        detectedMerchant = known;
        merchantConfidence = 0.98;
        logs.push(`✓ Khớp từ điển thương hiệu: "${known}"`);
        break;
      }
    }
    if (detectedMerchant) break;
  }

  if (!detectedMerchant) {
    for (const line of searchLines) {
      if (line.length >= 3 && !/^\d+$/.test(line) && !/^(hóa đơn|phiếu|bill|receipt|đc:|sđt)/i.test(line)) {
        detectedMerchant = line.replace(/^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$/gu, '').trim();
        merchantConfidence = 0.82;
        logs.push(`✓ Tiêu đề heuristic: "${detectedMerchant}"`);
        break;
      }
    }
  }

  // 2. Monetary Total Extraction
  const totalKeywords = /(?:TỔNG\s*CỘNG|TONG\s*CONG|THÀNH\s*TIỀN|THANH\s*TIEN|TỔNG\s*TIỀN|TONG\s*TIEN|CẦN\s*THANH\s*TOÁN|GRAND\s*TOTAL|TOTAL)\b/i;
  const negativeKeywords = /(?:TIỀN\s*KHÁCH\s*ĐƯA|TIỀN\s*THỪA|CHANGE|CASH\s*TENDERED|GIẢM\s*GIÁ|TAX|VAT)/i;

  let detectedTotal = null;
  let amountConfidence = 0.0;

  function parseNumber(str) {
    const usd = str.match(/\$\s*([0-9]+(?:\.[0-9]{2})?)/) || str.match(/([0-9]+\.[0-9]{2})\s*USD/i);
    if (usd) return parseFloat(usd[1]);

    const matches = [...str.matchAll(/([0-9]{1,3}(?:[.,\s][0-9]{3})+(?:\s*(?:đ|d|VND|VNĐ))?)/gi)];
    for (const m of matches) {
      const clean = m[1].replace(/[\s.,đdVNDvndVNĐ]/g, '');
      const val = parseFloat(clean);
      if (val >= 1000) return val;
    }
    return null;
  }

  for (let i = lines.length - 1; i >= 0; i--) {
    const line = lines[i];
    if (negativeKeywords.test(line)) continue;

    if (totalKeywords.test(line)) {
      const val = parseNumber(line);
      if (val) {
        detectedTotal = val;
        amountConfidence = 0.98;
        logs.push(`✓ Trích xuất tổng tiền từ khóa "${line.slice(0, 30)}...": ${formatVND(val)}`);
        break;
      }
      if (i + 1 < lines.length) {
        const nextVal = parseNumber(lines[i + 1]);
        if (nextVal) {
          detectedTotal = nextVal;
          amountConfidence = 0.88;
          logs.push(`✓ Trích xuất dòng kế tiếp: ${formatVND(nextVal)}`);
          break;
        }
      }
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
      logs.push(`✓ Nhận diện ngày tiếng Việt tự nhiên: ${detectedDate}`);
      break;
    }
    const ddm = line.match(ddmmyyyy);
    if (ddm) {
      detectedDate = `${ddm[1].padStart(2, '0')}/${ddm[2].padStart(2, '0')}/${ddm[3]}`;
      logs.push(`✓ Nhận diện ngày định dạng chuẩn: ${detectedDate}`);
      break;
    }
  }

  // 4. Category Classification
  const m = (detectedMerchant || '').toLowerCase();
  const corpus = `${m} ${lines.join(' ')}`.toLowerCase();
  let category = 'other';

  if (/(?:nhà thuốc|pharmacy|long châu|an khang)/.test(m)) category = 'health';
  else if (/(?:winmart|vinmart|circle k|7-eleven|familymart|gs25|bách hóa xanh|co\.op)/.test(m)) category = 'groceries';
  else if (/(?:fahasa|phương nam|nhà sách|vku)/.test(m)) category = 'education';
  else if (/(?:cgv|lotte cinema)/.test(m)) category = 'entertainment';
  else if (/(?:highlands|phúc long|coffee house|trung nguyên|starbucks|kfc|lotteria|pizza|jollibee)/.test(m)) category = 'food';
  else if (/(?:grab|be group|gojek|petrolimex)/.test(m)) category = 'transport';
  else if (/(?:evn|điện lực)/.test(m)) category = 'utilities';
  else {
    if (/(?:nhà thuốc|thuốc|vitamin|panadol)/.test(corpus)) category = 'health';
    else if (/(?:siêu thị|mart|rau|thịt|sữa|trứng)/.test(corpus)) category = 'groceries';
    else if (/(?:cafe|cà phê|trà|cơm|phở|bánh)/.test(corpus)) category = 'food';
    else if (/(?:phim|cinema|vé xem phim)/.test(corpus)) category = 'entertainment';
    else if (/(?:sách|giáo trình|vở)/.test(corpus)) category = 'education';
    else if (/(?:grab|\bbe\b|xăng|xe)/.test(corpus)) category = 'transport';
    else if (/(?:điện lực|tiền điện|nước sạch|cước)/.test(corpus)) category = 'utilities';
  }

  logs.push(`✓ Phân loại danh mục tự động: [${category}] (${categories[category]?.name || category})`);

  const confidence = ((merchantConfidence + amountConfidence + (detectedDate ? 0.9 : 0.4)) / 3).toFixed(2);

  return {
    merchant: detectedMerchant || 'Hóa đơn bán lẻ',
    amount: detectedTotal || 0,
    date: detectedDate || '01/10/2026',
    category,
    confidence: parseFloat(confidence),
    logs
  };
}

// =========================================================================
// CUSTOMPAINTER CANVAS ENGINE: ANIMATED PIE / DONUT CHART
// =========================================================================
let pieAnimProgress = 0;
let pieAnimId = null;

function animatePieChart() {
  pieAnimProgress = 0;
  if (pieAnimId) cancelAnimationFrame(pieAnimId);

  const startTime = performance.now();
  const duration = 800; // ms

  function frame(now) {
    const elapsed = now - startTime;
    const t = Math.min(1, elapsed / duration);
    // easeOutCubic curve
    pieAnimProgress = 1 - Math.pow(1 - t, 3);
    drawPieChart();

    if (t < 1) {
      pieAnimId = requestAnimationFrame(frame);
    }
  }
  pieAnimId = requestAnimationFrame(frame);
}

function drawPieChart() {
  const canvas = document.getElementById('pieCanvas');
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  const width = canvas.width;
  const height = canvas.height;
  const centerX = width / 2;
  const centerY = height / 2;
  const outerRadius = 130;
  const strokeWidth = 36;
  const innerRadius = outerRadius - strokeWidth;

  ctx.clearRect(0, 0, width, height);

  // Group by category
  const catSums = {};
  let totalSpent = 0;
  expenses.forEach(e => {
    catSums[e.category] = (catSums[e.category] || 0) + e.amount;
    totalSpent += e.amount;
  });

  const segments = Object.keys(catSums).map(catId => ({
    catId,
    category: categories[catId] || categories.other,
    amount: catSums[catId],
    pct: totalSpent > 0 ? (catSums[catId] / totalSpent) * 100 : 0
  })).sort((a, b) => b.amount - a.amount);

  let currentAngle = -Math.PI / 2;

  segments.forEach((seg, idx) => {
    const sweepAngle = (seg.pct / 100.0) * (2 * Math.PI) * pieAnimProgress;
    const isSelected = selectedPieCategory === seg.catId;
    const currentStroke = isSelected ? strokeWidth + 8 : strokeWidth;
    const radius = isSelected ? outerRadius + 4 : outerRadius;

    ctx.save();
    // Segment Glow on Selected
    if (isSelected) {
      ctx.shadowColor = seg.category.color;
      ctx.shadowBlur = 15;
    }

    ctx.beginPath();
    ctx.arc(centerX, centerY, radius - currentStroke / 2, currentAngle, currentAngle + sweepAngle);
    ctx.strokeStyle = seg.category.color;
    ctx.lineWidth = currentStroke;
    ctx.lineCap = 'butt';
    ctx.stroke();

    // White gap separator
    if (segments.length > 1) {
      ctx.beginPath();
      ctx.arc(centerX, centerY, radius - currentStroke / 2, currentAngle, currentAngle + 0.02);
      ctx.strokeStyle = '#0b1120';
      ctx.lineWidth = currentStroke + 2;
      ctx.stroke();
    }
    ctx.restore();

    currentAngle += sweepAngle;
  });

  // Center Donut Hole Text
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';

  if (selectedPieCategory && catSums[selectedPieCategory]) {
    const cat = categories[selectedPieCategory];
    ctx.fillStyle = '#94a3b8';
    ctx.font = '500 12px Plus Jakarta Sans';
    ctx.fillText(cat.name, centerX, centerY - 14);

    ctx.fillStyle = cat.color;
    ctx.font = '700 18px Plus Jakarta Sans';
    ctx.fillText(formatVND(catSums[selectedPieCategory]), centerX, centerY + 10);
  } else {
    ctx.fillStyle = '#94a3b8';
    ctx.font = '500 12px Plus Jakarta Sans';
    ctx.fillText('Tổng Chi Tiêu', centerX, centerY - 14);

    ctx.fillStyle = '#ffffff';
    ctx.font = '800 20px Plus Jakarta Sans';
    ctx.fillText(formatVND(totalSpent), centerX, centerY + 10);
  }
}

// Polar Hit-Testing for Canvas Tap
function handlePieCanvasClick(evt) {
  const canvas = document.getElementById('pieCanvas');
  const rect = canvas.getBoundingClientRect();
  const x = evt.clientX - rect.left;
  const y = evt.clientY - rect.top;

  const centerX = canvas.width / 2;
  const centerY = canvas.height / 2;
  const dx = x - centerX;
  const dy = y - centerY;
  const dist = Math.sqrt(dx * dx + dy * dy);

  const outerRadius = 130;
  const strokeWidth = 36;
  const innerRadius = outerRadius - strokeWidth;

  if (dist < innerRadius - 10 || dist > outerRadius + 15) {
    selectedPieCategory = null;
    drawPieChart();
    renderLegend();
    return;
  }

  let angle = Math.atan2(dy, dx) + Math.PI / 2;
  if (angle < 0) angle += 2 * Math.PI;

  const catSums = {};
  let totalSpent = 0;
  expenses.forEach(e => {
    catSums[e.category] = (catSums[e.category] || 0) + e.amount;
    totalSpent += e.amount;
  });

  const segments = Object.keys(catSums).map(catId => ({
    catId,
    pct: (catSums[catId] / totalSpent) * 100
  })).sort((a, b) => (catSums[b.catId] - catSums[a.catId]));

  let cur = 0;
  let clickedCat = null;
  for (const seg of segments) {
    const sweep = (seg.pct / 100) * 2 * Math.PI;
    if (angle >= cur && angle <= cur + sweep) {
      clickedCat = seg.catId;
      break;
    }
    cur += sweep;
  }

  selectedPieCategory = (selectedPieCategory === clickedCat) ? null : clickedCat;
  drawPieChart();
  renderLegend();
}

// =========================================================================
// CUSTOMPAINTER CANVAS ENGINE: ANIMATED BAR CHART
// =========================================================================
let barAnimProgress = 0;
let barAnimId = null;

function animateBarChart() {
  barAnimProgress = 0;
  if (barAnimId) cancelAnimationFrame(barAnimId);

  const startTime = performance.now();
  const duration = 750;

  function frame(now) {
    const elapsed = now - startTime;
    const t = Math.min(1, elapsed / duration);
    barAnimProgress = 1 - Math.pow(1 - t, 3);
    drawBarChart();

    if (t < 1) {
      barAnimId = requestAnimationFrame(frame);
    }
  }
  barAnimId = requestAnimationFrame(frame);
}

function getBarData() {
  if (barMode === 'monthly') {
    return [
      { label: 'Th.05', value: 850000 },
      { label: 'Th.06', value: 1200000 },
      { label: 'Th.07', value: 950000 },
      { label: 'Th.08', value: 1650000 },
      { label: 'Th.09', value: 1820000 },
      { label: 'Th.10', value: expenses.reduce((s, e) => s + e.amount, 0), isCurrent: true }
    ];
  } else {
    return [
      { label: 'T5 (25)', value: 220000 },
      { label: 'T6 (26)', value: 48000 },
      { label: 'T7 (27)', value: 54000 },
      { label: 'CN (28)', value: 210000 },
      { label: 'T2 (29)', value: 32000 },
      { label: 'T3 (30)', value: 245000 },
      { label: 'T4 (01)', value: 129000, isCurrent: true }
    ];
  }
}

function drawBarChart() {
  const canvas = document.getElementById('barCanvas');
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  const width = canvas.width;
  const height = canvas.height;

  ctx.clearRect(0, 0, width, height);

  const leftMargin = 50;
  const rightMargin = 20;
  const topMargin = 30;
  const bottomMargin = 35;

  const chartWidth = width - leftMargin - rightMargin;
  const chartHeight = height - topMargin - bottomMargin;

  const items = getBarData();
  const maxVal = Math.max(...items.map(i => i.value)) * 1.25 || 1000000;

  // 1. Grid Lines & Y Labels
  const steps = 4;
  ctx.strokeStyle = 'rgba(255, 255, 255, 0.08)';
  ctx.lineWidth = 1;
  ctx.textAlign = 'right';
  ctx.textBaseline = 'middle';
  ctx.fillStyle = '#64748b';
  ctx.font = '10px Plus Jakarta Sans';

  for (let s = 0; s <= steps; s++) {
    const y = topMargin + chartHeight - (s * (chartHeight / steps));
    ctx.beginPath();
    ctx.moveTo(leftMargin, y);
    ctx.lineTo(leftMargin + chartWidth, y);
    ctx.stroke();

    const val = (maxVal / steps) * s;
    const compactText = val >= 1000000 ? `${(val / 1000000).toFixed(1)}tr` : `${Math.round(val / 1000)}k`;
    ctx.fillText(compactText, leftMargin - 8, y);
  }

  // 2. Bars
  const totalBars = items.length;
  const barArea = chartWidth / totalBars;
  const barWidth = Math.min(32, barArea * 0.6);

  items.forEach((item, idx) => {
    const centerX = leftMargin + (idx * barArea) + (barArea / 2);
    const isHovered = hoveredBarIndex === idx;

    // Track
    ctx.fillStyle = 'rgba(255, 255, 255, 0.04)';
    roundRect(ctx, centerX - barWidth / 2, topMargin, barWidth, chartHeight, 6);
    ctx.fill();

    // Value Bar
    const scaled = (item.value / maxVal) * chartHeight * barAnimProgress;
    const barTop = topMargin + chartHeight - scaled;

    const grad = ctx.createLinearGradient(0, barTop, 0, topMargin + chartHeight);
    if (isHovered) {
      grad.addColorStop(0, '#00e676');
      grad.addColorStop(1, '#00e5ff');
    } else if (item.isCurrent) {
      grad.addColorStop(0, '#00e5ff');
      grad.addColorStop(1, '#0072ff');
    } else {
      grad.addColorStop(0, '#38bdf8');
      grad.addColorStop(1, '#1e3a8a');
    }

    ctx.save();
    if (isHovered) {
      ctx.shadowColor = '#00e676';
      ctx.shadowBlur = 12;
    }
    ctx.fillStyle = grad;
    roundRect(ctx, centerX - barWidth / 2, barTop, barWidth, scaled, 6);
    ctx.fill();
    ctx.restore();

    // X-Axis Label
    ctx.textAlign = 'center';
    ctx.textBaseline = 'top';
    ctx.fillStyle = isHovered ? '#00e5ff' : item.isCurrent ? '#ffffff' : '#94a3b8';
    ctx.font = isHovered || item.isCurrent ? '700 11px Plus Jakarta Sans' : '11px Plus Jakarta Sans';
    ctx.fillText(item.label, centerX, height - bottomMargin + 10);

    // Floating Tooltip on Hover
    if (isHovered) {
      const tooltipText = formatVND(item.value);
      ctx.font = '700 11px Plus Jakarta Sans';
      const tw = ctx.measureText(tooltipText).width + 16;
      const th = 22;
      const tipTop = barTop - th - 8;

      ctx.fillStyle = '#00e676';
      roundRect(ctx, centerX - tw / 2, tipTop, tw, th, 4);
      ctx.fill();

      ctx.fillStyle = '#0b1120';
      ctx.textBaseline = 'middle';
      ctx.fillText(tooltipText, centerX, tipTop + th / 2);
    }
  });
}

function roundRect(ctx, x, y, width, height, radius) {
  if (width <= 0 || height <= 0) return;
  radius = Math.min(radius, width / 2, height / 2);
  ctx.beginPath();
  ctx.moveTo(x + radius, y);
  ctx.lineTo(x + width - radius, y);
  ctx.quadraticCurveTo(x + width, y, x + width, y + radius);
  ctx.lineTo(x + width, y + height - radius);
  ctx.quadraticCurveTo(x + width, y + height, x + width - radius, y + height);
  ctx.lineTo(x + radius, y + height);
  ctx.quadraticCurveTo(x, y + height, x, y + height - radius);
  ctx.lineTo(x, y + radius);
  ctx.quadraticCurveTo(x, y, x + radius, y);
  ctx.closePath();
}

function handleBarMouseMove(evt) {
  const canvas = document.getElementById('barCanvas');
  const rect = canvas.getBoundingClientRect();
  const x = evt.clientX - rect.left;

  const leftMargin = 50;
  const rightMargin = 20;
  const chartWidth = canvas.width - leftMargin - rightMargin;
  const items = getBarData();
  const barArea = chartWidth / items.length;

  if (x >= leftMargin && x <= canvas.width - rightMargin) {
    const idx = Math.floor((x - leftMargin) / barArea);
    if (idx >= 0 && idx < items.length) {
      if (hoveredBarIndex !== idx) {
        hoveredBarIndex = idx;
        drawBarChart();
      }
      return;
    }
  }

  if (hoveredBarIndex !== null) {
    hoveredBarIndex = null;
    drawBarChart();
  }
}

// =========================================================================
// UI CONTROLLERS & DATA SYNC
// =========================================================================
function switchChartTab(tab) {
  document.getElementById('tabPie').classList.toggle('active', tab === 'pie');
  document.getElementById('tabBar').classList.toggle('active', tab === 'bar');
  document.getElementById('pieContainer').style.display = tab === 'pie' ? 'flex' : 'none';
  document.getElementById('barContainer').style.display = tab === 'bar' ? 'flex' : 'none';

  if (tab === 'pie') {
    animatePieChart();
  } else {
    animateBarChart();
  }
}

function setBarMode(mode) {
  barMode = mode;
  document.getElementById('btnMonthly').classList.toggle('active', mode === 'monthly');
  document.getElementById('btnWeekly').classList.toggle('active', mode === 'weekly');
  animateBarChart();
}

function renderLegend() {
  const container = document.getElementById('legendContainer');
  if (!container) return;

  const catSums = {};
  let totalSpent = 0;
  expenses.forEach(e => {
    catSums[e.category] = (catSums[e.category] || 0) + e.amount;
    totalSpent += e.amount;
  });

  const segments = Object.keys(catSums).map(catId => ({
    catId,
    name: categories[catId]?.name || catId,
    color: categories[catId]?.color || '#94a3b8',
    pct: totalSpent > 0 ? ((catSums[catId] / totalSpent) * 100).toFixed(0) : 0
  })).sort((a, b) => catSums[b.catId] - catSums[a.catId]);

  container.innerHTML = segments.map(seg => `
    <div class="legend-chip ${selectedPieCategory === seg.catId ? 'active' : ''}" onclick="toggleCategoryFilter('${seg.catId}')">
      <span class="legend-dot" style="background: ${seg.color}"></span>
      <span>${seg.name}</span>
      <strong>${seg.pct}%</strong>
    </div>
  `).join('');

  // Update budget bar
  const budgetLimit = 8000000;
  const ratio = ((totalSpent / budgetLimit) * 100).toFixed(1);
  document.getElementById('budgetRatioText').innerText = `${formatVND(totalSpent)} (${ratio}%)`;
  document.getElementById('budgetProgressFill').style.width = `${Math.min(100, ratio)}%`;
}

function toggleCategoryFilter(catId) {
  selectedPieCategory = (selectedPieCategory === catId) ? null : catId;
  drawPieChart();
  renderLegend();
  renderTransactionsTable();
}

function renderTransactionsTable() {
  const tbody = document.getElementById('txTableBody');
  const countBadge = document.getElementById('txCount');
  if (!tbody) return;

  const filtered = selectedPieCategory
    ? expenses.filter(e => e.category === selectedPieCategory)
    : expenses;

  countBadge.innerText = `${filtered.length} giao dịch`;

  tbody.innerHTML = filtered.map(item => `
    <tr>
      <td style="color: #94a3b8;">${item.date}</td>
      <td><strong>${item.title}</strong></td>
      <td>
        <span style="color: ${categories[item.category]?.color || '#fff'}">
          ● ${categories[item.category]?.name || item.category}
        </span>
      </td>
      <td style="color: #ff5252; font-weight: bold;">-${formatVND(item.amount)}</td>
      <td style="color: #00e5ff; font-size: 11px;">${item.method}</td>
      <td>
        <span style="background: rgba(0,230,118,0.15); color: #00e676; padding: 2px 8px; border-radius: 4px; font-size: 11px;">
          ${(item.confidence * 100).toFixed(0)}%
        </span>
      </td>
      <td>
        <button class="btn-del" onclick="deleteExpense('${item.id}')">Xóa</button>
      </td>
    </tr>
  `).join('');
}

function deleteExpense(id) {
  expenses = expenses.filter(e => e.id !== id);
  renderTransactionsTable();
  renderLegend();
  animatePieChart();
  animateBarChart();
}

function loadSample(idx) {
  document.querySelectorAll('.preset-chip').forEach((c, i) => {
    c.classList.toggle('active', i === idx);
  });
  const sample = sampleReceipts[idx];
  document.getElementById('rawOcrInput').value = sample.text;
  triggerParse();
}

function triggerParse() {
  const text = document.getElementById('rawOcrInput').value;
  const result = runRegexParser(text);
  currentParsed = result;

  document.getElementById('resMerchant').innerText = result.merchant;
  document.getElementById('resAmount').innerText = formatVND(result.amount);
  document.getElementById('resDate').innerText = result.date;
  document.getElementById('resCategory').innerText = categories[result.category]?.name || result.category;
  document.getElementById('aiConfidenceBadge').innerText = `Độ tin cậy: ${(result.confidence * 100).toFixed(0)}%`;

  const logsEl = document.getElementById('diagLogs');
  logsEl.innerHTML = result.logs.map(l => `<li>${l}</li>`).join('');
}

function addParsedToExpenses() {
  if (!currentParsed || currentParsed.amount <= 0) {
    alert('Vui lòng quét hoặc nhập hóa đơn có tổng tiền hợp lệ!');
    return;
  }

  const newTx = {
    id: String(Date.now()),
    title: `${currentParsed.merchant} - Quét AI`,
    amount: currentParsed.amount,
    category: currentParsed.category,
    date: currentParsed.date,
    method: 'ML Kit + Regex',
    confidence: currentParsed.confidence
  };

  expenses.unshift(newTx);
  renderTransactionsTable();
  renderLegend();
  animatePieChart();
  animateBarChart();

  alert(`Đã lưu thành công chi tiêu: ${formatVND(newTx.amount)} vào hệ thống!`);
}

// Setup Event Listeners
window.addEventListener('DOMContentLoaded', () => {
  const pieCanvas = document.getElementById('pieCanvas');
  const barCanvas = document.getElementById('barCanvas');

  if (pieCanvas) {
    pieCanvas.addEventListener('click', handlePieCanvasClick);
  }
  if (barCanvas) {
    barCanvas.addEventListener('mousemove', handleBarMouseMove);
    barCanvas.addEventListener('mouseleave', () => {
      hoveredBarIndex = null;
      drawBarChart();
    });
  }

  loadSample(0);
  renderTransactionsTable();
  renderLegend();
  animatePieChart();
});
