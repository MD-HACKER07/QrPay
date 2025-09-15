import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../services/auth_service.dart';
import 'auth_provider.dart';

class TransactionProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Transaction> get transactions => List.from(_transactions);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize and load user transactions
  Future<void> initialize() async {
    await loadTransactions();
  }

  /// Load user transactions from Firestore
  Future<void> loadTransactions() async {
    _setLoading(true);
    try {
      // Try to load user from storage first if not in memory
      var currentUser = AuthService.getCurrentUser();
      if (currentUser == null) {
        currentUser = await AuthService.loadUser();
        if (currentUser == null) {
          _transactions = [];
          _clearError();
          _setLoading(false);
          return;
        }
      }

      print('Loading transactions for user: ${currentUser.id}');
      final transactions = await TransactionService.getUserTransactions(currentUser.id);
      print('Loaded ${transactions.length} transactions');
      
      _transactions = transactions;
      _clearError();
    } catch (e) {
      print('Error loading transactions: $e');
      _setError('Failed to load transactions: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Send payment using real transaction service
  Future<void> sendPayment({
    required String toUpiId,
    required double amount,
    required String description,
  }) async {
    _isLoading = true;
    _clearError();
    notifyListeners();

    try {
      final currentUser = AuthService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      print('Starting payment: $amount to $toUpiId');
      
      final transaction = await TransactionService.processUpiPayment(
        fromUserId: currentUser.id,
        toUpiId: toUpiId,
        amount: amount,
        description: description,
      );

      print('Payment processed successfully: ${transaction.id}');

      // Add to local transactions list immediately
      _transactions.insert(0, transaction);
      
      // Force refresh user balance in AuthService immediately
      try {
        await AuthService.refreshCurrentUser();
        print('User balance refreshed');
      } catch (e) {
        print('Warning: Failed to refresh user balance: $e');
        // Don't fail the transaction for this
      }
      
      // Also reload all transactions to ensure consistency
      try {
        await loadTransactions();
        print('Transactions reloaded');
      } catch (e) {
        print('Warning: Failed to reload transactions: $e');
        // Don't fail the transaction for this
      }
      
    } catch (e) {
      print('Payment failed: $e');
      _setError('Payment failed: ${e.toString()}');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh transaction data
  Future<void> refresh() async {
    await loadTransactions();
  }

  /// Get user balance
  Future<double> getUserBalance() async {
    try {
      final currentUser = AuthService.getCurrentUser();
      if (currentUser == null) {
        return 0.0;
      }
      return await TransactionService.getUserBalance(currentUser.id);
    } catch (e) {
      _setError('Failed to get balance: $e');
      return 0.0;
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
