import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Keys for storage
  static const String _walletKey = 'wallet_data';
  static const String _privateKeyPrefix = 'private_key_';
  static const String _kyberKeyPrefix = 'kyber_key_';
  static const String _transactionsKey = 'transactions';
  static const String _userKey = 'user_data';

  /// Store wallet private key securely
  static Future<void> storePrivateKey(String walletId, String privateKey) async {
    await _storage.write(key: '$_privateKeyPrefix$walletId', value: privateKey);
  }

  /// Retrieve wallet private key
  static Future<String?> getPrivateKey(String walletId) async {
    return await _storage.read(key: '$_privateKeyPrefix$walletId');
  }

  /// Store Kyber private key for key exchange
  static Future<void> storeKyberKey(String walletId, String kyberPrivateKey) async {
    await _storage.write(key: '$_kyberKeyPrefix$walletId', value: kyberPrivateKey);
  }

  /// Retrieve Kyber private key
  static Future<String?> getKyberKey(String walletId) async {
    return await _storage.read(key: '$_kyberKeyPrefix$walletId');
  }

  /// Store wallet metadata (non-sensitive data)
  static Future<void> storeWalletData(Map<String, dynamic> walletData) async {
    final jsonString = jsonEncode(walletData);
    await _storage.write(key: _walletKey, value: jsonString);
  }

  /// Retrieve wallet metadata
  static Future<Map<String, dynamic>?> getWalletData() async {
    final jsonString = await _storage.read(key: _walletKey);
    if (jsonString != null) {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    }
    return null;
  }

  /// Store transaction history
  static Future<void> storeTransactions(List<Map<String, dynamic>> transactions) async {
    final jsonString = jsonEncode(transactions);
    await _storage.write(key: _transactionsKey, value: jsonString);
  }

  /// Retrieve transaction history
  static Future<List<Map<String, dynamic>>> getTransactions() async {
    final jsonString = await _storage.read(key: _transactionsKey);
    if (jsonString != null) {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Clear all stored data (for wallet reset)
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Check if wallet exists
  static Future<bool> hasWallet() async {
    final walletData = await getWalletData();
    return walletData != null;
  }

  /// Store user authentication data
  static Future<void> storeUserData(Map<String, dynamic> userData) async {
    final jsonString = jsonEncode(userData);
    await _storage.write(key: _userKey, value: jsonString);
  }

  /// Retrieve user authentication data
  static Future<Map<String, dynamic>?> getUserData() async {
    final jsonString = await _storage.read(key: _userKey);
    if (jsonString != null) {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    }
    return null;
  }

  /// Clear user data
  static Future<void> clearUserData() async {
    await _storage.delete(key: _userKey);
  }

  /// Check if user is logged in
  static Future<bool> isUserLoggedIn() async {
    final userData = await getUserData();
    return userData != null;
  }
}