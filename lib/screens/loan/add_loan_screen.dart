import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/loan_provider.dart';
import '../../constants/app_theme.dart';
import 'loan_details_screen.dart';
import '../../services/notification_service.dart';
import '../../main.dart' show notificationService;

class AddLoanScreen extends StatefulWidget {
  const AddLoanScreen({super.key});

  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loanNameController = TextEditingController();
  final _loanAmountController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _tenureController = TextEditingController();
  final _loanProviderController = TextEditingController();
  final _loanNumberController = TextEditingController();
  final _helplineNumberController = TextEditingController();
  final _managerNumberController = TextEditingController();

  String _selectedLoanType = 'Home Loan';
  String _selectedInterestType = 'Fixed';
  String _selectedPeriodType = 'Years';
  String _selectedPaymentMethod = 'UPI';
  DateTime _loanStartDate = DateTime(2025, 4, 25);
  DateTime _firstPaymentDate = DateTime(2025, 5, 25);

  final List<String> _loanTypes = [
    'Home Loan',
    'Personal Loan',
    'Car Loan',
    'Education Loan',
    'Business Loan',
  ];

  final List<String> _interestTypes = [
    'Fixed',
    'Floating',
  ];

  final List<String> _periodTypes = [
    'Years',
    'Months',
  ];

  final List<String> _paymentMethods = [
    'UPI',
    'Bank Transfer',
    'Auto Debit',
    'Cheque',
    'Cash',
  ];

