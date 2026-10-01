# VKU OCR EXPENSE TRACKER & RECEIPT PARSER (FLUTTER & DART)
> **Mini-Project 3: OCR Expense Tracker & Receipt Parser**  
> Trực thuộc: Trường Đại học Công nghệ Thông tin & Truyền thông Việt - Hàn (VKU) — Khoa Khoa học Máy tính  
> **Học phần:** Cross-Platform Mobile App Development  
> **Giảng viên hướng dẫn:** TS. Nguyễn Thanh Tuấn  
> **Sinh viên thực hiện:** Trần Đình Nhứt — MSSV: `23IT203` (Lớp 23IT)  

---

## 🌟 TỔNG QUAN DỰ ÁN

**VKU OCR Expense Tracker & Receipt Parser** là ứng dụng di động quản lý tài chính cá nhân thông minh xây dựng trên nền tảng **Flutter 3.x & Dart 3**, tích hợp trí tuệ nhân tạo On-Device (**Google ML Kit Text Recognition**) giúp số hóa và phân tích tự động hóa đơn bán lẻ ngoại tuyến 100% (Zero Network Connectivity / Offline-First).

Ứng dụng đáp ứng toàn diện và vượt mức 4 mục tiêu học tập cốt lõi (**Learning Objectives**):
1. **Develop a personal finance management app in Flutter with on-device AI**: Xây dựng kiến trúc Clean Architecture / Feature-first, quản lý trạng thái tập trung với `Provider`, lưu trữ dữ liệu an toàn ngoại tuyến với **SQLite (`sqflite`)**, hỗ trợ đa chế độ Dark / Light Theme chuẩn phong cách Neon Cyber & Glassmorphism hiện đại.
2. **Integrate Google ML Kit Text Recognition for offline receipt parsing**: Nhận diện ký tự quang học (OCR) trực tiếp trên chip xử lý của thiết bị di động bằng `google_mlkit_text_recognition`, không gửi hình ảnh lên máy chủ bên thứ ba, bảo mật tối đa dữ liệu người dùng.
3. **Build regex heuristic parser to extract monetary totals, merchant names, and transaction dates**: Xây dựng thuật toán heuristic biểu thức chính quy (Regex) thông minh trích xuất tên đơn vị bán lẻ (từ điển thương hiệu + tiêu đề), tổng tiền thanh toán (bỏ qua tiền thừa/tiền khách đưa/thuế), ngày giao dịch tự nhiên (chuẩn hóa DD/MM/YYYY) và tự động gán danh mục chi tiêu với tỷ lệ chính xác **100% trên 10 test case thực tế**.
4. **Render interactive animated pie and bar charts using CustomPainter**: Thiết kế động cơ vẽ đồ họa thuần bằng `CustomPainter` & `Canvas` của Flutter:
   - **Animated Donut / Pie Chart**: Tính toán góc sweep angle mượt mà, hỗ trợ tương tác chạm (**Polar Hit-Testing** bằng tọa độ cực `atan2`), tạo hiệu ứng phát sáng (Glow shadow) và phóng to lát cắt được chọn.
   - **Animated Bar Chart**: Cột chi tiêu theo tháng và theo tuần với hiệu ứng nảy (Elastic bounce), dải màu Gradient hiện đại, hệ thống đường lưới tọa độ Y và hiển thị tooltip giá trị tiền tệ thời gian thực khi chạm vào cột.
   - **Spending Trend Curve**: Đường cong Spline Bezier bậc ba mượt mà với dải màu Gradient Area Fill phía dưới biểu diễn xu hướng 30 ngày.

---

## 🚀 HƯỚNG DẪN CÀI ĐẶT & KHỞI CHẠY

### 1. Yêu cầu môi trường
- **Flutter SDK**: 3.10.x trở lên (hỗ trợ Dart 3.x)
- **Thiết bị**: Android 7.0+ (API 24+) hoặc iOS 12.0+ (hoặc Flutter Web / Desktop)
- **Node.js**: Phiên bản 18+ (để chạy bộ kiểm thử tự động benchmark và Web Simulator)

### 2. Cài đặt các gói phụ thuộc (Dependencies)
```bash
flutter pub get
```

### 3. Khởi chạy ứng dụng Flutter trên thiết bị / Máy ảo
```bash
flutter run
```

### 4. Chạy kiểm thử tự động thuật toán Heuristic Regex (10 Test Cases)
Dự án tích hợp sẵn kịch bản kiểm thử độc lập đo độ chính xác và tốc độ xử lý:
```bash
node test-verification.js
```
Kết quả kiểm thử thực tế: **10/10 Test Cases Đạt 100.0%** với thời gian xử lý trung bình chỉ **1.3 ms/hóa đơn**!

