import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:home_widget/home_widget.dart';

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
import 'services/widget_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(UserSettingsAdapter());
  Hive.registerAdapter(PeopleTransactionAdapter());
  Hive.registerAdapter(PersonContactAdapter());

  // Initialize services
  await HiveService.init();
  await PeopleHiveService.init();
  await ContactService.init();

  // ✅ Only initialize HomeWidget on Android and iOS (not Web)
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      await HomeWidget.setAppGroupId('com.example.mm');
      await WidgetService.updateWidget();
    } catch (e) {
      print('HomeWidget initialization failed: $e');
    }
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) {
        final appState = AppState();
        appState.loadFromHive();
        return appState;
      },
      child: const MoneyManagerApp(),
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
          home: settings.name.isEmpty
              ? const WelcomeScreen()
              : const MainNavigationScreen(),
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
