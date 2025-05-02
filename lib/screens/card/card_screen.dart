import 'package:flutter/material.dart';

class CardScreen extends StatefulWidget {
  const CardScreen({super.key});

  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  int _selectedCardIndex = 0;
  
  final List<Map<String, dynamic>> _cards = [];  // Empty cards list instead of sample data

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Cards',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddCardDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Card'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _cards.isEmpty
                ? _buildEmptyCardState()
                : _buildVerticalCardList(),
            const SizedBox(height: 24),
            _cards.isEmpty
                ? const SizedBox()  // Don't show entries section when no cards
                : _buildSelectedCardEntries(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCardState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.credit_card,
            size: 70,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'No cards yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Add your first card by tapping the "Add Card" button above',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _showAddCardDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Card'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalCardList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
        itemCount: _cards.length,
        itemBuilder: (context, index) {
          final card = _cards[index];
        final isSelected = index == _selectedCardIndex;
        
        // Calculate the percentage for progress bar
        double percentUsed = 0.0;
        if (card['cardType'] == 'Credit Card' && card['limit'] != 'N/A') {
          // Extract numeric values from strings
          final balanceValue = double.tryParse(
            card['balance'].toString().replaceAll('₹', '').replaceAll(',', '').trim()
          ) ?? 0.0;
          
          final limitValue = double.tryParse(
            card['limit'].toString().replaceAll('₹', '').replaceAll(',', '').trim()
          ) ?? 1.0; // Default to 1.0 to avoid division by zero
          
          if (limitValue > 0) {
            percentUsed = balanceValue / limitValue;
            // Cap at 1.0 (100%)
            if (percentUsed > 1.0) percentUsed = 1.0;
          }
        }
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCardIndex = index;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Card(
              elevation: isSelected ? 6 : 2,
              shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
                side: isSelected 
                    ? BorderSide(color: card['color'], width: 2)
                    : BorderSide.none,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            card['color'],
            card['color'].withOpacity(0.7),
          ],
        ),
          ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  card['bank'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                            Row(
                              children: [
                Text(
                  card['cardType'],
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                                const SizedBox(width: 8),
                                PopupMenuButton(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: Colors.white,
            ),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showEditCardDialog(index);
                                    } else if (value == 'delete') {
                                      _showDeleteCardConfirmation(index);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 20),
                                          SizedBox(width: 8),
                                          Text('Edit Card'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, size: 20, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete Card', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
            Text(
              card['cardNumber'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                            letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CARD HOLDER',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      card['holderName'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EXPIRES',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      card['expiry'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CVV',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  card['cvv'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.credit_card,
                  color: Colors.white,
                  size: 30,
                ),
              ],
            ),
          ],
        ),
      ),
                  Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                                  card['cardType'] == 'Debit Card' ? 'Balance' : 'Due Amount',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  card['balance'],
                                  style: TextStyle(
                                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                                    color: card['cardType'] == 'Debit Card' ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: () => _showAddEntryDialog(index),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: card['color'],
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Add Entry'),
                            ),
                          ],
                    ),
                        
