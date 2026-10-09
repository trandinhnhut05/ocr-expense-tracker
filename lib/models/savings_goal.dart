import 'package:flutter/material.dart';

class SavingsGoal {
  final String id;
  final String title;
  final double targetAmount;
  double currentAmount;
  final DateTime deadline;
  final IconData icon;
  final Color color;

  SavingsGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.deadline,
    this.icon = Icons.savings_rounded,
    this.color = const Color(0xFF00E5FF),
  });

  double get progress => targetAmount > 0
      ? (currentAmount / targetAmount).clamp(0.0, 1.0)
      : 0.0;

  double get remainingAmount =>
      (targetAmount - currentAmount).clamp(0.0, targetAmount);

  bool get isAchieved => currentAmount >= targetAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'deadline': deadline.toIso8601String(),
    };
  }

  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    return SavingsGoal(
      id: map['id'] as String,
      title: map['title'] as String,
      targetAmount: (map['target_amount'] as num).toDouble(),
      currentAmount: (map['current_amount'] as num?)?.toDouble() ?? 0.0,
      deadline: DateTime.parse(map['deadline'] as String),
    );
  }

  static List<SavingsGoal> defaultGoals = [
    SavingsGoal(
      id: 'g1',
      title: 'Mua Laptop Mới',
      targetAmount: 20000000.0,
      currentAmount: 14000000.0,
      deadline: DateTime(2026, 12, 31),
      icon: Icons.laptop_mac_rounded,
      color: const Color(0xFF00E5FF),
    ),
    SavingsGoal(
      id: 'g2',
      title: 'Quỹ Khẩn Cấp',
      targetAmount: 10000000.0,
      currentAmount: 6500000.0,
      deadline: DateTime(2026, 11, 30),
      icon: Icons.security_rounded,
      color: const Color(0xFF00E676),
    ),
    SavingsGoal(
      id: 'g3',
      title: 'Du Lịch Mùa Đông',
      targetAmount: 5000000.0,
      currentAmount: 2200000.0,
      deadline: DateTime(2026, 12, 20),
      icon: Icons.flight_takeoff_rounded,
      color: const Color(0xFFFFB300),
    ),
  ];
}
