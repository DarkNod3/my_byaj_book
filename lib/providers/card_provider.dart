import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CardProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _cards = [];
  bool _isLoading = true;
  int _selectedCardIndex = 0;

  List<Map<String, dynamic>> get cards => _cards;
  bool get isLoading => _isLoading;
  int get selectedCardIndex => _selectedCardIndex;

  CardProvider() {
    loadCards();
  }

  // Load saved cards from SharedPreferences
  Future<void> loadCards() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final cardsJson = prefs.getString('cards');
      
      if (cardsJson != null) {
        final List<dynamic> decodedCards = jsonDecode(cardsJson);
        
        _cards = [];
        for (var card in decodedCards) {
          // Convert color from int value to Color object
          final Map<String, dynamic> cardMap = Map<String, dynamic>.from(card);
          cardMap['color'] = Color(cardMap['color']);
          _cards.add(cardMap);
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save cards to SharedPreferences
  Future<void> saveCards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert cards to a serializable format
      final List<Map<String, dynamic>> serializableCards = _cards.map((card) {
        final Map<String, dynamic> serializedCard = Map<String, dynamic>.from(card);
        // Convert Color to int value for storage
        serializedCard['color'] = (card['color'] as Color).value;
        return serializedCard;
      }).toList();
      
      final String cardsJson = jsonEncode(serializableCards);
      await prefs.setString('cards', cardsJson);
    } catch (e) {
      // Removed debug print
    }
  }

  // Add a new card
  Future<void> addCard(Map<String, dynamic> card) async {
    _cards.add(card);
    _selectedCardIndex = _cards.length - 1;
    notifyListeners();
    await saveCards();
  }

  // Update an existing card
  Future<void> updateCard(int index, Map<String, dynamic> updatedCard) async {
    if (index >= 0 && index < _cards.length) {
      _cards[index] = updatedCard;
      notifyListeners();
      await saveCards();
    }
  }

  // Delete a card
  Future<void> deleteCard(int index) async {
    if (index >= 0 && index < _cards.length) {
      // Remove card from memory
      _cards.removeAt(index);
      
      // Update selected index if needed
      if (_cards.isEmpty) {
        _selectedCardIndex = 0;
      } else if (_selectedCardIndex >= _cards.length) {
        _selectedCardIndex = _cards.length - 1;
      }
      
      // Save immediately to ensure deletion is persisted
      await saveCards();
      
      notifyListeners();
    }
  }

  // Add entry to a card
  Future<void> addEntry(int cardIndex, Map<String, dynamic> entry) async {
    if (cardIndex >= 0 && cardIndex < _cards.length) {
      if (!_cards[cardIndex].containsKey('entries')) {
        _cards[cardIndex]['entries'] = [];
      }
      
      _cards[cardIndex]['entries'].add(entry);
      _selectedCardIndex = cardIndex;
      notifyListeners();
      await saveCards();
    }
  }

  // Delete entry from a card and update the card's balance
  Future<void> deleteEntry(int cardIndex, int entryIndex, Map<String, dynamic> updatedCard) async {
    if (cardIndex >= 0 && cardIndex < _cards.length) {
      if (_cards[cardIndex].containsKey('entries')) {
        List entries = _cards[cardIndex]['entries'];
        if (entryIndex >= 0 && entryIndex < entries.length) {
          // Remove the entry from memory
          entries.removeAt(entryIndex);
          
          // Update the card with adjusted balance
          _cards[cardIndex] = updatedCard;
          
          // Save immediately to ensure deletion is persisted
          await saveCards();
          
          notifyListeners();
        }
      }
    }
  }

  // Set selected card index
  void setSelectedCardIndex(int index) {
    if (index >= 0 && index < _cards.length) {
      _selectedCardIndex = index;
      notifyListeners();
    }
  }

  // Calculate summary data for all cards
  Map<String, dynamic> calculateCardsSummary() {
    int totalCards = _cards.length;
    double totalCreditLimit = 0.0;
    double totalAmountUsed = 0.0;
    double totalAmountDue = 0.0;
    
    for (var card in _cards) {
      if (card['cardType'] == 'Credit Card') {
        // Extract numeric values from limit (removing '₹' and commas)
        String limitStr = card['limit'].toString().replaceAll('₹', '').replaceAll(',', '').trim();
        double limit = double.tryParse(limitStr) ?? 0.0;
        totalCreditLimit += limit;
        
        // Extract numeric values from balance (removing '₹' and commas)
        String balanceStr = card['balance'].toString().replaceAll('₹', '').replaceAll(',', '').trim();
        double balance = double.tryParse(balanceStr) ?? 0.0;
        totalAmountUsed += balance;
      }
    }
    
    // Calculate amount left (available credit)
    double availableCredit = totalCreditLimit - totalAmountUsed;
    if (availableCredit < 0) availableCredit = 0;
    
    // For simplicity, treating the total balance on credit cards as the amount due
    totalAmountDue = totalAmountUsed;
    
    return {
      'totalCards': totalCards,
      'totalCreditLimit': totalCreditLimit,
      'availableCredit': availableCredit,
      'totalAmountDue': totalAmountDue,
    };
  }

  // Debug method to check persisted cards
  Future<void> _printSavedCards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cardsJson = prefs.getString('cards');
      // Removed debug print
    } catch (e) {
      // Removed debug print
    }
  }
} 