import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction.dart' as model;
import '../models/user.dart';
import 'qr_service.dart';
import 'upi_directory_service.dart';

class TransactionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Process UPI payment
  static Future<model.Transaction> processUpiPayment({
    required String fromUserId,
    required String toUpiId,
    required double amount,
    required String description,
  }) async {
    try {
      // Validate amount
      if (amount <= 0) {
        throw Exception('Invalid amount');
      }

      // Get sender details
      final fromUserDoc = await _firestore.collection('users').doc(fromUserId).get();
      if (!fromUserDoc.exists) {
        throw Exception('Sender not found');
      }
      
      final fromUser = User.fromJson(fromUserDoc.data()!);
      
      // Check if sender has UPI ID
      if (fromUser.upiId == null || fromUser.upiId!.isEmpty) {
        throw Exception('Sender UPI ID not configured');
      }

      // Prevent self-payment
      if (fromUser.upiId == toUpiId) {
        throw Exception('Cannot send money to yourself');
      }
      
      // Check if sender has sufficient balance
      if (fromUser.balance < amount) {
        throw Exception('Insufficient balance. Current balance: ₹${fromUser.balance.toStringAsFixed(2)}');
      }

      // Find recipient using UPI Directory Service
      User? foundUser = await UpiDirectoryService.getUserByUpiId(toUpiId);
      
      User toUser;
      
      if (foundUser == null) {
        // Try searching by phone number if UPI follows phone@qrpay pattern
        if (toUpiId.contains('@qrpay')) {
          final phoneNumber = toUpiId.split('@')[0];
          foundUser = await UpiDirectoryService.getUserByPhoneNumber(phoneNumber);
          
          if (foundUser != null) {
            // Update user's UPI ID if it's missing or different
            if (foundUser.upiId != toUpiId) {
              await UpiDirectoryService.updateUserUpiId(foundUser.id, toUpiId);
              toUser = foundUser.copyWith(upiId: toUpiId);
            } else {
              toUser = foundUser;
            }
          } else {
            // Create a new user for this UPI ID
            toUser = await UpiDirectoryService.createUserWithUpiId(
              upiId: toUpiId,
              phoneNumber: phoneNumber,
            );
          }
        } else {
          throw Exception('Recipient UPI ID not found: $toUpiId. Please ensure the recipient is registered with QrPay.');
        }
      } else {
        toUser = foundUser;
      }

      // Generate transaction ID
      final transactionId = QRService.generateTransactionId();
      
      // Create transaction
      final transaction = model.Transaction(
        id: transactionId,
        fromUserId: fromUserId,
        toUserId: toUser.id,
        fromUpiId: fromUser.upiId!,
        toUpiId: toUpiId,
        amount: amount,
        description: description,
        type: model.TransactionType.send,
        status: model.TransactionStatus.completed,
        timestamp: DateTime.now(),
        fromUserName: fromUser.name,
        toUserName: toUser.name,
        fromUserPhoto: fromUser.photoUrl,
        toUserPhoto: toUser.photoUrl,
        txHash: _generateTxHash(transactionId),
      );

      // Start atomic transaction in Firestore for real money transfer
      await _firestore.runTransaction((firestoreTransaction) async {
        try {
          print('Starting Firestore transaction...');
          
          // PHASE 1: READ ALL DATA FIRST (Firestore requirement)
          print('Reading sender balance for user: $fromUserId');
          final senderSnapshot = await firestoreTransaction.get(
            _firestore.collection('users').doc(fromUserId)
          );
          
          print('Checking recipient document for: ${toUser.id}');
          final recipientSnapshot = await firestoreTransaction.get(
            _firestore.collection('users').doc(toUser.id)
          );
          
          // PHASE 2: VALIDATE READ DATA
          if (!senderSnapshot.exists) {
            throw Exception('Sender user document not found');
          }
          
          final senderData = senderSnapshot.data();
          print('Sender data: $senderData');
          
          final currentBalance = senderData?['balance']?.toDouble() ?? 0.0;
          print('Current balance: $currentBalance, Required: $amount');
          
          if (currentBalance < amount) {
            throw Exception('Insufficient balance. Current: ₹${currentBalance.toStringAsFixed(2)}, Required: ₹${amount.toStringAsFixed(2)}');
          }
          
          // PHASE 3: PERFORM ALL WRITES
          // Deduct from sender (real money transfer)
          print('Updating sender balance...');
          firestoreTransaction.update(
            _firestore.collection('users').doc(fromUserId),
            {
              'balance': FieldValue.increment(-amount),
              'updatedAt': FieldValue.serverTimestamp(),
            }
          );
          
          // Add to recipient (real money transfer)
          if (recipientSnapshot.exists) {
            print('Updating existing recipient balance...');
            firestoreTransaction.update(
              _firestore.collection('users').doc(toUser.id),
              {
                'balance': FieldValue.increment(amount),
                'updatedAt': FieldValue.serverTimestamp(),
              }
            );
          } else {
            print('Creating new recipient user document...');
            firestoreTransaction.set(
              _firestore.collection('users').doc(toUser.id),
              {
                'id': toUser.id,
                'name': toUser.name,
                'email': toUser.email,
                'phoneNumber': toUser.phoneNumber,
                'upiId': toUser.upiId,
                'balance': amount,
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              }
            );
          }
          
          // Save transaction for sender
          print('Saving sender transaction...');
          final senderTransactionData = transaction.toJson();
          print('Sender transaction data: $senderTransactionData');
          
          firestoreTransaction.set(
            _firestore.collection('users').doc(fromUserId).collection('transactions').doc(transactionId),
            senderTransactionData
          );
          
          // Save transaction for recipient (as receive type)
          print('Creating recipient transaction...');
          final receiveTransaction = model.Transaction(
            id: transactionId,
            fromUserId: fromUserId,
            toUserId: toUser.id,
            fromUpiId: fromUser.upiId!,
            toUpiId: toUpiId,
            amount: amount,
            description: description,
            type: model.TransactionType.receive,
            status: model.TransactionStatus.completed,
            timestamp: DateTime.now(),
            fromUserName: fromUser.name,
            toUserName: toUser.name,
            fromUserPhoto: fromUser.photoUrl,
            toUserPhoto: toUser.photoUrl,
            txHash: transaction.txHash,
          );
          
          final receiveTransactionData = receiveTransaction.toJson();
          print('Recipient transaction data: $receiveTransactionData');
          
          firestoreTransaction.set(
            _firestore.collection('users').doc(toUser.id).collection('transactions').doc(transactionId),
            receiveTransactionData
          );
          
          // Save to global transactions collection
          print('Saving to global transactions...');
          firestoreTransaction.set(
            _firestore.collection('transactions').doc(transactionId),
            senderTransactionData
          );
          
          print('Firestore transaction operations completed successfully');
          
        } catch (e) {
          print('Error in Firestore transaction: $e');
          print('Error type: ${e.runtimeType}');
          rethrow;
        }
      });

      print('Transaction completed successfully: $transactionId');
      
      return transaction.copyWith(status: model.TransactionStatus.completed);
      
    } catch (e) {
      throw Exception('Transaction failed: $e');
    }
  }

  // Process QR code payment
  static Future<model.Transaction> processQRPayment({
    required String fromUserId,
    required String qrData,
    double? customAmount,
    String? customNote,
  }) async {
    try {
      final qrInfo = QRService.parseUpiQRData(qrData);
      final toUpiId = qrInfo['upiId']!;
      final amount = customAmount ?? double.parse(qrInfo['amount'] ?? '0');
      final description = customNote ?? qrInfo['note'] ?? 'QR Payment';
      
      if (amount <= 0) {
        throw Exception('Invalid amount');
      }
      
      return await processUpiPayment(
        fromUserId: fromUserId,
        toUpiId: toUpiId,
        amount: amount,
        description: description,
      );
    } catch (e) {
      throw Exception('QR payment failed: $e');
    }
  }

  // Get user transactions
  static Future<List<model.Transaction>> getUserTransactions(String userId, {int limit = 50}) async {
    try {
      print('Getting transactions for user: $userId');
      
      // First check if user document exists
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        print('User document does not exist for: $userId');
        return [];
      }

      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      print('Found ${querySnapshot.docs.length} transaction documents');
      
      final transactions = querySnapshot.docs.map((doc) {
        try {
          final data = doc.data();
          print('Transaction data: $data');
          return model.Transaction.fromJson(data);
        } catch (e) {
          print('Error parsing transaction ${doc.id}: $e');
          return null;
        }
      }).where((t) => t != null).cast<model.Transaction>().toList();
      
      print('Successfully parsed ${transactions.length} transactions');
      return transactions;
    } catch (e) {
      print('Error getting user transactions: $e');
      return [];
    }
  }

  // Get transaction by ID
  static Future<model.Transaction?> getTransaction(String transactionId) async {
    try {
      final doc = await _firestore.collection('transactions').doc(transactionId).get();
      if (doc.exists) {
        return model.Transaction.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get transaction: $e');
    }
  }


  // Generate mock transaction hash
  static String _generateTxHash(String transactionId) {
    final random = Random.secure();
    final chars = '0123456789abcdef';
    return List.generate(64, (index) => chars[random.nextInt(chars.length)]).join();
  }


  // Validate UPI ID exists
  static Future<User?> findUserByUpiId(String upiId) async {
    try {
      // Centralized lookup handles case-insensitive and fallback scans
      return await UpiDirectoryService.getUserByUpiId(upiId);
    } catch (e) {
      throw Exception('Failed to find user: $e');
    }
  }

  // Get user balance
  static Future<double> getUserBalance(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final user = User.fromJson(doc.data()!);
        return user.balance;
      }
      return 0.0;
    } catch (e) {
      throw Exception('Failed to get balance: $e');
    }
  }
}

extension TransactionExtension on model.Transaction {
  model.Transaction copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    String? fromUpiId,
    String? toUpiId,
    double? amount,
    String? description,
    model.TransactionType? type,
    model.TransactionStatus? status,
    DateTime? timestamp,
    String? signature,
    String? txHash,
    String? fromUserName,
    String? toUserName,
    String? fromUserPhoto,
    String? toUserPhoto,
  }) {
    return model.Transaction(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      fromUpiId: fromUpiId ?? this.fromUpiId,
      toUpiId: toUpiId ?? this.toUpiId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      signature: signature ?? this.signature,
      txHash: txHash ?? this.txHash,
      fromUserName: fromUserName ?? this.fromUserName,
      toUserName: toUserName ?? this.toUserName,
      fromUserPhoto: fromUserPhoto ?? this.fromUserPhoto,
      toUserPhoto: toUserPhoto ?? this.toUserPhoto,
    );
  }
}
