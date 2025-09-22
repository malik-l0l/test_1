import 'package:hive/hive.dart';

part 'people_transaction.g.dart';

@HiveType(typeId: 2)
class PeopleTransaction extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String personName;

  @HiveField(2)
  double amount;

  @HiveField(3)
  String reason;

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  DateTime timestamp;

  @HiveField(6)
  bool isGiven; // Legacy field - kept for backward compatibility

  @HiveField(7, defaultValue: 'give')
  String transactionType; // 'give', 'take', 'owe', 'claim'

  PeopleTransaction({
    required this.id,
    required this.personName,
    required this.amount,
    required this.reason,
    required this.date,
    required this.timestamp,
    this.isGiven = true, // Legacy - will be derived from transactionType
    this.transactionType = 'give',
  }) {
    // Ensure backward compatibility
    if (transactionType == 'give' || transactionType == 'take') {
      isGiven = transactionType == 'give';
    }
  }

  // Calculate the balance for this person
  // Positive means they owe you, negative means you owe them
  double get balanceImpact {
    switch (transactionType) {
      case 'give':
        return amount; // You gave money, they owe you
      case 'take':
        return -amount; // You took money, you owe them
      case 'owe':
        return -amount; // They spent for you, you owe them
      case 'claim':
        return amount; // They have your money, they owe you
      default:
        return isGiven ? amount : -amount; // Fallback for legacy data
    }
  }

  // Calculate the main balance impact
  double get mainBalanceImpact {
    switch (transactionType) {
      case 'give':
        return -amount; // Money left your account
      case 'take':
        return amount; // Money came to your account
      case 'owe':
        return 0; // No change to main balance (they paid for you)
      case 'claim':
        return 0; // No change to main balance (your money is with them)
      default:
        return isGiven ? -amount : amount; // Fallback for legacy data
    }
  }

  String get displayText {
    switch (transactionType) {
      case 'give':
        return "Collect ₹${amount.toStringAsFixed(2)} from $personName";
      case 'take':
        return "Pay ₹${amount.toStringAsFixed(2)} back to $personName";
      case 'owe':
        return "Pay ₹${amount.toStringAsFixed(2)} to $personName";
      case 'claim':
        return "Collect ₹${amount.toStringAsFixed(2)} from $personName";
      default:
        // Fallback for legacy data
        if (isGiven) {
          return "Collect ₹${amount.toStringAsFixed(2)} from $personName";
        } else {
          return "Pay ₹${amount.toStringAsFixed(2)} back to $personName";
        }
    }
  }

  String get actionDescription {
    switch (transactionType) {
      case 'give':
        return "You gave money";
      case 'take':
        return "You took money";
      case 'owe':
        return "They paid for you";
      case 'claim':
        return "Your money with them";
      default:
        return isGiven ? "You gave money" : "You took money";
    }
  }

  String get fullDescription {
    switch (transactionType) {
      case 'give':
        return "You gave ₹${amount.toStringAsFixed(2)} to $personName for $reason";
      case 'take':
        return "You took ₹${amount.toStringAsFixed(2)} from $personName for $reason";
      case 'owe':
        return "$personName spent ₹${amount.toStringAsFixed(2)} for you for $reason";
      case 'claim':
        return "$personName has ₹${amount.toStringAsFixed(2)} of your money for $reason";
      default:
        if (isGiven) {
          return "You gave ₹${amount.toStringAsFixed(2)} to $personName for $reason";
        } else {
          return "You took ₹${amount.toStringAsFixed(2)} from $personName for $reason";
        }
    }
  }

  // Check if this transaction creates a settlement point
  bool isSettlementPoint(List<PeopleTransaction> allTransactions) {
    // Find this transaction's index in the list
    final thisIndex = allTransactions.indexWhere((t) => t.id == id);
    if (thisIndex == -1 || thisIndex == allTransactions.length - 1) return false;
    
    // Calculate running balance up to this transaction
    double runningBalance = 0.0;
    for (int i = allTransactions.length - 1; i >= thisIndex; i--) {
      runningBalance += allTransactions[i].balanceImpact;
    }
    
    // Check if balance becomes zero after this transaction
    return runningBalance == 0.0;
  }
}