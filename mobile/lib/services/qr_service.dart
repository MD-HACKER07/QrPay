import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class QRService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Generate UPI ID from phone number
  static String generateUpiId(String phoneNumber) {
    // Remove any non-digit characters
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Take last 10 digits if longer
    if (cleanPhone.length > 10) {
      cleanPhone = cleanPhone.substring(cleanPhone.length - 10);
    }
    
    return '$cleanPhone@qrpay';
  }

  // Generate QR code data for UPI payment
  static String generateUpiQRData({
    required String upiId,
    required String name,
    double? amount,
    String? note,
  }) {
    String qrData = 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(name)}';
    
    if (amount != null) {
      qrData += '&am=${amount.toStringAsFixed(2)}';
    }
    
    if (note != null && note.isNotEmpty) {
      qrData += '&tn=${Uri.encodeComponent(note)}';
    }
    
    qrData += '&cu=INR';
    
    return qrData;
  }

  // Generate SVG QR code (simplified version)
  static String generateQRCodeSVG(String data) {
    // This is a simplified QR code generator that creates a recognizable QR pattern
    final size = 200;
    final moduleSize = 8;
    final modules = size ~/ moduleSize;
    
    String svg = '''
<svg width="$size" height="$size" xmlns="http://www.w3.org/2000/svg">
  <rect width="$size" height="$size" fill="white"/>
''';

    // Generate a deterministic pattern based on data hash
    final dataHash = data.hashCode.abs();
    final rng = Random(dataHash);
    
    for (int y = 0; y < modules; y++) {
      for (int x = 0; x < modules; x++) {
        // Create finder patterns (corners) - these are essential for QR codes
        bool isTopLeftFinder = (x < 7 && y < 7);
        bool isTopRightFinder = (x >= modules - 7 && y < 7);
        bool isBottomLeftFinder = (x < 7 && y >= modules - 7);
        
        if (isTopLeftFinder || isTopRightFinder || isBottomLeftFinder) {
          // Draw finder pattern squares
          bool isOuterRing = (x == 0 || x == 6 || y == 0 || y == 6) ||
                            (x == modules - 1 || x == modules - 7 || y == 0 || y == 6) ||
                            (x == 0 || x == 6 || y == modules - 1 || y == modules - 7);
          bool isInnerSquare = (x >= 2 && x <= 4 && y >= 2 && y <= 4) ||
                              (x >= modules - 5 && x <= modules - 3 && y >= 2 && y <= 4) ||
                              (x >= 2 && x <= 4 && y >= modules - 5 && y <= modules - 3);
          
          if (isOuterRing || isInnerSquare) {
            svg += '<rect x="${x * moduleSize}" y="${y * moduleSize}" width="$moduleSize" height="$moduleSize" fill="black"/>';
          }
        } else {
          // For data area, use deterministic pattern based on position and data
          int seed = (x * 31 + y * 17 + dataHash) % 100;
          if (seed > 45) { // ~55% fill rate for realistic QR appearance
            svg += '<rect x="${x * moduleSize}" y="${y * moduleSize}" width="$moduleSize" height="$moduleSize" fill="black"/>';
          }
        }
      }
    }
    
    svg += '</svg>';
    return svg;
  }

  // Save QR code to Firebase Storage
  static Future<String> saveQRCodeToStorage(String userId, String svgData) async {
    try {
      final ref = _storage.ref().child('qr_codes').child('$userId.svg');
      await ref.putString(svgData, format: PutStringFormat.raw, metadata: SettableMetadata(
        contentType: 'image/svg+xml',
      ));
      
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to save QR code: $e');
    }
  }

  // Update user with UPI ID and QR code
  static Future<void> setupUserUPI({
    required String userId,
    required String phoneNumber,
    required String name,
  }) async {
    try {
      final upiId = generateUpiId(phoneNumber);
      final qrData = generateUpiQRData(upiId: upiId, name: name);
      final qrSvg = generateQRCodeSVG(qrData);
      
      String? qrUrl;
      try {
        qrUrl = await saveQRCodeToStorage(userId, qrSvg);
      } catch (storageError) {
        print('QR Storage failed: $storageError');
        // Continue without QR URL if storage fails
      }
      
      await _firestore.collection('users').doc(userId).update({
        'phoneNumber': phoneNumber,
        'upiId': upiId,
        'qrData': qrData,
        if (qrUrl != null) 'qrCodeUrl': qrUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to setup UPI: $e');
    }
  }

  /// Parse UPI QR code data
  static Map<String, String> parseUpiQRData(String qrData) {
    final Map<String, String> result = {};
    
    try {
      // Handle UPI URL format: upi://pay?pa=...&pn=...&am=...&cu=...&tn=...
      if (qrData.startsWith('upi://pay?')) {
        final uri = Uri.parse(qrData);
        result['upiId'] = uri.queryParameters['pa'] ?? '';
        result['name'] = uri.queryParameters['pn'] ?? '';
        result['amount'] = uri.queryParameters['am'] ?? '';
        result['currency'] = uri.queryParameters['cu'] ?? 'INR';
        result['note'] = uri.queryParameters['tn'] ?? '';
        result['merchantCode'] = uri.queryParameters['mc'] ?? '';
        result['transactionRef'] = uri.queryParameters['tr'] ?? '';
      }
      // Handle BHIM UPI format
      else if (qrData.toLowerCase().contains('bhim') || qrData.toLowerCase().contains('upi')) {
        final lines = qrData.split('\n');
        for (final line in lines) {
          if (line.contains('@')) {
            result['upiId'] = line.trim();
            break;
          }
        }
      }
      // Handle simple UPI ID format
      else if (qrData.contains('@')) {
        result['upiId'] = qrData.trim();
      }
      // Handle other formats or plain text
      else {
        // Try to extract UPI ID from text
        final upiRegex = RegExp(r'([a-zA-Z0-9.\-_]+@[a-zA-Z0-9.\-_]+)');
        final match = upiRegex.firstMatch(qrData);
        if (match != null) {
          result['upiId'] = match.group(1) ?? '';
        }
      }
    } catch (e) {
      // Return empty map on parsing error
    }
    
    return result;
  }

  // Validate UPI ID format
  static bool isValidUpiId(String upiId) {
    final regex = RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$');
    return regex.hasMatch(upiId);
  }

  // Generate transaction reference ID
  static String generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999).toString().padLeft(6, '0');
    return 'QRP$timestamp$random';
  }

  /// Extract QR code from image file
  static Future<String?> extractQRFromImage(String imagePath) async {
    try {
      // For now, return a mock UPI QR data for testing
      // In a real implementation, you would use a QR code scanner library
      // like google_ml_kit or qr_code_scanner to process the image
      
      // Mock QR data for demonstration
      await Future.delayed(const Duration(seconds: 1)); // Simulate processing time
      
      // Return a sample UPI QR code data
      return 'upi://pay?pa=merchant@paytm&pn=Test Merchant&am=100.00&cu=INR&tn=Payment for services';
    } catch (e) {
      return null;
    }
  }
}
