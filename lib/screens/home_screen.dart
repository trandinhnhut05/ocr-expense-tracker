import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/category.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/metric_card.dart';
import '../widgets/category_chip.dart';
import '../widgets/expense_card.dart';
import 'ocr_scanner_screen.dart';
import 'analytics_screen.dart';
import 'manual_expense_screen.dart';
import 'expense_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _currentTabIndex == 0 ? 'Quản Lý Chi Tiêu' : 'Phân Tích & Biểu Đồ',
      ),
      body: _currentTabIndex == 0
          ? _buildHomeBody(context)
          : const AnalyticsScreen(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00E5FF),
        foregroundColor: const Color(0xFF0F172A),
        icon: const Icon(Icons.document_scanner_rounded),
        label: const Text(
          'Quét OCR',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const OcrScannerScreen()),
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        backgroundColor: const Color(0xFF0F172A),
        indicatorColor: const Color(0xFF00E5FF).withOpacity(0.2),
        onDestinationSelected: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wallet_rounded, color: Colors.white60),
            selectedIcon: Icon(Icons.wallet_rounded, color: Color(0xFF00E5FF)),
            label: 'Sổ Chi Tiêu',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_rounded, color: Colors.white60),
            selectedIcon: Icon(Icons.pie_chart_rounded, color: Color(0xFF00E5FF)),
            label: 'Biểu Đồ AI',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeBody(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
          );
        }

        final filtered = provider.filteredExpenses;

        return RefreshIndicator(
          color: const Color(0xFF00E5FF),
          onRefresh: () => provider.loadExpenses(),
          child: CustomScrollView(
            slivers: [
              // 1. Metric / Budget Overview Card
              SliverToBoxAdapter(
                child: MetricCard(
                  totalSpent: provider.totalSpentThisMonth,
                  monthlyBudget: provider.monthlyBudget,
                  remainingBudget: provider.remainingBudget,
                  progress: provider.budgetProgress,
                  onScanTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const OcrScannerScreen()),
                    );
                  },
                  onManualAddTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ManualExpenseScreen()),
                    );
                  },
                ),
              ),

              // 2. Search Field
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => provider.search(val),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm hóa đơn, tên cửa hàng...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: Color(0xFF00E5FF), size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded,
                                  color: Colors.white54, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                provider.search('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF00E5FF)),
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Category Horizontal Filter Chips
              SliverToBoxAdapter(
                child: Container(
                  height: 48,
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      CategoryChip(
                        category: null,
                        isSelected: provider.selectedCategoryFilter == null,
                        onTap: () => provider.filterByCategory(null),
                      ),
                      ...ExpenseCategory.defaultCategories.map((cat) {
                        return CategoryChip(
                          category: cat,
                          isSelected: provider.selectedCategoryFilter == cat.id,
                          onTap: () => provider.filterByCategory(cat.id),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),

              // 4. Header: Recent Transactions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Giao Dịch Gần Đây (${filtered.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (provider.selectedCategoryFilter != null)
                        TextButton(
                          onPressed: () => provider.filterByCategory(null),
                          child: const Text(
                            'Đặt lại bộ lọc',
                            style: TextStyle(
                              color: Color(0xFF00E5FF),
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 5. Expense Cards List
              if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Không tìm thấy giao dịch nào',
                          style: TextStyle(color: Colors.white54, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Hãy bấm nút "Quét OCR" để phân tích hóa đơn mới',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = filtered[index];
                      return ExpenseCard(
                        expense: item,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ExpenseDetailScreen(expense: item),
                            ),
                          );
                        },
                        onDelete: () {
                          provider.deleteExpense(item.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã xóa "${item.title}"'),
                              action: SnackBarAction(
                                label: 'Hoàn tác',
                                onPressed: () => provider.addExpense(item),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          ),
        );
      },
    );
  }
}
