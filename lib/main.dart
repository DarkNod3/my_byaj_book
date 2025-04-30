import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'constants/app_theme.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'providers/loan_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/bill_note_provider.dart';
import 'providers/nav_preferences_provider.dart';
import 'screens/bill_diary/bill_diary_screen.dart';
import 'screens/settings/nav_settings_screen.dart';
import 'utils/string_extensions.dart';
import 'package:my_byaj_book/providers/transaction_provider.dart';
import 'package:my_byaj_book/screens/tea_diary/tea_diary_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';

// Initialize notifications plugin globally
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize time zones for scheduling notifications
  tz.initializeTimeZones();
  
  // Configure notification settings
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();
  
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  
  // Initialize notifications with simpler configuration
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // Handle notification taps here
      print('Notification clicked: ${response.payload}');
    },
  );
  
  // Request notification permissions if needed
  // On Android 13+ users will see a permission dialog first time
  // On iOS permission is requested during notification setup
  
  // Set preferred orientations for better performance
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Optimize frame rasterization
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top],
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => NavPreferencesProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => LoanProvider()),
        ChangeNotifierProvider(create: (_) => BillNoteProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'My Byaj Book',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.themeData,
            home: const SplashScreen(),
            routes: {
              BillDiaryScreen.routeName: (ctx) => const BillDiaryScreen(),
              NavSettingsScreen.routeName: (ctx) => const NavSettingsScreen(),
              TeaDiaryScreen.routeName: (ctx) => const TeaDiaryScreen(),
            },
          );
        },
      ),
    );
  }
}
