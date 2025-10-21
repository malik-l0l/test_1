import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/hive_service.dart';
import '../services/people_hive_service.dart';
import '../services/greeting_service.dart';
import '../models/transaction.dart';
import '../models/daily_transaction_group.dart';
import '../models/app_state.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_card.dart';
import '../widgets/date_header.dart';
import '../widgets/custom_snackbar.dart';
import 'monthly_summary_screen.dart';
import '../widgets/add_transaction_modal.dart';
import '../widgets/add_people_transaction_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  List<DailyTransactionGroup> _displayedGroups = [];
  late ScrollController _scrollController;
  bool _isLoadingMore = false;
  int _currentPage = 0;
  static const int _itemsPerPage = 10;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    final appState = Provider.of<AppState>(context, listen: false);
    final allGroups = appState.getGroupedTransactions();

    setState(() {
      _currentPage = 0;
      _displayedGroups = [];
      _loadMoreGroupsFromList(allGroups);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreGroups();
    }
  }

  void refreshData() {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.loadFromHive();
    _loadInitialData();
  }

  void _loadMoreGroups() {
    if (_isLoadingMore) return;

    final appState = Provider.of<AppState>(context, listen: false);
    final allGroups = appState.getGroupedTransactions();

    if (_displayedGroups.length >= allGroups.length) return;

    setState(() {
      _isLoadingMore = true;
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _loadMoreGroupsFromList(allGroups);
          _isLoadingMore = false;
        });
      }
    });
  }

  void _loadMoreGroupsFromList(List<DailyTransactionGroup> allGroups) {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, allGroups.length);

    if (startIndex < allGroups.length) {
      _displayedGroups.addAll(allGroups.sublist(startIndex, endIndex));
      _currentPage++;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<AppState>(
      builder: (context, appState, child) {
        final settings = appState.userSettings;
        final balance = appState.balance;
        final allTransactions = appState.transactions;

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
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              BalanceCard(
                                balance: balance,
                                currency: settings.currency,
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                      _buildGroupedTransactionsList(settings.currency, allTransactions),
                      if (_isLoadingMore)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 120),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernAppBar(settings) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      settings.name,
                      style: const TextStyle(
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
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: const EdgeInsets.all(10),
              constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
              onPressed: _navigateToSummary,
              icon: const Icon(
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

  Widget _buildGroupedTransactionsList(String currency, List<Transaction> allTransactions) {
    if (allTransactions.isEmpty) {
      return SliverToBoxAdapter(
        child: SizedBox(
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
                const SizedBox(height: 16),
                Text(
                  'No transactions yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
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

          return _TransactionGroupWidget(
            key: ValueKey('group_${group.date.millisecondsSinceEpoch}'),
            group: group,
            currency: currency,
            onEdit: _editTransaction,
            onDelete: _deleteTransaction,
          );
        },
        childCount: _displayedGroups.length,
      ),
    );
  }

  int _findTransactionIndex(Transaction transaction) {
    final appState = Provider.of<AppState>(context, listen: false);
    return appState.transactions.indexWhere((t) => t.id == transaction.id);
  }

  void _editTransaction(Transaction transaction, int index) {
    if (transaction.id.endsWith('_main')) {
      final peopleTransactionId = transaction.id.replaceAll('_main', '');
      try {
        final peopleTransaction = PeopleHiveService.getAllPeopleTransactions()
            .firstWhere((t) => t.id == peopleTransactionId);

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AddPeopleTransactionModal(
            transaction: peopleTransaction,
            onSave: (updatedTransaction) async {
              await PeopleHiveService.updatePeopleTransaction(
                peopleTransactionId,
                updatedTransaction,
              );
              final appState = Provider.of<AppState>(context, listen: false);
              appState.loadFromHive();
              _loadInitialData();
              if (mounted) {
                CustomSnackBar.show(
                  context,
                  'People transaction updated successfully!',
                  SnackBarType.success,
                );
              }
            },
          ),
        );
      } catch (e) {
        if (mounted) {
          CustomSnackBar.show(
            context,
            'Error: Could not find associated people transaction',
            SnackBarType.error,
          );
        }
      }
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => AddTransactionModal(
          transaction: transaction,
          onSave: (updatedTransaction) async {
            await HiveService.updateTransaction(index, updatedTransaction);
            final appState = Provider.of<AppState>(context, listen: false);
            appState.loadFromHive();
            _loadInitialData();
            if (mounted) {
              CustomSnackBar.show(
                context,
                'Transaction updated successfully!',
                SnackBarType.success,
              );
            }
          },
        ),
      );
    }
  }

  void _deleteTransaction(int index) {
    if (index == -1) return;

    final appState = Provider.of<AppState>(context, listen: false);
    final transaction = appState.transactions[index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (transaction.id.endsWith('_main')) {
                await PeopleHiveService.deletePeopleTransactionByMainId(transaction.id);
              }

              await HiveService.deleteTransaction(index);
              appState.loadFromHive();
              Navigator.pop(context);
              _loadInitialData();
              if (mounted) {
                CustomSnackBar.show(
                  context,
                  'Transaction deleted successfully!',
                  SnackBarType.info,
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _navigateToSummary() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MonthlySummaryScreen()),
    );
  }
}

class _TransactionGroupWidget extends StatelessWidget {
  final DailyTransactionGroup group;
  final String currency;
  final Function(Transaction, int) onEdit;
  final Function(int) onDelete;

  const _TransactionGroupWidget({
    Key? key,
    required this.group,
    required this.currency,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey('group_column_${group.date.millisecondsSinceEpoch}'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DateHeader(
            date: group.date,
            totalIncome: group.totalIncome,
            totalExpenses: group.totalExpenses,
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: group.transactions.length,
          itemBuilder: (context, i) {
            final transaction = group.transactions[i];

            return Consumer<AppState>(
              builder: (context, appState, child) {
                final transactionIndex = appState.transactions.indexWhere((t) => t.id == transaction.id);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TransactionCard(
                    key: ValueKey(transaction.id),
                    transaction: transaction,
                    currency: currency,
                    onEdit: () => onEdit(transaction, transactionIndex),
                    onDelete: () => onDelete(transactionIndex),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
