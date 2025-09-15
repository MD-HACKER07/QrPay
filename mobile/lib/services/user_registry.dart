import '../models/user.dart';
import 'mock_transaction_service.dart';

class UserRegistry {
  // Get all registered users for testing
  static List<User> getAllUsers() {
    MockTransactionService.initializeMockUsers();
    return MockTransactionService.getAllUsers();
  }
  
  // Get user by UPI ID
  static User? getUserByUpiId(String upiId) {
    return MockTransactionService.findUserByUpiId(upiId);
  }
  
  // Get user by phone number
  static User? getUserByPhone(String phoneNumber) {
    final users = getAllUsers();
    for (final user in users) {
      if (user.phoneNumber == phoneNumber) {
        return user;
      }
    }
    return null;
  }
  
  // Register a new user
  static void registerUser(User user) {
    MockTransactionService.registerUser(user);
  }
  
  // Get sample UPI IDs for testing
  static List<String> getSampleUpiIds() {
    return [
      '9570175954@qrpay',
      '9876543210@qrpay', 
      '8765432109@qrpay',
      '7654321098@qrpay',
    ];
  }
  
  // Get sample user info for display
  static List<Map<String, String>> getSampleUsers() {
    return [
      {'name': 'MD Abu Shalem Alam', 'upiId': '9570175954@qrpay', 'phone': '9570175954'},
      {'name': 'Rahul Kumar', 'upiId': '9876543210@qrpay', 'phone': '9876543210'},
      {'name': 'Priya Sharma', 'upiId': '8765432109@qrpay', 'phone': '8765432109'},
      {'name': 'Amit Singh', 'upiId': '7654321098@qrpay', 'phone': '7654321098'},
    ];
  }
}
