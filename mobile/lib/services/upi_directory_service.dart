import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class UpiDirectoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch all users with UPI IDs from Firestore
  static Future<List<User>> getAllUsersWithUpiIds() async {
    try {
      // Fetching all users from Firestore
      
      final querySnapshot = await _firestore
          .collection('users')
          .where('upiId', isNotEqualTo: null)
          .get();
      
      // Found users with UPI IDs
      
      final users = querySnapshot.docs.map((doc) {
        final data = doc.data();
        // User data loaded
        return User.fromJson(data);
      }).toList();
      
      return users;
    } catch (e) {
      // Error fetching users
      return [];
    }
  }

  /// Fetch user by UPI ID
  static Future<User?> getUserByUpiId(String upiId) async {
    try {
      final trimmed = upiId.trim();
      final lower = trimmed.toLowerCase();

      // Try exact match first
      final exactQuery = await _firestore
          .collection('users')
          .where('upiId', isEqualTo: trimmed)
          .limit(1)
          .get();

      if (exactQuery.docs.isNotEmpty) {
        final userData = exactQuery.docs.first.data();
        return User.fromJson(userData);
      }

      // Try case-insensitive via normalized field if available
      try {
        final normQuery = await _firestore
            .collection('users')
            .where('upiIdLower', isEqualTo: lower)
            .limit(1)
            .get();
        if (normQuery.docs.isNotEmpty) {
          final userData = normQuery.docs.first.data();
          return User.fromJson(userData);
        }
      } catch (e) {
        // Field may not exist in older docs; ignore
      }

      // Try lowercase equality (if DB stored lowercase upiId)
      final lowerQuery = await _firestore
          .collection('users')
          .where('upiId', isEqualTo: lower)
          .limit(1)
          .get();
      if (lowerQuery.docs.isNotEmpty) {
        final userData = lowerQuery.docs.first.data();
        return User.fromJson(userData);
      }

      // Final fallback: small scan and check common aliases/normalized
      final scan = await _firestore.collection('users').limit(500).get();
      for (final doc in scan.docs) {
        final data = doc.data();
        final candidates = <String?>[
          data['upiId']?.toString(),
          data['upi']?.toString(),
          data['vpa']?.toString(),
          data['upi_id']?.toString(),
          data['UPIID']?.toString(),
          data['upiIdLower']?.toString(),
        ];
        for (final c in candidates) {
          if (c == null) continue;
          final cTrim = c.trim();
          if (cTrim == trimmed || cTrim.toLowerCase() == lower) {
            return User.fromJson(data);
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Fetch user by phone number
  static Future<User?> getUserByPhoneNumber(String phoneNumber) async {
    try {
      // Searching for phone number

      String normalize(String p) {
        final digits = p.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.length >= 10) {
          return digits.substring(digits.length - 10);
        }
        return digits;
      }

      final last10 = normalize(phoneNumber);
      final variants = <String>{
        phoneNumber,
        '+91$last10',
        '91$last10',
        last10,
      };

      // Try a few exact variants first to avoid scanning
      for (final v in variants) {
        final snap = await _firestore
            .collection('users')
            .where('phoneNumber', isEqualTo: v)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          final data = snap.docs.first.data();
          // Found user by phone variant
          return User.fromJson(data);
        }
      }

      // Fallback: small scan and normalize in memory (cap to 200 for safety)
      final allSnap = await _firestore.collection('users').limit(200).get();
      for (final doc in allSnap.docs) {
        final data = doc.data();
        final pn = (data['phoneNumber'] ?? '').toString();
        if (normalize(pn) == last10) {
          // Found user by phone normalized scan
          return User.fromJson(data);
        }
      }

      // No user found with phone number
      return null;
    } catch (e) {
      // Error searching for phone number
      return null;
    }
  }

  /// Create a new user with UPI ID
  static Future<User> createUserWithUpiId({
    required String upiId,
    required String phoneNumber,
    String? name,
    String? email,
    double initialBalance = 1000.0,
  }) async {
    try {
      final userId = _firestore.collection('users').doc().id;
      
      final user = User(
        id: userId,
        name: name ?? 'User ${phoneNumber.substring(phoneNumber.length - 4)}',
        email: email ?? '$phoneNumber@qrpay.com',
        phoneNumber: phoneNumber,
        upiId: upiId,
        balance: initialBalance,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _firestore.collection('users').doc(userId).set(user.toJson());
      
      // Created new user
      return user;
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  /// Update user's UPI ID
  static Future<void> updateUserUpiId(String userId, String newUpiId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'upiId': newUpiId.trim(),
        'upiIdLower': newUpiId.trim().toLowerCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Updated user UPI ID
    } catch (e) {
      throw Exception('Failed to update UPI ID: $e');
    }
  }

  /// Get all UPI IDs (for debugging)
  static Future<List<String>> getAllUpiIds() async {
    try {
      final users = await getAllUsersWithUpiIds();
      final upiIds = users
          .where((user) => user.upiId != null && user.upiId!.isNotEmpty)
          .map((user) => user.upiId!)
          .toList();
      
      // Retrieved all UPI IDs from database
      
      return upiIds;
    } catch (e) {
      // Error fetching UPI IDs
      return [];
    }
  }

  /// Search users by partial UPI ID or name
  static Future<List<User>> searchUsers(String query) async {
    try {
      // Searching users with query
      
      final querySnapshot = await _firestore
          .collection('users')
          .get();
      
      final users = querySnapshot.docs
          .map((doc) => User.fromJson(doc.data()))
          .where((user) {
            final matchesUpi = user.upiId?.toLowerCase().contains(query.toLowerCase()) ?? false;
            final matchesName = user.name.toLowerCase().contains(query.toLowerCase());
            final matchesPhone = user.phoneNumber?.contains(query) ?? false;
            return matchesUpi || matchesName || matchesPhone;
          })
          .toList();
      
      // Found matching users
      return users;
    } catch (e) {
      // Error searching users
      return [];
    }
  }
}
