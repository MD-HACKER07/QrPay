import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'upi_directory_service.dart';

class UpiAccountDetails {
  final String upiId;
  final String name;
  final String? profileImage;
  final String? bankName;
  final String? accountNumber;
  final bool isVerified;
  final DateTime lastUpdated;
  final int transactionCount;

  UpiAccountDetails({
    required this.upiId,
    required this.name,
    this.profileImage,
    this.bankName,
    this.accountNumber,
    required this.isVerified,
    required this.lastUpdated,
    this.transactionCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'upiId': upiId,
      'name': name,
      'profileImage': profileImage,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'isVerified': isVerified,
      'lastUpdated': lastUpdated.toIso8601String(),
      'transactionCount': transactionCount,
    };
  }

  factory UpiAccountDetails.fromJson(Map<String, dynamic> json) {
    return UpiAccountDetails(
      upiId: json['upiId'] ?? '',
      name: json['name'] ?? '',
      profileImage: json['profileImage'],
      bankName: json['bankName'],
      accountNumber: json['accountNumber'],
      isVerified: json['isVerified'] ?? false,
      lastUpdated: DateTime.parse(json['lastUpdated']),
      transactionCount: json['transactionCount'] ?? 0,
    );
  }

  String get maskedAccountNumber {
    if (accountNumber == null || accountNumber!.length < 4) return 'XXXX';
    return 'XXXX${accountNumber!.substring(accountNumber!.length - 4)}';
  }

  String get displayName {
    return name.isNotEmpty ? name : upiId.split('@')[0];
  }
}

class UpiAccountService {
  static const String _cacheKey = 'upi_account_cache';
  static const String _frequentUpiKey = 'frequent_upi_ids';
  static const int _cacheExpiryHours = 24;
  static const int _maxCacheSize = 100;

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch UPI account details with caching
  static Future<UpiAccountDetails?> getAccountDetails(String upiId) async {
    try {
      // Fetching account details for UPI ID

      // Use only real Firestore data - no test accounts

      // First check local cache
      final cachedDetails = await _getCachedAccountDetails(upiId);
      if (cachedDetails != null && !_isCacheExpired(cachedDetails)) {
        return cachedDetails;
      }

      // Check Firestore cache
      final firestoreDetails = await _getFirestoreAccountDetails(upiId);
      if (firestoreDetails != null && !_isCacheExpired(firestoreDetails)) {
        // Update local cache
        await _cacheAccountDetailsLocally(firestoreDetails);
        return firestoreDetails;
      }

      // Fetch fresh data from UPI system (simulated)
      final freshDetails = await _fetchFreshAccountDetails(upiId);
      if (freshDetails != null) {
        // Cache in both Firestore and local storage
        await _cacheAccountDetailsInFirestore(freshDetails);
        await _cacheAccountDetailsLocally(freshDetails);
        await _updateFrequentUpiIds(upiId);
        return freshDetails;
      }

      return null;
    } catch (e) {
      // Silently handle errors
      return null;
    }
  }

