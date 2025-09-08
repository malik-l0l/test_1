import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ThemeService {
  static void setSystemUIOverlayStyle(bool isDark) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: isDark ? Colors.black : Colors.white,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  static Color getBalanceColor(double balance, bool isDark) {
    if (balance > 0) {
      return Colors.green;
    } else if (balance < 0) {
      return Colors.red;
    } else {
      return isDark ? Colors.grey[400]! : Colors.grey[600]!;
    }
  }

  static Color getTransactionColor(double amount, bool isDark) {
    if (amount > 0) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  static BoxShadow getCardShadow(bool isDark) {
    return BoxShadow(
      color: isDark 
          ? Colors.black.withOpacity(0.3)
          : Colors.black.withOpacity(0.05),
      blurRadius: isDark ? 15 : 10,
      offset: Offset(0, isDark ? 8 : 5),
    );
  }

  static LinearGradient getBackgroundGradient(BuildContext context, bool isDark) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? [
              Colors.grey[900]!,
              Colors.black,
            ]
          : [
              Theme.of(context).primaryColor.withOpacity(0.05),
              Colors.white,
            ],
    );
  }
}