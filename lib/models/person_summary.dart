class PersonSummary {
  final String name;
  final double totalBalance;
  final int transactionCount;
  final DateTime lastTransactionDate;

  PersonSummary({
    required this.name,
    required this.totalBalance,
    required this.transactionCount,
    required this.lastTransactionDate,
  });

  bool get owesYou => totalBalance > 0;
  bool get youOwe => totalBalance < 0;
  bool get isSettled => totalBalance == 0;

  String get balanceText {
    if (isSettled) return "Settled";
    if (owesYou) return "Owes you ₹${totalBalance.abs().toStringAsFixed(2)}";
    return "You owe ₹${totalBalance.abs().toStringAsFixed(2)}";
  }

  String get actionText {
    if (isSettled) return "All settled up!";
    if (owesYou) return "Collect ₹${totalBalance.abs().toStringAsFixed(2)}";
    return "Pay ₹${totalBalance.abs().toStringAsFixed(2)}";
  }
}