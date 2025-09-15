import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'auth_service.dart';
import 'qr_service.dart';

class UpiConfigService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Update user's UPI ID
  static Future<void> updateUpiId(String userId, String newUpiId) async {
    try {
      // Validate UPI ID format
      if (!_isValidUpiId(newUpiId)) {
        throw Exception('Invalid UPI ID format');
      }

      // Check if UPI ID is already taken
      final existingUser = await _findUserByUpiId(newUpiId);
      if (existingUser != null && existingUser.id != userId) {
        throw Exception('UPI ID already exists');
      }

      // Generate new QR code data
      final qrData = QRService.generateUpiQRData(
        upiId: newUpiId,
        name: (await _getUserById(userId))?.name ?? 'User',
        amount: null,
        note: 'Pay to $newUpiId',
      );

      // Update user document
      await _firestore.collection('users').doc(userId).update({
        'upiId': newUpiId,
        'qrData': qrData,
        'updatedAt': DateTime.now().toIso8601String(),
      });

    } catch (e) {
      throw Exception('Failed to update UPI ID: $e');
    }
  }

  // Get user's current UPI configuration
  static Future<Map<String, dynamic>?> getUserUpiConfig(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return {
          'upiId': data['upiId'],
          'qrData': data['qrData'],
          'qrCodeUrl': data['qrCodeUrl'],
        };
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get UPI config: $e');
    }
  }

  // Initialize UPI ID for new user
  static Future<void> initializeUpiId(String userId, String? preferredUpiId) async {
    try {
      final user = await _getUserById(userId);
      if (user == null) throw Exception('User not found');

      String upiId;
      if (preferredUpiId != null && _isValidUpiId(preferredUpiId)) {
        // Check if preferred UPI ID is available
        final existing = await _findUserByUpiId(preferredUpiId);
        if (existing == null) {
          upiId = preferredUpiId;
        } else {
          // Generate alternative
          upiId = await _generateUniqueUpiId(user.name, user.phoneNumber);
        }
      } else {
        // Generate UPI ID based on user info
        upiId = await _generateUniqueUpiId(user.name, user.phoneNumber);
      }

      await updateUpiId(userId, upiId);
    } catch (e) {
      throw Exception('Failed to initialize UPI ID: $e');
    }
  }

  // Generate unique UPI ID
  static Future<String> _generateUniqueUpiId(String name, String? phoneNumber) async {
    // Create base UPI ID from name and phone
    String baseName = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    String basePhone = phoneNumber?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    
    if (baseName.length > 10) baseName = baseName.substring(0, 10);
    if (basePhone.length > 4) basePhone = basePhone.substring(basePhone.length - 4);
    
    String baseUpiId = '$baseName$basePhone@qrpay';
    
    // Check if base UPI ID is available
    if (await _findUserByUpiId(baseUpiId) == null) {
      return baseUpiId;
    }
    
    // Generate alternatives with numbers
    for (int i = 1; i <= 999; i++) {
      String alternativeUpiId = '${baseName}${basePhone}${i}@qrpay';
      if (await _findUserByUpiId(alternativeUpiId) == null) {
        return alternativeUpiId;
      }
    }
    
    // Fallback to timestamp-based UPI ID
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return 'user${timestamp.substring(timestamp.length - 8)}@qrpay';
  }

  // Validate UPI ID format
  static bool _isValidUpiId(String upiId) {
    final upiRegex = RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+$');
    return upiRegex.hasMatch(upiId) && upiId.length >= 6 && upiId.length <= 50;
  }

  // Find user by UPI ID
  static Future<User?> _findUserByUpiId(String upiId) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('upiId', isEqualTo: upiId)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        return User.fromJson(query.docs.first.data());
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get user by ID
  static Future<User?> _getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return User.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Check UPI ID availability
  static Future<bool> isUpiIdAvailable(String upiId) async {
    try {
      final user = await _findUserByUpiId(upiId);
      return user == null;
    } catch (e) {
      return false;
    }
  }

  // Get UPI ID suggestions
  static Future<List<String>> getUpiIdSuggestions(String name, String? phoneNumber) async {
    List<String> suggestions = [];
    
    String baseName = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    String basePhone = phoneNumber?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    
    if (baseName.length > 10) baseName = baseName.substring(0, 10);
    if (basePhone.length > 4) basePhone = basePhone.substring(basePhone.length - 4);
    
    // Generate multiple suggestions
    List<String> patterns = [
      '$baseName@qrpay',
      '$baseName$basePhone@qrpay',
      '${baseName}_${basePhone}@qrpay',
      '$baseName.${basePhone}@qrpay',
      '${baseName}pay@qrpay',
    ];
    
    for (String pattern in patterns) {
      if (await isUpiIdAvailable(pattern)) {
        suggestions.add(pattern);
      }
      if (suggestions.length >= 5) break;
    }
    
    return suggestions;
  }

  // Check UPI ID availability (alias for isUpiIdAvailable)
  static Future<bool> checkUpiIdAvailability(String upiId) async {
    return await isUpiIdAvailable(upiId);
  }

  // Setup UPI ID for user
  static Future<void> setupUpiId({required String upiId, required String userId}) async {
    try {
      // Validate UPI ID format
      if (!_isValidUpiId(upiId)) {
        throw Exception('Invalid UPI ID format');
      }

      // Check if UPI ID is available
      if (!await isUpiIdAvailable(upiId)) {
        throw Exception('UPI ID is already taken');
      }

      // Update user's UPI ID
      await updateUpiId(userId, upiId);
    } catch (e) {
      throw Exception('Failed to setup UPI ID: $e');
    }
  }
}
