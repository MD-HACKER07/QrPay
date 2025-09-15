import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/mock_transaction_service.dart';
import '../services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  /// Initialize the auth provider
  Future<void> initialize() async {
    _setLoading(true);
    try {
      _user = await AuthService.loadUser();
      _clearError();
    } catch (e) {
      _setError('Failed to load user: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      _user = await AuthService.signInWithGoogle();
      _clearError();
      notifyListeners();
      return _user != null;
    } catch (e) {
      _setError('Google sign-in failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with Apple
  Future<bool> signInWithApple() async {
    _setLoading(true);
    try {
      _user = await AuthService.signInWithApple();
      _clearError();
      notifyListeners();
      return _user != null;
    } catch (e) {
      _setError('Apple sign-in failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with email and password
  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      _user = await AuthService.signInWithEmail(email, password);
      _clearError();
      notifyListeners();
      return _user != null;
    } catch (e) {
      _setError('Email sign-in failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign up with email and password
  Future<bool> signUpWithEmail(String email, String password, String name, {String? phoneNumber}) async {
    _setLoading(true);
    try {
      _user = await AuthService.signUpWithEmail(email, password, name, phoneNumber: phoneNumber);
      _clearError();
      notifyListeners();
      return _user != null;
    } catch (e) {
      _setError('Email sign-up failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await AuthService.signOut();
      _user = null;
      _clearError();
    } catch (e) {
      _setError('Sign-out failed: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    try {
      await AuthService.resetPassword(email);
      _clearError();
      return true;
    } catch (e) {
      _setError('Password reset failed: $e');
      return false;
    } finally {
      _setLoading(false);
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

  void updateUser(User updatedUser) {
    _user = updatedUser;
    notifyListeners();
  }

  /// Refresh user data from the server
  Future<void> refreshUser() async {
    if (_user == null) return;
    
    try {
      // 1) Try Firestore first for authoritative data
      try {
        final remote = await FirebaseService.getUser(_user!.id);
        if (remote != null) {
          _user = remote;
          notifyListeners();
          return;
        }
      } catch (_) {}

      // 2) Fall back to mock service (for demo users)
      final mockUser = MockTransactionService.getUser(_user!.id);
      if (mockUser != null) {
        _user = mockUser;
      } else {
        // 3) Finally, load from secure storage if available
        _user = await AuthService.loadUser();
      }
      notifyListeners();
    } catch (e) {
      _setError('Failed to refresh user data: $e');
    }
  }
}