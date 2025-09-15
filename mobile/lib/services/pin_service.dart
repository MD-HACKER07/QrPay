import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'auth_service.dart';

class PinService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Hash PIN for secure storage
  static String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Set up UPI PIN for the current user
  static Future<bool> setupPin(String pin) async {
    try {
      final currentUser = AuthService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final hashedPin = _hashPin(pin);
      
      await _firestore.collection('users').doc(currentUser.id).update({
        'upiPin': hashedPin,
        'hasPinSet': true,
        'pinSetAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local user data
      final updatedUser = currentUser.copyWith(
        upiPin: hashedPin,
        hasPinSet: true,
        pinSetAt: DateTime.now(),
      );
      
      await AuthService.updateCurrentUser(updatedUser);
      
      return true;
    } catch (e) {
      print('Error setting up PIN: $e');
      return false;
    }
  }

  /// Verify PIN against stored PIN
  static Future<bool> verifyPin(String pin) async {
    try {
      final currentUser = AuthService.getCurrentUser();
      if (currentUser == null) {
        print('Error: User not authenticated');
        return false;
      }

      if (!currentUser.hasPinSet || currentUser.upiPin == null || currentUser.upiPin!.isEmpty) {
        print('Error: PIN not set up');
        return false;
      }

      final hashedPin = _hashPin(pin);
      print('Verifying PIN: ${hashedPin == currentUser.upiPin}');
      print('Stored PIN hash: ${currentUser.upiPin}');
      print('Input PIN hash: $hashedPin');
      
      return hashedPin == currentUser.upiPin;
    } catch (e) {
      print('Error verifying PIN: $e');
      return false;
    }
  }

  /// Change existing PIN
  static Future<bool> changePin(String oldPin, String newPin) async {
    try {
      // First verify old PIN
      final isOldPinValid = await verifyPin(oldPin);
      if (!isOldPinValid) {
        throw Exception('Current PIN is incorrect');
      }

      // Set new PIN
      return await setupPin(newPin);
    } catch (e) {
      print('Error changing PIN: $e');
      return false;
    }
  }

  /// Check if user has PIN set up
  static bool hasPinSetup() {
    final currentUser = AuthService.getCurrentUser();
    if (currentUser == null) return false;
    return currentUser.hasPinSet && currentUser.upiPin != null && currentUser.upiPin!.isNotEmpty;
  }

  /// Get PIN setup date
  static DateTime? getPinSetupDate() {
    final currentUser = AuthService.getCurrentUser();
    return currentUser?.pinSetAt;
  }

  /// Reset PIN (admin function)
  static Future<bool> resetPin() async {
    try {
      final currentUser = AuthService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('users').doc(currentUser.id).update({
        'upiPin': FieldValue.delete(),
        'hasPinSet': false,
        'pinSetAt': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local user data
      final updatedUser = currentUser.copyWith(
        upiPin: null,
        hasPinSet: false,
        pinSetAt: null,
      );
      
      await AuthService.updateCurrentUser(updatedUser);
      
      return true;
    } catch (e) {
      print('Error resetting PIN: $e');
      return false;
    }
  }

  /// Validate PIN format (6 digits)
  static bool isValidPinFormat(String pin) {
    return pin.length == 6 && RegExp(r'^\d{6}$').hasMatch(pin);
  }

  /// Check if PIN is secure (not sequential, not repeated)
  static bool isSecurePin(String pin) {
    if (!isValidPinFormat(pin)) return false;

    // Check for repeated digits (111111, 222222, etc.)
    if (RegExp(r'^(\d)\1{5}$').hasMatch(pin)) return false;

    // Check for sequential digits (123456, 654321)
    bool isSequential = true;
    for (int i = 1; i < pin.length; i++) {
      if (int.parse(pin[i]) != int.parse(pin[i - 1]) + 1) {
        isSequential = false;
        break;
      }
    }
    if (isSequential) return false;

    // Check for reverse sequential (654321)
    bool isReverseSequential = true;
    for (int i = 1; i < pin.length; i++) {
      if (int.parse(pin[i]) != int.parse(pin[i - 1]) - 1) {
        isReverseSequential = false;
        break;
      }
    }
    if (isReverseSequential) return false;

    // Check for common weak PINs
    final weakPins = ['123456', '654321', '111111', '000000', '123123', '456456'];
    if (weakPins.contains(pin)) return false;

    return true;
  }

  /// Get PIN strength message
  static String getPinStrengthMessage(String pin) {
    if (pin.length < 6) return 'PIN must be 6 digits';
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) return 'PIN must contain only numbers';
    if (!isSecurePin(pin)) return 'Choose a more secure PIN';
    return 'Strong PIN';
  }
}
