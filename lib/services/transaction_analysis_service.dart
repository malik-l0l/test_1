import '../models/people_transaction.dart';

class TransactionAnalysisService {
  /// Analyzes transactions and finds settlement points
  static List<int> findSettlementPoints(List<PeopleTransaction> transactions) {
    if (transactions.isEmpty) return [];
    
    List<int> settlementIndices = [];
    double runningBalance = 0.0;
    
    // Process transactions from oldest to newest (reverse order)
    for (int i = transactions.length - 1; i >= 0; i--) {
      runningBalance += transactions[i].balanceImpact;
      
      // If balance becomes zero, this is a settlement point
      if (runningBalance == 0.0 && i > 0) {
        settlementIndices.add(i);
      }
    }
    
    return settlementIndices;
  }
  
  /// Gets transactions above the last settlement point
  static List<PeopleTransaction> getTransactionsAboveLastSettlement(
    List<PeopleTransaction> transactions
  ) {
    final settlementPoints = findSettlementPoints(transactions);
    
    if (settlementPoints.isEmpty) {
      return transactions;
    }
    
    // Get the last (most recent) settlement point
    final lastSettlementIndex = settlementPoints.first;
    
    // Return transactions from start up to (but not including) the settlement point
    return transactions.sublist(0, lastSettlementIndex);
  }
  
  /// Calculates the balance for transactions above last settlement
  static double getBalanceAboveLastSettlement(List<PeopleTransaction> transactions) {
    final transactionsAboveSettlement = getTransactionsAboveLastSettlement(transactions);
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
    
    final lastSettlementIndex = settlementPoints.first;
    final transactionsBelowSettlement = transactions.sublist(lastSettlementIndex);
    
    return transactionsBelowSettlement.fold<double>(
      0.0, 
      (sum, transaction) => sum + transaction.balanceImpact,
    );
  }
}