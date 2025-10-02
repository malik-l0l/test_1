import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/hive_service.dart';
import '../models/transaction.dart';
import '../utils/date_formatter.dart';

enum TimePeriod { day, week, month }

class BalanceCard extends StatefulWidget {
  final double balance;
  final String currency;

  const BalanceCard({
    Key? key,
    required this.balance,
    required this.currency,
  }) : super(key: key);

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard>
    with TickerProviderStateMixin {
  bool _showChart = false;
  TimePeriod _selectedPeriod = TimePeriod.month;
  late AnimationController _chartAnimationController;
  late AnimationController _balanceAnimationController;
  late Animation<double> _chartSlideAnimation;
  late Animation<double> _chartFadeAnimation;
  late Animation<double> _balanceScaleAnimation;
  late Animation<double> _balanceFadeAnimation;

  List<FlSpot> _chartData = [];
  List<DailyBalance> _dailyBalances = [];
  double _minY = 0;
  double _maxY = 0;

  late DateTime _currentDate;
  late DateTime _currentWeekStart;
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();

    // Initialize dates
    final now = DateTime.now();
    _currentDate = now;
    _currentMonth = DateTime(now.year, now.month);
    _currentWeekStart = now.subtract(Duration(days: now.weekday % 7));

    _chartAnimationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _balanceAnimationController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );

