import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_provider.dart';

class LoanProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _activeLoans = [];
  List<Map<String, dynamic>> _completedLoans = [];
  bool _isLoading = true;

  List<Map<String, dynamic>> get activeLoans => _activeLoans;
  List<Map<String, dynamic>> get completedLoans => _completedLoans;
  bool get isLoading => _isLoading;

  // Initialize with sample data for development
  LoanProvider() {
    _initializeLoans();
  }

  // Public method to load loans, called from screens
  Future<void> loadLoans() async {
    _isLoading = true;
    notifyListeners();
    
    // Load saved loans
    await _loadLoans();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _initializeLoans() async {
    _isLoading = true;
    notifyListeners();
    
    // Load saved loans
    await _loadLoans();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addLoan(Map<String, dynamic> loan) async {
    // Generate a unique ID for the loan
    loan['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Add category based on loan type if not provided
    if (!loan.containsKey('category')) {
      final loanType = loan['loanType'] as String;
      loan['category'] = loanType.split(' ').first; // Extract 'Home' from 'Home Loan'
    }
    
    // Set initial progress and status
    loan['progress'] = 0.0;
    loan['status'] = 'Active';
    
    _activeLoans.add(loan);
    await _saveLoans();
    notifyListeners();
  }

  Future<void> updateLoan(Map<String, dynamic> loanData) async {
    final id = loanData['id'];
    if (id != null) {
      return updateLoanById(id, loanData);
    } else {
      // If loan doesn't have an ID yet, add it as a new loan
      return addLoan(loanData);
    }
  }

  Future<void> updateLoanById(String id, Map<String, dynamic> updatedData) async {
    final index = _activeLoans.indexWhere((loan) => loan['id'] == id);
    if (index != -1) {
      // Create a new map with all the updated data
      _activeLoans[index] = {..._activeLoans[index], ...updatedData};
      
      // Ensure progress field is correctly calculated if installments are present
      if (_activeLoans[index].containsKey('installments') && _activeLoans[index]['installments'] is List) {
        final installments = _activeLoans[index]['installments'] as List;
        final totalInstallments = installments.length;
        final paidInstallments = installments.where((inst) => inst['isPaid'] == true).length;
        
        // Calculate and update progress
        if (totalInstallments > 0) {
          final progress = paidInstallments / totalInstallments;
          _activeLoans[index]['progress'] = progress;
        }
      }
      
      // If loan is completed, move it to completed loans
      if (_activeLoans[index]['progress'] == 1.0 || _activeLoans[index]['status'] == 'Completed') {
        _activeLoans[index]['status'] = 'Completed';
        _activeLoans[index]['completionDate'] = DateTime.now();
        _completedLoans.add(_activeLoans[index]);
        _activeLoans.removeAt(index);
      }
      
      await _saveLoans();
      notifyListeners();
    }
  }

  Future<void> deleteLoan(String id) async {
    _activeLoans.removeWhere((loan) => loan['id'] == id);
    _completedLoans.removeWhere((loan) => loan['id'] == id);
    await _saveLoans();
    notifyListeners();
  }

  Future<void> _saveLoans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert DateTime objects to ISO strings for storage
      final activeLoansJson = _activeLoans.map((loan) {
        final loanCopy = Map<String, dynamic>.from(loan);
        loanCopy['startDate'] = loanCopy['startDate']?.toIso8601String();
        loanCopy['firstPaymentDate'] = loanCopy['firstPaymentDate']?.toIso8601String();
        loanCopy['createdDate'] = loanCopy['createdDate']?.toIso8601String();
        loanCopy['completionDate'] = loanCopy['completionDate']?.toIso8601String();
        
        // Handle installments if present
        if (loanCopy.containsKey('installments') && loanCopy['installments'] is List) {
          loanCopy['installments'] = (loanCopy['installments'] as List).map((installment) {
            final installmentCopy = Map<String, dynamic>.from(installment);
            // Convert DateTime objects in installments
            installmentCopy['dueDate'] = installmentCopy['dueDate']?.toIso8601String();
            installmentCopy['paidDate'] = installmentCopy['paidDate']?.toIso8601String();
            return installmentCopy;
          }).toList();
        }
        
        return loanCopy;
      }).toList();
      
      final completedLoansJson = _completedLoans.map((loan) {
        final loanCopy = Map<String, dynamic>.from(loan);
        loanCopy['startDate'] = loanCopy['startDate']?.toIso8601String();
        loanCopy['firstPaymentDate'] = loanCopy['firstPaymentDate']?.toIso8601String();
        loanCopy['createdDate'] = loanCopy['createdDate']?.toIso8601String();
        loanCopy['completionDate'] = loanCopy['completionDate']?.toIso8601String();
        
        // Handle installments if present
        if (loanCopy.containsKey('installments') && loanCopy['installments'] is List) {
          loanCopy['installments'] = (loanCopy['installments'] as List).map((installment) {
            final installmentCopy = Map<String, dynamic>.from(installment);
            // Convert DateTime objects in installments
            installmentCopy['dueDate'] = installmentCopy['dueDate']?.toIso8601String();
            installmentCopy['paidDate'] = installmentCopy['paidDate']?.toIso8601String();
            return installmentCopy;
          }).toList();
        }
        
        return loanCopy;
      }).toList();
      
      await prefs.setString('activeLoans', jsonEncode(activeLoansJson));
      await prefs.setString('completedLoans', jsonEncode(completedLoansJson));
    } catch (e) {
      debugPrint('Error saving loans: $e');
    }
  }

  Future<void> _loadLoans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final activeLoansString = prefs.getString('activeLoans');
      final completedLoansString = prefs.getString('completedLoans');
      
      if (activeLoansString != null) {
        final List<dynamic> activeLoansJson = jsonDecode(activeLoansString);
        _activeLoans = activeLoansJson.map((loan) {
          final loanMap = Map<String, dynamic>.from(loan);
          loanMap['startDate'] = loanMap['startDate'] != null ? DateTime.parse(loanMap['startDate']) : null;
          loanMap['firstPaymentDate'] = loanMap['firstPaymentDate'] != null ? DateTime.parse(loanMap['firstPaymentDate']) : null;
          loanMap['createdDate'] = loanMap['createdDate'] != null ? DateTime.parse(loanMap['createdDate']) : null;
          loanMap['completionDate'] = loanMap['completionDate'] != null ? DateTime.parse(loanMap['completionDate']) : null;
          
          // Process installments if present
          if (loanMap.containsKey('installments') && loanMap['installments'] is List) {
            loanMap['installments'] = (loanMap['installments'] as List).map((installment) {
              final installmentMap = Map<String, dynamic>.from(installment);
              // Convert string dates back to DateTime objects
              installmentMap['dueDate'] = installmentMap['dueDate'] != null ? DateTime.parse(installmentMap['dueDate']) : null;
              installmentMap['paidDate'] = installmentMap['paidDate'] != null ? DateTime.parse(installmentMap['paidDate']) : null;
              return installmentMap;
            }).toList();
          }
          
          return loanMap;
        }).toList();
      }
      
      if (completedLoansString != null) {
        final List<dynamic> completedLoansJson = jsonDecode(completedLoansString);
        _completedLoans = completedLoansJson.map((loan) {
          final loanMap = Map<String, dynamic>.from(loan);
          loanMap['startDate'] = loanMap['startDate'] != null ? DateTime.parse(loanMap['startDate']) : null;
          loanMap['firstPaymentDate'] = loanMap['firstPaymentDate'] != null ? DateTime.parse(loanMap['firstPaymentDate']) : null;
          loanMap['createdDate'] = loanMap['createdDate'] != null ? DateTime.parse(loanMap['createdDate']) : null;
          loanMap['completionDate'] = loanMap['completionDate'] != null ? DateTime.parse(loanMap['completionDate']) : null;
          
          // Process installments if present
          if (loanMap.containsKey('installments') && loanMap['installments'] is List) {
            loanMap['installments'] = (loanMap['installments'] as List).map((installment) {
              final installmentMap = Map<String, dynamic>.from(installment);
              // Convert string dates back to DateTime objects
              installmentMap['dueDate'] = installmentMap['dueDate'] != null ? DateTime.parse(installmentMap['dueDate']) : null;
              installmentMap['paidDate'] = installmentMap['paidDate'] != null ? DateTime.parse(installmentMap['paidDate']) : null;
              return installmentMap;
            }).toList();
          }
          
          return loanMap;
        }).toList();
      }
    } catch (e) {
      debugPrint('Error loading loans: $e');
    }
  }

  Map<String, dynamic> getLoanSummary({UserProvider? userProvider}) {
    // Filter out inactive loans from the count and calculations
    final activeLoans = _activeLoans.where((loan) => loan['status'] != 'Inactive').toList();
    
    int totalActiveLoans = activeLoans.length;
    
    // Calculate total loan amount as double
    double totalAmount = activeLoans.fold(0.0, (prev, loan) => 
      prev + (double.tryParse(loan['loanAmount'] ?? '0') ?? 0.0));
    
    // Calculate the next due amount as double
    double dueAmount = 0.0;
    final DateTime now = DateTime.now();
    final int currentMonth = now.month;
    final int currentYear = now.year;
    
    for (var loan in activeLoans) {
      // Check if this loan has installments
      bool emiBilledThisMonth = false;
      
      if (loan.containsKey('installments') && loan['installments'] is List) {
        final installments = loan['installments'] as List;
        
        // Look for an installment due this month
        for (final installment in installments) {
          if (installment['dueDate'] is DateTime) {
            final dueDate = installment['dueDate'] as DateTime;
            
            // If installment is due this month
            if (dueDate.month == currentMonth && dueDate.year == currentYear) {
              // If EMI is not paid, add it to due amount
              if (installment['isPaid'] != true) {
                dueAmount += installment['totalAmount'] as double? ?? 0.0;
              }
              emiBilledThisMonth = true;
              break;
            }
          }
        }
      }
      
      // If no installment was found for this month, calculate EMI
      if (!emiBilledThisMonth) {
        double principal = double.tryParse(loan['loanAmount'] ?? '0') ?? 0.0;
        double rate = (double.tryParse(loan['interestRate'] ?? '0') ?? 0.0) / 100 / 12;
        int time = int.tryParse(loan['loanTerm'] ?? '0') ?? 0;
        
        if (rate > 0 && time > 0) {
          double emi = principal * rate * _pow(1 + rate, time) / (_pow(1 + rate, time) - 1);
          dueAmount += emi;
        }
      }
    }
    
    // Get user name from UserProvider if provided
    String userName = 'User';
    if (userProvider != null && userProvider.user != null) {
      userName = userProvider.user!.name;
    }
    
    return {
      'userName': userName,
      'activeLoans': totalActiveLoans,
      'totalAmount': totalAmount,
      'dueAmount': dueAmount,
    };
  }

  double _pow(double x, int y) {
    double result = 1.0;
    for (int i = 0; i < y; i++) {
      result *= x;
    }
    return result;
  }

  // Get a loan by its ID
  Map<String, dynamic>? getLoanById(String id) {
    // First look in active loans
    final activeLoan = _activeLoans.firstWhere(
      (loan) => loan['id'] == id,
      orElse: () => <String, dynamic>{},
    );
    
    if (activeLoan.isNotEmpty) {
      return activeLoan;
    }
    
    // Then look in completed loans
    final completedLoan = _completedLoans.firstWhere(
      (loan) => loan['id'] == id,
      orElse: () => <String, dynamic>{},
    );
    
    if (completedLoan.isNotEmpty) {
      return completedLoan;
    }
    
    return null;
  }
} 