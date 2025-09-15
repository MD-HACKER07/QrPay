import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/pin_service.dart';
import 'pin_entry_screen.dart';

class PinManagementScreen extends StatefulWidget {
  const PinManagementScreen({super.key});

  @override
  State<PinManagementScreen> createState() => _PinManagementScreenState();
}

class _PinManagementScreenState extends State<PinManagementScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
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
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPinSet = PinService.hasPinSetup();
    final pinSetDate = PinService.getPinSetupDate();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1B23),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
        ),
        title: const Text(
          'UPI PIN Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PIN Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: hasPinSet
                        ? [Colors.green.shade600, Colors.green.shade700]
                        : [Colors.orange.shade600, Colors.orange.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (hasPinSet ? Colors.green : Colors.orange).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          hasPinSet ? Icons.security : Icons.warning_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          hasPinSet ? 'PIN Configured' : 'PIN Not Set',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      hasPinSet
                          ? 'Your UPI PIN is active and securing your transactions'
                          : 'Set up a UPI PIN to enable secure transactions',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    if (hasPinSet && pinSetDate != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Set on ${_formatDate(pinSetDate)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // PIN Actions
              const Text(
                'PIN Actions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Set/Change PIN Button
              _buildActionCard(
                icon: hasPinSet ? Icons.edit : Icons.add_circle_outline,
                title: hasPinSet ? 'Change PIN' : 'Set Up PIN',
                subtitle: hasPinSet
                    ? 'Update your current UPI PIN'
                    : 'Create a 6-digit PIN for transactions',
                onTap: hasPinSet ? _changePin : _setupPin,
                color: const Color(0xFF4F46E5),
              ),

              const SizedBox(height: 12),

              // Verify PIN Button (only if PIN is set)
              if (hasPinSet)
                _buildActionCard(
                  icon: Icons.verified_user,
                  title: 'Verify PIN',
                  subtitle: 'Test your current PIN',
                  onTap: _verifyPin,
                  color: Colors.green.shade600,
                ),

              if (hasPinSet) const SizedBox(height: 12),

              // Reset PIN Button (only if PIN is set)
              if (hasPinSet)
                _buildActionCard(
                  icon: Icons.refresh,
                  title: 'Reset PIN',
                  subtitle: 'Remove current PIN and set up new one',
                  onTap: _resetPin,
                  color: Colors.red.shade600,
                ),

              const SizedBox(height: 32),

              // Security Tips
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.tips_and_updates,
                          color: Colors.blue.shade400,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Security Tips',
                          style: TextStyle(
                            color: Colors.blue.shade400,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSecurityTip('Use a unique 6-digit PIN'),
                    _buildSecurityTip('Avoid sequential numbers (123456)'),
                    _buildSecurityTip('Don\'t use repeated digits (111111)'),
                    _buildSecurityTip('Keep your PIN confidential'),
                    _buildSecurityTip('Change PIN regularly for security'),
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

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _isLoading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade500,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _setupPin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PinEntryScreen(
          title: 'Set Up UPI PIN',
          subtitle: 'Create a 6-digit PIN to secure your transactions',
          isSetupMode: true,
          onPinEntered: (pin) async {
            setState(() => _isLoading = true);
            
            final success = await PinService.setupPin(pin);
            
            setState(() => _isLoading = false);
            Navigator.pop(context);
            
            if (success) {
              _showSuccessDialog('PIN Setup Complete', 'Your UPI PIN has been set up successfully.');
              setState(() {}); // Refresh UI
            } else {
              _showErrorDialog('Setup Failed', 'Failed to set up PIN. Please try again.');
            }
          },
        ),
      ),
    );
  }

  void _changePin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PinEntryScreen(
          title: 'Enter Current PIN',
          subtitle: 'Verify your current PIN to change it',
          onPinEntered: (oldPin) async {
            final isValid = await PinService.verifyPin(oldPin);
            Navigator.pop(context);
            
            if (isValid) {
              _showNewPinEntry(oldPin);
            } else {
              _showErrorDialog('Incorrect PIN', 'The current PIN you entered is incorrect.');
            }
          },
        ),
      ),
    );
  }

  void _showNewPinEntry(String oldPin) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PinEntryScreen(
          title: 'Set New PIN',
          subtitle: 'Create your new 6-digit UPI PIN',
          isSetupMode: true,
          onPinEntered: (newPin) async {
            setState(() => _isLoading = true);
            
            final success = await PinService.changePin(oldPin, newPin);
            
            setState(() => _isLoading = false);
            Navigator.pop(context);
            
            if (success) {
              _showSuccessDialog('PIN Changed', 'Your UPI PIN has been updated successfully.');
              setState(() {}); // Refresh UI
            } else {
              _showErrorDialog('Change Failed', 'Failed to change PIN. Please try again.');
            }
          },
        ),
      ),
    );
  }

  void _verifyPin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PinEntryScreen(
          title: 'Verify PIN',
          subtitle: 'Enter your UPI PIN to verify',
          onPinEntered: (pin) async {
            final isValid = await PinService.verifyPin(pin);
            Navigator.pop(context);
            
            if (isValid) {
              _showSuccessDialog('PIN Verified', 'Your PIN is correct and working properly.');
            } else {
              _showErrorDialog('Verification Failed', 'The PIN you entered is incorrect.');
            }
          },
        ),
      ),
    );
  }

  void _resetPin() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF2A2D3A),
        title: const Text(
          'Reset PIN',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to reset your UPI PIN? You will need to set up a new PIN.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              
              final success = await PinService.resetPin();
              
              setState(() => _isLoading = false);
              
              if (success) {
                _showSuccessDialog('PIN Reset', 'Your PIN has been reset. You can now set up a new PIN.');
                setState(() {}); // Refresh UI
              } else {
                _showErrorDialog('Reset Failed', 'Failed to reset PIN. Please try again.');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF2A2D3A),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF2A2D3A),
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red.shade600),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
