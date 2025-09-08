import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/transaction.dart';
import 'models/user_settings.dart';
import 'models/people_transaction.dart';
import 'models/person_contact.dart';
import 'screens/welcome_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'themes/app_theme.dart';
import 'services/hive_service.dart';
import 'services/people_hive_service.dart';
import 'services/contact_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  
  // Register adapters
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(UserSettingsAdapter());
  Hive.registerAdapter(PeopleTransactionAdapter());
  Hive.registerAdapter(PersonContactAdapter());
  
  // Initialize Hive services
  await HiveService.init();
  await PeopleHiveService.init();
  await ContactService.init();
  
  runApp(MoneyManagerApp());
}

class MoneyManagerApp extends StatelessWidget {
  const MoneyManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: HiveService.userSettingsBox.listenable(),
      builder: (context, box, child) {
        final settings = HiveService.getUserSettings();
        
        return MaterialApp(
          title: 'Money Manager',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _getThemeMode(settings.theme),
          home: settings.name.isEmpty ? WelcomeScreen() : MainNavigationScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
  
  ThemeMode _getThemeMode(String theme) {
    switch (theme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}