                        // Add progress bar for credit limit
                        if (card['cardType'] == 'Credit Card' && card['limit'] != 'N/A') ...[
                          const SizedBox(height: 16),
                          Row(
                        children: [
                              Text(
                                'Credit Limit: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  card['limit'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: percentUsed,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              percentUsed > 0.75 ? Colors.red : card['color']
                            ),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(percentUsed * 100).toStringAsFixed(0)}% used',
                            style: TextStyle(
                              fontSize: 12,
                              color: percentUsed > 0.75 ? Colors.red : Colors.grey[600],
                      ),
                    ),
                  ],
                      ],
                    ),
                ),
              ],
            ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedCardEntries() {
    final card = _cards[_selectedCardIndex];
    final entries = card['entries'] as List;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
            Row(
              children: [
                Text(
                  '${card['bank']} Card History',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${entries.length} ${entries.length == 1 ? 'transaction' : 'transactions'})',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.sort),
                  tooltip: 'Sort transactions',
                  onPressed: () {
                    // Could implement sorting options here
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sorting feature coming soon')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh transactions',
                  onPressed: () {
                    setState(() {});
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 48,
                  color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
                Text(
                  'No transactions yet',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
              ),
              const SizedBox(height: 8),
              Text(
                  'Tap "Add Entry" on the card to add a transaction',
                  textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                ),
              ),
            ],
            ),
          )
        else
          Column(
            children: [
              // Summary card
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                      _buildSummaryItem(
                        title: 'Total Income',
                        value: _calculateTotalIncomeExpense(entries, isExpense: false),
                        icon: Icons.arrow_downward,
                        color: Colors.green,
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.grey[300],
                ),
                      _buildSummaryItem(
                        title: 'Total Expense',
                        value: _calculateTotalIncomeExpense(entries, isExpense: true),
                        icon: Icons.arrow_upward,
                        color: Colors.red,
                ),
              ],
            ),
                ),
        ),
              
              // Transaction list
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: entry['isExpense'] 
                              ? Colors.red.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          entry['isExpense'] ? Icons.arrow_upward : Icons.arrow_downward,
                          color: entry['isExpense'] ? Colors.red : Colors.green,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        entry['description'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        entry['date'],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      trailing: Text(
                        entry['amount'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: entry['isExpense'] ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
      ],
    );
  }
  
  Widget _buildSummaryItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  String _calculateTotalIncomeExpense(List entries, {required bool isExpense}) {
    double total = 0;
    
    for (var entry in entries) {
      if (entry['isExpense'] == isExpense) {
        // Extract amount from string like '₹1500'
        final amountStr = entry['amount'].toString().replaceAll('₹', '').replaceAll(',', '');
        final amount = double.tryParse(amountStr) ?? 0;
        total += amount;
      }
    }
    
    return '₹${total.toStringAsFixed(0)}';
  }

  void _showAddEntryDialog(int cardIndex) {
    final card = _cards[cardIndex];
    
    // Controllers for the form
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    bool isExpense = true;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
      child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with bank name
                Row(
        children: [
          Container(
                      width: 40,
                      height: 40,
            decoration: BoxDecoration(
                        color: card['color'],
                        borderRadius: BorderRadius.circular(8),
            ),
                      child: const Icon(
                        Icons.credit_card,
                        color: Colors.white,
            ),
          ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
          Text(
                            'Add Entry to',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${card['bank']} Card',
            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Description (Optional)
            const Text(
                  'Description (Optional)',
              style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Grocery Shopping',
                    border: UnderlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
                ),
                
                const SizedBox(height: 20),
                
                // Amount (Required)
                const Text(
                  'Amount',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    prefixText: '₹ ',
                    hintText: '0.00',
                    border: UnderlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                ),
                
                const SizedBox(height: 20),
                
                // Transaction Type
                const Text(
                  'Transaction Type:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            isExpense = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isExpense ? Colors.red[50] : Colors.transparent,
                            border: Border.all(
                              color: isExpense ? Colors.red : Colors.grey[300]!,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_upward,
                                color: isExpense ? Colors.red : Colors.grey[600],
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Expense',
                                style: TextStyle(
                                  color: isExpense ? Colors.red : Colors.grey[600],
                                  fontWeight: isExpense ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              if (isExpense)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.red,
                                    size: 16,
                                  ),
            ),
          ],
        ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            isExpense = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !isExpense ? Colors.green[50] : Colors.transparent,
                            border: Border.all(
                              color: !isExpense ? Colors.green : Colors.grey[300]!,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_downward,
                                color: !isExpense ? Colors.green : Colors.grey[600],
                                size: 18,
        ),
                              const SizedBox(width: 8),
                              Text(
                                'Income',
                                style: TextStyle(
                                  color: !isExpense ? Colors.green : Colors.grey[600],
                                  fontWeight: !isExpense ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              if (!isExpense)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Icon(
                                    Icons.check_circle,
          color: Colors.green,
                                    size: 16,
                                  ),
        ),
      ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        // Validate inputs - only amount is required
                        if (amountController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter an amount')),
                          );
                          return;
                        }
                        
                        // Add the entry
                        setState(() {
                          // Get current date formatted nicely
                          final now = DateTime.now();
                          final formattedDate = "${now.day} ${_getMonthName(now.month)}, ${now.year}";
                          
                          _cards[cardIndex]['entries'].add({
                            'description': descriptionController.text.isEmpty ? 
                                (isExpense ? 'Expense' : 'Income') : descriptionController.text,
                            'amount': '₹${amountController.text}',
                            'date': formattedDate,
                            'isExpense': isExpense,
                          });
                          
                          // Select this card
                          _selectedCardIndex = cardIndex;
                        });
                        
                        Navigator.pop(context);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Entry added successfully')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: card['color'],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
                      ),
                      child: const Text(
                        'Add Entry',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  void _showAddCardDialog() {
    final TextEditingController bankController = TextEditingController();
    final TextEditingController cardTypeController = TextEditingController(text: 'Credit Card');
    final TextEditingController cardNumberController = TextEditingController();
    final TextEditingController holderNameController = TextEditingController();
    final TextEditingController expiryController = TextEditingController();
    final TextEditingController cvvController = TextEditingController();
    final TextEditingController balanceController = TextEditingController();
    final TextEditingController limitController = TextEditingController();
    final TextEditingController dueDateController = TextEditingController();
    
    Color selectedColor = Colors.blue;
    List<Color> availableColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Card'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: bankController,
                  decoration: const InputDecoration(
                    labelText: 'Bank Name',
                    hintText: 'e.g. HDFC Bank',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: cardTypeController.text,
                  decoration: const InputDecoration(labelText: 'Card Type'),
                  items: const [
                    DropdownMenuItem(value: 'Credit Card', child: Text('Credit Card')),
                    DropdownMenuItem(value: 'Debit Card', child: Text('Debit Card')),
                  ],
                  onChanged: (value) {
                    cardTypeController.text = value!;
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cardNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Card Number',
                    hintText: 'XXXX XXXX XXXX XXXX',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 19,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: holderNameController,
                  decoration: const InputDecoration(
                    labelText: 'Card Holder Name',
                    hintText: 'e.g. JOHN DOE',
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: expiryController,
                  decoration: const InputDecoration(
                    labelText: 'Expiry Date',
                    hintText: 'MM/YY',
                  ),
                  keyboardType: TextInputType.datetime,
                  maxLength: 5,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cvvController,
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    hintText: '123',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: balanceController,
                  decoration: const InputDecoration(
                    labelText: 'Current Balance',
                    hintText: 'e.g. ₹10,000',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: limitController,
                  decoration: InputDecoration(
                    labelText: cardTypeController.text == 'Credit Card' ? 'Credit Limit' : 'Daily Limit',
                    hintText: 'e.g. ₹50,000',
                  ),
                  keyboardType: TextInputType.number,
                ),
                if (cardTypeController.text == 'Credit Card') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: dueDateController,
                    decoration: const InputDecoration(
                      labelText: 'Due Date',
                      hintText: 'e.g. 15 May 2025',
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text('Card Color'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: availableColors.map((color) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: selectedColor == color
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                          boxShadow: selectedColor == color
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 5,
                                    spreadRadius: 1,
                                  )
                                ]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Validate inputs
                if (bankController.text.isEmpty ||
                    cardNumberController.text.isEmpty ||
                    holderNameController.text.isEmpty ||
                    expiryController.text.isEmpty ||
                    cvvController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all required fields')),
                  );
                  return;
                }
                
                // Format card number for display
                String formattedCardNumber = cardNumberController.text;
                
                // Add the new card
                setState(() {
                  _cards.add({
                    'bank': bankController.text,
                    'cardType': cardTypeController.text,
                    'cardNumber': formattedCardNumber,
                    'holderName': holderNameController.text.toUpperCase(),
                    'expiry': expiryController.text,
                    'cvv': cvvController.text,
                    'color': selectedColor,
                    'logo': 'assets/bank_logo.png', // Default logo
                    'balance': balanceController.text.isEmpty 
                        ? '₹0' 
                        : '₹${balanceController.text}',
                    'limit': limitController.text.isEmpty 
                        ? cardTypeController.text == 'Credit Card' ? '₹0' : 'N/A' 
                        : '₹${limitController.text}',
                    'dueDate': dueDateController.text.isEmpty 
                        ? 'N/A' 
                        : dueDateController.text,
                    'entries': [],
                  });
                  
                  // Select the newly added card
                  _selectedCardIndex = _cards.length - 1;
                });
                
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Card added successfully')),
                );
              },
              child: const Text('Add Card'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCardDialog(int cardIndex) {
    final card = _cards[cardIndex];
    
    final TextEditingController bankController = TextEditingController(text: card['bank']);
    final TextEditingController cardTypeController = TextEditingController(text: card['cardType']);
    final TextEditingController cardNumberController = TextEditingController(text: card['cardNumber']);
    final TextEditingController holderNameController = TextEditingController(text: card['holderName']);
    final TextEditingController expiryController = TextEditingController(text: card['expiry']);
    final TextEditingController cvvController = TextEditingController(text: card['cvv']);
    
    // Remove the "₹" symbol and format for controllers
    String balanceValue = card['balance'].toString().replaceAll('₹', '').trim();
    String limitValue = card['limit'].toString().replaceAll('₹', '').trim();
    
    final TextEditingController balanceController = TextEditingController(text: balanceValue);
    final TextEditingController limitController = TextEditingController(text: limitValue == 'N/A' ? '' : limitValue);
    final TextEditingController dueDateController = TextEditingController(
      text: card['dueDate'] != 'N/A' ? card['dueDate'] : '',
    );
    
    Color selectedColor = card['color'];
    List<Color> availableColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Card'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: bankController,
                  decoration: const InputDecoration(
                    labelText: 'Bank Name',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: cardTypeController.text,
                  decoration: const InputDecoration(labelText: 'Card Type'),
                  items: const [
                    DropdownMenuItem(value: 'Credit Card', child: Text('Credit Card')),
                    DropdownMenuItem(value: 'Debit Card', child: Text('Debit Card')),
                  ],
                  onChanged: (value) {
                    cardTypeController.text = value!;
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cardNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Card Number',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 19,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: holderNameController,
                  decoration: const InputDecoration(
                    labelText: 'Card Holder Name',
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: expiryController,
                  decoration: const InputDecoration(
                    labelText: 'Expiry Date',
                    hintText: 'MM/YY',
                  ),
                  keyboardType: TextInputType.datetime,
                  maxLength: 5,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cvvController,
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: balanceController,
                  decoration: const InputDecoration(
                    labelText: 'Current Balance',
                    prefixText: '₹ ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: limitController,
                  decoration: InputDecoration(
                    labelText: cardTypeController.text == 'Credit Card' ? 'Credit Limit' : 'Daily Limit',
                    prefixText: limitValue == 'N/A' ? '' : '₹ ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                if (cardTypeController.text == 'Credit Card') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: dueDateController,
                    decoration: const InputDecoration(
                      labelText: 'Due Date',
                      hintText: 'e.g. 15 May 2025',
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text('Card Color'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: availableColors.map((color) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: selectedColor.value == color.value
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                          boxShadow: selectedColor.value == color.value
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 5,
                                    spreadRadius: 1,
                                  )
                                ]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Validate inputs
                if (bankController.text.isEmpty ||
                    holderNameController.text.isEmpty ||
                    expiryController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all required fields')),
                  );
                  return;
                }
                
                // Update the card
                setState(() {
                  _cards[cardIndex] = {
                    'bank': bankController.text,
                    'cardType': cardTypeController.text,
                    'cardNumber': cardNumberController.text,
                    'holderName': holderNameController.text.toUpperCase(),
                    'expiry': expiryController.text,
                    'cvv': cvvController.text,
                    'color': selectedColor,
                    'logo': card['logo'], // Keep the existing logo
                    'balance': balanceController.text.isEmpty 
                        ? '₹0' 
                        : '₹${balanceController.text}',
                    'limit': limitController.text.isEmpty 
                        ? cardTypeController.text == 'Credit Card' ? '₹0' : 'N/A' 
                        : '₹${limitController.text}',
                    'dueDate': dueDateController.text.isEmpty 
                        ? 'N/A' 
                        : dueDateController.text,
                    'entries': card['entries'],
                  };
                });
                
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Card updated successfully')),
                );
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteCardConfirmation(int cardIndex) {
    final card = _cards[cardIndex];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Card'),
        content: Text(
          'Are you sure you want to delete your ${card['bank']} ${card['cardType']}?\n\n'
          'This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _cards.removeAt(cardIndex);
                
                // Update selected index if needed
                if (_cards.isEmpty) {
                  _selectedCardIndex = 0;
                } else if (_selectedCardIndex >= _cards.length) {
                  _selectedCardIndex = _cards.length - 1;
                }
              });
              
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Card deleted successfully')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
