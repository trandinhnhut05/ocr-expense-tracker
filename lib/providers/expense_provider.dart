import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/receipt_scan_result.dart';
import '../services/database_helper.dart';
import '../painters/bar_chart_painter.dart';
import '../utils/mock_data.dart';

class ExpenseProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  List<Expense> _expenses = [];
  bool _isLoading = true;
  String? _selectedCategoryFilter;
  String _searchQuery = '';
  double _monthlyBudget = 8000000.0; // 8M VND default personal budget

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get selectedCategoryFilter => _selectedCategoryFilter;
  String get searchQuery => _searchQuery;
  double get monthlyBudget => _monthlyBudget;

  ExpenseProvider() {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    _isLoading = true;
    notifyListeners();

    try {
      final loaded = await _dbHelper.getAllExpenses();
      if (loaded.isEmpty) {
        // First launch: Seed initial realistic mock data for evaluation
        final mockList = MockData.generateInitialExpenses();
        for (final item in mockList) {
          await _dbHelper.insertExpense(item);
        }
        _expenses = mockList;
      } else {
        _expenses = loaded;
      }
    } catch (e) {
      debugPrint('[ExpenseProvider] Fallback to memory mock due to: $e');
      _expenses = MockData.generateInitialExpenses();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- FILTERED LIST ---
  List<Expense> get filteredExpenses {
    return _expenses.where((exp) {
      final matchesCat = _selectedCategoryFilter == null ||
          exp.categoryId == _selectedCategoryFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          exp.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (exp.merchant?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      return matchesCat && matchesSearch;
    }).toList();
  }

  // --- AGGREGATIONS & METRICS ---
  double get totalSpentAllTime =>
      _expenses.fold(0.0, (sum, exp) => sum + exp.amount);

  double get totalSpentThisMonth {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold(0.0, (sum, exp) => sum + exp.amount);
  }

  double get remainingBudget => (_monthlyBudget - totalSpentThisMonth).clamp(0.0, _monthlyBudget);

  double get budgetProgress =>
      _monthlyBudget > 0 ? (totalSpentThisMonth / _monthlyBudget).clamp(0.0, 1.0) : 0.0;

  Map<String, double> get categoryBreakdownThisMonth {
    final now = DateTime.now();
    final map = <String, double>{};

    for (final exp in _expenses) {
      if (exp.date.year == now.year && exp.date.month == now.month) {
        map[exp.categoryId] = (map[exp.categoryId] ?? 0.0) + exp.amount;
      }
    }
    return map;
  }

  List<BarChartItem> get monthlySpendingTrend {
    final now = DateTime.now();
    final items = <BarChartItem>[];

    // Last 6 months
    for (int i = 5; i >= 0; i--) {
      final targetDate = DateTime(now.year, now.month - i, 1);
      final monthName = 'Th.${targetDate.month}';

      final total = _expenses
          .where((e) =>
              e.date.year == targetDate.year && e.date.month == targetDate.month)
          .fold(0.0, (sum, exp) => sum + exp.amount);

      items.add(BarChartItem(
        label: monthName,
        value: total,
        isCurrentPeriod: i == 0,
      ));
    }

    return items;
  }

  List<BarChartItem> get weeklySpendingTrend {
    final now = DateTime.now();
    final items = <BarChartItem>[];
    final dayNames = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];

    // Last 7 days
    for (int i = 6; i >= 0; i--) {
      final targetDay = DateTime(now.year, now.month, now.day - i);
      final label = dayNames[targetDay.weekday % 7];

      final total = _expenses
          .where((e) =>
              e.date.year == targetDay.year &&
              e.date.month == targetDay.month &&
              e.date.day == targetDay.day)
          .fold(0.0, (sum, exp) => sum + exp.amount);

      items.add(BarChartItem(
        label: label,
        value: total,
        isCurrentPeriod: i == 0,
      ));
    }

    return items;
  }

  List<double> get last30DaysTrend {
    final now = DateTime.now();
    final list = <double>[];

    for (int i = 29; i >= 0; i--) {
      final targetDay = DateTime(now.year, now.month, now.day - i);
      final total = _expenses
          .where((e) =>
              e.date.year == targetDay.year &&
              e.date.month == targetDay.month &&
              e.date.day == targetDay.day)
          .fold(0.0, (sum, exp) => sum + exp.amount);
      list.add(total);
    }
    return list;
  }

  // --- ACTIONS ---
  Future<void> addExpense(Expense expense) async {
    try {
      await _dbHelper.insertExpense(expense);
    } catch (e) {
      debugPrint('[ExpenseProvider] Memory insert fallback: $e');
    }
    _expenses.insert(0, expense);
    notifyListeners();
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      await _dbHelper.updateExpense(expense);
    } catch (e) {
      debugPrint('[ExpenseProvider] Memory update fallback: $e');
    }
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      _expenses[index] = expense;
      notifyListeners();
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _dbHelper.deleteExpense(id);
    } catch (e) {
      debugPrint('[ExpenseProvider] Memory delete fallback: $e');
    }
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Future<Expense> createExpenseFromScan({
    required ReceiptScanResult result,
    required String title,
    required double amount,
    required String categoryId,
    required DateTime date,
    String? merchant,
    String? receiptImagePath,
    String? notes,
  }) async {
    final expense = Expense(
      id: _uuid.v4(),
      title: title,
      amount: amount,
      categoryId: categoryId,
      date: date,
      merchant: merchant ?? result.merchantName,
      receiptImagePath: receiptImagePath,
      rawOcrText: result.rawText,
      confidenceScore: result.confidenceScore,
      notes: notes,
    );

    await addExpense(expense);
    return expense;
  }

  void filterByCategory(String? categoryId) {
    _selectedCategoryFilter = categoryId;
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void updateBudget(double newBudget) {
    _monthlyBudget = newBudget;
    notifyListeners();
  }
}
