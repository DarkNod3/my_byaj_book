import 'dart:convert';

class CardNotification {
  final String cardId;
  final String action;

  CardNotification({
    required this.cardId,
    required this.action,
  });

  Map<String, dynamic> toMap() {
    return {
      'cardId': cardId,
      'action': action,
    };
  }

  factory CardNotification.fromMap(Map<String, dynamic> map) {
    return CardNotification(
      cardId: map['cardId'] ?? '',
      action: map['action'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory CardNotification.fromJson(String source) => 
      CardNotification.fromMap(json.decode(source));
} 