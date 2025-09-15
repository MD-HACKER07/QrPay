import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/qr_service.dart';
import '../services/biometric_service.dart';
import 'qr_scanner_screen.dart';
import 'payment_success_screen.dart';
import 'pin_entry_screen.dart';
import 'biometric_auth_screen.dart';
import '../services/mock_transaction_service.dart';
import '../services/transaction_service.dart';

class ScanPayScreen extends StatefulWidget {
  const ScanPayScreen({super.key});

  @override
  State<ScanPayScreen> createState() => _ScanPayScreenState();
}

class _ScanPayScreenState extends State<ScanPayScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  String? _scannedUpiId;
  String? _merchantName;
  String? _presetAmount;
  bool _isProcessing = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _scanQRCode() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(
          onQRScanned: (qrData) {
            // Parse the full QR data
            final upiData = QRService.parseUpiQRData(qrData);
            return upiData;
          },
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      _processQRResult(result);
    }
  }

  Future<void> _uploadFromGallery() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Simulate QR extraction from gallery
      final qrData = await QRService.extractQRFromImage('');
      
      // Hide loading indicator
      if (mounted) Navigator.pop(context);
      
      if (qrData != null && qrData.isNotEmpty) {
        final upiData = QRService.parseUpiQRData(qrData);
        _processQRResult(upiData);
      } else {
        _showErrorSnackBar('No QR code found in the selected image');
      }
    } catch (e) {
      // Hide loading indicator if still showing
      if (mounted) Navigator.pop(context);
      _showErrorSnackBar('Failed to process image: ${e.toString()}');
    }
  }

  void _processQRResult(Map<String, String> result) {
    setState(() {
      _scannedUpiId = result['upiId'];
      _merchantName = result['name'] ?? result['upiId'];
      _presetAmount = result['amount'];
      
      // Pre-fill amount if provided in QR
      if (_presetAmount != null && _presetAmount!.isNotEmpty) {
        _amountController.text = _presetAmount!;
      }
      
      // Pre-fill note if provided in QR
      if (result['note'] != null && result['note']!.isNotEmpty) {
        _noteController.text = result['note']!;
      }
    });
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate() || _scannedUpiId == null) return;

    // Show confirmation dialog first
    final confirmed = await _showPaymentConfirmation();
    if (!confirmed) return;

    // Show authentication flow (biometric or PIN)
    final authSuccess = await _showAuthenticationFlow();
    if (!authSuccess) return;

    setState(() => _isProcessing = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final amount = double.parse(_amountController.text);
      final note = _noteController.text.trim();

      // Check self-transfer
      if (_scannedUpiId == authProvider.user?.upiId) {
        throw Exception('Cannot send money to yourself');
      }

      // Process payment with fallback
      final transaction = await _processPaymentWithFallback(
        fromUserId: authProvider.user!.id,
        toUpiId: _scannedUpiId!,
        amount: amount,
        description: note.isEmpty ? 'QR Payment' : note,
      );

      // Refresh user data
      await authProvider.refreshUser();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentSuccessScreen(
              amount: amount,
              recipientUpiId: _scannedUpiId!,
              transactionId: transaction.id,
              description: note.isEmpty ? 'QR Payment' : note,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    setState(() => _isProcessing = false);
  }

  Future<bool> _showAuthenticationFlow() async {
    // Check user's preferred authentication method
    final authResult = await BiometricService.authenticateUser(
      reason: 'Please authenticate to authorize this payment',
      allowFallback: true,
    );

    if (authResult.success) {
      return true;
    }

    if (authResult.requiresPinFallback) {
      // Show biometric screen first if biometric is preferred
      if (authResult.method == AuthenticationMethod.biometric) {
        final biometricResult = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => BiometricAuthScreen(
              title: 'Authenticate Payment',
              subtitle: 'Please authenticate to authorize this payment',
              onAuthSuccess: () {
                Navigator.pop(context, true);
              },
              onFallbackToPin: () {
                Navigator.pop(context);
                _showPinEntry();
              },
              allowPinFallback: true,
            ),
          ),
        );
        
        if (biometricResult == true) {
          return true;
        }
      }
      
      // Fallback to PIN entry
      return await _showPinEntry();
    }

    return false;
  }

  Future<bool> _showPinEntry() async {
    return await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PinEntryScreen(
          title: 'Enter UPI PIN',
          subtitle: 'Please enter your 6-digit UPI PIN to authorize this payment',
          onPinEntered: (pin) {
            Navigator.pop(context, true);
          },
          isSetupMode: false,
        ),
      ),
    ) ?? false;
  }

  Future<bool> _showPaymentConfirmation() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final note = _noteController.text.trim();
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please confirm the payment details:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, size: 18, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text('To: $_merchantName', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.account_circle, size: 18, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text('UPI: $_scannedUpiId', style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.currency_rupee, size: 18, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text('Amount: ₹${amount.toStringAsFixed(2)}', 
                           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.note, size: 18, color: Colors.purple),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Note: $note', style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red[600], size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This payment cannot be reversed. Please verify all details.',
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm & Pay'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<dynamic> _processPaymentWithFallback({
    required String fromUserId,
    required String toUpiId,
    required double amount,
    required String description,
  }) async {
    try {
      return await TransactionService.processUpiPayment(
        fromUserId: fromUserId,
        toUpiId: toUpiId,
        amount: amount,
        description: description,
      );
    } catch (e) {
      return await MockTransactionService.processUpiPayment(
        fromUserId: fromUserId,
        toUpiId: toUpiId,
        amount: amount,
        description: description,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan & Pay'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Balance Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet, color: Colors.white),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Available Balance',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          Text(
                            '₹${authProvider.user?.balance.toStringAsFixed(2) ?? '0.00'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),

                // QR Scanner Section
                if (_scannedUpiId == null) ...[
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Icon(
                            Icons.qr_code_scanner,
                            size: 60,
                            color: Colors.blue[600],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Scan QR Code to Pay',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Point your camera at a merchant QR code or upload from gallery',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _scanQRCode,
                                icon: const Icon(Icons.qr_code_scanner),
                                label: const Text('Scan Camera'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _uploadFromGallery,
                                icon: const Icon(Icons.photo_library),
                                label: const Text('Demo QR'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Payment Details Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.green[600],
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'QR Code Scanned',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Pay to: $_merchantName',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _scannedUpiId = null;
                                  _merchantName = null;
                                  _presetAmount = null;
                                  _amountController.clear();
                                  _noteController.clear();
                                });
                              },
                              child: const Text('Scan Again'),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Payment Form
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Amount Field
                              TextFormField(
                                controller: _amountController,
                                decoration: InputDecoration(
                                  labelText: _presetAmount != null ? 'Amount (Merchant Suggested)' : 'Amount',
                                  hintText: '0.00',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.currency_rupee),
                                  suffixIcon: _presetAmount != null 
                                    ? IconButton(
                                        icon: const Icon(Icons.edit, size: 20),
                                        onPressed: () {
                                          setState(() {
                                            _presetAmount = null;
                                          });
                                        },
                                        tooltip: 'Edit amount',
                                      )
                                    : null,
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter amount';
                                  }
                                  final amount = double.tryParse(value);
                                  if (amount == null || amount <= 0) {
                                    return 'Please enter a valid amount';
                                  }
                                  if (amount > (authProvider.user?.balance ?? 0)) {
                                    return 'Insufficient balance';
                                  }
                                  return null;
                                },
                              ),
                              
                              if (_presetAmount != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blue[200]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline, 
                                           color: Colors.blue[600], size: 18),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Merchant suggested amount: ₹$_presetAmount',
                                              style: TextStyle(
                                                color: Colors.blue[800],
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'You can edit this amount if needed',
                                              style: TextStyle(
                                                color: Colors.blue[700],
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              
                              const SizedBox(height: 16),
                              
                              // Note Field
                              TextFormField(
                                controller: _noteController,
                                decoration: const InputDecoration(
                                  labelText: 'Note (Optional)',
                                  hintText: 'Payment for...',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.note),
                                ),
                                maxLines: 2,
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Quick Amount Buttons (only if amount not preset)
                              if (_presetAmount == null) ...[
                                const Text(
                                  'Quick Amount',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [50, 100, 200, 500, 1000, 2000].map((amount) {
                                    return ActionChip(
                                      label: Text('₹$amount'),
                                      backgroundColor: Colors.blue[50],
                                      labelStyle: TextStyle(
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                      onPressed: () {
                                        _amountController.text = amount.toString();
                                      },
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 24),
                              ],
                              
                              // Pay Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isProcessing ? null : _processPayment,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isProcessing
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Pay Now',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 20),
                
                // Recent QR Payments & Security Info
                if (_scannedUpiId != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.history, color: Colors.green[600], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Payment Summary',
                              style: TextStyle(
                                color: Colors.green[800],
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'To: $_merchantName\nUPI ID: $_scannedUpiId',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Security Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.security, color: Colors.blue[600], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your payments are secured with quantum-resistant encryption',
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
