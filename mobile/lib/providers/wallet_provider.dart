import 'package:flutter/foundation.dart';
import '../models/wallet.dart';
import '../models/transaction.dart';
import '../services/wallet_service.dart';

class WalletProvider extends ChangeNotifier {
  Wallet? _wallet;
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  Wallet? get wallet => _wallet;
  List<Transaction> get transactions => List.from(_transactions);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasWallet => _wallet != null;

  /// Initialize the provider - check if wallet exists
  Future<void> initialize() async {
    _setLoading(true);
    try {
      _wallet = await WalletService.loadWallet();
      if (_wallet != null) {
        _transactions = WalletService.getTransactions();
      }
      _clearError();
    } catch (e) {
      _setError('Failed to initialize wallet: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new wallet
  Future<bool> createWallet(String name) async {
    _setLoading(true);
    try {
      _wallet = await WalletService.createWallet(name);
      _transactions = [];
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to create wallet: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Send payment
  Future<bool> sendPayment({
    required String toUpiId,
    required double amount,
    required String description,
  }) async {
    _setLoading(true);
    try {
      final transaction = await WalletService.sendPayment(
        toUpiId: toUpiId,
        amount: amount,
        description: description,
      );
      
      // Update local state
      _transactions.insert(0, transaction);
      _wallet = WalletService.getCurrentWallet();
      
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to send payment: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get wallet address
  Future<String?> getWalletAddress() async {
    try {
      return await WalletService.getWalletAddress();
    } catch (e) {
      _setError('Failed to get wallet address: $e');
      return null;
    }
  }

  /// Refresh wallet data
  Future<void> refresh() async {
    await initialize();
  }

  /// Check if wallet exists
  Future<bool> checkWalletExists() async {
    try {
      return await WalletService.hasWallet();
    } catch (e) {
      return false;
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}