import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/upi_config_service.dart';
import '../services/pin_service.dart';
import '../screens/pin_management_screen.dart';
import '../screens/pin_entry_screen.dart';

class UpiSettingsScreen extends StatefulWidget {
  const UpiSettingsScreen({super.key});

  @override
  State<UpiSettingsScreen> createState() => _UpiSettingsScreenState();
}

class _UpiSettingsScreenState extends State<UpiSettingsScreen> {
  final TextEditingController _upiController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _currentUpiId;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUpiId();
  }

  Future<void> _loadCurrentUpiId() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      if (user != null) {
        final config = await UpiConfigService.getUserUpiConfig(user.id);
        if (config != null && config['upiId'] != null) {
          setState(() {
            _currentUpiId = config['upiId'];
            _upiController.text = _currentUpiId!;
          });
        }
        
        // Load suggestions
        final suggestions = await UpiConfigService.getUpiIdSuggestions(
          user.name, 
          user.phoneNumber
        );
        setState(() => _suggestions = suggestions);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading UPI settings: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUpiId() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      if (user != null) {
        await UpiConfigService.updateUpiId(user.id, _upiController.text.trim());
        await authProvider.refreshUser();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('UPI ID updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update UPI ID: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _checkAvailability() async {
    final upiId = _upiController.text.trim();
    if (upiId.isEmpty) return;

    try {
      final isAvailable = await UpiConfigService.isUpiIdAvailable(upiId);
      final message = isAvailable ? 'UPI ID is available!' : 'UPI ID is already taken';
      final color = isAvailable ? Colors.green : Colors.red;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking availability: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UPI Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current UPI ID',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _currentUpiId ?? 'Not set',
                              style: TextStyle(
                                fontSize: 14,
                                color: _currentUpiId != null 
                                    ? Colors.green 
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // UPI PIN Section
                    _buildPinSection(),
                    
                    const SizedBox(height: 24),
                    const Text(
                      'Update UPI ID',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _upiController,
                      decoration: InputDecoration(
                        labelText: 'UPI ID',
                        hintText: 'yourname@qrpay',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.check_circle_outline),
                          onPressed: _checkAvailability,
                          tooltip: 'Check availability',
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a UPI ID';
                        }
                        if (!_isValidUpiFormat(value.trim())) {
                          return 'Please enter a valid UPI ID';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_suggestions.isNotEmpty) ...[
                      const Text(
                        'Suggestions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _suggestions.map((suggestion) {
                          return ActionChip(
                            label: Text(suggestion),
                            onPressed: () {
                              _upiController.text = suggestion;
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isUpdating ? null : _updateUpiId,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isUpdating
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'Update UPI ID',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'UPI ID Guidelines',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '• UPI ID must be unique across the platform\n'
                              '• Use letters, numbers, dots, hyphens, and underscores\n'
                              '• Must contain @ symbol followed by domain\n'
                              '• Length should be between 6-50 characters\n'
                              '• Cannot be changed frequently',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _upiController.dispose();
    super.dispose();
  }

  bool _isValidUpiFormat(String upiId) {
    return RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+$').hasMatch(upiId);
  }

  Widget _buildPinSection() {
    final hasPinSet = PinService.hasPinSetup();
    final pinSetDate = PinService.getPinSetupDate();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: hasPinSet ? Colors.green : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'UPI PIN Security',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: hasPinSet ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // PIN Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasPinSet 
                    ? Colors.green.withOpacity(0.1) 
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasPinSet ? Colors.green : Colors.orange,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        hasPinSet ? Icons.check_circle : Icons.warning,
                        color: hasPinSet ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        hasPinSet ? 'PIN Configured' : 'PIN Not Set',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: hasPinSet ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasPinSet
                        ? 'Your UPI PIN is active and securing your transactions'
                        : 'Set up a UPI PIN to enable payments and balance viewing',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (hasPinSet && pinSetDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Set on ${_formatDate(pinSetDate)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            if (!hasPinSet) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _setupPin,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Set Up UPI PIN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _changePin,
                      icon: const Icon(Icons.edit),
                      label: const Text('Change PIN'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _managePinSettings,
                      icon: const Icon(Icons.settings),
                      label: const Text('Manage PIN'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Security Note
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue[600],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'UPI PIN is required for all transactions and balance viewing for security',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
            final success = await PinService.setupPin(pin);
            Navigator.pop(context);
            
            if (success) {
              setState(() {}); // Refresh UI
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('UPI PIN setup complete! You can now make payments.'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to set up PIN. Please try again.'),
                  backgroundColor: Colors.red,
                ),
              );
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Incorrect PIN. Please try again.'),
                  backgroundColor: Colors.red,
                ),
              );
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
            final success = await PinService.changePin(oldPin, newPin);
            Navigator.pop(context);
            
            if (success) {
              setState(() {}); // Refresh UI
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('PIN changed successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to change PIN. Please try again.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  void _managePinSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PinManagementScreen(),
      ),
    ).then((_) {
      setState(() {}); // Refresh UI when returning
    });
  }
}
