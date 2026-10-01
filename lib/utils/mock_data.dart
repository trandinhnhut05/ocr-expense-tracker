import 'dart:math';
import '../models/expense.dart';
import '../models/category.dart';

class MockData {
  static List<Expense> generateInitialExpenses() {
    final now = DateTime.now();

    return [
      Expense(
        id: 'exp-001',
        title: 'Highlands Coffee - Phin Sữa Đá',
        amount: 85000,
        categoryId: 'food',
        date: now.subtract(const Duration(hours: 3)),
        merchant: 'Highlands Coffee',
        rawOcrText: '''
HIGHLANDS COFFEE
Tầng 1 Tòa Nhà FPT, Ngũ Hành Sơn, Đà Nẵng
HÓA ĐƠN BÁN HÀNG
Ngày: ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} 08:30
1. Phin Sữa Đá L      45.000
2. Freeze Trà Xanh M  40.000
--------------------------------
TỔNG CỘNG: 85.000 VND
Tiền khách đưa: 100.000 VND
Tiền thừa: 15.000 VND
        ''',
        confidenceScore: 0.98,
        notes: 'Cà phê sáng cùng bạn học tại campus VKU',
      ),
      Expense(
        id: 'exp-002',
        title: 'WinMart+ Mua sắm đồ tươi',
        amount: 245000,
        categoryId: 'groceries',
        date: now.subtract(const Duration(days: 1, hours: 2)),
        merchant: 'WinMart+',
        rawOcrText: '''
WINMART+ NAM KỲ KHỞI NGHĨA
Đà Nẵng
PHIẾU THANH TOÁN
Ngày: ${(now.subtract(const Duration(days: 1))).day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} 18:45
- Sữa tươi Vinamilk 1L    38.000
- Thịt heo nạc dăm 500g   72.000
- Trứng gà Ba Huân 10q    35.000
- Bánh mì sandwich        22.000
- Dầu ăn Simply 1L        78.000
--------------------------------
THÀNH TIỀN: 245.000 đ
Thanh toán: Thẻ ATM
        ''',
        confidenceScore: 0.96,
        notes: 'Thực phẩm tuần',
      ),
      Expense(
        id: 'exp-003',
        title: 'Grab Rides - Đi Thư viện VKU',
        amount: 32000,
        categoryId: 'transport',
        date: now.subtract(const Duration(days: 2)),
        merchant: 'Grab Rides',
        rawOcrText: '''
GRAB VIETNAM
Biên lai điện tử chuyến đi
Ngày: ${(now.subtract(const Duration(days: 2))).day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}
Từ: Ký túc xá VKU
Đến: Thư viện số Tòa V
CƯỚC PHÍ CHUYẾN ĐI
TỔNG TIỀN: 32.000 VND
Thanh toán qua Moca
        ''',
        confidenceScore: 0.95,
        notes: 'GrabBike đi học',
      ),
      Expense(
        id: 'exp-004',
        title: 'Nhà Sách Fahasa - Sách Flutter & AI',
        amount: 198000,
        categoryId: 'education',
        date: now.subtract(const Duration(days: 3)),
        merchant: 'Nhà Sách Fahasa',
        rawOcrText: '''
NHÀ SÁCH FAHASA ĐÀ NẴNG
HÓA ĐƠN BÁN LẺ
Ngày: ${(now.subtract(const Duration(days: 3))).day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}
1. Giáo trình Di động Flutter   150.000
2. Sổ tay kẻ ô B5              48.000
--------------------------------
TỔNG CỘNG: 198.000 VNĐ
        ''',
        confidenceScore: 0.97,
        notes: 'Sách tham khảo môn Mobile',
      ),
      Expense(
        id: 'exp-005',
        title: 'Circle K - Nước ngọt & Snack',
        amount: 54000,
        categoryId: 'groceries',
        date: now.subtract(const Duration(days: 4)),
        merchant: 'Circle K',
        rawOcrText: '''
CIRCLE K VIETNAM
STORE #112 DA NANG
RECEIPT
Date: ${(now.subtract(const Duration(days: 4))).day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}
1  COCA COLA 320ML     12.000
1  SNACK LAY'S         22.000
1  KEM CORNETTO        20.000
--------------------------------
TOTAL: 54.000 VND
        ''',
        confidenceScore: 0.94,
        notes: 'Ăn nhẹ ca học đêm',
      ),
      Expense(
        id: 'exp-006',
        title: 'CGV Cinemas - Vé xem phim cuối tuần',
        amount: 220000,
        categoryId: 'entertainment',
        date: now.subtract(const Duration(days: 6)),
        merchant: 'CGV Cinemas',
        rawOcrText: '''
CGV CINEMAS VINCOM DA NANG
PHIẾU THANH TOÁN VÉ PHIM
Ngày chiếu: ${(now.subtract(const Duration(days: 6))).day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} 19:30
2 Vé 2D Phim Hoạt Hình   220.000
--------------------------------
TỔNG CỘNG: 220.000 đ
        ''',
        confidenceScore: 0.99,
        notes: 'Xem phim thư giãn',
      ),
      Expense(
        id: 'exp-007',
        title: 'EVN Điện Lực - Tiền điện phòng trọ',
        amount: 450000,
        categoryId: 'utilities',
        date: now.subtract(const Duration(days: 10)),
        merchant: 'EVN Điện Lực',
        rawOcrText: '''
CÔNG TY ĐIỆN LỰC MIỀN TRUNG
THÔNG BÁO TIỀN ĐIỆN THÁNG 9/2026
Số công tơ: 9812401
Điện năng tiêu thụ: 180 kWh
TỔNG TIỀN THANH TOÁN: 450.000 VND
        ''',
        confidenceScore: 0.96,
        notes: 'Tiền điện sinh hoạt',
      ),
      Expense(
        id: 'exp-008',
        title: 'Nhà Thuốc Long Châu - Vitamin C & Thuốc cảm',
        amount: 115000,
        categoryId: 'health',
        date: now.subtract(const Duration(days: 12)),
        merchant: 'Nhà Thuốc Long Châu',
        rawOcrText: '''
HỆ THỐNG NHÀ THUỐC FPT LONG CHÂU
HÓA ĐƠN BÁN HÀNG
Ngày: ${(now.subtract(const Duration(days: 12))).day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}
1. Panadol Extra 1 Vỉ          25.000
2. Viên sủi Berocca Cam        90.000
--------------------------------
THÀNH TIỀN: 115.000 VND
        ''',
        confidenceScore: 0.98,
        notes: 'Thuốc hạ sốt và bổ sung vitamin',
      ),
    ];
  }
}
