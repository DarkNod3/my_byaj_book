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
import 'services/notification_service.dart';
import 'models/loan_notification.dart';
import 'screens/loan/loan_details_screen.dart';
import 'dart:io';

// Global notification service
final notificationService = NotificationService.instance;
// Global key for navigator to use in notification callbacks
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // When app is resumed, schedule notifications for any due loans
      _scheduleNotifications();
    }
  }

  void _scheduleNotifications() {
    final loanProvider = Provider.of<LoanProvider>(navigatorKey.currentContext!, listen: false);
    notificationService.scheduleLoanPaymentNotifications(loanProvider);
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
              TeaDiaryScreen.routeName: (ctx) => const TeaDiaryScreen(),
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
Future<void> _markLoanAsPaid(String loanId) async {
  await markLoanAsPaid(loanId);
}