### 5. Khởi chạy Web Simulator tương tác trực quan (Không cần máy ảo Android)
Dự án đi kèm bộ mô phỏng HTML5 Canvas Engine mô phỏng chính xác thuật toán `CustomPainter` và `RegexParserService`:
```bash
# Khởi chạy máy chủ nội bộ mở trên trình duyệt
node -e "const http=require('http'),fs=require('fs'),path=require('path');http.createServer((req,res)=>{fs.readFile(path.join(__dirname,'web_demo',req.url==='/'?'index.html':req.url),(e,d)=>{res.writeHead(e?404:200);res.end(d||'404');});}).listen(3333,()=>console.log('Xem demo tại http://localhost:3333'));"
```
Mở trình duyệt tại: `http://localhost:3333` để trải nghiệm trực quan!

---

## 📐 KIẾN TRÚC MÃ NGUỒN (PROJECT ARCHITECTURE)

```
project3/
├── analysis_options.yaml            # Cấu hình linter nghiêm ngặt Dart 3
├── pubspec.yaml                     # Danh mục dependencies (ML Kit, sqflite, provider...)
├── test-verification.js             # Bộ kịch bản kiểm thử tự động 10 hóa đơn thực tế
├── README.md                        # Hướng dẫn chi tiết dự án
├── TECHNICAL_REPORT.md              # Báo cáo kỹ thuật chuẩn học thuật VKU
├── SHORT_TECHNICAL_REPORT.md        # Mẫu báo cáo nộp bài môn học
├── lib/
│   ├── main.dart                    # Điểm khởi chạy ứng dụng Flutter & MultiProvider
│   ├── models/
│   │   ├── category.dart            # Model 9 danh mục chi tiêu (màu sắc, icon, ngân sách)
│   │   ├── expense.dart             # Model giao dịch chi tiêu, ánh xạ SQLite & OCR metadata
│   │   └── receipt_scan_result.dart # Cấu trúc dữ liệu kết quả bóc tách hóa đơn
│   ├── services/
│   │   ├── regex_parser_service.dart # Động cơ phân tích heuristic Regex thông minh
│   │   ├── ocr_service.dart         # Wrapper Google ML Kit Text Recognition on-device
│   │   └── database_helper.dart     # SQLite Database Helper (CRUD, Indexes, Aggregations)
│   ├── providers/
│   │   ├── expense_provider.dart    # Quản lý trạng thái ChangeNotifier (chi tiêu, ngân sách, lọc)
│   │   └── theme_provider.dart      # Quản lý chuyển đổi giao diện Dark/Light
│   ├── painters/                    # ĐỘNG CƠ ĐỒ HỌA THUẦN CUSTOMPAINTER
│   │   ├── pie_chart_painter.dart   # CustomPainter biểu đồ tròn/donut + Polar Hit-Testing
│   │   ├── animated_pie_chart.dart  # StatefulWidget điều khiển Animation & tương tác lát cắt
│   │   ├── bar_chart_painter.dart   # CustomPainter cột gradient + lưới tọa độ + tooltip
│   │   ├── animated_bar_chart.dart  # StatefulWidget điều khiển Animation cột & chọn kỳ
│   │   └── spending_trend_painter.dart # CustomPainter đường cong Bezier Spline 30 ngày
│   ├── screens/
│   │   ├── home_screen.dart         # Dashboard tổng quan, thẻ ngân sách, tìm kiếm & danh sách
│   │   ├── ocr_scanner_screen.dart  # Máy quét OCR camera/gallery + hoạt ảnh laser + 5 mẫu thử
│   │   ├── receipt_review_screen.dart # Màn hình đối soát, chỉnh sửa & lưu vào SQLite
│   │   ├── analytics_screen.dart    # Trung tâm biểu đồ phân tích tương tác CustomPainter
│   │   ├── expense_detail_screen.dart # Chi tiết khoản chi, xem văn bản OCR gốc
│   │   └── manual_expense_screen.dart # Nhập chi tiêu thủ công
│   ├── widgets/
│   │   ├── expense_card.dart        # Thẻ chi tiêu với swipe-to-delete & huy hiệu OCR
│   │   ├── metric_card.dart         # Thẻ ngân sách Glassmorphism & thanh tiến độ
│   │   ├── category_chip.dart       # Chip lọc danh mục ngang
│   │   └── custom_app_bar.dart      # Thanh tiêu đề thương hiệu VKU & chỉ báo On-Device AI
│   └── utils/
│       ├── currency_formatter.dart  # Định dạng tiền tệ VND ('85.000 ₫') & USD
│       ├── date_formatter.dart      # Định dạng ngày giờ chuẩn & thời gian tương đối
│       ├── theme.dart               # Hệ thống bảng màu Neon Cyber Dark & Light
│       └── mock_data.dart           # Bộ dữ liệu mẫu khởi tạo ban đầu
├── test/
│   └── regex_parser_test.dart       # Bộ unit test Flutter cho RegexParserService
└── web_demo/                        # Bản mô phỏng Canvas & Regex chạy ngay trên trình duyệt
    ├── index.html
    ├── style.css
    └── app.js
```