  /// Get cached account details from local storage
  static Future<UpiAccountDetails?> _getCachedAccountDetails(
    String upiId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = prefs.getString(_cacheKey);
      if (cacheData == null) return null;

      final Map<String, dynamic> cache = json.decode(cacheData);
      if (cache.containsKey(upiId)) {
        return UpiAccountDetails.fromJson(cache[upiId]);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get account details from Firestore cache
  static Future<UpiAccountDetails?> _getFirestoreAccountDetails(
    String upiId,
  ) async {
    try {
      final doc = await _firestore
          .collection('upi_account_cache')
          .doc(upiId)
          .get();

      if (doc.exists && doc.data() != null) {
        return UpiAccountDetails.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Simulate fetching fresh account details from UPI system
  static Future<UpiAccountDetails?> _fetchFreshAccountDetails(
    String upiId,
  ) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Check if UPI ID exists in our users collection
    try {
      final trimmed = upiId.trim();

      // Try centralized directory lookup first (handles normalization)
      final viaDirectory = await UpiDirectoryService.getUserByUpiId(trimmed);
      if (viaDirectory != null) {
        return UpiAccountDetails(
          upiId: trimmed,
          name: viaDirectory.name,
          profileImage: viaDirectory.photoUrl,
          bankName: _generateBankName(trimmed),
          accountNumber: _generateAccountNumber(),
          isVerified: true,
          lastUpdated: DateTime.now(),
          transactionCount: 0,
        );
      }

      // If directory lookup failed, try direct Firestore queries
      final userQuery = await _firestore
          .collection('users')
          .where('upiId', isEqualTo: trimmed)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final userData = userQuery.docs.first.data();
        return UpiAccountDetails(
          upiId: trimmed,
          name: userData['name'] ?? '',
          profileImage: userData['photoUrl'],
          bankName: _generateBankName(trimmed),
          accountNumber: _generateAccountNumber(),
          isVerified: true,
          lastUpdated: DateTime.now(),
          transactionCount: userData['transactionCount'] ?? 0,
        );
      } else {

        // Additional real lookup: If UPI ends with @qrpay, try resolving via phone number
        if (upiId.toLowerCase().contains('@qrpay')) {
          final phone = upiId.split('@').first.trim();
          final userByPhone = await UpiDirectoryService.getUserByPhoneNumber(phone);
          if (userByPhone != null) {
            // If user's UPI is missing or different, update it to match the entered UPI
            final currentUpi = (userByPhone.upiId ?? '').toLowerCase();
            final desiredUpi = upiId.trim().toLowerCase();
            if (currentUpi != desiredUpi) {
              await UpiDirectoryService.updateUserUpiId(userByPhone.id, upiId.trim());
            }

            return UpiAccountDetails(
              upiId: upiId.trim(),
              name: userByPhone.name,
              profileImage: userByPhone.photoUrl,
              bankName: _generateBankName(upiId),
              accountNumber: _generateAccountNumber(),
              isVerified: true,
              lastUpdated: DateTime.now(),
              transactionCount: 0,
            );
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Cache account details in Firestore
  static Future<void> _cacheAccountDetailsInFirestore(
    UpiAccountDetails details,
  ) async {
    try {
      await _firestore
          .collection('upi_account_cache')
          .doc(details.upiId)
          .set(details.toJson());
    } catch (e) {
      // Silently handle cache errors
    }
  }

  /// Cache account details locally
  static Future<void> _cacheAccountDetailsLocally(
    UpiAccountDetails details,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = prefs.getString(_cacheKey);
      Map<String, dynamic> cache = {};

      if (cacheData != null) {
        cache = json.decode(cacheData);
      }

      // Add new entry
      cache[details.upiId] = details.toJson();

      // Limit cache size
      if (cache.length > _maxCacheSize) {
        final sortedEntries = cache.entries.toList()
          ..sort((a, b) {
            final aTime = DateTime.parse(a.value['lastUpdated']);
            final bTime = DateTime.parse(b.value['lastUpdated']);
            return aTime.compareTo(bTime);
          });

        // Remove oldest entries
        final entriesToRemove = cache.length - _maxCacheSize;
        for (int i = 0; i < entriesToRemove; i++) {
          cache.remove(sortedEntries[i].key);
        }
      }

      await prefs.setString(_cacheKey, json.encode(cache));
    } catch (e) {
      // Silently handle cache errors
    }
  }

  /// Update frequently used UPI IDs
  static Future<void> _updateFrequentUpiIds(String upiId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final frequentData = prefs.getString(_frequentUpiKey);
      Map<String, int> frequentUpiIds = {};

      if (frequentData != null) {
        final Map<String, dynamic> data = json.decode(frequentData);
        frequentUpiIds = data.map((key, value) => MapEntry(key, value as int));
      }

      frequentUpiIds[upiId] = (frequentUpiIds[upiId] ?? 0) + 1;

      await prefs.setString(_frequentUpiKey, json.encode(frequentUpiIds));
    } catch (e) {
      // Silently handle cache errors
    }
  }

  /// Get frequently used UPI IDs
  static Future<List<String>> getFrequentUpiIds({int limit = 5}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final frequentData = prefs.getString(_frequentUpiKey);

      if (frequentData == null) return [];

      final Map<String, dynamic> data = json.decode(frequentData);
      final frequentUpiIds = data.map(
        (key, value) => MapEntry(key, value as int),
      );

      final sortedUpiIds = frequentUpiIds.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedUpiIds.take(limit).map((entry) => entry.key).toList();
    } catch (e) {
      return [];
    }
  }

  /// Check if cache is expired
  static bool _isCacheExpired(UpiAccountDetails details) {
    final now = DateTime.now();
    final difference = now.difference(details.lastUpdated);
    return difference.inHours >= _cacheExpiryHours;
  }

  /// Generate mock bank name based on UPI ID
  static String _generateBankName(String upiId) {
    final provider = upiId.split('@').last.toLowerCase();
    final bankMap = {
      'paytm': 'Paytm Payments Bank',
      'googlepay': 'Google Pay',
      'phonepe': 'PhonePe',
      'amazonpay': 'Amazon Pay',
      'mobikwik': 'MobiKwik',
      'freecharge': 'Freecharge',
      'airtel': 'Airtel Payments Bank',
      'jio': 'Jio Payments Bank',
      'sbi': 'State Bank of India',
      'hdfc': 'HDFC Bank',
      'icici': 'ICICI Bank',
      'axis': 'Axis Bank',
      'kotak': 'Kotak Mahindra Bank',
      'qrpay': 'QrPay Wallet',
    };

    return bankMap[provider] ?? 'Partner Bank';
  }

  /// Generate mock account number
  static String _generateAccountNumber() {
    final random = Random();
    final accountNumber = random.nextInt(999999999) + 100000000;
    return accountNumber.toString();
  }

  /// Clear all cached data
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_frequentUpiKey);
    } catch (e) {
      // Silently handle cache errors
    }
  }

  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = prefs.getString(_cacheKey);
      final frequentData = prefs.getString(_frequentUpiKey);

      int cacheSize = 0;
      int frequentSize = 0;

      if (cacheData != null) {
        final cache = json.decode(cacheData);
        cacheSize = cache.length;
      }

      if (frequentData != null) {
        final frequent = json.decode(frequentData);
        frequentSize = frequent.length;
      }

      return {
        'cacheSize': cacheSize,
        'frequentUpiCount': frequentSize,
        'maxCacheSize': _maxCacheSize,
        'cacheExpiryHours': _cacheExpiryHours,
      };
    } catch (e) {
      return {
        'cacheSize': 0,
        'frequentUpiCount': 0,
        'maxCacheSize': _maxCacheSize,
        'cacheExpiryHours': _cacheExpiryHours,
      };
    }
  }

}
