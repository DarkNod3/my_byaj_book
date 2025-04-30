import 'package:flutter/material.dart';

class CardScreen extends StatefulWidget {
  const CardScreen({super.key});

  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  int _selectedCardIndex = 0;
  
  final List<Map<String, dynamic>> _cards = [
    {
      'bank': 'HDFC Bank',
      'cardType': 'Credit Card',
      'cardNumber': '**** **** **** 1234',
      'holderName': 'JOHN DOE',
      'expiry': '12/26',
      'color': Colors.blue,
      'logo': 'assets/hdfc_logo.png', // Would need actual asset
      'balance': '₹27,500',
      'limit': '₹1,00,000',
      'dueDate': '28 May 2025',
    },
    {
      'bank': 'ICICI Bank',
      'cardType': 'Credit Card',
      'cardNumber': '**** **** **** 5678',
      'holderName': 'JOHN DOE',
      'expiry': '10/27',
      'color': Colors.orange,
      'logo': 'assets/icici_logo.png', // Would need actual asset
      'balance': '₹12,800',
      'limit': '₹75,000',
      'dueDate': '15 May 2025',
    },
    {
      'bank': 'SBI Bank',
      'cardType': 'Debit Card',
      'cardNumber': '**** **** **** 9012',
      'holderName': 'JOHN DOE',
      'expiry': '05/28',
      'color': Colors.green,
      'logo': 'assets/sbi_logo.png', // Would need actual asset
      'balance': '₹45,300',
      'limit': 'N/A',
      'dueDate': 'N/A',
    },
  ];

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
            _buildCardCarousel(),
            const SizedBox(height: 24),
            _buildCardDetails(),
            const SizedBox(height: 24),
            _buildRecentTransactions(),
          ],
        ),
      ),
    );
  }

  Widget _buildCardCarousel() {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.9),
        onPageChanged: (index) {
          setState(() {
            _selectedCardIndex = index;
          });
        },
        itemCount: _cards.length,
        itemBuilder: (context, index) {
          final card = _cards[index];
          return _buildCard(card, index == _selectedCardIndex);
        },
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> card, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: isActive ? 0 : 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            card['color'],
            card['color'].withOpacity(0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: card['color'].withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                Text(
                  card['cardType'],
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              card['cardNumber'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                letterSpacing: 2,
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
    );
  }

  Widget _buildCardDetails() {
    final card = _cards[_selectedCardIndex];
    final isDebit = card['cardType'] == 'Debit Card';
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isDebit ? 'Account Details' : 'Card Summary',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                PopupMenuButton(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditCardDialog(_selectedCardIndex);
                    } else if (value == 'delete') {
                      _showDeleteCardConfirmation(_selectedCardIndex);
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
                  icon: const Icon(Icons.more_vert),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailItem(
                  title: isDebit ? 'Account Balance' : 'Outstanding Balance',
                  value: card['balance'],
                  icon: Icons.account_balance_wallet,
                  color: isDebit ? Colors.green : Colors.red,
                ),
                _buildDetailItem(
                  title: isDebit ? 'Daily Limit' : 'Credit Limit',
                  value: card['limit'],
                  icon: Icons.credit_score,
                  color: Colors.blue,
                ),
                _buildDetailItem(
                  title: isDebit ? 'Card Status' : 'Due Date',
                  value: isDebit ? 'Active' : card['dueDate'],
                  icon: isDebit ? Icons.check_circle : Icons.calendar_today,
                  color: isDebit ? Colors.green : Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!isDebit) ...[
              LinearProgressIndicator(
                value: 0.4, // This would be calculated: outstanding/limit
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(card['color']),
                minHeight: 6,
              ),
              const SizedBox(height: 8),
              Text(
                '40% of credit limit used',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  label: isDebit ? 'Transfer' : 'Pay Bill',
                  icon: isDebit ? Icons.swap_horiz : Icons.payment,
                  onTap: () {},
                ),
                _buildActionButton(
                  label: 'Statements',
                  icon: Icons.receipt_long,
                  onTap: () {},
                ),
                _buildActionButton(
                  label: 'Rewards',
                  icon: Icons.card_giftcard,
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
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
          size: 28,
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
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // View all transactions
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTransactionItem(
          title: 'Amazon Shopping',
          subtitle: 'Online Shopping',
          amount: '₹3,450',
          date: '21 Apr, 2025',
          icon: Icons.shopping_bag,
          color: Colors.blue,
        ),
        _buildTransactionItem(
          title: 'Cafe Coffee Day',
          subtitle: 'Food & Beverages',
          amount: '₹280',
          date: '20 Apr, 2025',
          icon: Icons.local_cafe,
          color: Colors.orange,
        ),
        _buildTransactionItem(
          title: 'Movie Tickets',
          subtitle: 'Entertainment',
          amount: '₹500',
          date: '18 Apr, 2025',
          icon: Icons.movie,
          color: Colors.purple,
        ),
        _buildTransactionItem(
          title: 'Fuel Refill',
          subtitle: 'Transportation',
          amount: '₹1,200',
          date: '15 Apr, 2025',
          icon: Icons.local_gas_station,
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildTransactionItem({
    required String title,
    required String subtitle,
    required String amount,
    required String date,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        title: Text(title),
        subtitle: Text(
          '$subtitle • $date',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: Text(
          amount,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showAddCardDialog() {
    final TextEditingController bankController = TextEditingController();
    final TextEditingController cardTypeController = TextEditingController(text: 'Credit Card');
    final TextEditingController cardNumberController = TextEditingController();
    final TextEditingController holderNameController = TextEditingController();
    final TextEditingController expiryController = TextEditingController();
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
                    expiryController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all required fields')),
                  );
                  return;
                }
                
                // Format card number
                String formattedCardNumber = '**** **** **** ' + 
                    cardNumberController.text.replaceAll(' ', '').substring(
                      cardNumberController.text.length > 4 
                          ? cardNumberController.text.length - 4 
                          : 0
                    );
                
                // Add the new card
                setState(() {
                  _cards.add({
                    'bank': bankController.text,
                    'cardType': cardTypeController.text,
                    'cardNumber': formattedCardNumber,
                    'holderName': holderNameController.text.toUpperCase(),
                    'expiry': expiryController.text,
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
                  readOnly: true, // For security, don't allow editing full card number
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
