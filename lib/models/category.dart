import 'package:flutter/material.dart';

class ExpenseCategory {
  final String id;
  final String name;
  final String nameVi;
  final IconData icon;
  final Color color;
  final double defaultMonthlyBudget;

  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.nameVi,
    required this.icon,
    required this.color,
    this.defaultMonthlyBudget = 2000000.0, // Default 2,000,000 VND
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'name_vi': nameVi,
      'color_value': color.value,
      'budget_limit': defaultMonthlyBudget,
    };
  }

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) {
    final cat = defaultCategories.firstWhere(
      (c) => c.id == map['id'],
      orElse: () => defaultCategories.last,
    );
    return ExpenseCategory(
      id: map['id'] as String,
      name: map['name'] as String? ?? cat.name,
      nameVi: map['name_vi'] as String? ?? cat.nameVi,
      icon: cat.icon,
      color: map['color_value'] != null
          ? Color(map['color_value'] as int)
          : cat.color,
      defaultMonthlyBudget: (map['budget_limit'] as num?)?.toDouble() ??
          cat.defaultMonthlyBudget,
    );
  }

  static const List<ExpenseCategory> defaultCategories = [
    ExpenseCategory(
      id: 'food',
      name: 'Food & Dining',
      nameVi: 'Ăn uống & Cà phê',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFFF5722), // Deep Orange
      defaultMonthlyBudget: 3000000.0,
    ),
    ExpenseCategory(
      id: 'groceries',
      name: 'Groceries & Mart',
      nameVi: 'Siêu thị & Tạp hóa',
      icon: Icons.local_grocery_store_rounded,
      color: Color(0xFF4CAF50), // Green
      defaultMonthlyBudget: 2500000.0,
    ),
    ExpenseCategory(
      id: 'shopping',
      name: 'Shopping & Retail',
      nameVi: 'Mua sắm & Đồ dùng',
      icon: Icons.shopping_bag_rounded,
      color: Color(0xFFE91E63), // Pink
      defaultMonthlyBudget: 1500000.0,
    ),
    ExpenseCategory(
      id: 'transport',
      name: 'Transportation',
      nameVi: 'Di chuyển & Xăng xe',
      icon: Icons.directions_car_rounded,
      color: Color(0xFF2196F3), // Blue
      defaultMonthlyBudget: 1000000.0,
    ),
    ExpenseCategory(
      id: 'utilities',
      name: 'Bills & Utilities',
      nameVi: 'Điện nước & Hóa đơn',
      icon: Icons.bolt_rounded,
      color: Color(0xFFFFC107), // Amber
      defaultMonthlyBudget: 1200000.0,
    ),
    ExpenseCategory(
      id: 'entertainment',
      name: 'Entertainment',
      nameVi: 'Giải trí & Phim ảnh',
      icon: Icons.movie_filter_rounded,
      color: Color(0xFF9C27B0), // Purple
      defaultMonthlyBudget: 800000.0,
    ),
    ExpenseCategory(
      id: 'education',
      name: 'Education & Study',
      nameVi: 'Học tập & Sách vở',
      icon: Icons.school_rounded,
      color: Color(0xFF00BCD4), // Cyan
      defaultMonthlyBudget: 1500000.0,
    ),
    ExpenseCategory(
      id: 'health',
      name: 'Health & Pharmacy',
      nameVi: 'Sức khỏe & Thuốc men',
      icon: Icons.medical_services_rounded,
      color: Color(0xFF009688), // Teal
      defaultMonthlyBudget: 1000000.0,
    ),
    ExpenseCategory(
      id: 'other',
      name: 'Other Expenses',
      nameVi: 'Chi tiêu khác',
      icon: Icons.more_horiz_rounded,
      color: Color(0xFF78909C), // Blue Grey
      defaultMonthlyBudget: 1000000.0,
    ),
  ];

  static ExpenseCategory getById(String id) {
    return defaultCategories.firstWhere(
      (c) => c.id == id,
      orElse: () => defaultCategories.last,
    );
  }
}
