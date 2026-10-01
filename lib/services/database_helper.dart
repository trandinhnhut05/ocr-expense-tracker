import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/expense.dart';
import '../models/category.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ocr_expenses.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Categories table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        name_vi TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        budget_limit REAL NOT NULL
      )
    ''');

    // 2. Expenses table
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category_id TEXT NOT NULL,
        date TEXT NOT NULL,
        merchant TEXT,
        receipt_image_path TEXT,
        raw_ocr_text TEXT,
        confidence_score REAL DEFAULT 1.0,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    // 3. Performance Indexes
    await db.execute('CREATE INDEX idx_expenses_date ON expenses (date);');
    await db.execute('CREATE INDEX idx_expenses_cat ON expenses (category_id);');

    // Seed default categories
    final batch = db.batch();
    for (final cat in ExpenseCategory.defaultCategories) {
      batch.insert('categories', cat.toMap());
    }
    await batch.commit(noResult: true);
  }

  // --- EXPENSE CRUD ---

  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return await db.insert(
      'expenses',
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(String id) async {
    final db = await database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final result = await db.query('expenses', orderBy: 'date DESC, created_at DESC');
    return result.map((json) => Expense.fromMap(json)).toList();
  }

  Future<List<Expense>> getRecentExpenses({int limit = 15}) async {
    final db = await database;
    final result = await db.query(
      'expenses',
      orderBy: 'date DESC, created_at DESC',
      limit: limit,
    );
    return result.map((json) => Expense.fromMap(json)).toList();
  }

  Future<List<Expense>> getExpensesInRange(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.query(
      'expenses',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return result.map((json) => Expense.fromMap(json)).toList();
  }

  // --- ANALYTICS AGGREGATIONS ---

  Future<Map<String, double>> getCategoryTotals(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT category_id, SUM(amount) as total
      FROM expenses
      WHERE date >= ? AND date <= ?
      GROUP BY category_id
    ''', [start.toIso8601String(), end.toIso8601String()]);

    final Map<String, double> map = {};
    for (final row in result) {
      final catId = row['category_id'] as String;
      final total = (row['total'] as num).toDouble();
      map[catId] = total;
    }
    return map;
  }

  Future<List<Map<String, dynamic>>> getMonthlyTotals(int year) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT strftime('%m', date) as month, SUM(amount) as total
      FROM expenses
      WHERE strftime('%Y', date) = ?
      GROUP BY month
      ORDER BY month ASC
    ''', [year.toString()]);

    return result;
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