  @override
  void dispose() {
    _loanNameController.dispose();
    _loanAmountController.dispose();
    _interestRateController.dispose();
    _tenureController.dispose();
    _loanProviderController.dispose();
    _loanNumberController.dispose();
    _helplineNumberController.dispose();
    _managerNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        title: const Text(
          'Add New Loan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        color: AppTheme.backgroundColor,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle('Basic Information'),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _loanNameController,
                  label: 'Loan Name',
                  icon: Icons.label,
                  helper: 'E.g., Home Purchase, Car Loan',
                ),
                const SizedBox(height: 16),
                
                // Loan Type
                _buildDropdown(
                  label: 'Loan Type',
                  icon: Icons.account_balance,
                  value: _selectedLoanType,
                  items: _loanTypes.map((type) => DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(_getLoanTypeIcon(type), color: AppTheme.primaryColor, size: 20),
                        const SizedBox(width: 10),
                        Text(type),
                      ],
                    ),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedLoanType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Loan Provider
                _buildTextField(
                  controller: _loanProviderController,
                  label: 'Loan Provider',
                  icon: Icons.business,
                  helper: 'E.g., HDFC Bank, SBI, ICICI',
                  isRequired: false,
                ),
                const SizedBox(height: 16),
                
                // Loan Number
                _buildTextField(
                  controller: _loanNumberController,
                  label: 'Loan Account Number',
                  icon: Icons.credit_card,
                  keyboardType: TextInputType.text,
                  helper: 'Your loan reference number',
                  isRequired: false,
                ),
                const SizedBox(height: 24),
                
                _buildSectionTitle('Amount & Interest Details'),
                const SizedBox(height: 16),
                
                // Loan Amount
                _buildTextField(
                  controller: _loanAmountController,
                  label: 'Loan Amount',
                  prefix: '₹',
                  icon: Icons.currency_rupee,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
                const SizedBox(height: 16),
                
                // Interest Rate and Type in a row
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildTextField(
                        controller: _interestRateController,
                        label: 'Interest Rate (%)',
                        prefix: '%',
                        icon: Icons.percent,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _buildDropdown(
                        label: 'Interest Type',
                        value: _selectedInterestType,
                        items: _interestTypes.map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        )).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedInterestType = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Tenure and Period in a row
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildTextField(
                        controller: _tenureController,
                        label: 'Tenure',
                        icon: Icons.timer,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _buildDropdown(
                        label: 'Period',
                        value: _selectedPeriodType,
                        items: _periodTypes.map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        )).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedPeriodType = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                _buildSectionTitle('Important Dates'),
                const SizedBox(height: 16),
                
                // Loan Start Date
                _buildDatePicker(
                  label: 'Loan Start Date',
                  icon: Icons.calendar_today,
                  date: _loanStartDate,
                  onTap: () => _selectDate(context, true),
                ),
                const SizedBox(height: 16),
                
                // First Payment Date
                _buildDatePicker(
                  label: 'First Payment Date',
                  icon: Icons.event,
                  date: _firstPaymentDate,
                  onTap: () => _selectDate(context, false),
                ),
                const SizedBox(height: 24),
                
                _buildSectionTitle('Payment & Contact Information'),
                const SizedBox(height: 16),
                
                // Payment Method
                _buildDropdown(
                  label: 'Payment Method',
                  icon: Icons.payments_outlined,
                  value: _selectedPaymentMethod,
                  items: _paymentMethods.map((method) => DropdownMenuItem(
                    value: method,
                    child: Row(
                      children: [
                        Icon(_getPaymentMethodIcon(method), size: 20, color: AppTheme.primaryColor),
                        const SizedBox(width: 10),
                        Text(method),
                      ],
                    ),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPaymentMethod = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Helpline Number
                _buildTextField(
                  controller: _helplineNumberController,
                  label: 'Helpline Number',
                  icon: Icons.support_agent,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  helper: 'Customer care number (optional)',
                  isRequired: false,
                ),
                const SizedBox(height: 16),
                
                // Manager Number
                _buildTextField(
                  controller: _managerNumberController,
                  label: 'Manager Number',
                  icon: Icons.person,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  helper: 'Your loan manager number (optional)',
                  isRequired: false,
                ),
                const SizedBox(height: 32),
                
                // Save Button
                ElevatedButton.icon(
                  onPressed: _saveLoan,
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'Save Loan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          const Divider(height: 1, thickness: 1, color: Colors.black12),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? prefix,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? helper,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppTheme.primaryColor.withOpacity(0.7)),
              prefixText: prefix,
              prefixStyle: const TextStyle(color: AppTheme.textColor, fontSize: 16),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              hintText: helper,
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
            validator: (value) {
              if (isRequired && (value == null || value.isEmpty)) {
                return 'Please enter $label';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    IconData? icon,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: ButtonTheme(
              alignedDropdown: true,
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.primaryColor),
                iconSize: 24,
                elevation: 2,
                style: const TextStyle(color: AppTheme.textColor, fontSize: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                borderRadius: BorderRadius.circular(12),
                dropdownColor: Colors.white,
                items: items,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required IconData icon,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(icon, color: AppTheme.primaryColor.withOpacity(0.7)),
                    const SizedBox(width: 12),
                    Text(
                      '${date.day} ${_getMonthShortName(date.month)} ${date.year}',
                      style: const TextStyle(fontSize: 16, color: AppTheme.textColor),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime initialDate = isStartDate ? _loanStartDate : _firstPaymentDate;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _loanStartDate = picked;
          // Automatically set first payment date to one month later
          _firstPaymentDate = DateTime(
            picked.year,
            picked.month + 1,
            picked.day,
          );
        } else {
          _firstPaymentDate = picked;
        }
      });
    }
  }

  IconData _getLoanTypeIcon(String type) {
    switch (type) {
      case 'Home Loan':
        return Icons.home;
      case 'Personal Loan':
        return Icons.person;
      case 'Car Loan':
        return Icons.directions_car;
      case 'Education Loan':
        return Icons.school;
      case 'Business Loan':
        return Icons.business;
      default:
        return Icons.account_balance;
    }
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'UPI':
        return Icons.account_balance_wallet;
      case 'Bank Transfer':
        return Icons.account_balance;
      case 'Auto Debit':
        return Icons.schedule;
      case 'Cheque':
        return Icons.book;
      case 'Cash':
        return Icons.money;
      default:
        return Icons.payment;
    }
  }

  String _getMonthShortName(int month) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return monthNames[month - 1];
  }

  void _saveLoan() {
    if (_formKey.currentState!.validate()) {
      // Create loan data
      final loanData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'loanName': _loanNameController.text,
        'loanType': _selectedLoanType,
        'category': _selectedLoanType.split(' ').first, // Extract category from loan type
        'loanAmount': _loanAmountController.text,
        'interestRate': _interestRateController.text,
        'loanTerm': _selectedPeriodType == 'Years' 
            ? ((int.tryParse(_tenureController.text) ?? 1) * 12).toString() // Convert years to months properly
            : _tenureController.text,
        'periodType': 'Months', // Always store as months for consistency
        'interestType': _selectedInterestType,
        'startDate': _loanStartDate,
        'firstPaymentDate': _firstPaymentDate,
        'paymentMethod': _selectedPaymentMethod,
        'createdDate': DateTime.now(),
        'progress': 0.0,
        'status': 'Active',
        'loanProvider': _loanProviderController.text,
        'loanNumber': _loanNumberController.text,
        'helplineNumber': _helplineNumberController.text,
        'managerNumber': _managerNumberController.text,
      };
      
      // Save the loan using provider
      final loanProvider = Provider.of<LoanProvider>(context, listen: false);
      loanProvider.addLoan(loanData);
      
      // Schedule notifications for this loan
      notificationService.scheduleLoanPaymentNotifications(loanProvider);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loan added successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate back to loan screen
      Navigator.pop(context);
    }
  }
} 