import '../models/people_transaction.dart';

class TransactionAnalysisService {
  /// Analyzes transactions and finds settlement points
  /// Returns indices where separator should appear AFTER the transaction at that index
  static List<int> findSettlementPoints(List<PeopleTransaction> transactions) {
    if (transactions.isEmpty) return [];

    List<int> settlementIndices = [];
    double runningBalance = 0.0;

    // Process transactions from oldest to newest (backward through the list)
    // The list is sorted with newest first, so we iterate backwards
    for (int i = transactions.length - 1; i >= 0; i--) {
      runningBalance += transactions[i].balanceImpact;

      // If balance becomes zero after this transaction, mark the position
      // where the separator should appear
      if (runningBalance == 0.0 && i > 0) {
        // The next transaction (i-1) breaks the settlement
        // So separator appears after transaction at index (i-1)
        settlementIndices.add(i - 1);
      }
    }

    return settlementIndices;
  }

  /// Gets transactions above the last settlement point
  static List<PeopleTransaction> getTransactionsAboveLastSettlement(
      List<PeopleTransaction> transactions) {
    final settlementPoints = findSettlementPoints(transactions);

    if (settlementPoints.isEmpty) {
      return transactions;
    }

    // Get the last (most recent) settlement point
    // Since we add settlements as we find them from old to new,
    // the last settlement is the last element in the list
    final lastSettlementIndex = settlementPoints.last;

    // Return transactions from start up to and including the settlement point
    return transactions.sublist(0, lastSettlementIndex + 1);
  }

  /// Calculates the balance for transactions above last settlement
  static double getBalanceAboveLastSettlement(
      List<PeopleTransaction> transactions) {
    final transactionsAboveSettlement =
        getTransactionsAboveLastSettlement(transactions);
    return transactionsAboveSettlement.fold<double>(
      0.0,
      (sum, transaction) => sum + transaction.balanceImpact,
    );
  }

  /// Gets the previous balance (from transactions below the last settlement)
  static double getPreviousBalance(List<PeopleTransaction> transactions) {
    final settlementPoints = findSettlementPoints(transactions);

    if (settlementPoints.isEmpty) {
      return 0.0;
    }

    // Get the last (most recent) settlement point
    final lastSettlementIndex = settlementPoints.last;
    // Transactions below are everything after the settlement index
    if (lastSettlementIndex + 1 >= transactions.length) {
      return 0.0;
    }
    final transactionsBelowSettlement =
        transactions.sublist(lastSettlementIndex + 1);

    return transactionsBelowSettlement.fold<double>(
      0.0,
      (sum, transaction) => sum + transaction.balanceImpact,
    );
  }
}
