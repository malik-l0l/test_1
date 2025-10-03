import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import 'people_manager_screen.dart';
import 'settings_screen.dart';
import '../widgets/add_transaction_modal.dart';
import '../widgets/add_people_transaction_modal.dart';
import '../services/hive_service.dart';
import '../services/people_hive_service.dart';
import '../models/app_state.dart';
import '../widgets/custom_snackbar.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _fabAnimationController;
  late AnimationController _fabMorphController;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _fabRotationAnimation;
  late Animation<double> _morphAnimation;
  late Animation<Offset> _positionAnimation;

  // Keys for accessing child screen methods
  final GlobalKey<HomeScreenState> _homeScreenKey =
      GlobalKey<HomeScreenState>();
  final GlobalKey<PeopleManagerScreenState> _peopleScreenKey =
      GlobalKey<PeopleManagerScreenState>();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // FAB animation controller for show/hide
    _fabAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    // FAB morph animation controller for shape and position changes
    _fabMorphController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));

    _fabRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    ));

    _morphAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabMorphController,
      curve: Curves.easeInOutCubic,
    ));

    _positionAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fabMorphController,
      curve: Curves.easeInOutCubic,
    ));

    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
    _fabMorphController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    final previousIndex = _currentIndex;

    setState(() {
      _currentIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );

    // Haptic feedback for better UX
    HapticFeedback.lightImpact();

    // Handle FAB animations based on tab changes
    _handleFABTransition(previousIndex, index);
  }

  void _handleFABTransition(int fromIndex, int toIndex) {
    // Show FABs on Home (0) and People (1) tabs, hide on Settings (2)
    if ((fromIndex == 2 && (toIndex == 0 || toIndex == 1)) ||
        (fromIndex == -1 && (toIndex == 0 || toIndex == 1))) {
      // Show FABs
      _fabAnimationController.forward();
    } else if ((fromIndex == 0 || fromIndex == 1) && toIndex == 2) {
      // Hide FABs
      _fabAnimationController.reverse();
    }

    // Handle morphing animation between Home and People tabs
    if ((fromIndex == 0 && toIndex == 1) || (fromIndex == 1 && toIndex == 0)) {
      _triggerMorphAnimation();
    }
  }

  void _triggerMorphAnimation() {
    // Add haptic feedback for the morph animation
    HapticFeedback.selectionClick();

    _fabMorphController.forward().then((_) {
      _fabMorphController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          final previousIndex = _currentIndex;
          setState(() {
            _currentIndex = index;
          });

          _handleFABTransition(previousIndex, index);
        },
        children: [
          HomeScreen(key: _homeScreenKey),
          PeopleManagerScreen(key: _peopleScreenKey),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildModernBottomNavBar(),
      floatingActionButton: _buildAnimatedFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildModernBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 72, // Optimized height for better proportions
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Home Tab - 1/4 of available space
              Expanded(
                flex: 2,
                child:
                    _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
              ),

              // People Tab - 1/4 of available space
              Expanded(
                flex: 2,
                child: _buildNavItem(
                    1, Icons.people_outline, Icons.people, 'People'),
              ),

              // FAB Area - positioned between People and Settings
              Expanded(
                flex: 2,
                child:
                    Container(), // Empty space for FABs to dock in center of this area
              ),

              // Settings Tab - 1/4 of available space
              Expanded(
                flex: 2,
                child: _buildNavItem(
                    2, Icons.settings_outlined, Icons.settings, 'Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData outlinedIcon, IconData filledIcon, String label) {
    final isSelected = _currentIndex == index;
    final color =
        isSelected ? Theme.of(context).primaryColor : Colors.grey[600];

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: Container(
        // Standardized minimum touch target (44px)
        constraints: BoxConstraints(minHeight: 44, minWidth: 44),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          // Removed the background color decoration for selected tabs
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? filledIcon : outlinedIcon,
                  key: ValueKey(isSelected),
                  color: color,
                  size: 22, // Standardized icon size
                ),
              ),
              SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: isSelected ? 11 : 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                  letterSpacing: 0.2,
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedFAB() {
    // Only show FABs on Home (0) and People (1) tabs
    if (_currentIndex == 2) {
      return SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _fabAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabScaleAnimation.value,
          child: Transform.rotate(
            angle: _fabRotationAnimation.value * 0.1,
            child: Container(
              // Shift FABs slightly to the right
              margin: EdgeInsets.only(left: 110),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: _morphAnimation,
                builder: (context, child) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMorphingFAB(
                        isLeft: true,
                        onPressed: _currentIndex == 0
                            ? () => _showAddTransactionModal(
                                false) // Changed: Now shows regular transaction modal
                            : _showAddPeopleTransactionModal, // Changed: Now shows people transaction modal
                        heroTag: "left_fab",
                        backgroundColor: _currentIndex == 0
                            ? Theme.of(context)
                                .primaryColor // Changed: Now uses primary color on Home
                            : Colors
                                .purple, // Changed: Now uses purple on People
                        icon: _currentIndex == 0
                            ? Icons.add
                            : Icons
                                .person_add, // Changed: Now shows + on Home, person+ on People
                        iconSize: _currentIndex == 0
                            ? 28
                            : 20, // Changed: Larger on Home, smaller on People
                        isMini:
                            _currentIndex == 1, // Changed: Mini on People tab
                      ),
                      SizedBox(width: 12), // Consistent spacing between FABs
                      _buildMorphingFAB(
                        isLeft: false,
                        onPressed: _currentIndex == 0
                            ? _showAddPeopleTransactionModal // Changed: Now shows people transaction modal
                            : () => _showAddTransactionModal(
                                false), // Changed: Now shows regular transaction modal
                        heroTag: "right_fab",
                        backgroundColor: _currentIndex == 0
                            ? Colors.purple // Changed: Now uses purple on Home
                            : Theme.of(context)
                                .primaryColor, // Changed: Now uses primary color on People
                        icon: _currentIndex == 0
                            ? Icons.person_add
                            : Icons
                                .add, // Changed: Now shows person+ on Home, + on People
                        iconSize: _currentIndex == 0
                            ? 20
                            : 28, // Changed: Smaller on Home, larger on People
                        isMini: _currentIndex == 0, // Changed: Mini on Home tab
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMorphingFAB({
    required bool isLeft,
    required VoidCallback onPressed,
    required String heroTag,
    required Color backgroundColor,
    required IconData icon,
    required double iconSize,
    required bool isMini,
  }) {
    // Determine which FAB should be rectangular based on the icon/function
    bool isRectangular;
    double fabSize;

    if (_currentIndex == 0) {
      // Home tab: '+' FAB (left) is rectangular, 'people+' FAB (right) is circular
      isRectangular = isLeft; // Left FAB is rectangular
      fabSize = isLeft ? 56.0 : 40.0; // Left is regular, right is mini
    } else {
      // People tab: '+' FAB (left) is rectangular, 'people+' FAB (right) is circular
      isRectangular = isLeft; // Left FAB is rectangular
      fabSize = isLeft ? 56.0 : 40.0; // Left is regular, right is mini
    }

    double borderRadiusValue = isRectangular ? 16.0 : 20.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadiusValue),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        width: fabSize,
        height: fabSize,
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadiusValue),
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadiusValue),
            onTap: onPressed,
            onLongPress: (heroTag == "left_fab" &&
                    _currentIndex ==
                        0) // Changed: Now left_fab has long press on Home
                ? () => _showAddTransactionModal(true)
                : null,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadiusValue),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddTransactionModal([bool? forceIncome]) {
    // Show haptic feedback for long press
    if (forceIncome == true) {
      HapticFeedback.mediumImpact();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionModal(
        forceIncome: forceIncome,
        onSave: (transaction) async {
          await HiveService.addTransaction(transaction);
          final appState = Provider.of<AppState>(context, listen: false);
          appState.loadFromHive();
          _homeScreenKey.currentState?.refreshData();
          if (mounted) {
            CustomSnackBar.show(
                context, 'Transaction added successfully!', SnackBarType.success);
          }
        },
      ),
    );
  }

  void _showAddPeopleTransactionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPeopleTransactionModal(
        onSave: (transaction) async {
          await PeopleHiveService.addPeopleTransaction(transaction);
          final appState = Provider.of<AppState>(context, listen: false);
          appState.loadFromHive();
          _homeScreenKey.currentState?.refreshData();
          _peopleScreenKey.currentState?.refreshData();
          if (mounted) {
            CustomSnackBar.show(context, 'People transaction added successfully!',
                SnackBarType.success);
          }
        },
      ),
    );
  }
}
