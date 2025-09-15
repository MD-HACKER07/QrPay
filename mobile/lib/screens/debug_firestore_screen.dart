import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/upi_directory_service.dart';
import '../models/user.dart';

class DebugFirestoreScreen extends StatefulWidget {
  const DebugFirestoreScreen({super.key});

  @override
  State<DebugFirestoreScreen> createState() => _DebugFirestoreScreenState();
}

class _DebugFirestoreScreenState extends State<DebugFirestoreScreen> {
  final _upiController = TextEditingController(text: '9561712911@qrpay');
  String _debugOutput = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Firestore'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _upiController,
              decoration: const InputDecoration(
                labelText: 'UPI ID to test',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testDirectFirestoreQuery,
              child: _isLoading 
                ? const CircularProgressIndicator()
                : const Text('Test Direct Firestore Query'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _testUpiDirectoryService,
              child: const Text('Test UPI Directory Service'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _listAllUsers,
              child: const Text('List All Users'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _debugOutput,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testDirectFirestoreQuery() async {
    setState(() {
      _isLoading = true;
      _debugOutput = 'Testing direct Firestore query...\n';
    });

    try {
      final upiId = _upiController.text.trim();
      _addToOutput('Searching for UPI ID: "$upiId"');
      
      final firestore = FirebaseFirestore.instance;
      
      // Test exact match
      _addToOutput('Testing exact match query...');
      final exactQuery = await firestore
          .collection('users')
          .where('upiId', isEqualTo: upiId)
          .get();
      
      _addToOutput('Exact match returned ${exactQuery.docs.length} documents');
      
      if (exactQuery.docs.isNotEmpty) {
        final data = exactQuery.docs.first.data();
        _addToOutput('Found user: ${data['name']} with UPI: ${data['upiId']}');
        _addToOutput('Full user data: $data');
      } else {
        _addToOutput('No exact match found');
        
        // Test case variations
        final lowerUpi = upiId.toLowerCase();
        _addToOutput('Testing lowercase: "$lowerUpi"');
        
        final lowerQuery = await firestore
            .collection('users')
            .where('upiId', isEqualTo: lowerUpi)
            .get();
        
        _addToOutput('Lowercase query returned ${lowerQuery.docs.length} documents');
        
        if (lowerQuery.docs.isNotEmpty) {
          final data = lowerQuery.docs.first.data();
          _addToOutput('Found via lowercase: ${data['name']} with UPI: ${data['upiId']}');
        }
      }
      
    } catch (e) {
      _addToOutput('ERROR: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _testUpiDirectoryService() async {
    setState(() {
      _isLoading = true;
      _debugOutput = 'Testing UPI Directory Service...\n';
    });

    try {
      final upiId = _upiController.text.trim();
      _addToOutput('Using UpiDirectoryService.getUserByUpiId("$upiId")');
      
      final user = await UpiDirectoryService.getUserByUpiId(upiId);
      
      if (user != null) {
        _addToOutput('SUCCESS: Found user via UpiDirectoryService');
        _addToOutput('Name: ${user.name}');
        _addToOutput('UPI: ${user.upiId}');
        _addToOutput('Phone: ${user.phoneNumber}');
        _addToOutput('Email: ${user.email}');
      } else {
        _addToOutput('FAILED: UpiDirectoryService returned null');
      }
      
    } catch (e) {
      _addToOutput('ERROR: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _listAllUsers() async {
    setState(() {
      _isLoading = true;
      _debugOutput = 'Listing all users...\n';
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final allUsers = await firestore.collection('users').limit(10).get();
      
      _addToOutput('Found ${allUsers.docs.length} users in database:');
      
      for (final doc in allUsers.docs) {
        final data = doc.data();
        final name = data['name'] ?? 'Unknown';
        final upiId = data['upiId'] ?? 'No UPI';
        final phone = data['phoneNumber'] ?? 'No Phone';
        _addToOutput('- $name | UPI: $upiId | Phone: $phone');
      }
      
    } catch (e) {
      _addToOutput('ERROR: $e');
    }

    setState(() => _isLoading = false);
  }

  void _addToOutput(String message) {
    setState(() {
      _debugOutput += '$message\n';
    });
  }
}
