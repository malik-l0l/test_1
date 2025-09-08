class AppConstants {
  // App Info
  static const String appName = 'Money Manager';
  static const String appVersion = '1.0.0';
  
  // Hive Box Names
  static const String transactionsBox = 'transactions';
  static const String userSettingsBox = 'userSettings';
  static const String balanceBox = 'balance';
  static const String peopleTransactionsBox = 'peopleTransactions';
  
  // Settings Keys
  static const String userSettingsKey = 'settings';
  static const String balanceKey = 'balance';
  
  // Currency Options
  static const List<String> currencies = ['₹', '\$'];
  
  // Theme Options
  static const List<String> themes = ['system', 'light', 'dark'];
  
  // Default Values
  static const String defaultCurrency = '₹';
  static const String defaultTheme = 'system';
  static const double defaultBalance = 0.0;
  
  // UI Constants
  static const double borderRadius = 16.0;
  static const double cardPadding = 20.0;
  static const double spacing = 16.0;
  static const double smallSpacing = 8.0;
  static const double largeSpacing = 32.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 300);
  static const Duration mediumAnimation = Duration(milliseconds: 500);
  static const Duration longAnimation = Duration(milliseconds: 1000);
  
  // Transaction Types
  static const String income = 'income';
  static const String expense = 'expense';
  
  // Date Formats
  static const String dateFormat = 'dd MMM yyyy';
  static const String timeFormat = 'hh:mm a';
  static const String monthYearFormat = 'MMMM yyyy';
  static const String shortDateFormat = 'dd MMM';
  
  // Validation
  static const int maxReasonLength = 100;
  static const int maxNameLength = 50;
  static const double maxAmount = 999999999.99;
  static const double minAmount = 0.01;
  
  // Error Messages
  static const String emptyNameError = 'Please enter your name';
  static const String emptyReasonError = 'Please enter a reason';
  static const String invalidAmountError = 'Please enter a valid amount';
  static const String amountTooLargeError = 'Amount is too large';
  static const String amountTooSmallError = 'Amount must be greater than 0';
  
  // Success Messages
  static const String settingsSavedMessage = 'Settings saved successfully!';
  static const String transactionAddedMessage = 'Transaction added successfully!';
  static const String transactionUpdatedMessage = 'Transaction updated successfully!';
  static const String transactionDeletedMessage = 'Transaction deleted successfully!';
}