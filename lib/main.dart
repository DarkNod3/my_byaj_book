import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'providers/loan_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/bill_note_provider.dart';
import 'providers/nav_preferences_provider.dart';
import 'providers/milk_diary/daily_entry_provider.dart';
import 'providers/milk_diary/milk_seller_provider.dart';
import 'providers/card_provider.dart';
import 'screens/bill_diary/bill_diary_screen.dart';
import 'screens/settings/nav_settings_screen.dart';
import 'screens/profile/profile_edit_screen.dart';
import 'package:my_byaj_book/providers/transaction_provider.dart';
import 'package:my_byaj_book/screens/tea_diary/tea_diary_screen.dart';
import 'package:my_byaj_book/screens/reminder/reminder_screen.dart';
import 'services/notification_service.dart';
import 'screens/loan/loan_details_screen.dart';
import 'screens/auth/login_screen.dart';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_byaj_book/providers/customer_provider.dart';
import 'package:my_byaj_book/services/database_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/about/special_thanks_screen.dart';
import 'providers/notification_provider.dart';
import 'screens/notification/notification_center_screen.dart';
import 'dart:async';

// Global notification service
final notificationService = NotificationService.instance;
// Global key for navigator to use in notification callbacks
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Background message handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
  
  // Process the message and potentially show a notification
  await notificationService.handleBackgroundMessage(message);
}

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with better error handling and timeout
  try {
    print('===== FIREBASE INIT =====');
    print('Starting Firebase initialization...');
    print('Platform: ${Platform.isAndroid ? 'Android' : Platform.isIOS ? 'iOS' : 'Other'}');
    
    // Add timeout to Firebase initialization
    bool firebaseInitialized = false;
    
    await Future.any([
      Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyAyzvrHynsUE5ziad_Se-1IQxyLXptKu3A',
          appId: '1:586549083907:android:1e440fdfd5589676aa7336',
          messagingSenderId: '586549083907',
          projectId: 'my-byaj-book',
          storageBucket: 'my-byaj-book.firebasestorage.app',
        ),
      ).then((_) {
        firebaseInitialized = true;
      }),
      // Timeout after 5 seconds to prevent hanging
      Future.delayed(const Duration(seconds: 5)).then((_) {
        if (!firebaseInitialized) {
          print('Firebase initialization timed out');
          throw Exception('Firebase initialization timed out');
        }
      }),
    ]);
    
    if (firebaseInitialized) {
      // Setup FCM background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // Initialize Firebase App Check - helps with security and app verification
      await FirebaseAppCheck.instance.activate(
        // Use debug provider for development, replace with proper provider for production
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );
      
      // Configure Firebase services with proper app information
      // This helps set the app name in verification messages
      try {
        await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
        // Set the app name for Firebase Auth services
        FirebaseAuth.instance.setLanguageCode('en'); // Set to your preferred language
        
        // Request notification permissions
        if (Platform.isIOS || Platform.isMacOS) {
          // Request permission for iOS and macOS
          await FirebaseMessaging.instance.requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );
        } else if (Platform.isAndroid) {
          // For Android, permissions are handled in the manifest
          // We request notification permission in newer Android versions
          await FirebaseMessaging.instance.requestPermission();
        }
        
        // Get FCM token for this device
        String? token = await FirebaseMessaging.instance.getToken();
        print('FCM Token: $token');
        
        // Configure FCM foreground notification presentation options
        await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        
        print('Firebase App Check and FCM configured successfully');
      } catch (appCheckError) {
        print('Firebase App Check error: $appCheckError');
      }
    }
    
    // Enable Firebase Crashlytics in release mode
    if (!kDebugMode && firebaseInitialized) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    }
    
    print('Firebase initialized successfully!');
  } catch (e, stackTrace) {
    // More detailed error handling
    print('===== FIREBASE INIT ERROR =====');
    print('Failed to initialize Firebase: $e');
    print('Stack trace: $stackTrace');
    print('App will continue in local-only mode without Firebase.');
    print('==============================');
  }
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  await DatabaseService.instance.init();
  
  // Initialize notification service
  await notificationService.init();
  
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
  
  // Run the app in release mode with error handling
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => NavPreferencesProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => TransactionProvider()),
        ChangeNotifierProvider(
          create: (_) => LoanProvider(),
          lazy: false, // Initialize immediately
        ),
        ChangeNotifierProvider(create: (_) => BillNoteProvider()),
        ChangeNotifierProvider(create: (_) => DailyEntryProvider()),
        ChangeNotifierProvider(create: (_) => MilkSellerProvider()),
        ChangeNotifierProvider(create: (_) => CardProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Timer? _notificationRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize notifications after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
      _setupFCMHandlers();
      _syncAllReminders();
    });
    
    // Set up a timer to refresh notifications periodically
    _notificationRefreshTimer = Timer.periodic(
      const Duration(minutes: 15), // Refresh every 15 minutes
      (_) => _refreshNotifications(),
    );
  }

  @override
  void dispose() {
    _notificationRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  // Initialize all notifications when app starts
  Future<void> _initializeNotifications() async {
    if (!mounted) return;
    
    try {
      final notificationProvider = Provider.of<NotificationProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      
      final loanProvider = Provider.of<LoanProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      
      final cardProvider = Provider.of<CardProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      
      final transactionProvider = Provider.of<TransactionProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      
      final billNoteProvider = Provider.of<BillNoteProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      
      // Generate notifications for all providers
      await notificationProvider.generateDueNotifications(
        loanProvider: loanProvider,
        cardProvider: cardProvider,
        transactionProvider: transactionProvider,
        billNoteProvider: billNoteProvider,
      );
      
      // Schedule notifications through the notification service
      await notificationService.scheduleLoanPaymentNotifications(loanProvider);
      await notificationService.scheduleCardDueNotifications(cardProvider);
      await notificationService.scheduleManualReminders(transactionProvider);
    } catch (e) {
      // Handle errors silently
    }
  }
  
  // Refresh notifications when timer fires or app resumes
  Future<void> _refreshNotifications() async {
    if (!mounted) return;
    
    try {
      final notificationProvider = Provider.of<NotificationProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      
      final loanProvider = Provider.of<LoanProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      
      final cardProvider = Provider.of<CardProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      
      final transactionProvider = Provider.of<TransactionProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      
      final billNoteProvider = Provider.of<BillNoteProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      
      // Generate notifications for any due payments
      await notificationProvider.generateDueNotifications(
        loanProvider: loanProvider,
        cardProvider: cardProvider,
        transactionProvider: transactionProvider,
        billNoteProvider: billNoteProvider,
      );
    } catch (e) {
      // Handle errors silently
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Listen for app lifecycle changes
    if (state == AppLifecycleState.resumed) {
      // App came to the foreground - refresh notifications
      _refreshNotifications();
    }
  }

  // Setup FCM message handlers
  void _setupFCMHandlers() {
    // Handle messages that arrive when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Add to notification provider
      if (message.notification != null) {
        final notificationProvider = Provider.of<NotificationProvider>(
          navigatorKey.currentContext!,
          listen: false,
        );
        
        notificationProvider.handleFcmMessage(
          message.notification!.title ?? 'New Notification',
          message.notification!.body ?? '',
          message.data,
        );
      }
      
      // Also show notification (already handled by NotificationService)
      notificationService.showLocalNotificationFromFCM(message);
    });
    
    // Handle notification taps when app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Add to notification provider if not already added
      if (message.notification != null) {
        final notificationProvider = Provider.of<NotificationProvider>(
          navigatorKey.currentContext!,
          listen: false,
        );
        
        notificationProvider.handleFcmMessage(
          message.notification!.title ?? 'New Notification',
          message.notification!.body ?? '',
          message.data,
        );
        
        // Navigate based on message type/data
        _handleNotificationTap(message);
      }
    });
    
    // Get initial message if app was opened from a notification
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null && message.notification != null) {
        // Add to notification provider
        final notificationProvider = Provider.of<NotificationProvider>(
          navigatorKey.currentContext!,
          listen: false,
        );
        
        notificationProvider.handleFcmMessage(
          message.notification!.title ?? 'New Notification',
          message.notification!.body ?? '',
          message.data,
        );
        
        // Navigate based on message type/data
        _handleNotificationTap(message);
      }
    });
  }
  
  // Handle notification tap navigation
  void _handleNotificationTap(RemoteMessage message) {
    if (message.data.containsKey('type')) {
      final type = message.data['type'];
      
      switch (type) {
        case 'loan':
          if (message.data.containsKey('loanId')) {
            final loanId = message.data['loanId'];
            // Find the loan data first
            final context = navigatorKey.currentContext;
            if (context != null) {
              final loanProvider = Provider.of<LoanProvider>(context, listen: false);
              final loan = loanProvider.activeLoans.firstWhere(
                (loan) => loan['id'] == loanId,
                orElse: () => <String, dynamic>{},
              );
              
              if (loan.isNotEmpty) {
                navigatorKey.currentState?.push(
                  MaterialPageRoute(
                    builder: (context) => LoanDetailsScreen(
                      loanData: loan,
                      initialTab: 0, // Default to overview tab
                    ),
                  ),
                );
              }
            }
          }
          break;
        case 'reminder':
          navigatorKey.currentState?.pushNamed(ReminderScreen.routeName);
          break;
        case 'notification':
          navigatorKey.currentState?.pushNamed(NotificationCenterScreen.routeName);
          break;
        // Add other types as needed
      }
    } else {
      // Default to opening the notification center
      navigatorKey.currentState?.pushNamed(NotificationCenterScreen.routeName);
    }
  }

  // Method to sync all reminders
  Future<void> _syncAllReminders() async {
    try {
      // Use a safe way to access the context through navigatorKey
      if (navigatorKey.currentContext != null) {
        final notificationProvider = Provider.of<NotificationProvider>(
          navigatorKey.currentContext!,
          listen: false,
        );
        await notificationProvider.syncAllReminders();
      } else {
        // If context is not available yet, schedule a retry
        await Future.delayed(const Duration(seconds: 1), () async {
          if (mounted) {
            await _syncAllReminders();
          }
        });
      }
    } catch (e) {
      print('Error syncing reminders: $e');
      // Try again after a short delay to handle initialization timing issues
      if (mounted) {
        await Future.delayed(const Duration(seconds: 2), () async {
          if (mounted) {
            try {
              final notificationProvider = Provider.of<NotificationProvider>(
                navigatorKey.currentContext!,
                listen: false,
              );
              await notificationProvider.syncAllReminders();
            } catch (retryError) {
              print('Retry error syncing reminders: $retryError');
            }
          }
        });
      }
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => NavPreferencesProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => TransactionProvider()),
        ChangeNotifierProvider(
          create: (_) => LoanProvider(),
          lazy: false, // Initialize immediately
        ),
        ChangeNotifierProvider(create: (_) => BillNoteProvider()),
        ChangeNotifierProvider(create: (_) => DailyEntryProvider()),
        ChangeNotifierProvider(create: (_) => MilkSellerProvider()),
        ChangeNotifierProvider(create: (_) => CardProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            navigatorKey: navigatorKey, // Set global navigator key
            title: 'My Byaj Book',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.themeData,
            home: const SplashScreen(),
            routes: {
              BillDiaryScreen.routeName: (ctx) => const BillDiaryScreen(),
              NavSettingsScreen.routeName: (ctx) => const NavSettingsScreen(),
              TeaDiaryScreen.routeName: (ctx) => const TeaDiaryScreen(showAppBar: true),
              ProfileEditScreen.routeName: (ctx) => const ProfileEditScreen(),
              ReminderScreen.routeName: (ctx) => const ReminderScreen(),
              SpecialThanksScreen.routeName: (ctx) => const SpecialThanksScreen(),
              NotificationCenterScreen.routeName: (ctx) => const NotificationCenterScreen(),
              '/login': (ctx) => const LoginScreen(),
            },
          );
        },
      ),
    );
  }
}

