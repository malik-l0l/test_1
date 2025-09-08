import 'package:flutter/foundation.dart';
import 'transaction.dart';
import 'user_settings.dart';

class AppState extends ChangeNotifier {
  UserSettings _userSettings = UserSettings();
  double _balance = 0.0;
  List<Transaction> _transactions = [];
  bool _isFirstTime = true;

  UserSettings get userSettings => _userSettings;
  double get balance => _balance;
  List<Transaction> get transactions => _transactions;
  bool get isFirstTime => _isFirstTime;

  void updateUserSettings(UserSettings settings) {
    _userSettings = settings;
    _isFirstTime = false;
    notifyListeners();
  }

  void updateBalance(double balance) {
    _balance = balance;
    notifyListeners();
  }

  void addTransaction(Transaction transaction) {
    _transactions.insert(0, transaction);
    _balance += transaction.amount;
    notifyListeners();
  }

  void updateTransaction(int index, Transaction transaction) {
    if (index >= 0 && index < _transactions.length) {
      final oldTransaction = _transactions[index];
      _balance -= oldTransaction.amount;
      _balance += transaction.amount;
      _transactions[index] = transaction;
      notifyListeners();
    }
  }

  void deleteTransaction(int index) {
    if (index >= 0 && index < _transactions.length) {
      final transaction = _transactions[index];
      _balance -= transaction.amount;
      _transactions.removeAt(index);
      notifyListeners();
    }
  }

  List<Transaction> getMonthlyTransactions(DateTime month) {
    return _transactions.where((transaction) {
      return transaction.date.year == month.year &&
             transaction.date.month == month.month;
    }).toList();
  }

  double getMonthlyIncome(DateTime month) {
    final monthlyTransactions = getMonthlyTransactions(month);
    return monthlyTransactions
        .where((t) => t.amount > 0)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getMonthlyExpenses(DateTime month) {
    final monthlyTransactions = getMonthlyTransactions(month);
    return monthlyTransactions
        .where((t) => t.amount < 0)
        .fold(0.0, (sum, t) => sum + t.amount.abs());
  }
}