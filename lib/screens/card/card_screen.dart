import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/card_provider.dart';
import '../../main.dart' show notificationService;

class CardScreen extends StatefulWidget {
  static const routeName = '/cards';
  final bool showAppBar;
  
  const CardScreen({
    super.key, 
    this.showAppBar = false,
  });

  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  @override
  void initState() {
    super.initState();
    
    // Get the provider reference outside of the Future
    final cardProvider = Provider.of<CardProvider>(context, listen: false);
    
    // Add this call to convert any existing income transactions
    Future.delayed(Duration.zero, () {
      _initializeCardData();
      
      // Schedule notifications for card due dates
      notificationService.scheduleCardDueNotifications(cardProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CardProvider>(
      builder: (context, cardProvider, _) {
        final content = SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show summary card if we have cards and not loading
                if (!cardProvider.isLoading && cardProvider.cards.isNotEmpty) ...[
                  _buildCardsSummary(),
                  const SizedBox(height: 24),
                ],
                
                // Your Cards heading
                Text(
                  'Your Cards',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                const SizedBox(height: 16),
                
                cardProvider.isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : cardProvider.cards.isEmpty
                        ? _buildEmptyCardState()
                        : _buildVerticalCardList(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
        
        // Return the content wrapped in Scaffold if showAppBar is true
        if (widget.showAppBar) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Cards'),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            body: content,
          );
        }
        
        // Otherwise just return the content for use in the tab view
        return content;
      }
    );
  }

  // Widget to display card summary
  Widget _buildCardsSummary() {
    final cardProvider = Provider.of<CardProvider>(context, listen: false);
    final summaryData = cardProvider.calculateCardsSummary();
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade700,
              Colors.blue.shade500,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cards Summary',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddCardDialog,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add Card'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSummaryCardItem(
                  title: 'Total Cards',
                  value: '${summaryData['totalCards']}',
                  icon: Icons.credit_card,
                ),
                _buildSummaryCardItem(
                  title: 'Credit Limit',
                  value: '₹${summaryData['totalCreditLimit'].toStringAsFixed(0)}',
                  icon: Icons.account_balance_wallet,
                ),
                _buildSummaryCardItem(
                  title: 'Remaining',
                  value: '₹${summaryData['availableCredit'].toStringAsFixed(0)}',
                  icon: Icons.savings,
                ),
                _buildSummaryCardItem(
                  title: 'Amount Due',
                  value: '₹${summaryData['totalAmountDue'].toStringAsFixed(0)}',
                  icon: Icons.warning_amber_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCardItem({required String title, required String value, required IconData icon}) {
    return Flexible(
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalCardList() {
    final cardProvider = Provider.of<CardProvider>(context, listen: false);
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cardProvider.cards.length,
      itemBuilder: (context, index) {
        final card = cardProvider.cards[index];
        final isSelected = index == cardProvider.selectedCardIndex;
        
        // Calculate the percentage for progress bar
        double percentUsed = 0.0;
        if (card['limit'] != 'N/A') {
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
            cardProvider.setSelectedCardIndex(index);
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
                  // Card header with gradient
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
                          card['color'].withOpacity(0.85),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: card['color'].withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
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
                  // Card body with details
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
                                  'Due Amount',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  card['balance'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                // Add due date display
                                if (card['dueDate'] != null && card['dueDate'] != 'N/A') ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.event,
                                        size: 12,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Due: ${card['dueDate']}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[800],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                            Column(
                              children: [
                                // Add Entry button
                                ElevatedButton(
                                  onPressed: () => _showAddEntryDialog(index),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: card['color'].withOpacity(0.1),
                                    foregroundColor: card['color'],
                                  ),
                                  child: const Text('Add Entry'),
                                ),
                                const SizedBox(height: 8),
                                // View Details button
                                TextButton.icon(
                                  onPressed: () => _showCardDetails(index),
                                  icon: const Icon(Icons.history),
                                  label: const Text('View Details'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: card['color'],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        // Add progress bar for credit limit
                        if (card['limit'] != 'N/A') ...[
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
                              percentUsed > 0.75 ? Colors.red : card['color'].withOpacity(0.5)
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

  void _showAddCardDialog() {
    final TextEditingController bankController = TextEditingController();
    final TextEditingController cardTypeController = TextEditingController(text: 'Credit Card');
    final TextEditingController cardNumberController = TextEditingController();
    final TextEditingController holderNameController = TextEditingController();
    final TextEditingController expiryController = TextEditingController();
    final TextEditingController cvvController = TextEditingController();
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
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
                        color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
            ),
          ),
                      child: Column(
      children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                    color: selectedColor.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                          ),
                          child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                        'Add New Card',
                                style: TextStyle(
                          fontSize: 20,
                    fontWeight: FontWeight.bold,
                          color: selectedColor,
                                  ),
            ),
                IconButton(
                        icon: Icon(Icons.close, color: selectedColor),
                      onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
                ),
                
                // Form fields in a scrollable container
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
            child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                        // Bank Name
                TextField(
                  controller: bankController,
                          decoration: InputDecoration(
                    labelText: 'Bank Name',
                    hintText: 'e.g. HDFC Bank',
                            prefixIcon: Icon(Icons.account_balance, color: selectedColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: selectedColor, width: 2),
                            ),
                  ),
                ),
                        const SizedBox(height: 16),
                        
                        // Card Type
                TextField(
                  controller: cardTypeController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Card Type',
                    prefixIcon: Icon(Icons.credit_card, color: selectedColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: selectedColor, width: 2),
                    ),
                  ),
                ),
                        const SizedBox(height: 16),
                        
                        // Card Number
                TextField(
                  controller: cardNumberController,
                          decoration: InputDecoration(
                    labelText: 'Card Number',
                    hintText: 'XXXX XXXX XXXX XXXX',
                            prefixIcon: Icon(Icons.credit_card, color: selectedColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: selectedColor, width: 2),
                            ),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 19,
                ),
                        const SizedBox(height: 8),
                        
                        // Card Holder Name
                TextField(
                  controller: holderNameController,
                          decoration: InputDecoration(
                    labelText: 'Card Holder Name',
                    hintText: 'e.g. JOHN DOE',
                            prefixIcon: Icon(Icons.person, color: selectedColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: selectedColor, width: 2),
                            ),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                        const SizedBox(height: 16),
                        
                        // Two fields in a row: Expiry Date and CVV
                        Row(
                          children: [
                            // Expiry Date
                            Expanded(
                              flex: 3,
                              child: TextField(
                  controller: expiryController,
                                decoration: InputDecoration(
                    labelText: 'Expiry Date',
                    hintText: 'MM/YY',
                                  prefixIcon: Icon(Icons.calendar_month, color: selectedColor),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: selectedColor, width: 2),
                                  ),
                                ),
                                readOnly: true,
                                onTap: () async {
                                  await _showMonthYearPicker(context, expiryController, selectedColor);
                                },
                              ),
                ),
                            const SizedBox(width: 12),
                            // CVV (Optional)
                            Expanded(
                              flex: 2,
                              child: TextField(
                  controller: cvvController,
                                decoration: InputDecoration(
                    labelText: 'CVV (Optional)',
                    hintText: '123',
                                  prefixIcon: Icon(Icons.security, color: selectedColor),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: selectedColor, width: 2),
                                  ),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                  obscureText: true,
          ),
        ),
      ],
                        ),
                        const SizedBox(height: 8),
                        
                        // Credit Limit field (removed Current Balance)
                        TextField(
                  controller: limitController,
                  decoration: InputDecoration(
                    labelText: 'Credit Limit',
                                  hintText: 'e.g. 50000',
                                  prefixText: '₹ ',
                                  prefixIcon: Icon(Icons.credit_score, color: selectedColor),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: selectedColor, width: 2),
                                  ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                        const SizedBox(height: 16),
                        
                        // Due Date - clickable field to select date
                TextField(
                    controller: dueDateController,
                            decoration: InputDecoration(
                      labelText: 'Due Date',
                      hintText: 'e.g. 15 May 2025',
                              prefixIcon: Icon(Icons.event, color: selectedColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: selectedColor, width: 2),
                              ),
                            ),
                            readOnly: true,
                            onTap: () async {
                              await _showDueDatePicker(context, dueDateController, selectedColor);
                            },
                ),
                
                const SizedBox(height: 20),
                
                        // Card Color Selection
                const Text(
                          'Card Color',
                  style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                const SizedBox(height: 8),
                        SizedBox(
                          height: 50,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: availableColors.length,
                            itemBuilder: (context, index) {
                              final color = availableColors[index];
                              final isSelected = selectedColor == color;
                              
                    return GestureDetector(
                        onTap: () {
                          setState(() {
                          selectedColor = color;
                          });
                        },
                        child: Container(
                                  width: 50,
                                  height: 50,
                                  margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                                    border: isSelected
                                        ? Border.all(color: Colors.white, width: 3)
                              : null,
                                    boxShadow: [
                                  BoxShadow(
                                        color: isSelected ? color.withOpacity(0.7) : color.withOpacity(0.4),
                                        blurRadius: 8,
                                        spreadRadius: isSelected ? 2 : 0,
            ),
          ],
        ),
                                  child: isSelected 
                                    ? const Icon(Icons.check, color: Colors.white) 
                                    : null,
                      ),
                    );
                            },
                                  ),
        ),
      ],
                          ),
                        ),
                      ),
                
                // Bottom action buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                    ),
                  ],
                ),
                  child: Row(
                  children: [
                      Expanded(
                        child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
            ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
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
                        
                // Format card number for display
                String formattedCardNumber = cardNumberController.text;
                
                            // Add the new card through the provider
                            final newCard = {
                              'bank': bankController.text,
                              'cardType': 'Credit Card',
                              'cardNumber': formattedCardNumber,
                              'holderName': holderNameController.text.toUpperCase(),
                              'expiry': expiryController.text,
                              'cvv': cvvController.text,
                              'color': selectedColor,
                              'logo': 'assets/bank_logo.png', // Default logo
                              'balance': '₹0', // Always set new card balance to 0
                              'limit': limitController.text.isEmpty 
                                  ? '₹0' 
                                  : '₹${limitController.text}',
                              'dueDate': dueDateController.text.isEmpty 
                                  ? 'N/A' 
                                  : dueDateController.text,
                              'entries': [],
                            };
                            
                            addCard(newCard);
                        Navigator.pop(context);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Card added successfully')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                            backgroundColor: selectedColor,
                        foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                          ),
                      ),
                      child: const Text(
                            'Add Card',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
              ],
        ),
          );
        },
      ),
    );
  }

  void _showEditCardDialog(int cardIndex) {
    final cardProvider = Provider.of<CardProvider>(context, listen: false);
    final card = cardProvider.cards[cardIndex];
    
    final TextEditingController bankController = TextEditingController(text: card['bank']);
    final TextEditingController cardTypeController = TextEditingController(text: card['cardType']);
    final TextEditingController cardNumberController = TextEditingController(text: card['cardNumber']);
    final TextEditingController holderNameController = TextEditingController(text: card['holderName']);
    final TextEditingController expiryController = TextEditingController(text: card['expiry']);
    final TextEditingController cvvController = TextEditingController(text: card['cvv']);
    
    // Remove the "₹" symbol and format for controllers
    String balanceValue = card['balance'].toString().replaceAll('₹', '').replaceAll(',', '').trim();
    String limitValue = card['limit'].toString().replaceAll('₹', '').replaceAll(',', '').trim();
    
    final TextEditingController balanceController = TextEditingController(text: balanceValue);
    final TextEditingController limitController = TextEditingController(text: limitValue == 'N/A' ? '' : limitValue);
    final TextEditingController dueDateController = TextEditingController(
      text: card['dueDate'] != null && card['dueDate'] != 'N/A' ? card['dueDate'] : '',
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
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: selectedColor.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Edit Card',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: selectedColor,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: selectedColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                
                // Form fields in a scrollable container
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bank Name
                        TextField(
                          controller: bankController,
                          decoration: InputDecoration(
                            labelText: 'Bank Name',
                            hintText: 'e.g. HDFC Bank',
                            prefixIcon: Icon(Icons.account_balance, color: selectedColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: selectedColor, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Card Type
                        TextField(
                          controller: cardTypeController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Card Type',
                            prefixIcon: Icon(Icons.credit_card, color: selectedColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: selectedColor, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Card Number
                        TextField(
                          controller: cardNumberController,
                          decoration: InputDecoration(
                            labelText: 'Card Number',
                            hintText: 'XXXX XXXX XXXX XXXX',
                            prefixIcon: Icon(Icons.credit_card, color: selectedColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: selectedColor, width: 2),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 19,
                        ),
                        const SizedBox(height: 8),
                        
                        // Card Holder Name
                        TextField(
                          controller: holderNameController,
                          decoration: InputDecoration(
                            labelText: 'Card Holder Name',
                            hintText: 'e.g. JOHN DOE',
                            prefixIcon: Icon(Icons.person, color: selectedColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: selectedColor, width: 2),
                            ),
                          ),
                          textCapitalization: TextCapitalization.characters,
                        ),
                        const SizedBox(height: 16),
                        
                        // Two fields in a row: Expiry Date and CVV
                        Row(
                          children: [
                            // Expiry Date
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: expiryController,
                                decoration: InputDecoration(
                                  labelText: 'Expiry Date',
                                  hintText: 'MM/YY',
                                  prefixIcon: Icon(Icons.calendar_month, color: selectedColor),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: selectedColor, width: 2),
                                  ),
                                ),
                                readOnly: true,
                                onTap: () async {
                                  await _showMonthYearPicker(context, expiryController, selectedColor);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            // CVV (Optional)
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: cvvController,
                                decoration: InputDecoration(
                                  labelText: 'CVV (Optional)',
                                  hintText: '123',
                                  prefixIcon: Icon(Icons.security, color: selectedColor),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: selectedColor, width: 2),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                maxLength: 3,
                                obscureText: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // Credit Limit field
                        TextField(
                          controller: limitController,
                          decoration: InputDecoration(
                            labelText: 'Credit Limit',
                            hintText: 'e.g. 50000',
                            prefixText: '₹ ',
                            prefixIcon: Icon(Icons.credit_score, color: selectedColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: selectedColor, width: 2),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        
                        // Due Date with date picker - clickable field to select date
                        TextField(
                          controller: dueDateController,
                          decoration: InputDecoration(
                            labelText: 'Due Date',
                            hintText: 'e.g. 15 May 2025',
                            prefixIcon: Icon(Icons.event, color: selectedColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: selectedColor, width: 2),
                            ),
                          ),
                          readOnly: true,
                          onTap: () async {
                            await _showDueDatePicker(context, dueDateController, selectedColor);
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Card Color Selection
                        const Text(
                          'Card Color',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 50,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: availableColors.length,
                            itemBuilder: (context, index) {
                              final color = availableColors[index];
                              final isSelected = selectedColor == color;
                              
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedColor = color;
                                  });
                                },
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: isSelected
                                        ? Border.all(color: Colors.white, width: 3)
                                        : null,
                                    boxShadow: [
                                      BoxShadow(
                                        color: isSelected ? color.withOpacity(0.7) : color.withOpacity(0.4),
                                        blurRadius: 8,
                                        spreadRadius: isSelected ? 2 : 0,
                                      ),
                                    ],
                                  ),
                                  child: isSelected 
                                    ? const Icon(Icons.check, color: Colors.white) 
                                    : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Bottom action buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                    ),
                  ],
                ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
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
                            
                            // Update the card using the provider
                            final updatedCard = {
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
                                ? '₹0' 
                                  : '₹${limitController.text}',
                              'dueDate': dueDateController.text.isEmpty 
                                  ? 'N/A' 
                                  : dueDateController.text,
                              'entries': card['entries'],
                            };
                              
                            updateCard(cardIndex, updatedCard);
                            Navigator.pop(context);
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Card updated successfully')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDeleteCardConfirmation(int cardIndex) {
    final cardProvider = Provider.of<CardProvider>(context, listen: false);
    final card = cardProvider.cards[cardIndex];
    
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
              // Delete using the provider
              cardProvider.deleteCard(cardIndex);
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

  void _showAddEntryDialog(int cardIndex) {
    final cardProvider = Provider.of<CardProvider>(context, listen: false);
    final card = cardProvider.cards[cardIndex];
    
    // Controllers for the form
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    final dateController = TextEditingController();
    bool isExpense = true;
    bool isPayment = false;
    
    // Set default date to today
    final now = DateTime.now();
    dateController.text = "${now.day} ${_getMonthName(now.month)}, ${now.year}";
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Header bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: card['color'].withAlpha(26),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                          Column(
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
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                
                // Form fields
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                          decoration: InputDecoration(
                            hintText: 'e.g. Grocery Shopping',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Date Field
                        const Text(
                          'Date',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                TextField(
                          controller: dateController,
                          readOnly: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.calendar_month, color: card['color']),
                              onPressed: () async {
                                // Parse current date from controller
                                DateTime initialDate = DateTime.now();
                                try {
                                  final parts = dateController.text.split(' ');
                                  final day = int.parse(parts[0]);
                                  final month = _getMonthNumber(parts[1].replaceAll(',', ''));
                                  final year = int.parse(parts[2]);
                                  initialDate = DateTime(year, month, day);
                                } catch (e) {
                                  // Use today if parsing fails
                                }
                                
                                final selectedDate = await showDatePicker(
                                  context: context,
                                  initialDate: initialDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now().add(const Duration(days: 1)),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: card['color'],
                                          onPrimary: Colors.white,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                
                                if (selectedDate != null) {
                                  setState(() {
                                    dateController.text = "${selectedDate.day} ${_getMonthName(selectedDate.month)}, ${selectedDate.year}";
                                  });
                                }
                              },
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                  decoration: InputDecoration(
                            prefixText: '₹ ',
                            hintText: '0.00',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                        
                        // Only show Expense and Payment options
                        RadioListTile<bool>(
                          title: const Row(
                            children: [
                              Icon(Icons.arrow_upward, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text('Expense'),
                            ],
                          ),
                          value: true,
                          groupValue: isExpense,
                          activeColor: Colors.red,
                          onChanged: (value) {
                            setState(() {
                              isExpense = true;
                              isPayment = false;
                            });
                          },
                        ),
                        if (card['cardType'] == 'Credit Card')
                          RadioListTile<bool>(
                            title: Row(
                              children: [
                                const Icon(Icons.payment, color: Colors.blue, size: 20),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Payment'),
                                    Text(
                                      'Reduces card balance',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            value: true,
                            groupValue: isPayment,
                            activeColor: Colors.blue,
                            onChanged: (value) {
                        setState(() {
                                isPayment = true;
                                isExpense = false;
                        });
                      },
                          ),
                      ],
                    ),
                  ),
                ),
                
                // Bottom action bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                                  BoxShadow(
                        color: Colors.grey.withAlpha(26),
                                    spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
              onPressed: () {
                            // Validate inputs - only amount is required
                            if (amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter an amount')),
                  );
                  return;
                }
                
                            // Get amount value
                            double amount = double.tryParse(amountController.text) ?? 0.0;
                            
                            // Update the card balance based on transaction type
                            if (isPayment) {
                              // Subtract the payment from the balance
                              double balance = double.tryParse(card['balance'].toString().replaceAll('₹', '').replaceAll(',', '').trim()) ?? 0.0;
                              double newBalance = balance - amount;
                              if (newBalance < 0) newBalance = 0; // Balance can't be negative
                              
                              // Set a default description if none provided
                              if (descriptionController.text.isEmpty) {
                                descriptionController.text = 'Card Payment';
                              }
                              
                              // Update the card with new balance
                              final updatedCard = Map<String, dynamic>.from(card);
                              updatedCard['balance'] = '₹${newBalance.toStringAsFixed(0)}';
                              cardProvider.updateCard(cardIndex, updatedCard);
                            } else if (isExpense) {
                              // Add the expense to the balance
                              double balance = double.tryParse(card['balance'].toString().replaceAll('₹', '').replaceAll(',', '').trim()) ?? 0.0;
                              double newBalance = balance + amount;
                              
                              // Set a default description if none provided
                              if (descriptionController.text.isEmpty) {
                                descriptionController.text = 'Card Expense';
                              }
                              
                              // Update the card with new balance
                              final updatedCard = Map<String, dynamic>.from(card);
                              updatedCard['balance'] = '₹${newBalance.toStringAsFixed(0)}';
                              cardProvider.updateCard(cardIndex, updatedCard);
                            }
                            
                            // Add entry through provider
                            cardProvider.addEntry(cardIndex, {
                              'description': descriptionController.text.isEmpty ? 
                                  (isPayment ? 'Card Payment' : 'Expense') : descriptionController.text,
                              'amount': '₹${amountController.text}',
                              'date': dateController.text,
                              'isExpense': isPayment ? false : isExpense,
                              'isPayment': isPayment,
                });
                
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isPayment ? 'Payment recorded successfully' : 'Expense added successfully'
                                ),
                                backgroundColor: isPayment ? Colors.blue : Colors.red,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPayment ? Colors.blue : Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            isPayment ? 'Make Payment' : 'Add Expense',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
            ),
          ],
        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Show detailed card history
  void _showCardDetails(int cardIndex) {
    final cardProvider = Provider.of<CardProvider>(context, listen: false);
    final card = cardProvider.cards[cardIndex];
    
    // Recalculate the balance before showing card details
    _recalculateCardBalance(cardIndex);
    
    final entries = card['entries'] as List? ?? [];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${card['bank']} Card History',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${entries.length} transactions',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Summary card - Removed Total Income, keeping only Total Expense and Total Payments
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        const Icon(
                          Icons.arrow_upward,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Total Expense',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          _calculateTotalIncomeExpense(entries, isExpense: true),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.grey[300],
                    ),
                    Column(
                      children: [
                        const Icon(
                          Icons.payment,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Total Payments',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          _calculateTotalPayments(entries),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Transactions list
            Expanded(
              child: entries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your card transactions will appear here',
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final reversedIndex = entries.length - 1 - index; // Show newest first
                      final entry = entries[reversedIndex];
                      final bool isPayment = entry['isPayment'] ?? false;
                      final bool isExpense = entry['isExpense'] ?? true;
                      
                      // Determine icon and color based on transaction type
                      IconData icon;
                      Color color;
                      
                      if (isPayment) {
                        icon = Icons.payment;
                        color = Colors.blue;
                      } else if (isExpense) {
                        icon = Icons.arrow_upward;
                        color = Colors.red;
                      } else {
                        icon = Icons.arrow_downward;
                        color = Colors.green;
                      }
                      
                      return Dismissible(
                        key: UniqueKey(),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          color: Colors.red,
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Confirm Delete"),
                                content: const Text(
                                  "Are you sure you want to delete this transaction? This action will also adjust your card balance."
        ),
        actions: [
          TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text("CANCEL"),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text(
                                      "DELETE",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        onDismissed: (direction) {
                          _deleteTransaction(cardIndex, reversedIndex);
                          // Close the bottom sheet after deletion if no more entries
                          if (entries.length <= 1) {
                            Navigator.pop(context);
                          }
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withAlpha(26),
                              child: Icon(icon, color: color),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entry['description'],
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Text(
                                  entry['amount'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              entry['date'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // Calculate total for payments
  String _calculateTotalPayments(List entries) {
    double total = 0.0;
    
    for (var entry in entries) {
      if (entry['isPayment'] == true) {
        // Parse amount from string like "₹1000"
        String amountStr = entry['amount'].toString().replaceAll('₹', '').replaceAll(',', '').trim();
        double amount = double.tryParse(amountStr) ?? 0.0;
        total += amount;
      }
    }
    
    return '₹${total.toStringAsFixed(0)}';
  }

  // Update any existing income transactions to be treated as expense reductions
  void _convertIncomeTransactions(int cardIndex) {
    final cardProvider = Provider.of<CardProvider>(context, listen: false);
    final card = cardProvider.cards[cardIndex];
    
    if (!card.containsKey('entries')) return;
    
    final entries = card['entries'] as List;
    bool hasChanges = false;
    
    // Check if there are any income transactions (not expenses and not payments)
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      if (entry['isExpense'] == false && entry['isPayment'] != true) {
        // Convert to payment transaction
        final updatedEntry = Map<String, dynamic>.from(entry);
        updatedEntry['isPayment'] = true;
        updatedEntry['description'] = 'Payment: ${entry['description']}';
        
        // Update the entry
        entries[i] = updatedEntry;
        hasChanges = true;
      }
    }
    
    // If changes were made, save the updated card
    if (hasChanges) {
      final updatedCard = Map<String, dynamic>.from(card);
      updatedCard['entries'] = entries;
      cardProvider.updateCard(cardIndex, updatedCard);
    }
  }
  
  // Call this method when viewing card details or when the card screen is loaded
  void _initializeCardData() {
    final cardProvider = Provider.of<CardProvider>(context, listen: false);
    if (cardProvider.cards.isEmpty) return;
    
    for (int i = 0; i < cardProvider.cards.length; i++) {
      _convertIncomeTransactions(i);
    }
  }

  // Add month/year picker for expiry date
  Future<void> _showMonthYearPicker(
    BuildContext context, 
    TextEditingController controller,
    Color themeColor,
  ) async {
    int selectedMonth = 1;
    int selectedYear = DateTime.now().year;
    
    // If controller already has a value, try to parse it
    if (controller.text.isNotEmpty) {
      final parts = controller.text.split('/');
      if (parts.length == 2) {
        selectedMonth = int.tryParse(parts[0]) ?? 1;
        
        // Year might be in YY format, convert to full year
        int yearValue = int.tryParse(parts[1]) ?? 0;
        if (yearValue < 100) {
          // Convert 2-digit year to 4-digit
          selectedYear = yearValue + 2000;
        } else {
          selectedYear = yearValue;
        }
      }
    }
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: themeColor.withAlpha(26),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Expiry Date',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: themeColor,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      // Month selector
                      Expanded(
                        child: ListView.builder(
                          itemCount: 12,
                          itemBuilder: (context, index) {
                            final month = index + 1;
                            final isSelected = month == selectedMonth;
                            
                            return GestureDetector(
                              onTap: () {
              setState(() {
                                  selectedMonth = month;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: isSelected ? themeColor.withAlpha(51) : Colors.transparent,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey[200]!,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    _getMonthName(month),
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? themeColor : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      // Year selector
                      Expanded(
                        child: ListView.builder(
                          itemCount: 20, // Show next 20 years
                          itemBuilder: (context, index) {
                            final year = DateTime.now().year + index;
                            final isSelected = year == selectedYear;
                            
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedYear = year;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: isSelected ? themeColor.withAlpha(51) : Colors.transparent,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey[200]!,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    year.toString(),
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? themeColor : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Confirm button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      // Format as MM/YY and set to controller
                      String monthStr = selectedMonth.toString().padLeft(2, '0');
                      String yearStr = (selectedYear % 100).toString().padLeft(2, '0');
                      controller.text = '$monthStr/$yearStr';
              Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Add date picker for due date
  Future<void> _showDueDatePicker(
    BuildContext context,
    TextEditingController controller,
    Color themeColor,
  ) async {
    DateTime initialDate = DateTime.now();
    
    // If controller has a value, try to parse it
    if (controller.text.isNotEmpty && controller.text != 'N/A') {
      try {
        List<String> parts = controller.text.split(' ');
        if (parts.length >= 3) {
          int day = int.tryParse(parts[0]) ?? 1;
          String monthName = parts[1];
          int month = _getMonthNumber(monthName);
          int year = int.tryParse(parts[2]) ?? DateTime.now().year;
          
          initialDate = DateTime(year, month, day);
        }
      } catch (e) {
        // Removed debug print
        // Continue with fallback logic
      }
    }
    
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: themeColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (selectedDate != null) {
      String formattedDate = "${selectedDate.day} ${_getMonthName(selectedDate.month)}, ${selectedDate.year}";
      controller.text = formattedDate;
      
      // Schedule notifications after due date changes
      // This will happen when the dialog is closed with the new date
    }
  }

  // Helper method to get month name from month number
  String _getMonthName(int month) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    if (month >= 1 && month <= 12) {
      return monthNames[month - 1];
    }
    return '';
  }
  
  // Helper method to get month number from name
  int _getMonthNumber(String monthName) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    int index = monthNames.indexOf(monthName);
    return index >= 0 ? index + 1 : 1;
  }

  // Missing summary item builder method
  // ignore: unused_element
  Widget _buildSummaryItem({
    required String title, 
    required String value, 
    required IconData icon, 
    required Color color
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
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // Missing income/expense calculator method
  String _calculateTotalIncomeExpense(List entries, {required bool isExpense}) {
    double total = 0.0;
    
    for (var entry in entries) {
      if (entry['isExpense'] == isExpense) {
        // Parse amount from string like "₹1000"
        String amountStr = entry['amount'].toString().replaceAll('₹', '').replaceAll(',', '').trim();
        double amount = double.tryParse(amountStr) ?? 0.0;
        total += amount;
      }
    }
    
    return '₹${total.toStringAsFixed(0)}';
  }

  // Add the empty card state method if it's missing
  Widget _buildEmptyCardState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.credit_card,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No cards added yet',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your cards will appear here once you add them',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
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

  // Add a method to recalculate the entire card balance from scratch
  void _recalculateCardBalance(int cardIndex) {
    final cardProvider = Provider.of<CardProvider>(context, listen: false);
    final card = cardProvider.cards[cardIndex];
    
    if (!card.containsKey('entries')) return;
    
    final entries = card['entries'] as List;
    
    // Start with a zero balance
    double newBalance = 0.0;
    
    // Calculate the balance based on all existing transactions
    for (var entry in entries) {
      final bool isExpense = entry['isExpense'] ?? true;
      final bool isPayment = entry['isPayment'] ?? false;
      
      // Extract amount from the entry
      String amountStr = entry['amount'].toString().replaceAll('₹', '').replaceAll(',', '').trim();
      double amount = double.tryParse(amountStr) ?? 0.0;
      
      if (isPayment) {
        // Payments reduce the balance
        newBalance -= amount;
      } else if (isExpense) {
        // Expenses increase the balance
        newBalance += amount;
      }
    }
    
    // Ensure balance isn't negative
    if (newBalance < 0) newBalance = 0;
    
    // Update the card with the recalculated balance
    final updatedCard = Map<String, dynamic>.from(card);
    updatedCard['balance'] = '₹${newBalance.toStringAsFixed(0)}';
    cardProvider.updateCard(cardIndex, updatedCard);
  }

  // Update the _deleteTransaction method
  void _deleteTransaction(int cardIndex, int entryIndex) {
    final cardProvider = Provider.of<CardProvider>(context, listen: false);
    final card = cardProvider.cards[cardIndex];
    final entries = card['entries'] as List;
    final entry = entries[entryIndex];
    
    // Store the entry for potential undo
    final deletedEntry = Map<String, dynamic>.from(entry);
    
    // Store original balance for undo
    final originalBalance = card['balance'];
    
    // Remove the entry
    final updatedCard = Map<String, dynamic>.from(card);
    cardProvider.deleteEntry(cardIndex, entryIndex, updatedCard);
    
    // If this was the last entry or if there will be no entries left
    if (entries.length <= 1) {
      // Reset balance when all transactions are deleted
      final resetCard = Map<String, dynamic>.from(cardProvider.cards[cardIndex]);
      resetCard['balance'] = '₹0';
      cardProvider.updateCard(cardIndex, resetCard);
    } else {
      // Recalculate the entire balance from all remaining transactions
      _recalculateCardBalance(cardIndex);
    }
    
    // Force UI refresh
    setState(() {});
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Transaction deleted'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            // Re-add the entry
            cardProvider.addEntry(cardIndex, deletedEntry);
            
            // If it was the only entry, restore original balance
            if (entries.length <= 1) {
              final revertedCard = Map<String, dynamic>.from(cardProvider.cards[cardIndex]);
              revertedCard['balance'] = originalBalance;
              cardProvider.updateCard(cardIndex, revertedCard);
            } else {
              // Otherwise recalculate
              _recalculateCardBalance(cardIndex);
            }
            
            // Force UI refresh
            setState(() {});
          },
        ),
      ),
    );
  }

  // Add a new card
  Future<void> addCard(Map<String, dynamic> card) async {
    final cardProvider = Provider.of<CardProvider>(context, listen: false);
    await cardProvider.addCard(card);
    
    // Update notifications after adding a card
    notificationService.scheduleCardDueNotifications(cardProvider);
  }

  // Update an existing card
  Future<void> updateCard(int index, Map<String, dynamic> updatedCard) async {
    final cardProvider = Provider.of<CardProvider>(context, listen: false);
    await cardProvider.updateCard(index, updatedCard);
    
    // Update notifications after editing a card
    notificationService.scheduleCardDueNotifications(cardProvider);
  }
}
