import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/transaction.dart';
import 'models/user_settings.dart';
import 'models/people_transaction.dart';
import 'models/person_contact.dart';
import 'models/app_state.dart';
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
  
  runApp(
    ChangeNotifierProvider(
      create: (context) {
        final appState = AppState();
        appState.loadFromHive();
        return appState;
      },
      child: MoneyManagerApp(),
    ),
  );
}

class MoneyManagerApp extends StatelessWidget {
  const MoneyManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final settings = appState.userSettings;

        return MaterialApp(
          title: 'Money Manager',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _getThemeMode(settings.theme),
          home: settings.name.isEmpty ? const WelcomeScreen() : const MainNavigationScreen(),
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