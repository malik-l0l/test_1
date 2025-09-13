import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/hive_service.dart';
import '../models/transaction.dart';
import '../utils/date_formatter.dart';

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

    // Get all transactions for this month
    final monthlyTransactions = HiveService.getMonthlyTransactions(now);

    // Calculate daily balances
    double runningBalance = widget.balance;

    // Work backwards from today to calculate historical balances
    for (int day = now.day; day >= 1; day--) {
      final currentDate = DateTime(now.year, now.month, day);

      // If this is today, use current balance
      if (day == now.day) {
        _dailyBalances.insert(0, DailyBalance(currentDate, runningBalance));
      } else {
        // Subtract transactions that happened after this day
        final futureTransactions = monthlyTransactions
            .where((t) => t.date.isAfter(currentDate))
            .toList();

        double historicalBalance = widget.balance;
        for (final transaction in futureTransactions) {
          historicalBalance -= transaction.amount;
        }

        _dailyBalances.insert(0, DailyBalance(currentDate, historicalBalance));
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleChart,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
        width: double.infinity,
        height: _showChart ? 240 : 120,
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
              'No data for this month',
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
        // Chart Header
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
                  DateFormatter.formatMonthYear(DateTime.now()),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_dailyBalances.length} days',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 20),

        // Chart - Increased height to prevent overflow
        Expanded(
          child: Container(
            height: 140, // Fixed height to prevent overflow
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
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 25,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            value.toInt().toString(),
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
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: (_maxY - _minY) / 3,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            '${widget.currency}${_formatChartValue(value)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 1,
                maxX: DateTime.now().day.toDouble(),
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
                        Colors.black.withOpacity(0.8),
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        final day = barSpot.x.toInt();
                        final balance = barSpot.y;
                        final date = DateTime(
                            DateTime.now().year, DateTime.now().month, day);

                        return LineTooltipItem(
                          '${DateFormatter.formatShortDate(date)}\n${widget.currency}${balance.toStringAsFixed(2)}',
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                  touchCallback:
                      (FlTouchEvent event, LineTouchResponse? touchResponse) {
                    // Add haptic feedback on touch
                    if (event is FlTapUpEvent) {
                      // HapticFeedback.lightImpact();
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

  String _formatChartValue(double value) {
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }
}

class DailyBalance {
  final DateTime date;
  final double balance;

  DailyBalance(this.date, this.balance);
}