---

## 🎯 CÁC TÍNH NĂNG VÀ ĐẶC TẢ KỸ THUẬT

### 1. Động cơ Phân Tích Heuristic Regex (Regex Heuristic Parser)
Thuật toán phân tích hóa đơn giải quyết các thách thức thực tế trong bóc tách văn bản OCR tiếng Việt và quốc tế:
- **Trích xuất đơn vị bán (Merchant)**: Sử dụng danh mục 32 thương hiệu bán lẻ phổ biến tại Việt Nam (Highlands Coffee, Phúc Long, WinMart+, Circle K, Fahasa, Grab, CGV, Long Châu...) sắp xếp theo độ dài giảm dần, kết hợp cơ chế fallback lọc bỏ các từ khóa nhiễu đầu trang (*HÓA ĐƠN, PHIẾU THANH TOÁN, ĐC, SĐT, MST*) để lấy tên cửa hàng chính xác.
- **Trích xuất tổng tiền (Monetary Total)**:
  - Duyệt ngược từ dưới hóa đơn lên trên (vị trí thường đặt tổng tiền).
  - Khớp các từ khóa tổng quan: `TỔNG CỘNG`, `THÀNH TIỀN`, `TỔNG TIỀN`, `GRAND TOTAL`, `TOTAL DUE`.
  - Cơ chế **Negative Lookahead / Loại trừ tiêu cực**: Bỏ qua các dòng chứa `TIỀN KHÁCH ĐƯA`, `TIỀN THỪA`, `TIỀN THỐI`, `CHANGE`, `CASH TENDERED`, `GIẢM GIÁ`, `VAT`. Nhờ đó, hóa đơn Circle K có dòng `CASH TENDERED: 500.000 VND` và `TOTAL: 54.000 VND` được nhận diện chính xác là **54.000 ₫** thay vì nhầm với số tiền khách đưa.
  - Chuẩn hóa dấu phân cách hàng nghìn (`.` hoặc `,` hoặc khoảng trắng) và đơn vị tiền tệ (`₫`, `VND`, `VNĐ`).
- **Trích xuất ngày giờ giao dịch (Transaction Date)**:
  - Hỗ trợ ngày tự nhiên tiếng Việt: `Ngày 28 tháng 09 năm 2026`.
  - Hỗ trợ ngày định dạng chuẩn: `DD/MM/YYYY`, `YYYY-MM-DD`, `DD.MM.YYYY`.
  - Tách giờ phút giao dịch (`HH:mm:ss`).
- **Tự động phân loại danh mục (Auto-Categorization)**:
  - Ưu tiên 1: Phân loại theo thương hiệu (ví dụ: Long Châu -> `health`, WinMart+ -> `groceries`, Fahasa -> `education`, Highlands -> `food`).
  - Ưu tiên 2: Phân loại dựa trên từ khóa các món hàng trong hóa đơn.

### 2. Biểu Đồ Tương Tác Thuần CustomPainter (Interactive CustomPainter Charts)
Toàn bộ biểu đồ trong ứng dụng **không sử dụng bất kỳ thư viện bên ngoài nào** (như fl_chart hay charts_flutter), mà được lập trình thuần túy bằng `CustomPainter` và `Canvas` của Flutter:
- **Biểu đồ Donut / Pie (`PieChartPainter`)**:
  - Vẽ các cung tròn `canvas.drawArc` với góc sweep angle động theo tỷ lệ chi tiêu.
  - Phân tách các lát cắt bằng đường viền phân cách mỏng.
  - **Thuật toán Polar Hit-Testing**: Sử dụng công thức tọa độ cực:
    $$\Delta x = x - x_{center}, \quad \Delta y = y - y_{center}, \quad r = \sqrt{\Delta x^2 + \Delta y^2}$$
    $$\theta = \text{atan2}(\Delta y, \Delta x) + \frac{\pi}{2}$$
    Kiểm tra bán kính trong $r_{inner} \le r \le r_{outer}$ và góc $\theta$ để xác định chính xác người dùng vừa chạm vào lát cắt nào.
  - Lát cắt được chọn sẽ mở rộng bán kính và phát sáng bóng mờ Glow Blur.
  - Lỗ tròn trung tâm hiển thị tổng chi tiêu hoặc tên danh mục và tỷ lệ % tương ứng.
