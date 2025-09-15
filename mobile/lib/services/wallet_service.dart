import 'dart:math';
import '../models/wallet.dart';
import '../models/transaction.dart';
import 'crypto_service.dart';
import 'secure_storage_service.dart';
import 'firebase_service.dart';
import 'auth_service.dart';

class WalletService {
  static Wallet? _currentWallet;
  static List<Transaction> _transactions = [];

  /// Create a new quantum-resistant wallet
  static Future<Wallet> createWallet(String name) async {
    final currentUser = AuthService.getCurrentUser();
    if (currentUser == null) {
      throw Exception('User must be authenticated to create wallet');
    }

    // Generate Dilithium key pair for signatures
    final dilithiumKeys = CryptoService.generateDilithiumKeyPair();

    // Generate Kyber key pair for key exchange
    final kyberKeys = CryptoService.generateKyberKeyPair();

    // Generate wallet ID and address
    final walletId = _generateWalletId();
    final address = CryptoService.generateAddress(dilithiumKeys['publicKey']!);

    // Create wallet object
    final wallet = Wallet(
      id: walletId,
      name: name,
      publicKey: dilithiumKeys['publicKey']!,
      balance: 1000.0, // Mock initial balance
      createdAt: DateTime.now(),
    );

    // Store keys securely locally
    await SecureStorageService.storePrivateKey(
      walletId,
      dilithiumKeys['privateKey']!,
    );
    await SecureStorageService.storeKyberKey(
      walletId,
      kyberKeys['privateKey']!,
    );

    // Store wallet in Firebase
    await FirebaseService.createWallet(wallet, currentUser.id);

    // Store wallet metadata locally
    await SecureStorageService.storeWalletData({
      'id': wallet.id,
      'name': wallet.name,
      'publicKey': wallet.publicKey,
      'address': address,
      'balance': wallet.balance,
      'createdAt': wallet.createdAt.toIso8601String(),
      'kyberPublicKey': kyberKeys['publicKey'],
    });

    _currentWallet = wallet;
    return wallet;
  }

  /// Load existing wallet
  static Future<Wallet?> loadWallet() async {
    final currentUser = AuthService.getCurrentUser();
    if (currentUser == null) return null;

    try {
      // Try to load from Firebase first
      _currentWallet = await FirebaseService.getUserWallet(currentUser.id);

      if (_currentWallet != null) {
        // Load transaction history from Firebase
        final address = await getWalletAddress();
        if (address != null) {
          final firebaseTransactions =
              await FirebaseService.getWalletTransactions(address);
          _transactions = firebaseTransactions;
        }

        // Update local storage
        await SecureStorageService.storeWalletData({
          'id': _currentWallet!.id,
          'name': _currentWallet!.name,
          'publicKey': _currentWallet!.publicKey,
          'address': address,
          'balance': _currentWallet!.balance,
          'createdAt': _currentWallet!.createdAt.toIso8601String(),
        });
      } else {
        // Fallback to local storage
        final walletData = await SecureStorageService.getWalletData();
        if (walletData != null) {
          _currentWallet = Wallet(
            id: walletData['id'],
            name: walletData['name'],
            publicKey: walletData['publicKey'],
            balance: walletData['balance'].toDouble(),
            createdAt: DateTime.parse(walletData['createdAt']),
          );
        }
      }

      return _currentWallet;
    } catch (e) {
      // Fallback to local storage on error
      final walletData = await SecureStorageService.getWalletData();
      if (walletData != null) {
        _currentWallet = Wallet(
          id: walletData['id'],
          name: walletData['name'],
          publicKey: walletData['publicKey'],
          balance: walletData['balance'].toDouble(),
          createdAt: DateTime.parse(walletData['createdAt']),
        );
        return _currentWallet;
      }
      return null;
    }
  }

  /// Get current wallet
  static Wallet? getCurrentWallet() => _currentWallet;

