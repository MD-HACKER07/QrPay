import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../services/upi_config_service.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';

class UpiSetupScreen extends StatefulWidget {
  const UpiSetupScreen({super.key});

  @override
  State<UpiSetupScreen> createState() => _UpiSetupScreenState();
}

class _UpiSetupScreenState extends State<UpiSetupScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _upiController = TextEditingController();
  bool _isLoading = false;
  bool _isValidating = false;
  String? _validationMessage;
  bool? _isUpiValid;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _upiController.dispose();
    _animationController.dispose();
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
    if (upiId.trim().isEmpty) {
      setState(() {
        _validationMessage = null;
        _isUpiValid = null;
        _isValidating = false;
      });
      return;
    }

    // Format validation first
    if (!_isValidUpiFormat(upiId.trim())) {
      setState(() {
        _validationMessage = 'Invalid UPI ID format';
        _isUpiValid = false;
        _isValidating = false;
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _validationMessage = 'Checking availability...';
      _isUpiValid = null;
    });

    try {
      final isAvailable = await UpiConfigService.checkUpiIdAvailability(upiId.trim());
      
      if (isAvailable) {
        setState(() {
          _validationMessage = 'UPI ID is available';
          _isUpiValid = true;
          _isValidating = false;
        });
      } else {
        setState(() {
          _validationMessage = 'UPI ID is already taken';
          _isUpiValid = false;
          _isValidating = false;
        });
      }
    } catch (e) {
      setState(() {
        _validationMessage = 'Unable to validate UPI ID';
        _isUpiValid = false;
        _isValidating = false;
      });
    }
  }

  Future<void> _setupUpiId() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_isUpiValid != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid and available UPI ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = AuthService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not found');
      }

      await UpiConfigService.setupUpiId(
        userId: currentUser.id,
        upiId: _upiController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('UPI ID setup successful!'),
            backgroundColor: Colors.green,
          ),
        );
        
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Setup failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF00D4FF),
              Color(0xFF0099CC),
              Color(0xFF006699),
              Color(0xFF003366),
              Color(0xFF001122),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    
                    // Header
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      child: Column(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Setup Your UPI ID',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 32,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.4),
                                  offset: const Offset(2, 2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Create your unique UPI ID to start sending and receiving money',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // UPI ID Setup Form
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      child: Container(
                        padding: const EdgeInsets.all(24),
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Choose Your UPI ID',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'This will be your unique identifier for receiving payments',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // UPI ID Input
                              TextFormField(
                                controller: _upiController,
                                decoration: InputDecoration(
                                  labelText: 'UPI ID',
                                  hintText: 'yourname@qrpay',
                                  prefixIcon: const Icon(Icons.alternate_email),
                                  suffixText: '@qrpay',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter a UPI ID';
                                  }
                                  if (value.trim().length < 3) {
                                    return 'UPI ID must be at least 3 characters';
                                  }
                                  if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(value.trim())) {
                                    return 'Only letters, numbers, dots, hyphens and underscores allowed';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  final fullUpiId = '${value.trim()}@qrpay';
                                  _validateUpiId(fullUpiId);
                                },
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
                                    borderRadius: BorderRadius.circular(8),
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
                                      if (_isValidating)
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
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
                              
                              const SizedBox(height: 32),
                              
                              // Setup Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _setupUpiId,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.primaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.check_circle),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Setup UPI ID',
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Skip Button
                              SizedBox(
                                width: double.infinity,
                                child: TextButton(
                                  onPressed: () => context.go('/home'),
                                  child: Text(
                                    'Skip for now',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Info Section
                    FadeInUp(
                      duration: const Duration(milliseconds: 1000),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Why do I need a UPI ID?',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '• Receive money from anyone using your UPI ID\n'
                              '• Send money to others using their UPI ID\n'
                              '• Generate QR codes for easy payments\n'
                              '• Access all QrPay features',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
