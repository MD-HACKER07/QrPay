import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/wallet.dart';
import '../models/transaction.dart' as app_transaction;

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static const String _usersCollection = 'users';
  static const String _walletsCollection = 'wallets';
  static const String _transactionsCollection = 'transactions';

  /// User Management
  static Future<void> createUser(User user) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(user.id)
          .set(user.toJson());
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  static Future<User?> getUser(String userId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();
      if (doc.exists && doc.data() != null) {
        return User.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  static Future<void> updateUser(User user) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(user.id)
          .update(user.toJson());
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  /// Wallet Management
  static Future<void> createWallet(Wallet wallet, String userId) async {
    try {
      final walletData = wallet.toJson();
      walletData['userId'] = userId;
      walletData['address'] = 'qrpay_${wallet.id.substring(0, 16)}';
      walletData['createdAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection(_walletsCollection)
          .doc(wallet.id)
          .set(walletData);

      // Update user with wallet reference
      await _firestore.collection(_usersCollection).doc(userId).update({
        'walletId': wallet.id,
        'hasWallet': true,
      });
    } catch (e) {
      throw Exception('Failed to create wallet: $e');
    }
  }

  static Future<Wallet?> getWallet(String walletId) async {
    try {
      final doc = await _firestore
          .collection(_walletsCollection)
          .doc(walletId)
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return Wallet(
          id: data['id'],
          name: data['name'],
          publicKey: data['publicKey'],
          balance: (data['balance'] as num).toDouble(),
          createdAt: data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get wallet: $e');
    }
  }

  static Future<Wallet?> getUserWallet(String userId) async {
    try {
      final userDoc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();
      if (userDoc.exists &&
          userDoc.data() != null &&
          userDoc.data()!['walletId'] != null) {
        return await getWallet(userDoc.data()!['walletId']);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user wallet: $e');
    }
  }

  static Future<void> updateWalletBalance(
    String walletId,
    double newBalance,
  ) async {
    try {
      await _firestore.collection(_walletsCollection).doc(walletId).update({
        'balance': newBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update wallet balance: $e');
    }
  }

  /// Transaction Management
  static Future<void> createTransaction(
    app_transaction.Transaction transaction,
  ) async {
    try {
      final transactionData = transaction.toJson();
      transactionData['createdAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection(_transactionsCollection)
          .doc(transaction.id)
          .set(transactionData);
    } catch (e) {
      throw Exception('Failed to create transaction: $e');
    }
  }

  static Future<List<app_transaction.Transaction>> getWalletTransactions(
    String walletAddress, {
    int limit = 50,
  }) async {
    try {
      final query1 = await _firestore
          .collection(_transactionsCollection)
          .where('fromAddress', isEqualTo: walletAddress)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      final query2 = await _firestore
          .collection(_transactionsCollection)
          .where('toAddress', isEqualTo: walletAddress)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      final List<app_transaction.Transaction> transactions = [];

      // Add sent transactions
      for (var doc in query1.docs) {
        final data = doc.data();
        transactions.add(app_transaction.Transaction.fromJson(data));
      }

      // Add received transactions
      for (var doc in query2.docs) {
        final data = doc.data();
        transactions.add(app_transaction.Transaction.fromJson(data));
      }

      // Sort by timestamp
      transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return transactions.take(limit).toList();
    } catch (e) {
      // Return empty list on error to avoid breaking the app
      return [];
    }
  }

  static Future<app_transaction.Transaction?> getTransaction(
    String transactionId,
  ) async {
    try {
      final doc = await _firestore
          .collection(_transactionsCollection)
          .doc(transactionId)
          .get();
      if (doc.exists && doc.data() != null) {
        return app_transaction.Transaction.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get transaction: $e');
    }
  }

  /// Utility Methods
  static Future<bool> walletAddressExists(String address) async {
    try {
      final query = await _firestore
          .collection(_walletsCollection)
          .where('address', isEqualTo: address)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> getWalletAddress(String walletId) async {
    try {
      final doc = await _firestore
          .collection(_walletsCollection)
          .doc(walletId)
          .get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['address'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Real-time listeners
  static Stream<Wallet?> watchWallet(String walletId) {
    return _firestore
        .collection(_walletsCollection)
        .doc(walletId)
        .snapshots()
        .map((doc) {
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            return Wallet(
              id: data['id'],
              name: data['name'],
              publicKey: data['publicKey'],
              balance: (data['balance'] as num).toDouble(),
              createdAt: data['createdAt'] != null
                  ? (data['createdAt'] as Timestamp).toDate()
                  : DateTime.now(),
            );
          }
          return null;
        });
  }

  static Stream<List<app_transaction.Transaction>> watchWalletTransactions(
    String walletAddress,
  ) {
    return _firestore
        .collection(_transactionsCollection)
        .where('fromAddress', isEqualTo: walletAddress)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => app_transaction.Transaction.fromJson(doc.data()))
              .toList();
        });
  }
}