  /// Get wallet address
  static Future<String?> getWalletAddress() async {
    if (_currentWallet != null) {
      // Try Firebase first
      try {
        final address = await FirebaseService.getWalletAddress(
          _currentWallet!.id,
        );
        if (address != null) return address;
      } catch (e) {
        // Fallback to local storage
      }
    }

    final walletData = await SecureStorageService.getWalletData();
    return walletData?['address'];
  }

  /// Send payment (mock implementation)
  static Future<Transaction> sendPayment({
    required String toUpiId,
    required double amount,
    required String description,
  }) async {
    if (_currentWallet == null) {
      throw Exception('No wallet loaded');
    }

    if (_currentWallet!.balance < amount) {
      throw Exception('Insufficient balance');
    }

    // Get private key for signing
    final privateKey = await SecureStorageService.getPrivateKey(
      _currentWallet!.id,
    );
    if (privateKey == null) {
      throw Exception('Private key not found');
    }

    // Create transaction mapped to app model
    final currentUser = AuthService.getCurrentUser();
    final fromUpi = 'wallet:${currentUser?.id ?? 'local'}';
    final transaction = Transaction(
      id: _generateTransactionId(),
      fromUserId: currentUser?.id ?? 'local',
      toUserId: 'external',
      fromUpiId: fromUpi,
      toUpiId: toUpiId,
      amount: amount,
      description: description,
      type: TransactionType.send,
      status: TransactionStatus.pending,
      timestamp: DateTime.now(),
    );

    // Sign transaction with Dilithium
    final transactionData =
        '${transaction.fromUpiId}${transaction.toUpiId}${transaction.amount}${transaction.timestamp.millisecondsSinceEpoch}';
    final signature = CryptoService.signTransaction(
      privateKey,
      transactionData,
    );

    // Update transaction with signature
    final signedTransaction = Transaction(
      id: transaction.id,
      fromUserId: transaction.fromUserId,
      toUserId: transaction.toUserId,
      fromUpiId: transaction.fromUpiId,
      toUpiId: transaction.toUpiId,
      amount: transaction.amount,
      description: transaction.description,
      type: transaction.type,
      status: TransactionStatus.completed, // Mock completion
      timestamp: transaction.timestamp,
      signature: signature,
      txHash: 'qrpay_tx_${transaction.id}',
    );

    // Update balance (mock)
    _currentWallet = Wallet(
      id: _currentWallet!.id,
      name: _currentWallet!.name,
      publicKey: _currentWallet!.publicKey,
      balance: _currentWallet!.balance - amount,
      createdAt: _currentWallet!.createdAt,
    );

    // Store updated wallet data
    final walletData = await SecureStorageService.getWalletData();
    if (walletData != null) {
      walletData['balance'] = _currentWallet!.balance;
      await SecureStorageService.storeWalletData(walletData);
    }

    // Add to transaction history
    _transactions.add(signedTransaction);
    await _saveTransactions();

    return signedTransaction;
  }

  /// Get transaction history
  static List<Transaction> getTransactions() => List.from(_transactions);

  /// Generate unique wallet ID
  static String _generateWalletId() {
    final random = Random.secure();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomBytes = List.generate(8, (i) => random.nextInt(256));
    final randomHex = randomBytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return 'wallet_${timestamp}_$randomHex';
  }

  /// Generate unique transaction ID
  static String _generateTransactionId() {
    final random = Random.secure();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomBytes = List.generate(8, (i) => random.nextInt(256));
    final randomHex = randomBytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return 'tx_${timestamp}_$randomHex';
  }

  /// Save transactions to secure storage
  static Future<void> _saveTransactions() async {
    final transactionData = _transactions.map((tx) => tx.toJson()).toList();
    await SecureStorageService.storeTransactions(transactionData);
  }

  /// Check if wallet exists
  static Future<bool> hasWallet() async {
    return await SecureStorageService.hasWallet();
  }
}
