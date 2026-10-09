import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/wallet.dart';
import '../models/savings_goal.dart';
import '../models/receipt_scan_result.dart';
import '../services/database_helper.dart';
import '../services/nlp_parser_service.dart';
import '../painters/bar_chart_painter.dart';
import '../utils/mock_data.dart';

enum DateFilterOption { all, today, thisWeek, thisMonth }

class ExpenseProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  List<Expense> _expenses = [];
  bool _isLoading = true;
  String? _selectedCategoryFilter;
  String _searchQuery = '';
  DateFilterOption _dateFilter = DateFilterOption.all;
  double _monthlyBudget = 8000000.0; // 8M VND default personal budget

  final List<Wallet> _wallets = List.from(Wallet.defaultWallets);
  final List<SavingsGoal> _savingsGoals = List.from(SavingsGoal.defaultGoals);

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get selectedCategoryFilter => _selectedCategoryFilter;
  String get searchQuery => _searchQuery;
  DateFilterOption get dateFilter => _dateFilter;
  double get monthlyBudget => _monthlyBudget;
  List<Wallet> get wallets => _wallets;
  List<SavingsGoal> get savingsGoals => _savingsGoals;

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

  // --- FILTERED LIST WITH SEARCH, CATEGORY & DATE RANGE ---
  List<Expense> get filteredExpenses {
    final now = DateTime.now();

    return _expenses.where((exp) {
      // 1. Category Filter
      final matchesCat = _selectedCategoryFilter == null ||
          exp.categoryId == _selectedCategoryFilter;

      // 2. Search Query Filter
      final matchesSearch = _searchQuery.isEmpty ||
          exp.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (exp.merchant?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          exp.amount.toString().contains(_searchQuery);

      // 3. Date Range Filter
      bool matchesDate = true;
      if (_dateFilter == DateFilterOption.today) {
        matchesDate = exp.date.year == now.year &&
            exp.date.month == now.month &&
            exp.date.day == now.day;
      } else if (_dateFilter == DateFilterOption.thisWeek) {
        final diffDays = now.difference(exp.date).inDays;
        matchesDate = diffDays >= 0 && diffDays <= 7;
      } else if (_dateFilter == DateFilterOption.thisMonth) {
        matchesDate = exp.date.year == now.year && exp.date.month == now.month;
      }

      return matchesCat && matchesSearch && matchesDate;
    }).toList();
  }

  // --- FINANCIAL AGGREGATIONS & METRICS ---
  double get totalBalance =>
      _wallets.fold(0.0, (sum, w) => sum + w.balance);

  double get totalIncomeThisMonth {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.isIncome && e.date.year == now.year && e.date.month == now.month)
        .fold(0.0, (sum, exp) => sum + exp.amount);
  }

  double get totalSpentThisMonth {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.isExpense && e.date.year == now.year && e.date.month == now.month)
        .fold(0.0, (sum, exp) => sum + exp.amount);
  }

  double get totalSpentAllTime =>
      _expenses.where((e) => e.isExpense).fold(0.0, (sum, exp) => sum + exp.amount);

  double get remainingBudget => (_monthlyBudget - totalSpentThisMonth).clamp(0.0, _monthlyBudget);

  double get budgetProgress =>
      _monthlyBudget > 0 ? (totalSpentThisMonth / _monthlyBudget).clamp(0.0, 1.0) : 0.0;

  Map<String, double> get categoryBreakdownThisMonth {
    final now = DateTime.now();
    final map = <String, double>{};

    for (final exp in _expenses) {
      if (exp.isExpense && exp.date.year == now.year && exp.date.month == now.month) {
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
              e.isExpense &&
              e.date.year == targetDate.year &&
              e.date.month == targetDate.month)
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
              e.isExpense &&
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

  // --- WALLET & INTERNAL TRANSFER ACTIONS ---
  void transferBetweenWallets({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    String? notes,
  }) {
    if (fromWalletId == toWalletId || amount <= 0) return;

    final fromIndex = _wallets.indexWhere((w) => w.id == fromWalletId);
    final toIndex = _wallets.indexWhere((w) => w.id == toWalletId);

    if (fromIndex != -1 && toIndex != -1) {
      _wallets[fromIndex].balance -= amount;
      _wallets[toIndex].balance += amount;

      // Note: Internal transfer is NOT counted as Expense or Income!
      final tx = Expense(
        id: _uuid.v4(),
        title: 'Chuyển tiền: ${_wallets[fromIndex].name} ➔ ${_wallets[toIndex].name}',
        amount: amount,
        categoryId: 'other',
        date: DateTime.now(),
        type: TransactionType.transfer,
        walletId: fromWalletId,
        targetWalletId: toWalletId,
        notes: notes ?? 'Chuyển tiền nội bộ giữa các ví',
      );
      _expenses.insert(0, tx);
      notifyListeners();
    }
  }

  // --- SAVINGS GOAL ACTIONS ---
  void contributeToSavingsGoal({
    required String goalId,
    required double amount,
    required String fromWalletId,
  }) {
    if (amount <= 0) return;
    final goalIndex = _savingsGoals.indexWhere((g) => g.id == goalId);
    final walletIndex = _wallets.indexWhere((w) => w.id == fromWalletId);

    if (goalIndex != -1 && walletIndex != -1) {
      _wallets[walletIndex].balance -= amount;
      _savingsGoals[goalIndex].currentAmount += amount;

      final tx = Expense(
        id: _uuid.v4(),
        title: 'Nạp quỹ: ${_savingsGoals[goalIndex].title}',
        amount: amount,
        categoryId: 'other',
        date: DateTime.now(),
        type: TransactionType.transfer,
        walletId: fromWalletId,
        notes: 'Tiết kiệm cho mục tiêu: ${_savingsGoals[goalIndex].title}',
      );
      _expenses.insert(0, tx);
      notifyListeners();
    }
  }

  // --- NLP QUICK TRANSACTION ACTION ---
  ParsedNlpTransaction parseAndAddNlpTransaction(String naturalText) {
    final parsed = NlpParserService.parse(naturalText);

    if (parsed.type == TransactionType.transfer) {
      transferBetweenWallets(
        fromWalletId: parsed.walletId,
        toWalletId: parsed.targetWalletId ?? 'momo',
        amount: parsed.amount,
        notes: parsed.explanation,
      );
    } else {
      final tx = Expense(
        id: _uuid.v4(),
        title: parsed.title,
        amount: parsed.amount,
        categoryId: parsed.categoryId,
        date: DateTime.now(),
        type: parsed.type,
        walletId: parsed.walletId,
        notes: parsed.explanation,
      );
      addExpense(tx);

      // Adjust wallet balance
      final wIdx = _wallets.indexWhere((w) => w.id == parsed.walletId);
      if (wIdx != -1) {
        if (parsed.type == TransactionType.income) {
          _wallets[wIdx].balance += parsed.amount;
        } else {
          _wallets[wIdx].balance -= parsed.amount;
        }
      }
    }

    notifyListeners();
    return parsed;
  }

  // --- GENERAL TRANSACTION ACTIONS ---
  Future<void> addExpense(Expense expense) async {
    try {
      await _dbHelper.insertExpense(expense);
    } catch (e) {
      debugPrint('[ExpenseProvider] Memory insert fallback: $e');
    }
    _expenses.insert(0, expense);

    // Adjust corresponding wallet
    final wIdx = _wallets.indexWhere((w) => w.id == expense.walletId);
    if (wIdx != -1) {
      if (expense.isIncome) {
        _wallets[wIdx].balance += expense.amount;
      } else if (expense.isExpense) {
        _wallets[wIdx].balance -= expense.amount;
      }
    }

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
    String walletId = 'cash',
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
      walletId: walletId,
      type: TransactionType.expense,
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

  void setDateFilter(DateFilterOption option) {
    _dateFilter = option;
    notifyListeners();
  }

  void updateBudget(double newBudget) {
    _monthlyBudget = newBudget;
    notifyListeners();
  }

  // --- CATEGORY BUDGET ALERTS ---
  bool isCategoryOverBudget(String categoryId, double budgetLimit) {
    final spent = categoryBreakdownThisMonth[categoryId] ?? 0.0;
    return spent >= budgetLimit;
  }

  bool isCategoryNearBudgetLimit(String categoryId, double budgetLimit, {double threshold = 0.75}) {
    final spent = categoryBreakdownThisMonth[categoryId] ?? 0.0;
    return spent >= (budgetLimit * threshold) && spent < budgetLimit;
  }

  // --- CSV EXPORT GENERATOR ---
  String exportToCsvString() {
    final buffer = StringBuffer();
    // Prepend UTF-8 BOM so Excel opens Vietnamese characters cleanly
    buffer.write('\uFEFF');
    buffer.writeln('Mã giao dịch,Thời gian,Loại,Đơn vị / Tiêu đề,Danh mục,Ví thanh toán,Số tiền (VNĐ),Độ tin cậy AI,Ghi chú');

    for (final item in filteredExpenses) {
      final id = '"${item.id}"';
      final date = '"${item.date.day.toString().padLeft(2, '0')}/${item.date.month.toString().padLeft(2, '0')}/${item.date.year}"';
      final type = item.isIncome ? '"Thu nhập"' : (item.isTransfer ? '"Chuyển ví"' : '"Chi tiêu"');
      final title = '"${item.title.replaceAll('"', '""')}"';
      final cat = '"${item.categoryId.replaceAll('"', '""')}"';
      final wallet = '"${item.walletId}"';
      final amount = item.amount.toStringAsFixed(0);
      final conf = '"${(item.confidenceScore * 100).toStringAsFixed(0)}%"';
      final notes = '"${(item.notes ?? '').replaceAll('"', '""')}"';

      buffer.writeln('$id,$date,$type,$title,$cat,$wallet,$amount,$conf,$notes');
    }

    return buffer.toString();
  }
}