// Mark loan as paid from notification
Future<void> markLoanAsPaid(String loanId) async {
  final context = navigatorKey.currentContext;
  if (context != null) {
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);
    final loan = loanProvider.activeLoans.firstWhere(
      (loan) => loan['id'] == loanId,
      orElse: () => <String, dynamic>{},
    );
    
    if (loan.isNotEmpty) {
      // Create a copy of the loan with updated status
      final updatedLoan = Map<String, dynamic>.from(loan);
      
      // Track whether we marked something as paid
      bool markedAsPaid = false;
      int installmentNumber = 0;
      double installmentAmount = 0.0;
      
      // Mark the current installment as paid
      if (updatedLoan.containsKey('installments')) {
        List<Map<String, dynamic>> installments = List<Map<String, dynamic>>.from(updatedLoan['installments']);
        for (int i = 0; i < installments.length; i++) {
          if (!installments[i]['isPaid']) {
            installments[i]['isPaid'] = true;
            installments[i]['paidDate'] = DateTime.now();
            markedAsPaid = true;
            installmentNumber = installments[i]['installmentNumber'] as int;
            installmentAmount = installments[i]['totalAmount'] as double;
            break; // Only mark the first unpaid installment
          }
        }
        updatedLoan['installments'] = installments;
        
        // Update progress
        int totalInstallments = installments.length;
        int paidInstallments = installments.where((inst) => inst['isPaid'] == true).length;
        double progress = totalInstallments > 0 ? paidInstallments / totalInstallments : 0.0;
        updatedLoan['progress'] = progress;
        
        // Check if all installments are paid
        if (paidInstallments == totalInstallments) {
          updatedLoan['status'] = 'Completed';
        }
      }
      
      // Update the loan
      await loanProvider.updateLoan(updatedLoan);
      
      // Cancel the notification for this loan
      await notificationService.cancelNotificationForLoan(loanId);
      
      // Schedule the next notification
      await notificationService.scheduleLoanPaymentNotifications(loanProvider);
      
      // Show a confirmation snackbar if in the app
      if (markedAsPaid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Installment #$installmentNumber for ${loan['loanName']} (₹${installmentAmount.toStringAsFixed(2)}) marked as paid'
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'VIEW',
              onPressed: () {
                // Navigate to loan details screen
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => LoanDetailsScreen(
                      loanData: updatedLoan,
                      initialTab: 1, // Open the payments tab
                    ),
                  ),
                );
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No pending payments found for ${loan['loanName']}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      // Loan not found
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loan not found or has been deleted'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Update NotificationService._markLoanAsPaid to use this function
// Future<void> _markLoanAsPaid(String loanId) async {
//   await markLoanAsPaid(loanId);
// }
