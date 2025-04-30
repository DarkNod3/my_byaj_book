import 'dart:convert';

class LoanNotification {
  final String loanId;
  final String action; // 'view_details' or 'mark_as_paid'
  
  LoanNotification({
    required this.loanId,
    required this.action,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'loanId': loanId,
      'action': action,
    };
  }
  
  factory LoanNotification.fromMap(Map<String, dynamic> map) {
    return LoanNotification(
      loanId: map['loanId'] as String,
      action: map['action'] as String,
    );
  }
  
  String toJson() => json.encode(toMap());
  
  factory LoanNotification.fromJson(String source) => 
      LoanNotification.fromMap(json.decode(source) as Map<String, dynamic>);
} 