import 'package:flutter/material.dart';
import '../utils/currency_formatter.dart';

class MetricCard extends StatelessWidget {
  final double totalSpent;
  final double monthlyBudget;
  final double remainingBudget;
  final double progress;
  final VoidCallback? onScanTap;
  final VoidCallback? onManualAddTap;

  const MetricCard({
    Key? key,
    required this.totalSpent,
    required this.monthlyBudget,
    required this.remainingBudget,
    required this.progress,
    this.onScanTap,
    this.onManualAddTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isWarning = progress > 0.8;
    final isOver = progress >= 1.0;
    final progressColor = isOver
        ? const Color(0xFFFF5252)
        : isWarning
            ? const Color(0xFFFFAB00)
            : const Color(0xFF00E676);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0x3338BDF8),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Month and Budget Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Color(0xFF00E5FF),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Chi Tiêu Tháng Này',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: progressColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    isOver
                        ? 'Vượt ngân sách'
                        : '${(progress * 100).toStringAsFixed(0)}% Ngân sách',
                    style: TextStyle(
                      color: progressColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Big Number: Total Spent
            Text(
              CurrencyFormatter.formatVND(totalSpent),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 12),
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 12),
            // Budget stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ngân sách: ${CurrencyFormatter.formatVND(monthlyBudget)}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Còn lại: ${CurrencyFormatter.formatVND(remainingBudget)}',
                  style: TextStyle(
                    color: remainingBudget > 0 ? const Color(0xFF00E676) : const Color(0xFFFF5252),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Action Buttons
            Row(
              children: [
                // Scan Receipt Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onScanTap,
                    icon: const Icon(Icons.document_scanner_rounded, size: 18),
                    label: const Text('Quét Hóa Đơn AI'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Manual Add Button
                InkWell(
                  onTap: onManualAddTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