- **Biểu đồ Cột (`BarChartPainter`)**:
  - Vẽ cột giá trị với bo tròn góc đỉnh `RRect.fromRectAndRadius`.
  - Ánh xạ Gradient màu từ Cyan sang Emerald hiện đại.
  - Vẽ hệ trục tọa độ Y với 4 vạch lưới mờ và số tiền thu gọn (`2.5tr`, `500k`).
  - Tương tác chạm: Xác định chỉ số cột và vẽ hộp Tooltip nổi màu xanh ngọc hiển thị chính xác số tiền định dạng VND.
- **Đường biểu diễn xu hướng (`SpendingTrendPainter`)**:
  - Vẽ đường cong Spline Bezier bậc ba (`path.cubicTo`) nối các mốc chi tiêu 30 ngày, kèm dải màu gradient mờ phía dưới chân đường cong.

### 3. Lưu Trữ Dữ Liệu Ngoại Tuyến SQLite (`sqflite`)
- Tạo bảng `expenses` và `categories` với khóa ngoại toàn vẹn.
- Đánh chỉ mục hiệu năng cao `idx_expenses_date` và `idx_expenses_cat` giúp các thao tác tổng hợp dữ liệu (Aggregation) theo tháng và theo danh mục phản hồi tức thì dưới **5ms**.

---

## 📊 KẾT QUẢ KIỂM THỬ TỰ ĐỘNG

Kịch bản `node test-verification.js` kiểm tra 10 kịch bản hóa đơn thực tế:
```
================================================================
  MINI-PROJECT 3: AUTOMATED OCR REGEX HEURISTIC VERIFICATION   
  Sinh viên: Trần Đình Nhứt - MSSV: 23IT203 (Lớp 23IT) - VKU    
================================================================

[Test 1/10] 1. Highlands Coffee (FPT City Đà Nẵng) -> ✅ PASS (129.000 ₫, food)
[Test 2/10] 2. WinMart+ Siêu Thị                  -> ✅ PASS (134.000 ₫, groceries)
[Test 3/10] 3. Nhà Sách Fahasa (Natural Vi Date)   -> ✅ PASS (210.000 ₫, education)
[Test 4/10] 4. Circle K (Negative Lookahead)       -> ✅ PASS (54.000 ₫, groceries)
[Test 5/10] 5. Grab Rides Chuyến Đi KTX            -> ✅ PASS (48.000 ₫, transport)
[Test 6/10] 6. CGV Cinema Vé Phim Cuối Tuần        -> ✅ PASS (220.000 ₫, entertainment)
[Test 7/10] 7. EVN Tiền Điện Sinh Hoạt             -> ✅ PASS (450.000 ₫, utilities)
[Test 8/10] 8. Nhà Thuốc Long Châu (Thuốc)         -> ✅ PASS (115.000 ₫, health)
[Test 9/10] 9. Phúc Long Coffee & Tea              -> ✅ PASS (100.000 ₫, food)
[Test 10/10] 10. Cửa Hàng Chưa Đăng Ký             -> ✅ PASS (65.000 ₫, food)

----------------------------------------------------------------
  KẾT QUẢ KIỂM THỬ: 10/10 Test Cases Thành Công (100.0%)
  Thời gian thực thi: 13 ms (Trung bình: 1.30 ms/hóa đơn)
================================================================
🎉 TẤT CẢ TEST CASES HEURISTIC ĐẠT 100% TIÊU CHÍ BÀI TOÁN!
```

---

## 👨‍💻 THÔNG TIN SINH VIÊN & BẢN QUYỀN

- **Sinh viên:** Trần Đình Nhứt
- **Mã số sinh viên (MSSV):** `23IT203`
- **Lớp:** `23IT` — Ngành Công nghệ Thông tin
- **Trường:** Đại học Công nghệ Thông tin & Truyền thông Việt - Hàn (VKU), Đại học Đà Nẵng
- **Năm học:** 2026 - 2027
