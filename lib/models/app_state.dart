import 'package:flutter/foundation.dart';
import 'transaction.dart';
import 'user_settings.dart';
import 'daily_transaction_group.dart';
import '../services/hive_service.dart';

class AppState extends ChangeNotifier {
  UserSettings _userSettings = UserSettings();
  double _balance = 0.0;
  List<Transaction> _transactions = [];
  bool _isFirstTime = true;

  List<DailyTransactionGroup>? _cachedGroups;
  Map<String, List<Transaction>> _monthlyTransactionsCache = {};
  Map<String, double> _monthlyIncomeCache = {};
  Map<String, double> _monthlyExpensesCache = {};

  UserSettings get userSettings => _userSettings;
  double get balance => _balance;
  List<Transaction> get transactions => _transactions;
  bool get isFirstTime => _isFirstTime;

  void loadFromHive() {
    _userSettings = HiveService.getUserSettings();
    _balance = HiveService.getBalance();
    _transactions = HiveService.getAllTransactions();
    _invalidateCache();
    notifyListeners();
  }

  void _invalidateCache() {
    _cachedGroups = null;
    _monthlyTransactionsCache.clear();
    _monthlyIncomeCache.clear();
    _monthlyExpensesCache.clear();
  }

  List<DailyTransactionGroup> getGroupedTransactions() {
    if (_cachedGroups == null) {
      _cachedGroups = DailyTransactionGroup.groupTransactionsByDate(_transactions);
    }
    return _cachedGroups!;
  }

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
    _invalidateCache();
    notifyListeners();
  }

  void updateTransaction(int index, Transaction transaction) {
    if (index >= 0 && index < _transactions.length) {
      final oldTransaction = _transactions[index];
      _balance -= oldTransaction.amount;
      _balance += transaction.amount;
      _transactions[index] = transaction;
      _invalidateCache();
      notifyListeners();
    }
  }

  void deleteTransaction(int index) {
    if (index >= 0 && index < _transactions.length) {
      final transaction = _transactions[index];
      _balance -= transaction.amount;
      _transactions.removeAt(index);
      _invalidateCache();
      notifyListeners();
    }
  }

  List<Transaction> getMonthlyTransactions(DateTime month) {
    final key = '${month.year}-${month.month}';
    if (!_monthlyTransactionsCache.containsKey(key)) {
      _monthlyTransactionsCache[key] = _transactions.where((transaction) {
        return transaction.date.year == month.year &&
               transaction.date.month == month.month;
      }).toList();
    }
    return _monthlyTransactionsCache[key]!;
  }

  double getMonthlyIncome(DateTime month) {
    final key = '${month.year}-${month.month}';
    if (!_monthlyIncomeCache.containsKey(key)) {
      final monthlyTransactions = getMonthlyTransactions(month);
      _monthlyIncomeCache[key] = monthlyTransactions
          .where((t) => t.amount > 0)
          .fold(0.0, (sum, t) => sum + t.amount);
    }
    return _monthlyIncomeCache[key]!;
  }

  double getMonthlyExpenses(DateTime month) {
    final key = '${month.year}-${month.month}';
    if (!_monthlyExpensesCache.containsKey(key)) {
      final monthlyTransactions = getMonthlyTransactions(month);
      _monthlyExpensesCache[key] = monthlyTransactions
          .where((t) => t.amount < 0)
          .fold(0.0, (sum, t) => sum + t.amount.abs());
    }
    return _monthlyExpensesCache[key]!;
  }
}
