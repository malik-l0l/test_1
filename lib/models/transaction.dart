import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  DateTime date;
  
  @HiveField(2)
  double amount;
  
  @HiveField(3)
  String reason;
  
  @HiveField(4)
  DateTime timestamp;
  
  Transaction({
    required this.id,
    required this.date,
    required this.amount,
    required this.reason,
    required this.timestamp,
  });
  
  bool get isIncome => amount > 0;
  bool get isExpense => amount < 0;
}
