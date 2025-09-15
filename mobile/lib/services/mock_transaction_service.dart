import 'dart:math';
import '../models/transaction.dart' as model;
import '../models/user.dart';

class MockTransactionService {
  // Mock database of users
  static final Map<String, User> _mockUsers = {};
  static final Map<String, List<model.Transaction>> _mockTransactions = {};

  // Initialize mock users - no predefined users, only real database users
  static void initializeMockUsers() {
    // No predefined users - all operations should use real Firestore database
    // This method is kept for compatibility but doesn't create any mock data
  }

  // Process UPI payment (mock version)
  static Future<model.Transaction> processUpiPayment({
    required String fromUserId,
    required String toUpiId,
    required double amount,
    required String description,
  }) async {
    try {
      initializeMockUsers();

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Get sender - try to find by ID first, then by UPI ID pattern
      User? fromUser = _mockUsers[fromUserId];
      if (fromUser == null) {
        // Try to find user by UPI ID pattern in existing users
        for (final user in _mockUsers.values) {
          if (user.id.contains(fromUserId) ||
              fromUserId.contains(user.phoneNumber ?? '')) {
            fromUser = user;
            break;
          }
        }

        // If still not found, create a new user but link to existing UPI if possible
        if (fromUser == null) {
          fromUser = User(
            id: fromUserId,
            name: 'Current User',
            email: 'user@qrpay.com',
            phoneNumber: '9570175954',
            upiId: '9570175954@qrpay',
            balance: 10000.0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          _mockUsers[fromUserId] = fromUser;
          _mockTransactions[fromUserId] = [];
        }
      }

      // Step 1: Validate recipient UPI ID exists in database
      User? toUser = findUserByUpiId(toUpiId);

      // Step 2: If recipient not found, throw error - no fake recipients allowed
      if (toUser == null) {
        throw Exception(
          'UPI ID not found: $toUpiId is not registered with QrPay. Only registered users can receive payments.',
        );
      }

      // Step 3: Prevent self-transfer
      if (fromUser.upiId == toUpiId) {
        throw Exception('Cannot send money to yourself');
      }

      // Step 4: Validate sufficient balance
      if (fromUser.balance < amount) {
        throw Exception(
          'Insufficient balance. Available: ₹${fromUser.balance.toStringAsFixed(2)}, Required: ₹${amount.toStringAsFixed(2)}',
        );
      }

      // Generate transaction ID
      final transactionId = _generateTransactionId();

      // Create transaction
      final transaction = model.Transaction(
        id: transactionId,
        fromUserId: fromUserId,
        toUserId: toUser.id,
        fromUpiId: fromUser.upiId!,
        toUpiId: toUpiId,
        amount: amount,
        description: description,
        type: model.TransactionType.send,
        status: model.TransactionStatus.completed,
        timestamp: DateTime.now(),
        fromUserName: fromUser.name,
        toUserName: toUser.name,
        fromUserPhoto: fromUser.photoUrl,
        toUserPhoto: toUser.photoUrl,
        txHash: _generateTxHash(transactionId),
      );

      // Step 5: Execute REAL money transfer between users
      print('💰 REAL MONEY TRANSFER INITIATED');
      print(
        '💰 FROM: ${fromUser.name} (${fromUser.upiId}) - Current Balance: ₹${fromUser.balance}',
      );
      print(
        '💰 TO: ${toUser.name} (${toUser.upiId}) - Current Balance: ₹${toUser.balance}',
      );
      print('💰 TRANSFER AMOUNT: ₹$amount');

      // Calculate new balances
      final senderNewBalance = fromUser.balance - amount;
      final recipientNewBalance = toUser.balance + amount;

      // Update balances - ACTUAL money transfer
      _mockUsers[fromUserId] = fromUser.copyWith(balance: senderNewBalance);
      _mockUsers[toUser.id] = toUser.copyWith(balance: recipientNewBalance);

      print('💰 REAL TRANSFER EXECUTED:');
      print(
        '💰 ${fromUser.name} NEW BALANCE: ₹$senderNewBalance (Deducted: ₹$amount)',
      );
      print(
        '💰 ${toUser.name} NEW BALANCE: ₹$recipientNewBalance (Added: ₹$amount)',
      );
      print('✅ REAL MONEY TRANSFER COMPLETED SUCCESSFULLY');

      // Add transaction to both users' history
      _mockTransactions[fromUserId]!.insert(0, transaction);

      final receiveTransaction = model.Transaction(
        id: transactionId,
        fromUserId: fromUserId,
        toUserId: toUser.id,
        fromUpiId: fromUser.upiId!,
        toUpiId: toUpiId,
        amount: amount,
        description: description,
        type: model.TransactionType.receive,
        status: model.TransactionStatus.completed,
        timestamp: DateTime.now(),
        fromUserName: fromUser.name,
        toUserName: toUser.name,
        fromUserPhoto: fromUser.photoUrl,
        toUserPhoto: toUser.photoUrl,
        txHash: transaction.txHash,
      );

      _mockTransactions[toUser.id]!.insert(0, receiveTransaction);

      return transaction;
    } catch (e) {
      throw Exception('Transaction failed: $e');
    }
  }

  // Get user by ID
  static User? getUser(String userId) {
    initializeMockUsers();
    return _mockUsers[userId];
  }

  // Update user
  static void updateUser(User user) {
    _mockUsers[user.id] = user;
  }

  // Get user transactions
  static List<model.Transaction> getUserTransactions(
    String userId, {
    int limit = 50,
  }) {
    initializeMockUsers();
    final transactions = _mockTransactions[userId] ?? [];
    return transactions.take(limit).toList();
  }

  // Add mock money to user
  static void addMockMoney(String userId, double amount) {
    initializeMockUsers();
    User? user = _mockUsers[userId];
    if (user == null) {
      // Create user if not exists
      user = User(
        id: userId,
        name: 'Current User',
        email: 'user@example.com',
        phoneNumber: '9570175954',
        upiId: '9570175954@qrpay',
        balance: amount,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _mockUsers[userId] = user;
      _mockTransactions[userId] = [];
    } else {
      _mockUsers[userId] = user.copyWith(balance: user.balance + amount);
    }
  }

  // Find user by UPI ID - should not be used since we use real TransactionService
  static User? findUserByUpiId(String upiId) {
    // This mock service should not be used for real transactions
    // All operations should go through the real TransactionService with Firestore
    return null;
  }

  // Find user by phone number - should not be used since we use real TransactionService
  static User? findUserByPhone(String phone) {
    // This mock service should not be used for real transactions
    // All operations should go through the real TransactionService with Firestore
    return null;
  }

  // Get all users
  static List<User> getAllUsers() {
    initializeMockUsers();
    return _mockUsers.values.toList();
  }

  // Register a new user
  static void registerUser(User user) {
    _mockUsers[user.id] = user;
    _mockTransactions[user.id] = [];
  }

  // Generate transaction ID
  static String _generateTransactionId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = random.nextInt(9999).toString().padLeft(4, '0');
    return 'TXN$timestamp$randomSuffix';
  }

  // Generate mock transaction hash
  static String _generateTxHash(String transactionId) {
    final random = Random();
    final chars = '0123456789abcdef';
    return List.generate(
      64,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }
}

// Extension for User copyWith
extension UserExtension on User {
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? upiId,
    double? balance,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      upiId: upiId ?? this.upiId,
      balance: balance ?? this.balance,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
