import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/user_settings.dart';
import '../utils/constants.dart';
import 'widget_service.dart';

class HiveService {
  static late Box<Transaction> _transactionsBox;
  static late Box<UserSettings> _userSettingsBox;
  static late Box<double> _balanceBox;

  static Box<Transaction> get transactionsBox => _transactionsBox;
  static Box<UserSettings> get userSettingsBox => _userSettingsBox;
  static Box<double> get balanceBox => _balanceBox;

  static Future<void> init() async {
    _transactionsBox = await Hive.openBox<Transaction>(AppConstants.transactionsBox);
    _userSettingsBox = await Hive.openBox<UserSettings>(AppConstants.userSettingsBox);
    _balanceBox = await Hive.openBox<double>(AppConstants.balanceBox);
    
    // Initialize default settings if not exists
    if (!_userSettingsBox.containsKey(AppConstants.userSettingsKey)) {
      await _userSettingsBox.put(AppConstants.userSettingsKey, UserSettings());
    }
    
    // Initialize balance if not exists
    if (!_balanceBox.containsKey(AppConstants.balanceKey)) {
      await _balanceBox.put(AppConstants.balanceKey, AppConstants.defaultBalance);
    }
  }

  // User Settings
  static UserSettings getUserSettings() {
    return _userSettingsBox.get(AppConstants.userSettingsKey) ?? UserSettings();
  }

  static Future<void> updateUserSettings(UserSettings settings) async {
    await _userSettingsBox.put(AppConstants.userSettingsKey, settings);
  }

  // Balance Management
  static double getBalance() {
    return _balanceBox.get(AppConstants.balanceKey) ?? AppConstants.defaultBalance;
  }

  static Future<void> updateBalance(double balance) async {
    await _balanceBox.put(AppConstants.balanceKey, balance);
  }

  // Transaction Management
  static Future<void> addTransaction(Transaction transaction) async {
    await _transactionsBox.put(transaction.id, transaction);

    // Update balance
    final currentBalance = getBalance();
    await updateBalance(currentBalance + transaction.amount);
    await WidgetService.updateWidget();
  }

  static List<Transaction> getAllTransactions() {
    return _transactionsBox.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  static Future<void> updateTransaction(int index, Transaction transaction) async {
    final allTransactions = getAllTransactions();
    if (index >= 0 && index < allTransactions.length) {
      final oldTransaction = allTransactions[index];

      // Update balance (remove old, add new)
      final currentBalance = getBalance();
      final newBalance = currentBalance - oldTransaction.amount + transaction.amount;
      await updateBalance(newBalance);

      // Update transaction
      await _transactionsBox.put(transaction.id, transaction);
      await WidgetService.updateWidget();
    }
  }

  static Future<void> deleteTransaction(int index) async {
    final allTransactions = getAllTransactions();
    if (index >= 0 && index < allTransactions.length) {
      final transaction = allTransactions[index];

      // Update balance
      final currentBalance = getBalance();
      await updateBalance(currentBalance - transaction.amount);

      // Delete transaction
      await _transactionsBox.delete(transaction.id);
      await WidgetService.updateWidget();
    }
  }

  // Delete transaction by ID (for people transactions)
  static Future<void> deleteTransactionById(String id) async {
    final transaction = _transactionsBox.get(id);
    if (transaction != null) {
      // Update balance
      final currentBalance = getBalance();
      await updateBalance(currentBalance - transaction.amount);

      // Delete transaction
      await _transactionsBox.delete(id);
      await WidgetService.updateWidget();
    }
  }

  // Check if a transaction exists by ID
  static bool transactionExists(String id) {
    return _transactionsBox.containsKey(id);
  }

  // Get transaction by ID
  static Transaction? getTransactionById(String id) {
    return _transactionsBox.get(id);
  }

  // Monthly transactions
  static List<Transaction> getMonthlyTransactions(DateTime month) {
    return getAllTransactions().where((transaction) {
      return transaction.date.year == month.year &&
             transaction.date.month == month.month;
    }).toList();
  }

  // Clear all data (for testing/reset)
  static Future<void> clearAllData() async {
    await _transactionsBox.clear();
    await _balanceBox.clear();
    await updateBalance(AppConstants.defaultBalance);
  }
}