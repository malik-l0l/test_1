import 'transaction.dart';

class DailyTransactionGroup {
  final DateTime date;
  final List<Transaction> transactions;
  final double totalIncome;
  final double totalExpenses;
  final double netAmount;

  DailyTransactionGroup({
    required this.date,
    required this.transactions,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netAmount,
  });

  static List<DailyTransactionGroup> groupTransactionsByDate(List<Transaction> transactions) {
    if (transactions.isEmpty) return [];

    // Sort transactions by date (newest first)
    transactions.sort((a, b) => b.date.compareTo(a.date));

    final Map<String, List<Transaction>> groupedTransactions = {};
    
    for (final transaction in transactions) {
      final dateKey = '${transaction.date.year}-${transaction.date.month}-${transaction.date.day}';
      if (!groupedTransactions.containsKey(dateKey)) {
        groupedTransactions[dateKey] = [];
      }
      groupedTransactions[dateKey]!.add(transaction);
    }

    final List<DailyTransactionGroup> groups = [];
    
    for (final entry in groupedTransactions.entries) {
      final dayTransactions = entry.value;
      final date = dayTransactions.first.date;
      
      double totalIncome = 0;
      double totalExpenses = 0;
      
      for (final transaction in dayTransactions) {
        if (transaction.amount > 0) {
          totalIncome += transaction.amount;
        } else {
          totalExpenses += transaction.amount.abs();
        }
      }
      
      // Sort transactions within the day by timestamp (newest first)
      dayTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      groups.add(DailyTransactionGroup(
        date: date,
        transactions: dayTransactions,
        totalIncome: totalIncome,
        totalExpenses: totalExpenses,
        netAmount: totalIncome - totalExpenses,
      ));
    }

    // Sort groups by date (newest first)
    groups.sort((a, b) => b.date.compareTo(a.date));
    
    return groups;
  }
}