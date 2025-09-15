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

      _transactions = await TransactionService.getUserTransactions(currentUser.id);
      _clearError();
    } catch (e) {
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
    try {
      _isLoading = true;
      notifyListeners();

      final currentUser = AuthService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final transaction = await TransactionService.processUpiPayment(
        fromUserId: currentUser.id,
        toUpiId: toUpiId,
        amount: amount,
        description: description,
      );

      // Add to local transactions list immediately
      _transactions.insert(0, transaction);
      
      // Force refresh user balance in AuthService immediately
      await AuthService.refreshCurrentUser();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
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
