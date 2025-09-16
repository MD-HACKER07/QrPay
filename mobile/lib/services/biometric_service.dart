import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if biometric authentication is available on the device
  static Future<bool> isBiometricAvailable() async {
    try {
      // Biometric authentication is not supported on web
      if (kIsWeb) {
        return false;
      }
      
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get available biometric types (fingerprint, face, etc.)
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      // Return empty list for web platform
      if (kIsWeb) {
        return [];
      }
      
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Authenticate using biometrics
  static Future<bool> authenticateWithBiometrics({
    String reason = 'Please authenticate to authorize this payment',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      // For web platform, simulate biometric unavailability
      if (kIsWeb) {
        print('Biometric authentication not supported on web platform');
        return false;
      }
      
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        print('Biometric authentication not available on this device');
        return false;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true,
        ),
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      print('Biometric authentication error: ${e.message}');
      return false;
    } catch (e) {
      print('Unexpected biometric error: $e');
      return false;
    }
  }

  /// Check if user has enabled biometric authentication for payments
  static Future<bool> isBiometricEnabledForPayments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('biometric_payments_enabled') ?? false;
    } catch (e) {
      print('Error checking biometric payment preference: $e');
      return false;
    }
  }

  /// Enable/disable biometric authentication for payments
  static Future<bool> setBiometricForPayments(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool('biometric_payments_enabled', enabled);
    } catch (e) {
      print('Error setting biometric payment preference: $e');
      return false;
    }
  }

  /// Get user's preferred authentication method
  static Future<AuthenticationMethod> getPreferredAuthMethod() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final methodString = prefs.getString('preferred_auth_method') ?? 'pin';
      return AuthenticationMethod.values.firstWhere(
        (method) => method.name == methodString,
        orElse: () => AuthenticationMethod.pin,
      );
    } catch (e) {
      print('Error getting preferred auth method: $e');
      return AuthenticationMethod.pin;
    }
  }

  /// Set user's preferred authentication method
  static Future<bool> setPreferredAuthMethod(AuthenticationMethod method) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString('preferred_auth_method', method.name);
    } catch (e) {
      print('Error setting preferred auth method: $e');
      return false;
    }
  }

  /// Get biometric type display name
  static String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.strong:
        return 'Strong Biometric';
      case BiometricType.weak:
        return 'Weak Biometric';
    }
  }

  /// Get primary biometric type available
  static Future<BiometricType?> getPrimaryBiometricType() async {
    final availableBiometrics = await getAvailableBiometrics();
    if (availableBiometrics.isEmpty) return null;

    // Prioritize face ID, then fingerprint
    if (availableBiometrics.contains(BiometricType.face)) {
      return BiometricType.face;
    } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
      return BiometricType.fingerprint;
    } else if (availableBiometrics.contains(BiometricType.strong)) {
      return BiometricType.strong;
    } else {
      return availableBiometrics.first;
    }
  }

  /// Check if biometric authentication should be used for this payment
  static Future<bool> shouldUseBiometricAuth() async {
    final isAvailable = await isBiometricAvailable();
    final isEnabled = await isBiometricEnabledForPayments();
    final preferredMethod = await getPreferredAuthMethod();
    
    return isAvailable && isEnabled && 
           (preferredMethod == AuthenticationMethod.biometric || 
            preferredMethod == AuthenticationMethod.both);
  }

  /// Authenticate user with their preferred method
  static Future<AuthResult> authenticateUser({
    String reason = 'Please authenticate to authorize this payment',
    bool allowFallback = true,
  }) async {
    final preferredMethod = await getPreferredAuthMethod();
    final biometricAvailable = await isBiometricAvailable();
    
    // If on web or biometric not available, always use PIN
    if (kIsWeb || !biometricAvailable) {
      return AuthResult(
        success: false, 
        method: AuthenticationMethod.pin, 
        requiresPinFallback: true,
        error: kIsWeb ? 'Biometric authentication not supported on web' : 'Biometric authentication not available'
      );
    }
    
    switch (preferredMethod) {
      case AuthenticationMethod.biometric:
        final success = await authenticateWithBiometrics(reason: reason);
        if (success) {
          return AuthResult(success: true, method: AuthenticationMethod.biometric);
        } else if (allowFallback) {
          // Fallback to PIN if biometric fails
          return AuthResult(success: false, method: AuthenticationMethod.biometric, requiresPinFallback: true);
        }
        return AuthResult(success: false, method: AuthenticationMethod.biometric);
        
      case AuthenticationMethod.both:
        // Try biometric first, then PIN if needed
        final biometricSuccess = await authenticateWithBiometrics(reason: reason);
        if (biometricSuccess) {
          return AuthResult(success: true, method: AuthenticationMethod.biometric);
        }
        return AuthResult(success: false, method: AuthenticationMethod.biometric, requiresPinFallback: true);
        
      case AuthenticationMethod.pin:
        return AuthResult(success: false, method: AuthenticationMethod.pin, requiresPinFallback: true);
    }
  }
}

enum AuthenticationMethod {
  pin,
  biometric,
  both,
}

class AuthResult {
  final bool success;
  final AuthenticationMethod method;
  final bool requiresPinFallback;
  final String? error;

  AuthResult({
    required this.success,
    required this.method,
    this.requiresPinFallback = false,
    this.error,
  });
}
