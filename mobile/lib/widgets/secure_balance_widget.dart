import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/pin_service.dart';
import '../screens/pin_entry_screen.dart';

class SecureBalanceWidget extends StatefulWidget {
  final double balance;
  final TextStyle? textStyle;
  final bool showCurrency;
  final String currency;

  const SecureBalanceWidget({
    super.key,
    required this.balance,
    this.textStyle,
    this.showCurrency = true,
    this.currency = '₹',
  });

  @override
  State<SecureBalanceWidget> createState() => _SecureBalanceWidgetState();
}

class _SecureBalanceWidgetState extends State<SecureBalanceWidget>
    with TickerProviderStateMixin {
  bool _isBalanceVisible = false;
  bool _isVerifying = false;
  late AnimationController _fadeController;
  late AnimationController _shakeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _toggleBalanceVisibility() async {
    if (_isBalanceVisible) {
      // Hide balance immediately
      setState(() {
        _isBalanceVisible = false;
      });
      _fadeController.reverse();
      return;
    }

    // Check if PIN is set up
    if (!PinService.hasPinSetup()) {
      _showSetupPinDialog();
      return;
    }

    // Show PIN verification
    setState(() {
      _isVerifying = true;
    });

    final verified = await _requestPinVerification();
    
    setState(() {
      _isVerifying = false;
    });

    if (verified) {
      setState(() {
        _isBalanceVisible = true;
      });
      _fadeController.forward();
      HapticFeedback.lightImpact();
      
      // Auto-hide after 10 seconds for security
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && _isBalanceVisible) {
          setState(() {
            _isBalanceVisible = false;
          });
          _fadeController.reverse();
        }
      });
    } else {
      _shakeController.forward().then((_) {
        _shakeController.reverse();
      });
      HapticFeedback.heavyImpact();
    }
  }

  Future<bool> _requestPinVerification() async {
    final completer = Completer<bool>();
    
    // Check if PIN is actually set up first
    if (!PinService.hasPinSetup()) {
      completer.complete(false);
      return completer.future;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PinEntryScreen(
          title: 'Verify PIN',
          subtitle: 'Enter your UPI PIN to view balance',
          isSetupMode: false,
          onPinEntered: (pin) async {
            final isValid = await PinService.verifyPin(pin);
            Navigator.pop(context);
            completer.complete(isValid);
          },
        ),
      ),
    );
    
    return completer.future;
  }

  void _showSetupPinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF2A2D3A),
        title: Row(
          children: [
            Icon(Icons.security, color: Colors.orange.shade600),
            const SizedBox(width: 12),
            const Text(
              'PIN Required',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Text(
          'Set up your UPI PIN to securely view your balance.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToSetupPin();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
            ),
            child: const Text('Set PIN'),
          ),
        ],
      ),
    );
  }

  void _navigateToSetupPin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PinEntryScreen(
          title: 'Set Up UPI PIN',
          subtitle: 'Create a 6-digit PIN to secure your balance',
          isSetupMode: true,
          onPinEntered: (pin) async {
            final success = await PinService.setupPin(pin);
            Navigator.pop(context);
            
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('PIN setup complete! You can now view your balance.'),
                  backgroundColor: Colors.green.shade600,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Failed to set up PIN. Please try again.'),
                  backgroundColor: Colors.red.shade600,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: GestureDetector(
            onTap: _isVerifying ? null : _toggleBalanceVisibility,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isVerifying) ...[
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ] else ...[
                    Icon(
                      _isBalanceVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white.withOpacity(0.8),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                  ],
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isBalanceVisible
                        ? FadeTransition(
                            opacity: _fadeAnimation,
                            child: Text(
                              '${widget.showCurrency ? widget.currency : ''}${widget.balance.toStringAsFixed(2)}',
                              style: widget.textStyle ?? const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : Text(
                            '${widget.showCurrency ? widget.currency : ''}••••••',
                            style: widget.textStyle ?? const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Extension for easy integration
extension SecureBalanceExtension on double {
  Widget toSecureBalance({
    TextStyle? textStyle,
    bool showCurrency = true,
    String currency = '₹',
  }) {
    return SecureBalanceWidget(
      balance: this,
      textStyle: textStyle,
      showCurrency: showCurrency,
      currency: currency,
    );
  }
}
