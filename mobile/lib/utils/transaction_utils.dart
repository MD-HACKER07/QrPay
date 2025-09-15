import 'dart:math';

class TransactionUtils {
  static String generateTransactionId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = random.nextInt(9999).toString().padLeft(4, '0');
    
    // Format: QRP + timestamp last 8 digits + random 4 digits
    final timestampStr = timestamp.toString();
    final shortTimestamp = timestampStr.substring(timestampStr.length - 8);
    
    return 'QRP$shortTimestamp$randomSuffix';
  }

  static String formatTransactionId(String transactionId) {
    // Add spaces for better readability: QRP 12345678 9012
    if (transactionId.length >= 15) {
      return '${transactionId.substring(0, 3)} ${transactionId.substring(3, 11)} ${transactionId.substring(11)}';
    }
    return transactionId;
  }

  static String generateUpiTransactionRef() {
    final random = Random();
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(12, (index) => chars[random.nextInt(chars.length)]).join();
  }
}