    _chartSlideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _chartAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _chartFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _chartAnimationController,
      curve: Curves.easeOut,
    ));

    _balanceScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _balanceAnimationController,
      curve: Curves.easeInOut,
    ));

    _balanceFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.3,
    ).animate(CurvedAnimation(
      parent: _balanceAnimationController,
      curve: Curves.easeInOut,
    ));

    _generateChartData();
  }

  @override
  void didUpdateWidget(BalanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Regenerate chart data when balance changes (real-time updates)
    if (oldWidget.balance != widget.balance) {
      _generateChartData();
    }
  }

  @override
  void dispose() {
    _chartAnimationController.dispose();
    _balanceAnimationController.dispose();
    super.dispose();
  }

  void _generateChartData() {
    _dailyBalances = [];
    _chartData = [];

    switch (_selectedPeriod) {
      case TimePeriod.day:
        _generateDayData(_currentDate);
        break;
      case TimePeriod.week:
        _generateWeekData(_currentWeekStart);
        break;
      case TimePeriod.month:
        _generateMonthData(_currentMonth);
        break;
    }

    // Calculate min/max for chart scaling
    if (_chartData.isNotEmpty) {
      final balances = _chartData.map((spot) => spot.y).toList();
      _minY = balances.reduce((a, b) => a < b ? a : b);
      _maxY = balances.reduce((a, b) => a > b ? a : b);

      // Add padding to min/max
      final range = _maxY - _minY;
      final padding = range * 0.1;
      _minY -= padding;
      _maxY += padding;

      // Ensure we have some range even if all values are the same
      if (range == 0) {
        _minY -= 100;
        _maxY += 100;
      }
    }
  }

  void _generateDayData(DateTime targetDate) {
    // Get today's transactions
    final todayTransactions = HiveService.getMonthlyTransactions(targetDate)
        .where((t) =>
            t.date.year == targetDate.year &&
            t.date.month == targetDate.month &&
            t.date.day == targetDate.day)
        .toList();

    // Sort transactions by time
    todayTransactions.sort((a, b) => a.date.compareTo(b.date));

    if (todayTransactions.isEmpty) {
      return;
    }

    double runningBalance = widget.balance;

    // Work backwards to get starting balance (balance at start of day)
    for (final transaction in todayTransactions.reversed) {
      runningBalance -= transaction.amount;
    }

    // Add starting point at beginning of day
    final startHour = 0;
    _dailyBalances.add(DailyBalance(
      DateTime(targetDate.year, targetDate.month, targetDate.day, startHour),
      runningBalance,
      0,
      0,
    ));
    _chartData.add(FlSpot(startHour.toDouble(), runningBalance));

    // Add data point for each transaction with accumulated values
    for (int i = 0; i < todayTransactions.length; i++) {
      final transaction = todayTransactions[i];
      runningBalance += transaction.amount;

      // Calculate accumulated credit/expense up to this transaction
      double accumulatedCredit = 0;
      double accumulatedExpense = 0;

      for (int j = 0; j <= i; j++) {
        if (todayTransactions[j].amount > 0) {
          accumulatedCredit += todayTransactions[j].amount;
        } else {
          accumulatedExpense += todayTransactions[j].amount.abs();
        }
      }

      final timeValue =
          transaction.date.hour + (transaction.date.minute / 60.0);

      _dailyBalances.add(DailyBalance(
        transaction.date,
        runningBalance,
        accumulatedCredit,
        accumulatedExpense,
      ));

      _chartData.add(FlSpot(timeValue, runningBalance));
    }

    // Add end point at end of day (current balance)
    final endHour = 23.99;
    _dailyBalances.add(DailyBalance(
      DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59),
      runningBalance,
      _dailyBalances.last.credit,
      _dailyBalances.last.expense,
    ));
    _chartData.add(FlSpot(endHour, runningBalance));
  }

  void _generateWeekData(DateTime weekStart) {
    final allTransactions = HiveService.getAllTransactions();

    for (int i = 0; i < 7; i++) {
      final currentDate = weekStart.add(Duration(days: i));

      // Get transactions for this specific day
      final dayTransactions = allTransactions
          .where((t) =>
              t.date.year == currentDate.year &&
              t.date.month == currentDate.month &&
              t.date.day == currentDate.day)
          .toList();

      // Calculate daily credit and expense
      double dailyCredit = 0;
      double dailyExpense = 0;

      for (final transaction in dayTransactions) {
        if (transaction.amount > 0) {
          dailyCredit += transaction.amount;
        } else {
          dailyExpense += transaction.amount.abs();
        }
      }

      // Calculate balance at the end of this day
      double dayBalance = widget.balance;

      // Subtract all transactions that happened after this day
      for (final transaction in allTransactions) {
        if (transaction.date.isAfter(DateTime(currentDate.year,
            currentDate.month, currentDate.day, 23, 59, 59))) {
          dayBalance -= transaction.amount;
        }
      }

      _dailyBalances.add(
          DailyBalance(currentDate, dayBalance, dailyCredit, dailyExpense));
      _chartData.add(FlSpot(i.toDouble(), dayBalance));
    }
  }

  void _generateMonthData(DateTime targetMonth) {
    final allTransactions = HiveService.getAllTransactions();

    // Get transactions for this month
    final monthlyTransactions = allTransactions
        .where((t) =>
            t.date.year == targetMonth.year &&
            t.date.month == targetMonth.month)
        .toList();

    final daysInMonth =
        DateTime(targetMonth.year, targetMonth.month + 1, 0).day;

    // Calculate daily balances
    for (int day = 1; day <= daysInMonth; day++) {
      final currentDate = DateTime(targetMonth.year, targetMonth.month, day);

      // Get transactions for this specific day
      final dayTransactions =
          monthlyTransactions.where((t) => t.date.day == day).toList();

      // Calculate daily credit and expense
      double dailyCredit = 0;
      double dailyExpense = 0;

      for (final transaction in dayTransactions) {
        if (transaction.amount > 0) {
          dailyCredit += transaction.amount;
        } else {
          dailyExpense += transaction.amount.abs();
        }
      }

      // Calculate balance at the end of this day
      double dayBalance = widget.balance;

      // Subtract all transactions that happened after this day
      for (final transaction in allTransactions) {
        if (transaction.date.isAfter(DateTime(currentDate.year,
            currentDate.month, currentDate.day, 23, 59, 59))) {
          dayBalance -= transaction.amount;
        }
      }

      _dailyBalances.add(
          DailyBalance(currentDate, dayBalance, dailyCredit, dailyExpense));
      _chartData.add(FlSpot(day.toDouble(), dayBalance));
    }
  }

  void _toggleChart() {
    setState(() {
      _showChart = !_showChart;
    });

    if (_showChart) {
      _balanceAnimationController.forward();
      _chartAnimationController.forward();
    } else {
      _balanceAnimationController.reverse();
      _chartAnimationController.reverse();
    }
  }

  void _onPeriodChanged(TimePeriod period) {
    setState(() {
      _selectedPeriod = period;

      // Reset to current date/week/month when changing period
      final now = DateTime.now();
      _currentDate = now;
      _currentMonth = DateTime(now.year, now.month);
      _currentWeekStart = now.subtract(Duration(days: now.weekday % 7));
    });
    _generateChartData();
  }

  void _onSwipe(DragEndDetails details) {
    if (!_showChart) return;

    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 500) return;

    setState(() {
      if (velocity > 0) {
        // Swipe right - go to previous period
        _navigateToPrevious();
      } else {
        // Swipe left - go to next period
        _navigateToNext();
      }
    });
  }

  void _navigateToPrevious() {
    switch (_selectedPeriod) {
      case TimePeriod.day:
        _currentDate = _currentDate.subtract(Duration(days: 1));
        break;
      case TimePeriod.week:
        _currentWeekStart = _currentWeekStart.subtract(Duration(days: 7));
        break;
      case TimePeriod.month:
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
        break;
    }
    _generateChartData();
  }

  void _navigateToNext() {
    switch (_selectedPeriod) {
      case TimePeriod.day:
        _currentDate = _currentDate.add(Duration(days: 1));
        break;
      case TimePeriod.week:
        _currentWeekStart = _currentWeekStart.add(Duration(days: 7));
        break;
      case TimePeriod.month:
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
        break;
    }
    _generateChartData();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleChart,
      onHorizontalDragEnd: _onSwipe,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
        width: double.infinity,
        height: _showChart ? 280 : 120,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            // Balance Display
            AnimatedBuilder(
              animation: _balanceAnimationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _balanceScaleAnimation.value,
                  child: Opacity(
                    opacity: _balanceFadeAnimation.value,
                    child: _buildBalanceDisplay(),
                  ),
                );
              },
            ),

            // Chart Display
            if (_showChart)
              AnimatedBuilder(
                animation: _chartAnimationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _chartSlideAnimation.value * 100),
                    child: Opacity(
                      opacity: _chartFadeAnimation.value,
                      child: _buildChartDisplay(),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceDisplay() {
    final balanceColor = _getBalanceColor();
    final statusText = _getBalanceStatus();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Balance Amount
        Text(
          '${widget.currency}${widget.balance.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),

        SizedBox(height: 8),

        // Balance Status Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: balanceColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: balanceColor.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildChartDisplay() {
    if (_chartData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              color: Colors.white.withOpacity(0.5),
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'No data for this ${_selectedPeriod.name}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Chart Header with Period Selection
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Balance Trend',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _getSubtitle(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                // Period Selection Buttons
                _buildPeriodButton('Day', TimePeriod.day),
                SizedBox(width: 8),
                _buildPeriodButton('Week', TimePeriod.week),
                SizedBox(width: 8),
                _buildPeriodButton('Month', TimePeriod.month),
              ],
            ),
          ],
        ),

        SizedBox(height: 20),

        // Chart
        Expanded(
          child: Container(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (_maxY - _minY) / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 25,
                      interval: _getBottomInterval(),
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            _getBottomLabel(value),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: _getMinX(),
                maxX: _getMaxX(),
                minY: _minY,
                maxY: _maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: _chartData,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: _getChartLineColor(),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: _getChartLineColor(),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _getChartLineColor().withOpacity(0.3),
                          _getChartLineColor().withOpacity(0.05),
                        ],
                      ),
                    ),
                    shadow: Shadow(
                      color: _getChartLineColor().withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) =>
                        Colors.black.withOpacity(0.9),
                    tooltipRoundedRadius: 12,
                    tooltipPadding: EdgeInsets.all(12),
                    tooltipMargin: 8,
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        final dailyBalance = _getDailyBalanceForSpot(barSpot);

                        return LineTooltipItem(
                          _buildTooltipText(dailyBalance),
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        );
                      }).toList();
                    },
                  ),
                  touchCallback:
                      (FlTouchEvent event, LineTouchResponse? touchResponse) {
                    if (event is FlTapUpEvent) {
                      // Add haptic feedback if needed
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodButton(String label, TimePeriod period) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () => _onPeriodChanged(period),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.2)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: Colors.white.withOpacity(0.3), width: 1)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  String _buildTooltipText(DailyBalance dailyBalance) {
    String dateText = _getTooltipDateText(dailyBalance.date);
    String balanceText =
        '${widget.currency}${dailyBalance.balance.toStringAsFixed(2)}';

    List<String> lines = [dateText, balanceText];

    if (dailyBalance.credit > 0) {
      lines.add('+${widget.currency}${dailyBalance.credit.toStringAsFixed(2)}');
    }

    if (dailyBalance.expense > 0) {
      lines
          .add('-${widget.currency}${dailyBalance.expense.toStringAsFixed(2)}');
    }

    return lines.join('\n');
  }

  String _getTooltipDateText(DateTime date) {
    switch (_selectedPeriod) {
      case TimePeriod.day:
        final hour = date.hour;
        final minute = date.minute;
        final period = hour >= 12 ? 'PM' : 'AM';
        final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        return '${hour12.toString()}:${minute.toString().padLeft(2, '0')} $period';
      case TimePeriod.week:
        return DateFormatter.formatShortDate(date);
      case TimePeriod.month:
        return DateFormatter.formatShortDate(date);
    }
  }

  DailyBalance _getDailyBalanceForSpot(LineBarSpot barSpot) {
    switch (_selectedPeriod) {
      case TimePeriod.day:
        // Find the closest data point to the tapped spot
        if (_dailyBalances.isEmpty) {
          return DailyBalance(DateTime.now(), barSpot.y, 0, 0);
        }

        DailyBalance? closest;
        double minDiff = double.infinity;

        for (final db in _dailyBalances) {
          final timeValue = db.date.hour + (db.date.minute / 60.0);
          final diff = (timeValue - barSpot.x).abs();
          if (diff < minDiff) {
            minDiff = diff;
            closest = db;
          }
        }

        return closest ?? DailyBalance(DateTime.now(), barSpot.y, 0, 0);
      case TimePeriod.week:
        final dayIndex = barSpot.x.toInt();
        if (dayIndex < _dailyBalances.length) {
          return _dailyBalances[dayIndex];
        }
        return DailyBalance(DateTime.now(), barSpot.y, 0, 0);
      case TimePeriod.month:
        final day = barSpot.x.toInt();
        return _dailyBalances.firstWhere(
          (db) => db.date.day == day,
          orElse: () => DailyBalance(DateTime.now(), barSpot.y, 0, 0),
        );
    }
  }

  String _getSubtitle() {
    switch (_selectedPeriod) {
      case TimePeriod.day:
        return DateFormatter.formatShortDate(_currentDate);
      case TimePeriod.week:
        final endOfWeek = _currentWeekStart.add(Duration(days: 6));
        return '${DateFormatter.formatShortDate(_currentWeekStart)} - ${DateFormatter.formatShortDate(endOfWeek)}';
      case TimePeriod.month:
        return DateFormatter.formatMonthYear(_currentMonth);
    }
  }

  double _getBottomInterval() {
    switch (_selectedPeriod) {
      case TimePeriod.day:
        return 6; // Every 6 hours (0, 6, 12, 18, 24)
      case TimePeriod.week:
        return 1; // Every day
      case TimePeriod.month:
        return 5; // Every 5 days
    }
  }

  String _getBottomLabel(double value) {
    switch (_selectedPeriod) {
      case TimePeriod.day:
        final hour = value.toInt();
        return hour < 24 ? '${hour}h' : '';
      case TimePeriod.week:
        final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        final index = value.toInt();
        return index < days.length ? days[index] : '';
      case TimePeriod.month:
        return value.toInt().toString();
    }
  }

  double _getMinX() {
    switch (_selectedPeriod) {
      case TimePeriod.day:
        return 0;
      case TimePeriod.week:
        return 0;
      case TimePeriod.month:
        return 1;
    }
  }

  double _getMaxX() {
    switch (_selectedPeriod) {
      case TimePeriod.day:
        return 23;
      case TimePeriod.week:
        return 6;
      case TimePeriod.month:
        return DateTime(_currentMonth.year, _currentMonth.month + 1, 0)
            .day
            .toDouble();
    }
  }

  Color _getBalanceColor() {
    if (widget.balance > 0) {
      return Colors.green;
    } else if (widget.balance < 0) {
      return Colors.red;
    } else {
      return Colors.amber;
    }
  }

  String _getBalanceStatus() {
    if (widget.balance > 0) {
      return 'Healthy Balance';
    } else if (widget.balance < 0) {
      return 'Negative Balance';
    } else {
      return 'Zero Balance';
    }
  }

  Color _getChartLineColor() {
    if (widget.balance > 0) {
      return Colors.green;
    } else if (widget.balance < 0) {
      return Colors.red;
    } else {
      return Colors.amber;
    }
  }
}

class DailyBalance {
  final DateTime date;
  final double balance;
  final double credit;
  final double expense;

  DailyBalance(this.date, this.balance, this.credit, this.expense);
}
