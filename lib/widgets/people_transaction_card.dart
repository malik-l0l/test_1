import 'package:flutter/material.dart';
import '../models/people_transaction.dart';
import '../utils/date_formatter.dart';
import '../services/hive_service.dart';
import '../services/transaction_analysis_service.dart';

class PeopleTransactionCard extends StatelessWidget {
  final PeopleTransaction transaction;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final List<PeopleTransaction>? allTransactions;
  final bool showSeparator;

  const PeopleTransactionCard({
    Key? key,
    required this.transaction,
    this.onEdit,
    this.onDelete,
    this.allTransactions,
    this.showSeparator = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = HiveService.getUserSettings();
    
    // Get color and icon based on transaction type
    Color amountColor;
    IconData iconData;
    String actionText;
    
    switch (transaction.transactionType) {
      case 'give':
        amountColor = Colors.red;
        iconData = Icons.arrow_upward;
        actionText = 'Given';
        break;
      case 'take':
        amountColor = Colors.green;
        iconData = Icons.arrow_downward;
        actionText = 'Taken';
        break;
      case 'owe':
        amountColor = Colors.orange;
        iconData = Icons.credit_card;
        actionText = 'You Owe';
        break;
      case 'claim':
        amountColor = Colors.blue;
        iconData = Icons.account_balance_wallet;
        actionText = 'Claim';
        break;
      default:
        // Fallback for legacy data
        final isGiven = transaction.isGiven;
        amountColor = isGiven ? Colors.red : Colors.green;
        iconData = isGiven ? Icons.arrow_upward : Icons.arrow_downward;
        actionText = isGiven ? 'Given' : 'Taken';
    }
    
    Widget cardWidget;
    
    if (settings.cardTheme == 'theme1') {
      cardWidget = Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: amountColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: amountColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onEdit,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: amountColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      iconData,
                      color: amountColor,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.reason,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 4),
                            Text(
                              DateFormatter.formatDate(transaction.date),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(width: 12),
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 4),
                            Text(
                              DateFormatter.formatTime(transaction.timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${transaction.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: amountColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        actionText,
                        style: TextStyle(
                          fontSize: 12,
                          color: amountColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (onDelete != null) ...[
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      // Theme 2 - Original design
      cardWidget = Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onEdit,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: amountColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          iconData,
                          color: amountColor,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              transaction.reason,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                SizedBox(width: 4),
                                Text(
                                  DateFormatter.formatDate(transaction.date),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(width: 12),
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                SizedBox(width: 4),
                                Text(
                                  DateFormatter.formatTime(transaction.timestamp),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${transaction.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: amountColor,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            actionText,
                            style: TextStyle(
                              fontSize: 12,
                              color: amountColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (onDelete != null) ...[
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: onDelete,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    // Wrap with separator if needed
    if (showSeparator) {
      return Column(
        children: [
          cardWidget,
          _buildSettlementSeparator(context),
        ],
      );
    }
    
    return cardWidget;
  }
  
  Widget _buildSettlementSeparator(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.grey[400]!,
                    Colors.grey[400]!,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.green.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  'SETTLED',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.grey[400]!,
                    Colors.grey[400]!,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}