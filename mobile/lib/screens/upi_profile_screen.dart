import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/auth_provider.dart';
import '../services/mock_transaction_service.dart';
import '../services/firebase_service.dart';
import '../services/qr_service.dart';
import '../utils/transaction_utils.dart';
import '../widgets/secure_balance_widget.dart';
import 'payment_success_screen.dart';
import 'dart:math';

class UpiProfileScreen extends StatefulWidget {
  const UpiProfileScreen({super.key});

  @override
  State<UpiProfileScreen> createState() => _UpiProfileScreenState();
}

class _UpiProfileScreenState extends State<UpiProfileScreen> {
  double _balance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        final balance = authProvider.user?.balance ?? 0.0;
        setState(() {
          _balance = balance;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black),
          ),
        ),
        title: const Text(
          'My QR Code',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              _showTopUpInfo();
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.green),
            ),
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.user == null) {
            return const Center(
              child: Text('Please login to view your QR code'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile Card
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF667EEA),
                          Color(0xFF764BA2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667EEA).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Profile Picture
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: auth.user!.photoUrl != null
                                ? Image.network(
                                    auth.user!.photoUrl!,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.account_circle,
                                        color: Colors.white,
                                        size: 50,
                                      );
                                    },
                                  )
                                : const Icon(
                                    Icons.account_circle,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Name
                        Text(
                          auth.user!.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // UPI ID
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                auth.user!.upiId ?? 'Setting up UPI...',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (auth.user!.upiId != null) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: auth.user!.upiId!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('UPI ID copied to clipboard'),
                                        backgroundColor: Colors.green,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Icon(
                                    Icons.copy,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  onPressed: _promptSetupUpi,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white70),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  icon: const Icon(Icons.link, size: 16, color: Colors.white),
                                  label: const Text('Setup UPI'),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Balance
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.account_balance_wallet,
                              color: Colors.white70,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Consumer<AuthProvider>(
                              builder: (context, auth, child) {
                                final balance = auth.user?.balance ?? 0.0;
                                return SecureBalanceWidget(
                                  balance: balance,
                                  textStyle: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // QR Code Card
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Scan to Pay',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // QR Code with real UPI data
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: auth.user!.upiId != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: QrImageView(
                                    data: _generateUpiQrData(auth.user!.upiId!, auth.user!.name),
                                    version: QrVersions.auto,
                                    size: 200.0,
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.all(16),
                                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.qr_code_2,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Setup UPI ID\nto generate QR',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    FilledButton.icon(
                                      onPressed: _promptSetupUpi,
                                      icon: const Icon(Icons.qr_code_2),
                                      label: const Text('Generate QR'),
                                    ),
                                  ],
                                ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        const Text(
                          'Show this QR code to receive payments',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _shareQRCode(auth.user!),
                                icon: const Icon(Icons.share),
                                label: const Text('Share'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _copyUpiId(auth.user!.upiId!),
                                icon: const Icon(Icons.copy),
                                label: const Text('Copy UPI'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Money Management Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _showAddMoneyDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Money'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _showSendMoneyDialog,
                                icon: const Icon(Icons.send),
                                label: const Text('Send Money'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _generateUpiQrData(String upiId, String name) {
    // Generate UPI QR code data in standard format
    // Format: upi://pay?pa=UPI_ID&pn=NAME&cu=INR
    return 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(name)}&cu=INR';
  }

  Future<void> _shareQRCode(user) async {
    try {
      if (user.upiId == null) {
        _showErrorSnackBar('UPI ID not set up yet');
        return;
      }

      final shareText = '''💳 Pay me using UPI\n\nUPI ID: ${user.upiId}\nName: ${user.name}\n\nScan QR code or use UPI ID to send money instantly!\n\n🔒 Powered by QrPay - Secure & Fast Payments''';
      
      await Share.share(
        shareText,
        subject: 'Pay ${user.name} - QrPay',
      );
      
      // Add haptic feedback
      HapticFeedback.lightImpact();
    } catch (e) {
      _showErrorSnackBar('Failed to share QR code: ${e.toString()}');
    }
  }

  Future<void> _copyUpiId(String upiId) async {
    try {
      await Clipboard.setData(ClipboardData(text: upiId));
      HapticFeedback.selectionClick();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('UPI ID copied: $upiId'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to copy UPI ID');
    }
  }

  void _showQROptions(BuildContext context, user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'QR Code Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blue),
              title: const Text('Share QR Code'),
              subtitle: const Text('Share your payment QR via apps'),
              onTap: () {
                Navigator.pop(context);
                _shareQRCode(user);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.green),
              title: const Text('Copy UPI ID'),
              subtitle: Text('Copy ${user.upiId ?? 'UPI ID'}'),
              onTap: () {
                Navigator.pop(context);
                if (user.upiId != null) _copyUpiId(user.upiId!);
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_2, color: Colors.purple),
              title: const Text('Show Fullscreen QR'),
              subtitle: const Text('Display QR in fullscreen mode'),
              onTap: () {
                Navigator.pop(context);
                _showFullscreenQR(context, user);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.orange),
              title: const Text('QR Code Info'),
              subtitle: const Text('Learn about UPI QR codes'),
              onTap: () {
                Navigator.pop(context);
                _showQRInfo(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFullscreenQR(BuildContext context, user) {
    if (user.upiId == null) {
      _showErrorSnackBar('UPI ID not set up yet');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Scan to Pay'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                onPressed: () => _shareQRCode(user),
                icon: const Icon(Icons.share),
              ),
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: _generateUpiQrData(user.upiId!, user.name),
                    version: QrVersions.auto,
                    size: 300.0,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.all(16),
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user.upiId!,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Scan this QR code to pay me instantly',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showQRInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About UPI QR Codes'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How UPI QR Codes Work:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• QR codes contain your UPI ID and payment details'),
              Text('• Anyone can scan to send you money instantly'),
              Text('• Works with all UPI apps (GPay, PhonePe, Paytm, etc.)'),
              Text('• Secure and encrypted payment method'),
              SizedBox(height: 16),
              Text(
                'Safety Tips:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• Only share your QR code with trusted people'),
              Text('• Never scan unknown QR codes'),
              Text('• Verify payment details before confirming'),
              Text('• Keep your UPI PIN secure and private'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showAddMoneyDialog() async {
    final TextEditingController amountController = TextEditingController();
    bool isLoading = false;
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  const Text('Add Mock Money'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This is mock money for testing purposes only',
                              style: TextStyle(
                                color: Colors.blue[800],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Enter amount to add to your wallet:'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText: 'Amount (₹)',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.currency_rupee),
                        hintText: 'e.g., 1000',
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Quick amount buttons
                    Wrap(
                      spacing: 8,
                      children: [100, 500, 1000, 5000].map((amount) {
                        return ActionChip(
                          label: Text('₹$amount'),
                          onPressed: isLoading ? null : () {
                            amountController.text = amount.toString();
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: isLoading ? null : () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    final amount = double.tryParse(amountController.text);
                    if (amount != null && amount > 0 && amount <= 50000) {
                      setState(() {
                        isLoading = true;
                      });
                      
                      try {
                        // Real money addition would require bank integration
                        // For now, show that this requires proper banking setup
                        throw Exception('Real money addition requires bank account linking and KYC verification');
                      } catch (e) {
                        setState(() {
                          isLoading = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.error, color: Colors.white),
                                const SizedBox(width: 8),
                                Expanded(child: Text('Failed to add money: $e')),
                              ],
                            ),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } else if (amount != null && amount > 50000) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Maximum amount is ₹50,000'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid amount'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  child: isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add Money'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showSendMoneyDialog() async {
    final TextEditingController upiController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    final TextEditingController noteController = TextEditingController();
    bool isLoading = false;
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.send, color: Colors.orange[600]),
                  const SizedBox(width: 8),
                  const Text('Send Money'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[600], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Send mock money to another user via UPI ID',
                              style: TextStyle(
                                color: Colors.orange[800],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: upiController,
                      enabled: !isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Recipient UPI ID',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.alternate_email),
                        hintText: 'e.g., user@paytm',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      enabled: !isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Amount (₹)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.currency_rupee),
                        hintText: 'e.g., 500',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      enabled: !isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Note (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                        hintText: 'Payment for...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Current balance display
                    Consumer<AuthProvider>(
                      builder: (context, auth, child) {
                        final balance = auth.user?.balance ?? 0.0;
                        return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.account_balance_wallet, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Available Balance: ₹${balance.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: isLoading ? null : () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    final upiId = upiController.text.trim();
                    final amount = double.tryParse(amountController.text);
                    final note = noteController.text.trim();
                    
                    if (upiId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter recipient UPI ID'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid amount'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    final currentBalance = authProvider.user?.balance ?? 0.0;
                    
                    if (amount > currentBalance) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Insufficient balance'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    setState(() {
                      isLoading = true;
                    });
                    
                    try {
                      // Generate transaction ID
                      final transactionId = TransactionUtils.generateTransactionId();
                      
                      // Process UPI payment using MockTransactionService
                      await MockTransactionService.processUpiPayment(
                        fromUserId: authProvider.user!.id,
                        toUpiId: upiId,
                        amount: amount,
                        description: note.isEmpty ? 'Money Transfer' : note,
                      );
                      
                      // Refresh user data to get updated balance
                      await authProvider.refreshUser();
                      
                      // Update local balance
                      this.setState(() {
                        _balance = authProvider.user!.balance;
                      });
                      
                      Navigator.of(context).pop();
                      
                      // Navigate to animated success screen
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => PaymentSuccessScreen(
                            amount: amount,
                            recipientUpiId: upiId,
                            transactionId: TransactionUtils.formatTransactionId(transactionId),
                            description: note.isEmpty ? 'Money Transfer' : note,
                          ),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            const begin = Offset(0.0, 1.0);
                            const end = Offset.zero;
                            const curve = Curves.easeInOutCubic;

                            var tween = Tween(begin: begin, end: end).chain(
                              CurveTween(curve: curve),
                            );

                            return SlideTransition(
                              position: animation.drive(tween),
                              child: child,
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 500),
                        ),
                      );
                    } catch (e) {
                      setState(() {
                        isLoading = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.white),
                              const SizedBox(width: 8),
                              Expanded(child: Text('Transfer failed: $e')),
                            ],
                          ),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send Money'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addMoney(double amount) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user!;
      
      // Update balance locally and in Firestore
      final updatedUser = user.copyWith(
        balance: user.balance + amount,
        updatedAt: DateTime.now(),
      );
      
      await FirebaseService.updateUser(updatedUser);
      authProvider.updateUser(updatedUser);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('₹${amount.toStringAsFixed(2)} added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add money: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showTopUpInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Top-up'),
        content: const Text(
          'Add Money feature will be available soon. Your balance will be updated from the server when you add funds.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _promptSetupUpi() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) return;

    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Setup UPI'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: 'Enter your 10-digit phone number',
            ),
            validator: (v) {
              final value = (v ?? '').replaceAll(RegExp('[^0-9]'), '');
              if (value.length != 10) return 'Enter a valid 10-digit phone number';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final phone = phoneController.text.replaceAll(RegExp('[^0-9]'), '');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Setting up UPI...')),
      );

      await QRService.setupUserUPI(
        userId: authProvider.user!.id,
        phoneNumber: phone,
        name: authProvider.user!.name,
      );

      // Refresh user from Firestore and update provider
      final updated = await FirebaseService.getUser(authProvider.user!.id);
      if (updated != null) {
        authProvider.updateUser(updated);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('UPI setup complete!')),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to setup UPI: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

class QRCodePainter extends CustomPainter {
  final String data;
  
  QRCodePainter(this.data);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    
    final moduleSize = size.width / 25;
    final random = Random(data.hashCode);
    
    // Draw QR code pattern
    for (int y = 0; y < 25; y++) {
      for (int x = 0; x < 25; x++) {
        // Finder patterns (corners)
        bool isFinderPattern = (x < 7 && y < 7) || 
                              (x >= 18 && y < 7) || 
                              (x < 7 && y >= 18);
        
        if (isFinderPattern) {
          // Draw finder pattern
          if ((x == 0 || x == 6 || y == 0 || y == 6) ||
              (x >= 2 && x <= 4 && y >= 2 && y <= 4) ||
              (x >= 20 && x <= 24 && y == 0) ||
              (x >= 20 && x <= 24 && y == 6) ||
              (x >= 22 && x <= 24 && y >= 2 && y <= 4) ||
              (x == 0 && y >= 20 && y <= 24) ||
              (x == 6 && y >= 20 && y <= 24) ||
              (x >= 2 && x <= 4 && y >= 22 && y <= 24)) {
            canvas.drawRect(
              Rect.fromLTWH(x * moduleSize, y * moduleSize, moduleSize, moduleSize),
              paint,
            );
          }
        } else if (random.nextBool()) {
          canvas.drawRect(
            Rect.fromLTWH(x * moduleSize, y * moduleSize, moduleSize, moduleSize),
            paint,
          );
        }
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
