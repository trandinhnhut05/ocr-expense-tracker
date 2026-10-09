import 'package:flutter/material.dart';

enum WalletType {
  cash,
  bank,
  eWallet,
}

class Wallet {
  final String id;
  final String name;
  final WalletType type;
  double balance;
  final IconData icon;
  final Color color;
  final String accountNumber;

  Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.icon,
    required this.color,
    this.accountNumber = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'balance': balance,
      'account_number': accountNumber,
    };
  }

  factory Wallet.fromMap(Map<String, dynamic> map) {
    final typeName = map['type'] as String? ?? 'cash';
    final type = WalletType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => WalletType.cash,
    );

    final defaultWallet = defaultWallets.firstWhere(
      (w) => w.id == map['id'],
      orElse: () => defaultWallets.first,
    );

    return Wallet(
      id: map['id'] as String,
      name: map['name'] as String? ?? defaultWallet.name,
      type: type,
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      icon: defaultWallet.icon,
      color: defaultWallet.color,
      accountNumber: map['account_number'] as String? ?? '',
    );
  }

  static List<Wallet> defaultWallets = [
    Wallet(
      id: 'cash',
      name: 'Tiền mặt',
      type: WalletType.cash,
      balance: 1500000.0,
      icon: Icons.account_balance_wallet_rounded,
      color: const Color(0xFF00E676),
    ),
    Wallet(
      id: 'bank',
      name: 'Tài khoản VCB / MB',
      type: WalletType.bank,
      balance: 12500000.0,
      icon: Icons.account_balance_rounded,
      color: const Color(0xFF00E5FF),
      accountNumber: '**** 8899',
    ),
    Wallet(
      id: 'momo',
      name: 'Ví MoMo',
      type: WalletType.eWallet,
      balance: 1820000.0,
      icon: Icons.payments_rounded,
      color: const Color(0xFFE91E63),
      accountNumber: '098****321',
    ),
  ];
}
