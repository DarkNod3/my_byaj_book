import 'package:flutter/material.dart';
import '../../widgets/loan_summary_card.dart';
import '../../providers/loan_provider.dart';
import '../../providers/user_provider.dart';
import '../../constants/app_theme.dart';
import 'package:provider/provider.dart';
import 'add_loan_screen.dart';
import 'loan_details_screen.dart';

class LoanScreen extends StatefulWidget {
  const LoanScreen({super.key});

  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen> {
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    // Fetch loan data when screen initializes
    _loadLoanData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when dependencies change (like after navigating back)
    _loadLoanData();
  }

  void _loadLoanData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if the widget is still mounted before accessing the provider
      if (!mounted) return;
      
      try {
        // Get the provider, handling possible exceptions
        final provider = Provider.of<LoanProvider>(context, listen: false);
        provider.loadLoans();
      } catch (e) {
        print('Error loading loan data: $e');
        // You could show a snackbar or other error message here
      }
    });
  }

  List<Map<String, dynamic>> get _filteredLoans {
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);
    if (_selectedCategory == 'All') {
      return loanProvider.activeLoans;
    } else {
      return loanProvider.activeLoans.where((loan) => 
        loan['category'] == _selectedCategory || 
        loan['loanType'] == '${_selectedCategory} Loan').toList();
    }
  }

  // Get category-specific summary data
  Map<String, dynamic> _getCategorySummary(LoanProvider loanProvider, UserProvider userProvider) {
    if (_selectedCategory == 'All') {
      return loanProvider.getLoanSummary(userProvider: userProvider);
    } else {
      final filteredLoans = loanProvider.activeLoans.where((loan) => 
        loan['category'] == _selectedCategory || 
        loan['loanType'] == '${_selectedCategory} Loan').toList();
      
      // Calculate summary data for filtered loans
      double totalAmount = 0.0;
      double dueAmount = 0.0;
      
      for (var loan in filteredLoans) {
        // Add to total amount
        totalAmount += double.tryParse(loan['loanAmount'] ?? '0') ?? 0.0;
        
        // Calculate EMI for due amount
        double principal = double.tryParse(loan['loanAmount'] ?? '0') ?? 0.0;
        double rate = (double.tryParse(loan['interestRate'] ?? '0') ?? 0.0) / 100 / 12;
        int time = int.tryParse(loan['loanTerm'] ?? '0') ?? 0;
        
        if (rate > 0 && time > 0) {
          double emi = principal * rate * _pow(1 + rate, time) / (_pow(1 + rate, time) - 1);
          dueAmount += emi;
        }
      }
      
      return {
        'userName': userProvider.user?.name ?? 'User',
        'activeLoans': filteredLoans.length,
        'totalAmount': totalAmount,
        'dueAmount': dueAmount,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoanProvider>(
      builder: (context, loanProvider, _) {
        // Get user provider to pass to loan summary
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        
        // Get loan summary data with user info, filtered by category
        final summaryData = _getCategorySummary(loanProvider, userProvider);
        
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoanSummaryCard(
                  userName: summaryData['userName'] ?? 'User',
                  activeLoans: summaryData['activeLoans'] ?? 0,
                  totalAmount: summaryData['totalAmount'] ?? 0,
                  dueAmount: summaryData['dueAmount'] ?? 0,
                ),
                const SizedBox(height: 24),
                _buildLoanTypeFilters(),
                const SizedBox(height: 24),
                _buildActiveLoansList(loanProvider),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildLoanTypeFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Loan Categories',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(label: 'All'),
              _buildFilterChip(label: 'Personal'),
              _buildFilterChip(label: 'Home'),
              _buildFilterChip(label: 'Car'),
              _buildFilterChip(label: 'Education'),
              _buildFilterChip(label: 'Business'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({required String label}) {
    final isSelected = _selectedCategory == label;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCategory = label;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(50),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.blue.shade100,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveLoansList(LoanProvider loanProvider) {
    if (loanProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (loanProvider.activeLoans.isEmpty) {
      return _buildEmptyState();
    }

    if (_filteredLoans.isEmpty && _selectedCategory != 'All') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No loans in $_selectedCategory category',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different category',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddLoanScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Loan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedCategory == 'All' ? 'All Loans' : '$_selectedCategory Loans',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddLoanScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('New Loan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _filteredLoans.length,
          itemBuilder: (context, index) {
            return _buildLoanCard(_filteredLoans[index]);
          },
        ),
      ],
    );
  }

  Widget _buildLoanCard(Map<String, dynamic> loan) {
    final Color loanColor = _getLoanColor(loan['loanType']);
    final IconData loanIcon = _getLoanIcon(loan['loanType']);
    final bool isNextPaymentDue = _isPaymentDue(loan['firstPaymentDate']);
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoanDetailsScreen(loanData: loan),
          ),
        );
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: loanColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      loanIcon,
                      color: loanColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loan['loanName'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Principal: ₹${loan['loanAmount']}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: loan['status'] == 'Active' ? Colors.green.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      loan['status'] ?? 'Active',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: loan['status'] == 'Active' ? Colors.green.shade800 : Colors.grey.shade800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      _showLoanOptions(loan);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLoanDetail(
                    title: 'Monthly EMI',
                    value: _calculateEMI(loan),
                    color: Colors.blue,
                  ),
                  _buildLoanDetail(
                    title: 'Next Payment',
                    value: _formatDate(loan['firstPaymentDate']),
                    color: isNextPaymentDue ? Colors.red : Colors.orange,
                    badge: isNextPaymentDue ? 'Due' : null,
                    badgeColor: Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Loan Repayment Progress',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: (loan['progress'] != null && loan['progress'] is num) ? loan['progress'] : 
                          (loan['installments'] != null && loan['installments'] is List) ? 
                            (loan['installments'] as List).where((inst) => inst['isPaid'] == true).length / 
                            (loan['installments'] as List).length : 0.0,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(loanColor),
                        minHeight: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${((loan['progress'] != null && loan['progress'] is num) ? (loan['progress'] * 100).toInt() : 
                        (loan['installments'] != null && loan['installments'] is List) ? 
                            ((loan['installments'] as List).where((inst) => inst['isPaid'] == true).length / 
                            (loan['installments'] as List).length * 100).toInt() : 0)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: loanColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Remaining: ₹${_calculateRemainingAmount(loan)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoanDetailsScreen(loanData: loan),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: loanColor,
                      side: BorderSide(color: loanColor),
                    ),
                    child: const Text('View Details'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show options for a loan
  void _showLoanOptions(Map<String, dynamic> loan) {
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);
    final String loanId = loan['id'] ?? '';
    final bool isActive = loan['status'] == 'Active';
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Loan Options',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                  color: isActive ? Colors.orange : Colors.green,
                ),
                title: Text(isActive ? 'Mark as Inactive' : 'Mark as Active'),
                onTap: () {
                  // Toggle active status
                  final updatedLoan = Map<String, dynamic>.from(loan);
                  updatedLoan['status'] = isActive ? 'Inactive' : 'Active';
                  loanProvider.updateLoan(updatedLoan);
                  Navigator.pop(context);
                  // Show feedback to user
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Loan marked as ${isActive ? 'inactive' : 'active'}'),
                      backgroundColor: isActive ? Colors.orange : Colors.green,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete Loan'),
                onTap: () {
                  // Show confirmation dialog
                  Navigator.pop(context);
                  _showDeleteConfirmation(loan);
                },
              ),
              ListTile(
                leading: const Icon(Icons.payment, color: Colors.blue),
                title: const Text('Record Payment'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => LoanDetailsScreen(loanData: loan, initialTab: 1),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Show confirmation dialog before deleting
  void _showDeleteConfirmation(Map<String, dynamic> loan) {
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);
    final String loanId = loan['id'] ?? '';
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Loan'),
          content: Text('Are you sure you want to delete "${loan['loanName']}"? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                loanProvider.deleteLoan(loanId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Loan deleted successfully'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoanDetail({
    required String title,
    required String value,
    required Color color,
    String? badge,
    Color? badgeColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor?.withOpacity(0.1) ?? Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeColor ?? Colors.red,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // Check if payment is due (date has passed)
  bool _isPaymentDue(DateTime? paymentDate) {
    if (paymentDate == null) return false;
    final now = DateTime.now();
    return paymentDate.isBefore(now);
  }

  Color _getLoanColor(String loanType) {
    switch (loanType) {
      case 'Home Loan':
        return Colors.blue;
      case 'Car Loan':
        return Colors.green;
      case 'Personal Loan':
        return Colors.purple;
      case 'Education Loan':
        return Colors.orange;
      case 'Business Loan':
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }

  IconData _getLoanIcon(String loanType) {
    switch (loanType) {
      case 'Home Loan':
        return Icons.home;
      case 'Car Loan':
        return Icons.directions_car;
      case 'Personal Loan':
        return Icons.person;
      case 'Education Loan':
        return Icons.school;
      case 'Business Loan':
        return Icons.business;
      default:
        return Icons.account_balance;
    }
  }

  String _calculateEMI(Map<String, dynamic> loan) {
    double principal = double.tryParse(loan['loanAmount']) ?? 0;
    double rate = (double.tryParse(loan['interestRate']) ?? 0) / 100 / 12; // Monthly rate
    int time = int.tryParse(loan['loanTerm']) ?? 0;
    
    if (rate == 0 || time == 0) return '₹0';
    
    // EMI formula: P * r * (1+r)^n / ((1+r)^n - 1)
    double emi = principal * rate * _pow(1 + rate, time) / (_pow(1 + rate, time) - 1);
    return '₹${emi.toStringAsFixed(2)}';
  }

  String _calculateRemainingAmount(Map<String, dynamic> loan) {
    double principal = double.tryParse(loan['loanAmount']) ?? 0;
    double rate = (double.tryParse(loan['interestRate']) ?? 0) / 100 / 12;
    int time = int.tryParse(loan['loanTerm']) ?? 0;
    double progress = double.tryParse(loan['progress'].toString()) ?? 0.0;
    
    if (rate == 0 || time == 0) return '₹${principal.toStringAsFixed(2)}';
    
    double emi = principal * rate * _pow(1 + rate, time) / (_pow(1 + rate, time) - 1);
    double totalAmount = emi * time;
    double remainingAmount = totalAmount * (1 - progress);
    
    return '₹${remainingAmount.toStringAsFixed(2)}';
  }

  double _pow(double x, int y) {
    double result = 1.0;
    for (int i = 0; i < y; i++) {
      result *= x;
    }
    return result;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No loans found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a new loan to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddLoanScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Loan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// Global navigator key to access context from static methods
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
