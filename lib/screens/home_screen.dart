import 'package:flutter/material.dart';
import '../services/hive_service.dart';
import '../services/people_hive_service.dart';
import '../services/greeting_service.dart';
import '../models/transaction.dart';
import '../models/daily_transaction_group.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_card.dart';
import '../widgets/date_header.dart';
import '../widgets/custom_snackbar.dart';
import 'monthly_summary_screen.dart';
import '../widgets/add_transaction_modal.dart';
import 'package:flutter/rendering.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<Transaction> _allTransactions = [];
  List<DailyTransactionGroup> _displayedGroups = [];
  List<DailyTransactionGroup> _allGroups = [];
  double _balance = 0.0;
  late ScrollController _scrollController;
  bool _isLoadingMore = false;
  int _currentPage = 0;
  static const int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    refreshData();

    // Initialize scroll controller
    _scrollController = ScrollController();

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Pagination logic
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreGroups();
    }
  }

  // Public method to refresh data from parent
  void refreshData() {
    setState(() {
      _allTransactions = HiveService.getAllTransactions();
      _balance = HiveService.getBalance();
      _allGroups =
          DailyTransactionGroup.groupTransactionsByDate(_allTransactions);
      _currentPage = 0;
      _displayedGroups = [];
      _loadMoreGroups();
    });
  }

  void _loadMoreGroups() {
    if (_isLoadingMore || _displayedGroups.length >= _allGroups.length) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Simulate loading delay for smooth UX
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          final startIndex = _currentPage * _itemsPerPage;
          final endIndex =
              (startIndex + _itemsPerPage).clamp(0, _allGroups.length);

          if (startIndex < _allGroups.length) {
            _displayedGroups.addAll(_allGroups.sublist(startIndex, endIndex));
            _currentPage++;
          }

          _isLoadingMore = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = HiveService.getUserSettings();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildModernAppBar(settings),
            Expanded(
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BalanceCard(
                            balance: _balance,
                            currency: settings.currency,
                          ),
                          SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  _buildGroupedTransactionsList(settings.currency),
                  if (_isLoadingMore)
                    SliverToBoxAdapter(
                      child: Container(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  // Add some bottom padding for bottom nav
                  SliverToBoxAdapter(
                    child: SizedBox(height: 120),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar(settings) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  GreetingService.getSessionGreeting(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                ),
                if (settings.name.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                      settings.name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.all(10),
              constraints: BoxConstraints(minWidth: 42, minHeight: 42),
              onPressed: _navigateToSummary,
              icon: Icon(
                Icons.analytics_outlined,
                color: Colors.blue,
                size: 22,
              ),
              tooltip: 'Monthly Summary',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedTransactionsList(String currency) {
    if (_allTransactions.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          height: 300,
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
                SizedBox(height: 8),
                Text(
                  'Tap the + button to add your first transaction',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, groupIndex) {
          if (groupIndex >= _displayedGroups.length) return null;

          final group = _displayedGroups[groupIndex];
          final List<Widget> children = [];

          // Add date header
          children.add(
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: DateHeader(
                date: group.date,
                totalIncome: group.totalIncome,
                totalExpenses: group.totalExpenses,
              ),
            ),
          );

          // Add transactions for this date
          for (int i = 0; i < group.transactions.length; i++) {
            final transaction = group.transactions[i];
            final transactionIndex = _findTransactionIndex(transaction);

            children.add(
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TransactionCard(
                  transaction: transaction,
                  currency: currency,
                  onEdit: () => _editTransaction(transaction, transactionIndex),
                  onDelete: () => _deleteTransaction(transactionIndex),
                ),
              ),
            );
          }

          return Column(children: children);
        },
        childCount: _displayedGroups.length,
      ),
    );
  }

  int _findTransactionIndex(Transaction transaction) {
    return _allTransactions.indexWhere((t) => t.id == transaction.id);
  }

  void _editTransaction(Transaction transaction, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionModal(
        transaction: transaction,
        onSave: (updatedTransaction) async {
          await HiveService.updateTransaction(index, updatedTransaction);
          refreshData();
          CustomSnackBar.show(context, 'Transaction updated successfully!',
              SnackBarType.success);
        },
      ),
    );
  }

  void _deleteTransaction(int index) {
    if (index == -1) return; // Transaction not found

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
              final transaction = _allTransactions[index];

              // Check if this is a people transaction (has _main suffix)
              if (transaction.id.endsWith('_main')) {
                // This is a people transaction, delete from people manager too
                await PeopleHiveService.deletePeopleTransactionByMainId(
                    transaction.id);
              }

              // Delete the main transaction
              await HiveService.deleteTransaction(index);
              Navigator.pop(context);
              refreshData();
              CustomSnackBar.show(context, 'Transaction deleted successfully!',
                  SnackBarType.info);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _navigateToSummary() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MonthlySummaryScreen()),
    );
  }
}
