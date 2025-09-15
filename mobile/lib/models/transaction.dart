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
      id: json['id'] ?? '',
      fromUserId: json['fromUserId'] ?? '',
      toUserId: json['toUserId'] ?? '',
      fromUpiId: json['fromUpiId'] ?? '',
      toUpiId: json['toUpiId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => TransactionType.send,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => TransactionStatus.pending,
      ),
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      signature: json['signature'],
      txHash: json['txHash'],
      fromUserName: json['fromUserName'],
      toUserName: json['toUserName'],
      fromUserPhoto: json['fromUserPhoto'],
      toUserPhoto: json['toUserPhoto'],
    );
  }

  Transaction copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    String? fromUpiId,
    String? toUpiId,
    double? amount,
    String? description,
    TransactionType? type,
    TransactionStatus? status,
    DateTime? timestamp,
    String? signature,
    String? txHash,
    String? fromUserName,
    String? toUserName,
    String? fromUserPhoto,
    String? toUserPhoto,
  }) {
    return Transaction(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      fromUpiId: fromUpiId ?? this.fromUpiId,
      toUpiId: toUpiId ?? this.toUpiId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      signature: signature ?? this.signature,
      txHash: txHash ?? this.txHash,
      fromUserName: fromUserName ?? this.fromUserName,
      toUserName: toUserName ?? this.toUserName,
      fromUserPhoto: fromUserPhoto ?? this.fromUserPhoto,
      toUserPhoto: toUserPhoto ?? this.toUserPhoto,
    );
  }
}