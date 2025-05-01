import 'package:flutter/material.dart';

class CardScreen extends StatefulWidget {
  // Static route name for consistent navigation
  static const routeName = '/cards';
  
  final bool showAppBar;
  
  const CardScreen({
    super.key,
    this.showAppBar = false, // Default is false
  });

  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> with SingleTickerProviderStateMixin {
  int _selectedCardIndex = 0;
  late PageController _pageController;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    _tabController = TabController(length: _cards.length > 0 ? _cards.length : 1, vsync: this);
    
    _pageController.addListener(() {
      // Update tab controller when page changes
      if (_pageController.page != null) {
        _tabController.animateTo(_pageController.page!.round());
      }
    });
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  // Replace sample cards with an empty list
  final List<Map<String, dynamic>> _cards = [];
  
  // List to store transactions for each card
  final Map<String, List<Map<String, dynamic>>> _cardTransactions = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: widget.showAppBar ? AppBar(
        title: const Text('Cards'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              _showNotificationsWithDueDates();
            },
          ),
        ],
      ) : null,
      body: _cards.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.only(top: 16, bottom: 80),
              itemCount: _cards.length,
              itemBuilder: (context, index) {
                final card = _cards[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _buildVerticalCard(card, index),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCardDialog,
        child: const Icon(Icons.add_card),
        tooltip: 'Add Card',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Icon(
            Icons.credit_card_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Cards Added Yet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first card',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _showAddCardDialog,
            icon: const Icon(Icons.add_card),
            label: const Text('Add a Card'),
                  style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
      ),
    );
  }

  Widget _buildVerticalCard(Map<String, dynamic> card, int index) {
    bool isCredit = card['cardType'] == 'Credit Card';
    return GestureDetector(
      onTap: () {
          setState(() {
            _selectedCardIndex = index;
          });
        _showCardTransactions(card);
      },
      child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: card['color'].withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Card Display
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            card['color'],
            card['color'].withOpacity(0.7),
          ],
        ),
              ),
              child: Stack(
                children: [
                  // Background pattern
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.1,
                      child: CustomPaint(
                        painter: CardPatternPainter(),
                      ),
                    ),
                  ),
                  
                  // Card content
                  Padding(
                    padding: const EdgeInsets.all(16),
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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                  card['cardType'],
                  style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
                          _formatCardNumber(card['cardNumber']),
              style: const TextStyle(
                color: Colors.white,
                            fontSize: 16,
                letterSpacing: 2,
                            fontWeight: FontWeight.w500,
              ),
            ),
                        const SizedBox(height: 12),
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
                                    fontSize: 8,
                                    fontWeight: FontWeight.w500,
                      ),
                    ),
                                const SizedBox(height: 2),
                    Text(
                      card['holderName'],
                      style: const TextStyle(
                        color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
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
                                    fontSize: 8,
                                    fontWeight: FontWeight.w500,
                      ),
                    ),
                                const SizedBox(height: 2),
                    Text(
                      card['expiry'],
                      style: const TextStyle(
                        color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                  Icons.credit_card,
                  color: Colors.white,
                                size: 18,
                              ),
                ),
              ],
            ),
          ],
        ),
      ),
                  
                  // Card chip
                  Positioned(
                    top: 48,
                    left: 16,
                    child: Container(
                      width: 30,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.amber.shade300,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(3.0),
                        child: CustomPaint(
                          painter: ChipPainter(),
                        ),
                      ),
                    ),
                  ),
                  
                  // More options button for the card
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          _showCardOptions(context, index);
                        },
      child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Icon(
                            Icons.more_horiz,
                            color: Colors.white.withOpacity(0.8),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Card Summary Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                        isCredit ? 'Outstanding Balance' : 'Available Balance',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        card['balance'],
                        style: TextStyle(
                          fontSize: 18,
                    fontWeight: FontWeight.bold,
                          color: isCredit ? Colors.red[700] : Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (isCredit) ...[
                    Row(
                        children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Due Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                card['dueDate'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        ],
                      ),
                    ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                              Text(
                                'Credit Limit',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                card['limit'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                          ),
                ),
              ],
            ),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                            Text(
                              'Credit Utilization',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '${(card['utilization'] * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: _getUtilizationColor(card['utilization']),
                                fontWeight: FontWeight.bold,
                              ),
                ),
              ],
            ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: card['utilization'],
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(_getUtilizationColor(card['utilization'])),
                minHeight: 6,
              ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
              Text(
                          'Card Active',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Tap to View Transactions',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCardTransactions(Map<String, dynamic> card) {
    // Get the card ID or use bank name + card number as an ID
    final cardId = card['id'] ?? '${card['bank']}_${card['cardNumber']}';
    
    // Get transactions for this card, or initialize with empty list if none exist
    final transactions = _cardTransactions[cardId] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${card['bank']} Transactions',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Entry'),
                      onPressed: () => _showAddEntryDialog(card),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 60,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Transactions Yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add a new transaction to get started',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => _showAddEntryDialog(card),
                              icon: const Icon(Icons.add),
                              label: const Text('Add First Transaction'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          return _buildTransactionItem(
                            title: transaction['title'] as String,
                            subtitle: transaction['subtitle'] as String,
                            amount: transaction['amount'] as String,
                            date: transaction['date'] as String,
                            icon: transaction['icon'] as IconData,
                            color: transaction['color'] as Color,
                            onDelete: () => _deleteTransaction(card, index),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add a method to delete a transaction
  void _deleteTransaction(Map<String, dynamic> card, int index) {
    final cardId = card['id'] ?? '${card['bank']}_${card['cardNumber']}';
    
    setState(() {
      if (_cardTransactions.containsKey(cardId) && 
          _cardTransactions[cardId]!.length > index) {
        _cardTransactions[cardId]!.removeAt(index);
      }
    });
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transaction deleted'),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Show dialog to add a new entry to an existing card
  void _showAddEntryDialog(Map<String, dynamic> card) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    
    // Categories for the dropdown
    final List<Map<String, dynamic>> categories = [
      {'name': 'Shopping', 'icon': Icons.shopping_bag, 'color': Colors.blue},
      {'name': 'Food & Beverages', 'icon': Icons.restaurant, 'color': Colors.orange},
      {'name': 'Entertainment', 'icon': Icons.movie, 'color': Colors.purple},
      {'name': 'Travel', 'icon': Icons.flight, 'color': Colors.green},
      {'name': 'Bills & Utilities', 'icon': Icons.receipt, 'color': Colors.red},
      {'name': 'Others', 'icon': Icons.more_horiz, 'color': Colors.grey},
    ];
    
    String selectedCategory = categories[0]['name'] as String;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: card['color'].withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.credit_card, color: card['color']),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Transaction Entry',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          Text(
                            '${card['bank']} ${card['cardType']}',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Category'),
                const SizedBox(height: 8),
                Container(
                  height: 60,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: ButtonTheme(
                      alignedDropdown: true,
                      child: DropdownButton<String>(
                        value: selectedCategory,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down),
                        iconSize: 24,
                        elevation: 16,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedCategory = newValue;
                            });
                          }
                        },
                        items: categories.map((Map<String, dynamic> category) {
                          return DropdownMenuItem<String>(
                            value: category['name'] as String,
                            child: Row(
                              children: [
                                Icon(
                                  category['icon'] as IconData,
                                  color: category['color'] as Color,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(category['name'] as String),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (amountController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter an amount')),
                        );
                        return;
                      }
                      
                      // Get the selected category
                      final selectedCategoryData = categories.firstWhere(
                        (category) => category['name'] == selectedCategory,
                        orElse: () => categories[0],
                      );
                      
                      // Get the card ID or create one
                      final cardId = card['id'] ?? '${card['bank']}_${card['cardNumber']}';
                      
                      // Create a new transaction
                      final transaction = {
                        'title': descriptionController.text.isNotEmpty 
                            ? descriptionController.text 
                            : selectedCategory,
                        'subtitle': selectedCategory,
                        'amount': '₹${amountController.text}',
                        'date': _formatCurrentDate(),
                        'icon': selectedCategoryData['icon'] as IconData,
                        'color': selectedCategoryData['color'] as Color,
                        'timestamp': DateTime.now().millisecondsSinceEpoch,
                      };
                      
                      // Add the transaction to the card's transaction list
                      setState(() {
                        if (!_cardTransactions.containsKey(cardId)) {
                          _cardTransactions[cardId] = [];
                        }
                        _cardTransactions[cardId]!.insert(0, transaction);
                      });
                      
                      // Close the dialog
                      Navigator.pop(context);
                      
                      // Update the main screen state
                      this.setState(() {});
                      
                      // Show confirmation
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added ₹${amountController.text} to ${card['bank']} ${card['cardType']}'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Save Transaction',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Format current date as "DD MMM" (e.g. "21 Apr")
  String _formatCurrentDate() {
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${now.day} ${months[now.month - 1]}';
  }

  Widget _buildTransactionItem({
    required String title,
    required String subtitle,
    required String amount,
    required String date,
    required IconData icon,
    required Color color,
    required VoidCallback onDelete,
  }) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        onDelete();
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 6,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amount,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationsWithDueDates() {
    // Filter cards with upcoming due dates
    final cardsWithDueDates = _cards.where((card) => 
      card['cardType'] == 'Credit Card' && 
      card['dueDate'] != 'N/A').toList();
    
    if (cardsWithDueDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No upcoming due dates'))
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      child: Column(
          mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.notifications, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 12),
                  Text(
                    'Upcoming Due Dates',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: cardsWithDueDates.length,
                itemBuilder: (context, index) {
                  final card = cardsWithDueDates[index];
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: card['color'].withOpacity(0.2),
                        shape: BoxShape.circle,
            ),
            child: Icon(
                        Icons.credit_card,
                        color: card['color'],
                      ),
                    ),
                    title: Text(card['bank'] + ' ' + card['cardType']),
                    subtitle: Text('Due Date: ' + card['dueDate']),
                    trailing: Text(
                      card['balance'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      // Find the index of this card in the original list
                      final originalIndex = _cards.indexWhere((c) => 
                        c['cardNumber'] == card['cardNumber']);
                      if (originalIndex >= 0) {
                        setState(() {
                          _selectedCardIndex = originalIndex;
                          _pageController.animateToPage(
                            originalIndex,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        });
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showCardOptions(BuildContext context, int cardIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit, color: Colors.blue),
              ),
              title: const Text('Edit Card'),
              onTap: () {
                Navigator.pop(context);
                _showEditCardDialog(cardIndex);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.block, color: Colors.orange),
              ),
              title: const Text('Block Card'),
              subtitle: const Text('Temporarily block this card'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete, color: Colors.red),
              ),
              title: const Text('Delete Card'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteCardConfirmation(cardIndex);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Color _getUtilizationColor(double utilization) {
    if (utilization < 0.3) return Colors.green;
    if (utilization < 0.6) return Colors.orange;
    return Colors.red;
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
                  onChanged: (value) {
                    // Format the card number as the user types
                    if (value.isNotEmpty) {
                      // Remove all non-digits
                      String digitsOnly = value.replaceAll(RegExp(r'\D'), '');
                      
                      // Format with spaces every 4 digits
                      String formatted = '';
                      for (int i = 0; i < digitsOnly.length; i++) {
                        if (i > 0 && i % 4 == 0) {
                          formatted += ' ';
                        }
                        formatted += digitsOnly[i];
                      }
                      
                      // Only update if different to avoid cursor jumping
                      if (formatted != value) {
                        cardNumberController.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(offset: formatted.length),
                        );
                      }
                    }
                  },
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                  controller: expiryController,
                  decoration: const InputDecoration(
                    labelText: 'Expiry Date',
                    hintText: 'MM/YY',
                  ),
                  keyboardType: TextInputType.datetime,
                  maxLength: 5,
                        onChanged: (value) {
                          // Format expiry date as MM/YY
                          if (value.length == 2 && !value.contains('/')) {
                            expiryController.text = '$value/';
                            expiryController.selection = TextSelection.fromPosition(
                              TextPosition(offset: expiryController.text.length),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: cvvController,
                        decoration: const InputDecoration(
                          labelText: 'CVV',
                          hintText: '123',
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 3,
                        obscureText: true,
                      ),
                    ),
                  ],
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
                
                // Get the card number
                String cardNumber = cardNumberController.text;
                
                // Add the new card
                setState(() {
                  _cards.add({
                    'bank': bankController.text,
                    'cardType': cardTypeController.text,
                    'cardNumber': cardNumber,  // Store full card number
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
                    'utilization': 0.0, // Assuming 0% utilization
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

  // Function to format card number for display
  String _formatCardNumber(String cardNumber) {
    // If it's already a formatted string with stars, return as is
    if (cardNumber.contains('*')) return cardNumber;
    
    // Remove any spaces
    String cleaned = cardNumber.replaceAll(' ', '');
    
    // Format with spaces for display
    String formatted = '';
    for (int i = 0; i < cleaned.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted += ' ';
      }
      formatted += cleaned[i];
    }
    
    return formatted;
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
                    'utilization': 0.0, // Assuming 0% utilization
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

// Custom painters for visual enhancement
class CardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Draw a pattern of circles
    for (int i = -1; i < 4; i++) {
      for (int j = -1; j < 3; j++) {
        final center = Offset(
          size.width * (i / 3),
          size.height * (j / 2),
        );
        canvas.drawCircle(center, size.width * 0.15, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    
    // Draw chip lines
    for (int i = 0; i < 4; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
    
    for (int i = 0; i < 5; i++) {
      final x = size.width * (i / 4);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
