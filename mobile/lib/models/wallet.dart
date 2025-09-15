class Wallet {
  final String id;
  final String name;
  final String publicKey;
  final double balance;
  final DateTime createdAt;

  Wallet({
    required this.id,
    required this.name,
    required this.publicKey,
    required this.balance,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'publicKey': publicKey,
      'balance': balance,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'],
      name: json['name'],
      publicKey: json['publicKey'],
      balance: json['balance'].toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}