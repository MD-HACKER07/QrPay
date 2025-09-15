enum TransactionType { send, receive }
enum TransactionStatus { pending, completed, failed }

class Transaction {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String fromUpiId;
  final String toUpiId;
  final double amount;
  final String description;
  final TransactionType type;
  final TransactionStatus status;
  final DateTime timestamp;
  final String? signature;
  final String? txHash;
  final String? fromUserName;
  final String? toUserName;
  final String? fromUserPhoto;
  final String? toUserPhoto;

  Transaction({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.fromUpiId,
    required this.toUpiId,
    required this.amount,
    required this.description,
    required this.type,
    required this.status,
    required this.timestamp,
    this.signature,
    this.txHash,
    this.fromUserName,
    this.toUserName,
    this.fromUserPhoto,
    this.toUserPhoto,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'fromUpiId': fromUpiId,
      'toUpiId': toUpiId,
      'amount': amount,
      'description': description,
      'type': type.toString(),
      'status': status.toString(),
      'timestamp': timestamp.toIso8601String(),
      'signature': signature,
      'txHash': txHash,
      'fromUserName': fromUserName,
      'toUserName': toUserName,
      'fromUserPhoto': fromUserPhoto,
      'toUserPhoto': toUserPhoto,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      fromUserId: json['fromUserId'],
      toUserId: json['toUserId'],
      fromUpiId: json['fromUpiId'],
      toUpiId: json['toUpiId'],
      amount: json['amount'].toDouble(),
      description: json['description'],
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
      ),
      timestamp: DateTime.parse(json['timestamp']),
      signature: json['signature'],
      txHash: json['txHash'],
      fromUserName: json['fromUserName'],
      toUserName: json['toUserName'],
      fromUserPhoto: json['fromUserPhoto'],
      toUserPhoto: json['toUserPhoto'],
    );
  }
}