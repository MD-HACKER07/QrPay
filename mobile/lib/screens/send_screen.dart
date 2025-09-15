import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../services/upi_account_service.dart';
import '../services/auth_service.dart';
import '../services/transaction_service.dart';
import '../widgets/frequent_contacts_widget.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/payment_success_animation.dart';
import 'qr_scanner_screen.dart';
import 'user_directory_screen.dart';
import 'upi_settings_screen.dart';
import '../services/qr_service.dart';
import 'dart:async';

class SendScreen extends StatefulWidget {
  final String? prefilledUpiId;
  final String? prefilledAmount;
  final String? prefilledNote;

  const SendScreen({
    super.key,
    this.prefilledUpiId,
    this.prefilledAmount,
    this.prefilledNote,
  });

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _upiController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isValidatingUpi = false;
  bool _isSending = false;
  UpiAccountDetails? _recipientDetails;
  String? _validationMessage;
  bool? _isUpiValid;
  Timer? _validationTimer;
  bool _isAmountFocused = false;
  bool _isNoteFocused = false;
  final FocusNode _amountFocusNode = FocusNode();
  final FocusNode _noteFocusNode = FocusNode();

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _prefillData();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutQuart,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));


    _slideController.forward();
    _fadeController.forward();
    _pulseController.repeat(reverse: true);

    // Focus listeners
    _amountFocusNode.addListener(() {
      setState(() {
        _isAmountFocused = _amountFocusNode.hasFocus;
      });
    });
    
    _noteFocusNode.addListener(() {
      setState(() {
        _isNoteFocused = _noteFocusNode.hasFocus;
      });
    });
  }

  void _prefillData() {
    if (widget.prefilledUpiId != null) {
      _upiController.text = widget.prefilledUpiId!;
      _validateUpiId(widget.prefilledUpiId!);
    }
    if (widget.prefilledAmount != null) {
      _amountController.text = widget.prefilledAmount!;
    }
    if (widget.prefilledNote != null) {
      _noteController.text = widget.prefilledNote!;
    }
  }

  @override
  void dispose() {
    _upiController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _validationTimer?.cancel();
    _amountFocusNode.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  bool _isValidUpiFormat(String upiId) {
    if (upiId.isEmpty) return false;

    // Must contain exactly one @ symbol
    final parts = upiId.split('@');
    if (parts.length != 2) return false;

    final username = parts[0];
    final provider = parts[1];

    // Username should not be empty and should be alphanumeric
    if (username.isEmpty || !RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(username)) {
      return false;
    }

    // Provider should not be empty
    if (provider.isEmpty) return false;

    return true;
  }

  Future<void> _validateUpiId(String upiId) async {
    // Cancel previous validation timer
    _validationTimer?.cancel();
    
    if (upiId.trim().isEmpty) {
      setState(() {
        _recipientDetails = null;
        _validationMessage = null;
        _isUpiValid = null;
        _isValidatingUpi = false;
      });
      return;
    }

    // Basic format validation
    final trimmedUpi = upiId.trim();
    if (!_isValidUpiFormat(trimmedUpi)) {
      setState(() {
        _recipientDetails = null;
        _validationMessage = '⚠️ Invalid UPI ID format';
        _isUpiValid = false;
        _isValidatingUpi = false;
      });
      return;
    }

    // Debounce validation - wait 500ms before validating
    _validationTimer = Timer(const Duration(milliseconds: 500), () async {
      setState(() {
        _isValidatingUpi = true;
        _validationMessage = '🔍 Verifying UPI ID...';
        _isUpiValid = null;
      });

      try {
        final accountDetails = await UpiAccountService.getAccountDetails(
          trimmedUpi,
        );

        if (accountDetails != null) {
          final currentUser = AuthService.getCurrentUser();
          if (currentUser?.upiId == trimmedUpi) {
            setState(() {
              _recipientDetails = null;
              _validationMessage = '❌ Cannot send money to yourself';
              _isUpiValid = false;
              _isValidatingUpi = false;
            });
          } else {
            setState(() {
              _recipientDetails = accountDetails;
              _validationMessage = '✅ Valid recipient found';
              _isUpiValid = true;
              _isValidatingUpi = false;
            });
            // Haptic feedback for success
            HapticFeedback.lightImpact();
          }
        } else {
          setState(() {
            _recipientDetails = null;
            _validationMessage = '❌ UPI ID not found';
            _isUpiValid = false;
            _isValidatingUpi = false;
          });
        }
      } catch (e) {
        setState(() {
          _recipientDetails = null;
          _validationMessage = '⚠️ Unable to verify UPI ID';
          _isUpiValid = false;
          _isValidatingUpi = false;
        });
      }
    });
  }

  Future<void> _scanQRCode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(
          onQRScanned: (qrData) {
            final data = QRService.parseUpiQRData(qrData);
            if (data['upiId'] != null && data['upiId']!.isNotEmpty) {
              _upiController.text = data['upiId']!;
              _validateUpiId(data['upiId']!);
            }
            if (data['amount'] != null && data['amount']!.isNotEmpty) {
              _amountController.text = data['amount']!;
            }
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _selectFromContacts() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserDirectoryScreen()),
    );
    if (result != null && result is String) {
      _upiController.text = result;
      _validateUpiId(result);
    }
  }

  Future<void> _sendMoney() async {
    // Check UPI validation first before form validation
    final upiId = _upiController.text.trim();
    if (upiId.isNotEmpty && _isUpiValid != true) {
      await _validateUpiId(upiId);
      if (_isUpiValid != true) {
        return;
      }
    }

    // Force form validation and check result
    final isFormValid = _formKey.currentState!.validate();
    print('Form validation result: $isFormValid');
    print('UPI Controller text: "${_upiController.text}"');

    if (!isFormValid) {
      print('Form validation failed, stopping send process');
      return;
    }

    final currentUser = AuthService.getCurrentUser();
    if (currentUser == null) {
      _showErrorDialog('Authentication Error', 'Please sign in to continue.');
      return;
    }

    // Refresh user data to get latest UPI configuration
    final refreshedUser = await AuthService.refreshCurrentUser();
    
    if (refreshedUser?.upiId == null || refreshedUser!.upiId!.isEmpty) {
      _showErrorDialog(
        'UPI Not Configured',
        'Please configure your UPI ID before sending money.',
        actionText: 'Configure UPI',
        onAction: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UpiSettingsScreen()),
        ),
      );
      return;
    }

    // Check if UPI ID is filled
    if (upiId.isEmpty) {
      _showErrorDialog('Missing UPI ID', 'Please enter a valid UPI ID.');
      return;
    }

    // Re-validate UPI ID if not already validated or if validation failed
    if (_isUpiValid != true) {
      await _validateUpiId(upiId);

      // Check again after validation
      if (_isUpiValid != true) {
        throw Exception(_validationMessage ?? 'Invalid UPI ID');
      }
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showErrorDialog('Invalid Amount', 'Please enter a valid amount.');
      return;
    }

    if (currentUser.balance < amount) {
      _showErrorDialog(
        'Insufficient Balance',
        'Your current balance is ₹${currentUser.balance.toStringAsFixed(2)}. Please add money to your wallet.',
        actionText: 'Add Money',
        onAction: () => Navigator.pop(context),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(amount);
    if (!confirmed) return;

    setState(() => _isSending = true);

    try {
      await _processPayment(
        fromUserId: currentUser.id,
        toUpiId: _upiController.text.trim(),
        amount: amount,
        description: _noteController.text.trim().isEmpty
            ? 'Payment'
            : _noteController.text.trim(),
      );

      _showSuccessAnimation(amount);
    } catch (e) {
      _showErrorDialog(
        'Payment Failed',
        e.toString().replaceFirst('Exception: ', ''),
        showRetry: true,
        onRetry: _sendMoney,
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<bool> _showConfirmationDialog(double amount) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Confirm Payment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_recipientDetails != null) ...[
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.blue.shade100,
                        backgroundImage: _recipientDetails!.profileImage != null
                            ? NetworkImage(_recipientDetails!.profileImage!)
                            : null,
                        child: _recipientDetails!.profileImage == null
                            ? Text(
                                _recipientDetails!.displayName[0].toUpperCase(),
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _recipientDetails!.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _recipientDetails!.upiId,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Amount:'),
                    Text(
                      '₹${amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                if (_noteController.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Note:'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _noteController.text.trim(),
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _processPayment({
    required String fromUserId,
    required String toUpiId,
    required double amount,
    required String description,
  }) async {
    // Use real money transfer via TransactionProvider
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    await transactionProvider.sendPayment(
      toUpiId: toUpiId,
      amount: amount,
      description: description,
    );
  }

  void _showSuccessAnimation(double amount) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => PaymentSuccessAnimation(
          amount: amount,
          recipientName: _recipientDetails?.displayName ?? '',
          recipientUpiId: _upiController.text.trim(),
          onComplete: () {
            Navigator.of(context).pop(); // Close animation
            Navigator.of(context).pop(); // Go back to previous screen
          },
        ),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _showErrorDialog(
    String title,
    String message, {
    bool showRetry = false,
    VoidCallback? onRetry,
    String? actionText,
    VoidCallback? onAction,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          if (showRetry && onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
          if (actionText != null && onAction != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onAction();
              },
              child: Text(actionText),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Send Money'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.textTheme.bodyLarge?.color,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      FadeInDown(
                        duration: const Duration(milliseconds: 600),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.primaryColor,
                                theme.primaryColor.withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: theme.primaryColor.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Send Money',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Transfer money instantly using UPI',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Frequent Contacts
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 200),
                        child: FrequentContactsWidget(
                          onContactSelected: (upiId) {
                            _upiController.text = upiId;
                            _validateUpiId(upiId);
                          },
                        ),
                      ),

                      // Recipient Section
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 300),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recipient',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // UPI ID Input
                            TextFormField(
                              controller: _upiController,
                              decoration: InputDecoration(
                                labelText: 'UPI ID',
                                hintText: 'Enter UPI ID (e.g. user@paytm)',
                                prefixIcon: const Icon(Icons.alternate_email),
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.contacts),
                                      onPressed: _selectFromContacts,
                                      tooltip: 'Select from contacts',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.qr_code_scanner),
                                      onPressed: _scanQRCode,
                                      tooltip: 'Scan QR code',
                                    ),
                                  ],
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                filled: true,
                                fillColor: theme.cardColor,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a UPI ID';
                                }
                                if (!_isValidUpiFormat(value.trim())) {
                                  return 'Invalid UPI ID format';
                                }
                                // Only show validation error if we've explicitly validated and it failed
                                if (_isUpiValid == false && !_isValidatingUpi) {
                                  return _validationMessage ?? 'UPI ID not found';
                                }
                                return null;
                              },
                              onChanged: (value) => _validateUpiId(value),
                            ),

                            // Validation Status
                            if (_validationMessage != null) ...[
                              const SizedBox(height: 12),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _isUpiValid == true
                                      ? Colors.green.shade50
                                      : _isUpiValid == false
                                      ? Colors.red.shade50
                                      : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _isUpiValid == true
                                        ? Colors.green.shade200
                                        : _isUpiValid == false
                                        ? Colors.red.shade200
                                        : Colors.blue.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    if (_isValidatingUpi)
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                theme.primaryColor,
                                              ),
                                        ),
                                      )
                                    else
                                      Icon(
                                        _isUpiValid == true
                                            ? Icons.check_circle
                                            : Icons.error,
                                        color: _isUpiValid == true
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                        size: 16,
                                      ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _validationMessage!,
                                        style: TextStyle(
                                          color: _isUpiValid == true
                                              ? Colors.green.shade700
                                              : _isUpiValid == false
                                              ? Colors.red.shade700
                                              : Colors.blue.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Recipient Details Card
                            if (_recipientDetails != null &&
                                _isUpiValid == true) ...[
                              const SizedBox(height: 16),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.green.shade200,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Colors.green.shade100,
                                      backgroundImage:
                                          _recipientDetails!.profileImage !=
                                              null
                                          ? NetworkImage(
                                              _recipientDetails!.profileImage!,
                                            )
                                          : null,
                                      child:
                                          _recipientDetails!.profileImage ==
                                              null
                                          ? Text(
                                              _recipientDetails!.displayName[0]
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                color: Colors.green.shade700,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  _recipientDetails!
                                                      .displayName,
                                                  style: theme
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                              ),
                                              if (_recipientDetails!.isVerified)
                                                Icon(
                                                  Icons.verified,
                                                  color: Colors.green.shade600,
                                                  size: 20,
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _recipientDetails!.bankName ??
                                                'Bank Account',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: Colors.grey.shade600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Amount Section
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 400),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Amount',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: _isAmountFocused
                                    ? LinearGradient(
                                        colors: [
                                          const Color(0xFF4F46E5).withOpacity(0.1),
                                          const Color(0xFF7C3AED).withOpacity(0.1),
                                        ],
                                      )
                                    : null,
                                boxShadow: _isAmountFocused
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF4F46E5).withOpacity(0.2),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: TextFormField(
                                controller: _amountController,
                                focusNode: _amountFocusNode,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}'),
                                  ),
                                ],
                                decoration: InputDecoration(
                                  labelText: 'Enter amount',
                                  hintText: '₹ 0.00',
                                  prefixIcon: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    child: Icon(
                                      Icons.currency_rupee_rounded,
                                      color: _isAmountFocused
                                          ? const Color(0xFF4F46E5)
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                  suffixIcon: _amountController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            _amountController.clear();
                                            setState(() {});
                                          },
                                        )
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 2,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF4F46E5),
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: _isAmountFocused
                                      ? Colors.white
                                      : theme.cardColor,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 20,
                                  ),
                                ),
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1F2937),
                                ),
                                onChanged: (value) {
                                  setState(() {});
                                  HapticFeedback.selectionClick();
                                },
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return '💰 Please enter amount';
                                  }
                                  final amount = double.tryParse(value.trim());
                                  if (amount == null || amount <= 0) {
                                    return '⚠️ Please enter valid amount';
                                  }
                                  if (amount > 100000) {
                                    return '⚠️ Maximum amount is ₹1,00,000';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Note Section
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 500),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Note (Optional)',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: _isNoteFocused
                                    ? LinearGradient(
                                        colors: [
                                          const Color(0xFF10B981).withOpacity(0.1),
                                          const Color(0xFF059669).withOpacity(0.1),
                                        ],
                                      )
                                    : null,
                              ),
                              child: TextFormField(
                                controller: _noteController,
                                focusNode: _noteFocusNode,
                                decoration: InputDecoration(
                                  labelText: 'Add a note',
                                  hintText: '💬 What\'s this payment for?',
                                  prefixIcon: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    child: Icon(
                                      Icons.sticky_note_2_rounded,
                                      color: _isNoteFocused
                                          ? const Color(0xFF10B981)
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                  suffixIcon: _noteController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            _noteController.clear();
                                            setState(() {});
                                          },
                                        )
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 2,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF10B981),
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: _isNoteFocused
                                      ? Colors.white
                                      : theme.cardColor,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                                maxLines: 3,
                                onChanged: (value) {
                                  setState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Send Button
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 600),
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            final canSend = _isUpiValid == true && 
                                           _amountController.text.isNotEmpty &&
                                           !_isSending;
                            
                            return Transform.scale(
                              scale: canSend ? _pulseAnimation.value : 1.0,
                              child: Container(
                                width: double.infinity,
                                height: 64,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: canSend
                                        ? [
                                            const Color(0xFF4F46E5),
                                            const Color(0xFF7C3AED),
                                          ]
                                        : [
                                            Colors.grey.shade400,
                                            Colors.grey.shade500,
                                          ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: canSend
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF4F46E5).withOpacity(0.4),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(24),
                                    onTap: canSend ? () {
                                      HapticFeedback.mediumImpact();
                                      _sendMoney();
                                    } : null,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 16,
                                      ),
                                      child: _isSending
                                          ? Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 3,
                                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                                      Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                const Text(
                                                  '⚡ Processing...',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.flash_on_rounded,
                                                  color: Colors.white,
                                                  size: 28,
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  canSend ? '⚡ Send Instantly' : 'Enter Details',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      // Quick Amount Buttons
                      if (!_isSending) ...[
                        const SizedBox(height: 24),
                        FadeInUp(
                          duration: const Duration(milliseconds: 600),
                          delay: const Duration(milliseconds: 700),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quick Amount',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildQuickAmountButton('₹100', 100),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildQuickAmountButton('₹500', 500),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildQuickAmountButton('₹1000', 1000),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildQuickAmountButton('₹2000', 2000),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickAmountButton(String label, double amount) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _amountController.text = amount.toString();
            setState(() {});
            HapticFeedback.lightImpact();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _amountController.text == amount.toString()
                    ? const Color(0xFF4F46E5)
                    : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _amountController.text == amount.toString()
                    ? const Color(0xFF4F46E5)
                    : Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
