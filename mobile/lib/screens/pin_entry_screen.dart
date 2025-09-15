import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/pin_service.dart';

class PinEntryScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final Function(String) onPinEntered;
  final bool isSetupMode;
  final String? existingPin;

  const PinEntryScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onPinEntered,
    this.isSetupMode = false,
    this.existingPin,
  });

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen>
    with TickerProviderStateMixin {
  String _pin = '';
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _shakeController;
  late AnimationController _fadeController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onNumberPressed(String number) {
    if (_pin.length < 6) {
      setState(() {
        _pin += number;
        _errorMessage = null;
      });
      
      HapticFeedback.lightImpact();
      
      if (_pin.length == 6) {
        _validatePin();
      }
    }
  }

  void _onBackspacePressed() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = null;
      });
      HapticFeedback.selectionClick();
    }
  }

  void _validatePin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.isSetupMode) {
        // For setup mode, validate PIN strength and return
        if (!PinService.isSecurePin(_pin)) {
          _showError(PinService.getPinStrengthMessage(_pin));
          return;
        }
        widget.onPinEntered(_pin);
      } else {
        // Validate PIN against stored PIN using PinService
        final isValid = await PinService.verifyPin(_pin);
        if (isValid) {
          widget.onPinEntered(_pin);
        } else {
          _showError('Incorrect PIN. Please try again.');
        }
      }
    } catch (e) {
      _showError('PIN validation failed. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _pin = '';
    });
    
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
    
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B23),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.security,
                            color: Colors.green.shade400,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Secure',
                            style: TextStyle(
                              color: Colors.green.shade400,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Title and Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        widget.isSetupMode ? Icons.security : Icons.lock,
                        color: const Color(0xFF4F46E5),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 60),

              // PIN Display
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(6, (index) {
                          bool isFilled = index < _pin.length;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isFilled
                                  ? const Color(0xFF4F46E5)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isFilled
                                    ? const Color(0xFF4F46E5)
                                    : Colors.grey.shade600,
                                width: 2,
                              ),
                              boxShadow: isFilled ? [
                                BoxShadow(
                                  color: const Color(0xFF4F46E5).withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ] : null,
                            ),
                            child: isFilled ? 
                              const Icon(
                                Icons.circle,
                                color: Colors.white,
                                size: 8,
                              ) : null,
                          );
                        }),
                      ),
                    ),
                  );
                },
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade400,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              const Spacer(),

              // Loading Indicator
              if (_isLoading)
                Container(
                  padding: const EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF4F46E5),
                    ),
                  ),
                ),

              if (!_isLoading) ...[
                // Number Pad
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      // Row 1: 1, 2, 3
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNumberButton('1'),
                          _buildNumberButton('2'),
                          _buildNumberButton('3'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Row 2: 4, 5, 6
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNumberButton('4'),
                          _buildNumberButton('5'),
                          _buildNumberButton('6'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Row 3: 7, 8, 9
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNumberButton('7'),
                          _buildNumberButton('8'),
                          _buildNumberButton('9'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Row 4: *, 0, backspace
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          const SizedBox(width: 70, height: 70), // Empty space
                          _buildNumberButton('0'),
                          _buildBackspaceButton(),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 40),

              // Security Note
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: Colors.grey.shade500,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Your PIN is encrypted and secure',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(35),
        onTap: () => _onNumberPressed(number),
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(35),
        onTap: _onBackspacePressed,
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.backspace_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
