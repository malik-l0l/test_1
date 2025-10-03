import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/hive_service.dart';
import '../models/transaction.dart';
import '../models/daily_transaction_group.dart';
import '../models/app_state.dart';
import '../widgets/transaction_card.dart';
import '../widgets/date_header.dart';
import '../utils/date_formatter.dart';

class MonthlySummaryScreen extends StatefulWidget {
  const MonthlySummaryScreen({Key? key}) : super(key: key);

  @override
  State<MonthlySummaryScreen> createState() => _MonthlySummaryScreenState();
}

class _MonthlySummaryScreenState extends State<MonthlySummaryScreen> {
  DateTime _selectedMonth = DateTime.now();
  List<DailyTransactionGroup> _displayedGroups = [];
  List<DailyTransactionGroup> _allGroups = [];
  int _currentPage = 0;
  bool _isLoadingMore = false;
  static const int _itemsPerPage = 10;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadMonthlyData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreGroups();
    }
  }

  void _loadMonthlyData() {
    final appState = Provider.of<AppState>(context, listen: false);
    final monthlyTransactions = appState.getMonthlyTransactions(_selectedMonth);
    setState(() {
      _allGroups =
          DailyTransactionGroup.groupTransactionsByDate(monthlyTransactions);
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
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final settings = appState.userSettings;
        final totalIncome = appState.getMonthlyIncome(_selectedMonth);
        final totalExpenses = appState.getMonthlyExpenses(_selectedMonth);
        final monthlyTransactions = appState.getMonthlyTransactions(_selectedMonth);

        return _buildScaffold(settings, totalIncome, totalExpenses, monthlyTransactions);
      },
    );
  }

  Widget _buildScaffold(
    settings,
    double totalIncome,
    double totalExpenses,
    List<Transaction> monthlyTransactions,
  ) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Summary'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _selectMonth,
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthSelector(),
            const SizedBox(height: 24),
            _buildSummaryCards(totalIncome, totalExpenses, settings.currency),
            const SizedBox(height: 32),
            _buildGroupedTransactionsList(settings.currency),
            if (_isLoadingMore)
              Container(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _selectedMonth =
                    DateTime(_selectedMonth.year, _selectedMonth.month - 1);
              });
            },
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            DateFormatter.formatMonthYear(_selectedMonth),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: _isNextMonthDisabled()
                ? null
                : () {
                    setState(() {
                      _selectedMonth = DateTime(
                          _selectedMonth.year, _selectedMonth.month + 1);
                    });
                  },
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  bool _isNextMonthDisabled() {
    final now = DateTime.now();
    final nextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    return nextMonth.isAfter(DateTime(now.year, now.month));
  }

  int _findTransactionIndex(Transaction transaction) {
    final allTransactions = HiveService.getMonthlyTransactions(_selectedMonth);
    return allTransactions.indexWhere((t) => t.id == transaction.id);
  }

  Widget _buildSummaryCards(double income, double expenses, String currency) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Income',
            income,
            currency,
            Colors.green,
            Icons.trending_up,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Total Expenses',
            expenses,
            currency,
            Colors.red,
            Icons.trending_down,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, double amount, String currency,
      Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$currency${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedTransactionsList(String currency) {
    final allTransactions = HiveService.getMonthlyTransactions(_selectedMonth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transactions (${allTransactions.length})',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (allTransactions.isEmpty)
          SizedBox(
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
                  const SizedBox(height: 16),
                  Text(
                    'No transactions this month',
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
          Column(
            children: _displayedGroups.map((group) {
              return Column(
                children: [
                  // Date header
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 0),
                    child: DateHeader(
                      date: group.date,
                      totalIncome: group.totalIncome,
                      totalExpenses: group.totalExpenses,
                    ),
                  ),
                  // Transactions for this date
                  ...group.transactions.map((transaction) {
                    final transactionIndex = _findTransactionIndex(transaction);
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                      child: TransactionCard(
                        transaction: transaction,
                        currency: HiveService.getUserSettings().currency,
                        onEdit: null, // Read-only mode
                        onDelete: null, // Read-only mode
                      ),
                    );
                  }).toList(),
                ],
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildOldTransactionsList(
      List<Transaction> transactions, String currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transactions (${transactions.length})',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (transactions.isEmpty)
          SizedBox(
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
                  const SizedBox(height: 16),
                  Text(
                    'No transactions this month',
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
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return TransactionCard(
                transaction: transaction,
                currency: currency,
                onEdit: null, // Read-only mode
                onDelete: null, // Read-only mode
              );
            },
          ),
      ],
    );
  }

  void _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).primaryColor,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedMonth) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
        _loadMonthlyData(); // Reload data for new month
      });
    }
  }
}
