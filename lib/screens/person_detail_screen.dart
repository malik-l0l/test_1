import 'package:flutter/material.dart';
import '../services/people_hive_service.dart';
import '../services/contact_service.dart';
import '../services/transaction_analysis_service.dart';
import '../models/people_transaction.dart';
import '../models/person_summary.dart';
import '../widgets/people_transaction_card.dart';
import '../widgets/add_people_transaction_modal.dart';
import '../widgets/share_modal.dart';
import '../widgets/custom_snackbar.dart';

class PersonDetailScreen extends StatefulWidget {
  final String personName;

  const PersonDetailScreen({Key? key, required this.personName})
      : super(key: key);

  @override
  _PersonDetailScreenState createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  List<PeopleTransaction> _transactions = [];
  double _balance = 0.0;
  late PersonSummary _personSummary;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    if (!mounted) return;

    try {
      setState(() {
        _transactions =
            PeopleHiveService.getTransactionsForPerson(widget.personName);
        _balance = PeopleHiveService.getBalanceForPerson(widget.personName);

        // Create person summary for sharing
        _personSummary = PersonSummary(
          name: widget.personName,
          totalBalance: _balance,
          transactionCount: _transactions.length,
          lastTransactionDate: _transactions.isNotEmpty
              ? _transactions.first.timestamp
              : DateTime.now(),
        );
      });
    } catch (e) {
      // Handle any potential errors gracefully
      if (mounted) {
        CustomSnackBar.show(context, 'Error loading data', SnackBarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = _balance >= 0;
    final balanceColor = isPositive ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.personName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_transactions.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: _showShareModal,
                  icon: Icon(
                    Icons.share,
                    color: Theme.of(context).primaryColor,
                    size: 22,
                  ),
                  tooltip: 'Share transaction summary',
                ),
              ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(),
            SizedBox(height: 24),
            _buildTransactionsList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionModal,
        child: Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildBalanceCard() {
    final isPositive = _balance >= 0;
    final color =
        _balance == 0 ? Colors.grey : (isPositive ? Colors.green : Colors.red);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Balance with ${widget.personName}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _balance == 0
                      ? Icons.check_circle
                      : isPositive
                          ? Icons.trending_up
                          : Icons.trending_down,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            '₹${_balance.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _balance == 0
                ? 'All settled up!'
                : isPositive
                    ? '${widget.personName} owes you'
                    : 'You owe ${widget.personName}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    final settlementPoints =
        TransactionAnalysisService.findSettlementPoints(_transactions);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction History (${_transactions.length})',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        if (_transactions.isEmpty)
          Container(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No transactions yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _transactions.length,
            itemBuilder: (context, index) {
              final transaction = _transactions[index];
              final showSeparator = settlementPoints.contains(index);

              return PeopleTransactionCard(
                transaction: transaction,
                currentIndex: index, // Added currentIndex parameter
                allTransactions: _transactions,
                showSeparator: showSeparator,
                onEdit: () => _editTransaction(transaction),
                onDelete: () => _deleteTransaction(transaction),
              );
            },
          ),
      ],
    );
  }

  void _showAddTransactionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPeopleTransactionModal(
        prefilledPersonName: widget.personName,
        onSave: (transaction) async {
          await PeopleHiveService.addPeopleTransaction(transaction);
          if (mounted) {
            _loadData();
            CustomSnackBar.show(context, 'People transaction added successfully!',
                SnackBarType.success);
          }
        },
      ),
    );
  }

  void _editTransaction(PeopleTransaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPeopleTransactionModal(
        transaction: transaction,
        onSave: (updatedTransaction) async {
          await PeopleHiveService.updatePeopleTransaction(
            transaction.id,
            updatedTransaction,
          );
          if (mounted) {
            _loadData();
            CustomSnackBar.show(context,
                'People transaction updated successfully!', SnackBarType.success);
          }
        },
      ),
    );
  }

  void _deleteTransaction(PeopleTransaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Transaction'),
        content: Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await PeopleHiveService.deletePeopleTransaction(transaction.id);
              Navigator.pop(context);
              if (mounted) {
                _loadData();
                CustomSnackBar.show(context, 'Transaction deleted successfully!',
                    SnackBarType.success);
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showShareModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ShareModal(
        person: _personSummary,
        allTransactions: _transactions,
      ),
    );
  }
}
