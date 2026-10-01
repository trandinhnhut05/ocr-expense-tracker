import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final Expense expense;

  const ExpenseDetailScreen({Key? key, required this.expense}) : super(key: key);

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  bool _showRawOcr = false;

  @override
  Widget build(BuildContext context) {
    final exp = widget.expense;
    final cat = exp.category;
    final hasOcr = exp.rawOcrText != null && exp.rawOcrText!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Chi Tiết Khoản Chi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF5252)),
            onPressed: () {
              Provider.of<ExpenseProvider>(context, listen: false)
                  .deleteExpense(exp.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã xóa "${exp.title}"')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Amount & Category Badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cat.color.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cat.color.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(cat.icon, color: cat.color, size: 36),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    CurrencyFormatter.formatVND(exp.amount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    exp.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Metadata Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: Icons.category_rounded,
                    label: 'Danh mục',
                    value: cat.nameVi,
                    valueColor: cat.color,
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  _buildDetailRow(
                    icon: Icons.storefront_rounded,
                    label: 'Đơn vị bán',
                    value: exp.merchant ?? 'Chưa xác định',
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  _buildDetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Thời gian',
                    value: DateFormatter.formatDateTime(exp.date),
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  _buildDetailRow(
                    icon: Icons.psychology_rounded,
                    label: 'Phương thức nhập',
                    value: hasOcr
                        ? 'Google ML Kit OCR (${(exp.confidenceScore * 100).toStringAsFixed(0)}% tin cậy)'
                        : 'Nhập thủ công',
                    valueColor: hasOcr ? const Color(0xFF00E5FF) : Colors.white70,
                  ),
                  if (exp.notes != null && exp.notes!.isNotEmpty) ...[
                    const Divider(color: Colors.white10, height: 24),
                    _buildDetailRow(
                      icon: Icons.notes_rounded,
                      label: 'Ghi chú',
                      value: exp.notes!,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Raw OCR Section (if scanned)
            if (hasOcr) ...[
              InkWell(
                onTap: () => setState(() => _showRawOcr = !_showRawOcr),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _showRawOcr
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF00E5FF),
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showRawOcr ? 'Ẩn văn bản OCR' : 'Xem chi tiết văn bản hóa đơn đã OCR',
                      style: const TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_showRawOcr) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: SelectableText(
                    exp.rawOcrText!,
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
