import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ocr_service.dart';
import '../services/regex_parser_service.dart';
import '../models/receipt_scan_result.dart';
import 'receipt_review_screen.dart';

class OcrScannerScreen extends StatefulWidget {
  const OcrScannerScreen({Key? key}) : super(key: key);

  @override
  State<OcrScannerScreen> createState() => _OcrScannerScreenState();
}

class _OcrScannerScreenState extends State<OcrScannerScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();
  File? _selectedImage;
  bool _isScanning = false;
  late AnimationController _laserController;

  // Preset receipt texts for instant demonstration and edge-case testing
  final List<Map<String, String>> _sampleReceipts = [
    {
      'title': 'Highlands Coffee (Đà Nẵng)',
      'text': '''
HIGHLANDS COFFEE
Tầng 1 Tòa Nhà FPT, Ngũ Hành Sơn, Đà Nẵng
HÓA ĐƠN BÁN HÀNG
Ngày: 01/10/2026 08:30:15
Thu ngân: NV002 - Quầy 1
1. Phin Sữa Đá L          45.000
2. Trà Sen Vàng L         55.000
3. Bánh Chuối             29.000
------------------------------------
TỔNG CỘNG: 129.000 VND
Tiền khách đưa: 200.000 VND
Tiền thừa: 71.000 VND
Cảm ơn quý khách!
      ''',
    },
    {
      'title': 'WinMart+ Siêu Thị Thực Phẩm',
      'text': '''
WINMART+ NAM KỲ KHỞI NGHĨA
Đà Nẵng
MST: 0104918404
PHIẾU THANH TOÁN
Ngày: 29/09/2026 19:12
- Sữa tươi TH True Milk 1L    36.000
- Ức gà phi lê 500g           45.000
- Rau cải ngọt Đà Lạt 300g    15.000
- Trứng gà Ta 10 quả          38.000
------------------------------------
THÀNH TIỀN: 134.000 đ
Thanh toán: VNPAY-QR
      ''',
    },
    {
      'title': 'Nhà Sách Fahasa Giáo Trình',
      'text': '''
NHÀ SÁCH FAHASA ĐÀ NẴNG
300 Lê Duẩn, Đà Nẵng
HÓA ĐƠN BÁN LẺ
Ngày 28 tháng 09 năm 2026
1. Giáo trình Flutter Cross-Platform   185.000
2. Bút bi Pilot G2                      25.000
------------------------------------
TỔNG CỘNG: 210.000 VNĐ
      ''',
    },
    {
      'title': 'Circle K Ăn Vặt Ban Đêm',
      'text': '''
CIRCLE K VIETNAM #108
RECEIPT / PHIẾU THU
Date: 27/09/2026 23:45
1  Mì Trộn Trứng Xúc Xích    32.000
1  Trà Sữa Thái Xanh          22.000
------------------------------------
TOTAL: 54.000 VND
CASH: 54.000 VND
CHANGE: 0 VND
      ''',
    },
    {
      'title': 'Grab Rides Chuyến Đi',
      'text': '''
GRAB VIETNAM
Biên lai dịch vụ vận tải
Ngày: 26/09/2026 14:10
Tài xế: Nguyễn Văn A
Từ: Trường ĐH CNTT&TT Việt - Hàn
Đến: Trung tâm Hành chính Đà Nẵng
------------------------------------
TỔNG TIỀN: 48.000 VND
Thanh toán bằng thẻ Visa ****1203
      ''',
    },
  ];

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _laserController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
          _isScanning = true;
        });

        // Run ML Kit OCR
        final result = await _ocrService.processReceiptImage(_selectedImage!);

        setState(() {
          _isScanning = false;
        });

        _navigateToReview(result, _selectedImage?.path);
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể chụp/chọn ảnh: $e')),
      );
    }
  }

  void _processSampleReceipt(Map<String, String> sample) {
    setState(() {
      _isScanning = true;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      final result = RegexParserService.parseReceiptText(sample['text']!);
      setState(() {
        _isScanning = false;
      });
      _navigateToReview(result, null);
    });
  }

  void _navigateToReview(ReceiptScanResult result, String? imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptReviewScreen(
          scanResult: result,
          receiptImagePath: imagePath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Máy Quét Hóa Đơn AI'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 1. Scanner Viewfinder / Camera Simulation View
          Expanded(
            flex: 5,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  // Receipt or Placeholder
                  Center(
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00E5FF).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.receipt_long_rounded,
                                  size: 64,
                                  color: Color(0xFF00E5FF),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Đặt hóa đơn vào khung hình',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Google ML Kit sẽ tự động nhận diện chữ offline',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                  ),

                  // Scanner Corner Reticles
                  _buildCornerReticles(),

                  // Animated Laser Scanning Line
                  AnimatedBuilder(
                    animation: _laserController,
                    builder: (context, child) {
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final topPos =
                              _laserController.value * (constraints.maxHeight - 20);
                          return Positioned(
                            top: topPos,
                            left: 12,
                            right: 12,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Color(0xFF00E5FF),
                                    Color(0xFF00E676),
                                    Colors.transparent,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00E5FF).withOpacity(0.8),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  // Processing Overlay
                  if (_isScanning)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Color(0xFF00E5FF)),
                            SizedBox(height: 16),
                            Text(
                              'Đang chạy Heuristic Regex AI...',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 2. Action Buttons (Camera / Gallery)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Chụp Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Chọn Ảnh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. One-Tap Sample Receipts Tester
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: Color(0xFFFFAB00), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Thử nghiệm nhanh mẫu hóa đơn thực tế:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _sampleReceipts.map((sample) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          backgroundColor: const Color(0xFF1E293B),
                          side: const BorderSide(color: Color(0xFF38BDF8), width: 0.8),
                          label: Text(
                            sample['title']!,
                            style: const TextStyle(
                              color: Color(0xFF00E5FF),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onPressed: () => _processSampleReceipt(sample),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerReticles() {
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            // Top Left
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFF00E5FF), width: 3),
                    left: BorderSide(color: Color(0xFF00E5FF), width: 3),
                  ),
                ),
              ),
            ),
            // Top Right
            Align(
              alignment: Alignment.topRight,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFF00E5FF), width: 3),
                    right: BorderSide(color: Color(0xFF00E5FF), width: 3),
                  ),
                ),
              ),
            ),
            // Bottom Left
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF00E5FF), width: 3),
                    left: BorderSide(color: Color(0xFF00E5FF), width: 3),
                  ),
                ),
              ),
            ),
            // Bottom Right
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF00E5FF), width: 3),
                    right: BorderSide(color: Color(0xFF00E5FF), width: 3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
