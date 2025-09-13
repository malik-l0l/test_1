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

  @override
  void initState() {
    super.initState();

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
    final now = DateTime.now();
    _dailyBalances = [];
    _chartData = [];

    switch (_selectedPeriod) {
      case TimePeriod.day:
        _generateDayData(now);
        break;
      case TimePeriod.week:
        _generateWeekData(now);
        break;
      case TimePeriod.month:
        _generateMonthData(now);
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

  void _generateDayData(DateTime now) {
    // Get today's transactions
    final todayTransactions = HiveService.getMonthlyTransactions(now)
        .where((t) =>
            t.date.year == now.year &&
            t.date.month == now.month &&
            t.date.day == now.day)
        .toList();

    // Sort transactions by time
    todayTransactions.sort((a, b) => a.date.compareTo(b.date));

    double runningBalance = widget.balance;

    // Work backwards to get starting balance
    for (final transaction in todayTransactions.reversed) {
      runningBalance -= transaction.amount;
    }

    // Create hourly data points
    for (int hour = 0; hour <= 23; hour++) {
      final hourTransactions =
          todayTransactions.where((t) => t.date.hour <= hour).toList();

      double hourBalance = runningBalance;
      double hourCredit = 0;
      double hourExpense = 0;

      for (final transaction in hourTransactions) {
        hourBalance += transaction.amount;
        if (transaction.amount > 0) {
          hourCredit += transaction.amount;
        } else {
          hourExpense += transaction.amount.abs();
        }
      }

      final hourDate = DateTime(now.year, now.month, now.day, hour);
      _dailyBalances
          .add(DailyBalance(hourDate, hourBalance, hourCredit, hourExpense));
      _chartData.add(FlSpot(hour.toDouble(), hourBalance));
    }
  }

  void _generateWeekData(DateTime now) {
    // Get start of current week (Sunday)
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));

    for (int i = 0; i < 7; i++) {
      final currentDate = startOfWeek.add(Duration(days: i));

      // Get transactions for this specific day
      final dayTransactions = HiveService.getMonthlyTransactions(currentDate)
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

      // Calculate balance for this day
      double dayBalance = widget.balance;

      // Subtract all transactions that happened after this day
      final allTransactions = HiveService.getMonthlyTransactions(now);
      for (final transaction in allTransactions) {
        if (transaction.date.isAfter(currentDate.add(Duration(days: 1)))) {
          dayBalance -= transaction.amount;
        }
      }

      _dailyBalances.add(
          DailyBalance(currentDate, dayBalance, dailyCredit, dailyExpense));
      _chartData.add(FlSpot(i.toDouble(), dayBalance));
    }
  }

  void _generateMonthData(DateTime now) {
    // Get all transactions for this month
    final monthlyTransactions = HiveService.getMonthlyTransactions(now);

    // Calculate daily balances, credits, and expenses
    double runningBalance = widget.balance;

    // Work backwards from today to calculate historical balances
    for (int day = now.day; day >= 1; day--) {
      final currentDate = DateTime(now.year, now.month, day);

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

      // If this is today, use current balance
      if (day == now.day) {
        _dailyBalances.insert(
            0,
            DailyBalance(
                currentDate, runningBalance, dailyCredit, dailyExpense));
      } else {
        // Subtract transactions that happened after this day
        final futureTransactions = monthlyTransactions
            .where((t) => t.date.isAfter(currentDate))
            .toList();

        double historicalBalance = widget.balance;
        for (final transaction in futureTransactions) {
          historicalBalance -= transaction.amount;
        }

        _dailyBalances.insert(
            0,
            DailyBalance(
                currentDate, historicalBalance, dailyCredit, dailyExpense));
        runningBalance = historicalBalance;
      }
    }

    // Convert to chart data
    for (int i = 0; i < _dailyBalances.length; i++) {
      _chartData.add(FlSpot(
        _dailyBalances[i].date.day.toDouble(),
        _dailyBalances[i].balance,
      ));
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
    });
    _generateChartData();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleChart,
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
        return '${date.hour.toString().padLeft(2, '0')}:00';
      case TimePeriod.week:
        return DateFormatter.formatShortDate(date);
      case TimePeriod.month:
        return DateFormatter.formatShortDate(date);
    }
  }

  DailyBalance _getDailyBalanceForSpot(LineBarSpot barSpot) {
    switch (_selectedPeriod) {
      case TimePeriod.day:
        final hour = barSpot.x.toInt();
        return _dailyBalances.firstWhere(
          (db) => db.date.hour == hour,
          orElse: () => DailyBalance(DateTime.now(), barSpot.y, 0, 0),
        );
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
        return DateFormatter.formatShortDate(DateTime.now());
      case TimePeriod.week:
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
        final endOfWeek = startOfWeek.add(Duration(days: 6));
        return '${DateFormatter.formatShortDate(startOfWeek)} - ${DateFormatter.formatShortDate(endOfWeek)}';
      case TimePeriod.month:
        return DateFormatter.formatMonthYear(DateTime.now());
    }
  }

  double _getBottomInterval() {
    switch (_selectedPeriod) {
      case TimePeriod.day:
        return 4; // Every 4 hours
      case TimePeriod.week:
        return 1; // Every day
      case TimePeriod.month:
        return 5; // Every 5 days
    }
  }

  String _getBottomLabel(double value) {
    switch (_selectedPeriod) {
      case TimePeriod.day:
        return '${value.toInt()}h';
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
        return DateTime.now().day.toDouble();
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
