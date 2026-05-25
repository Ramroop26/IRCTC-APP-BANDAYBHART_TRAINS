import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_service.dart';

class WalletService extends ChangeNotifier {
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal();

  double _balance = 0.0;
  final List<WalletTransaction> _transactions = [];

  double get balance => _balance;
  List<WalletTransaction> get transactions => List.unmodifiable(_transactions);

  // Fetch balance and transaction ledger from MySQL
  Future<void> fetchWalletData() async {
    final email = AuthService().userEmail;
    if (email.isEmpty) return;

    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/wallet/balance?email=$email'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          _balance = data['balance'].toDouble();
          _transactions.clear();
          final txns = data['transactions'] as List;
          for (var t in txns) {
            _transactions.add(WalletTransaction(
              id: t['id'],
              amount: t['amount'].toDouble(),
              type: t['type'] == 'credit' ? WalletTransactionType.credit : WalletTransactionType.debit,
              description: t['description'],
              date: DateTime.parse(t['date']),
            ));
          }
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch wallet data: $e");
    }
  }

  // Deposit funds to eWallet
  Future<void> addFunds(double amount) async {
    if (amount <= 0) return;
    final email = AuthService().userEmail;
    if (email.isEmpty) return;

    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/wallet/deposit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'amount': amount
        }),
      );
      if (res.statusCode == 200) {
        await fetchWalletData();
      }
    } catch (e) {
      debugPrint("Add funds network error: $e");
    }
  }

  // Deduct funds (handles booking charge sync)
  Future<bool> deductFunds(double amount, String ticketInfo) async {
    // Note: Database level booking/create already processes deductions in transaction.
    // We fetch the updated state here to keep UI in sync.
    await fetchWalletData();
    return true;
  }

  // Refund funds (handles cancellation refund sync)
  Future<void> refundFunds(double amount, String pnr) async {
    // Note: Database level booking/cancel already processes refunds in transaction.
    // We fetch the updated state here to keep UI in sync.
    await fetchWalletData();
  }

  // Withdraw funds to bank
  Future<bool> withdrawFunds(double amount, String bankDetails) async {
    if (amount <= 0) return false;
    final email = AuthService().userEmail;
    if (email.isEmpty) return false;

    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/wallet/withdraw'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'amount': amount,
          'bankDetails': bankDetails
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          await fetchWalletData();
          return true;
        }
      }
    } catch (e) {
      debugPrint("Wallet withdrawal error: $e");
    }
    return false;
  }
}

enum WalletTransactionType { credit, debit }

class WalletTransaction {
  final String id;
  final double amount;
  final WalletTransactionType type;
  final String description;
  final DateTime date;

  WalletTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    required this.date,
  });

  String get formattedDate => DateFormat('dd MMM yyyy, hh:mm a').format(date);
  String get formattedAmount => "₹${amount.toStringAsFixed(2)}";
}
