import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/hive_service.dart';

class WidgetService {
  static Future<void> updateWidget() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final allTransactions = HiveService.getAllTransactions();
      final todayTransactions = allTransactions.where((transaction) {
        final transactionDate = DateTime(
          transaction.date.year,
          transaction.date.month,
          transaction.date.day,
        );
        return transactionDate.isAtSameMomentAs(today);
      }).toList();

      double todayIncome = 0.0;
      double todayExpense = 0.0;

      for (var transaction in todayTransactions) {
        if (transaction.amount > 0) {
          todayIncome += transaction.amount;
        } else {
          todayExpense += transaction.amount.abs();
        }
      }

      final balance = HiveService.getBalance();
      final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

      await HomeWidget.saveWidgetData<String>('balance', currencyFormat.format(balance));
      await HomeWidget.saveWidgetData<String>('income', currencyFormat.format(todayIncome));
      await HomeWidget.saveWidgetData<String>('expense', currencyFormat.format(todayExpense));

      await HomeWidget.updateWidget(
        androidName: 'HomeWidgetProvider',
        iOSName: 'HomeWidgetProvider',
      );
    } catch (e) {
      print('Error updating widget: $e');
    }
  }
}
