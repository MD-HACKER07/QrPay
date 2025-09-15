import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/upi_config_service.dart';

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
}
