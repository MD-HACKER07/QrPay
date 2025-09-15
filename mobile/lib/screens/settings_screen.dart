import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../services/biometric_service.dart';
import '../providers/language_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B23),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Security Section
            _buildSectionHeader('Security & Authentication'),
            const SizedBox(height: 16),
            _buildSecuritySettings(),
            
            const SizedBox(height: 32),
            
            // General Section
            _buildSectionHeader('General'),
            const SizedBox(height: 16),
            _buildGeneralSettings(),
            
            const SizedBox(height: 32),
            
            // About Section
            _buildSectionHeader('About'),
            const SizedBox(height: 16),
            _buildAboutSettings(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSecuritySettings() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D3A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildBiometricSettings(),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.pin,
            title: 'Change UPI PIN',
            subtitle: 'Update your UPI PIN for transactions',
            onTap: () {
              // TODO: Navigate to change PIN screen
            },
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.security,
            title: 'Two-Factor Authentication',
            subtitle: 'Add extra security to your account',
            onTap: () {
              // TODO: Navigate to 2FA settings
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricSettings() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getBiometricInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data ?? {};
        final isAvailable = data['available'] ?? false;
        final isEnabled = data['enabled'] ?? false;
        final biometricType = data['type'] as BiometricType?;
        final preferredMethod = data['preferredMethod'] as AuthenticationMethod? ?? AuthenticationMethod.pin;

        if (!isAvailable) {
          return _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'Biometric Authentication',
            subtitle: 'Not available on this device',
            trailing: const Icon(Icons.block, color: Colors.grey),
            onTap: null,
          );
        }

        return ExpansionTile(
          leading: Icon(
            biometricType == BiometricType.face ? Icons.face : Icons.fingerprint,
            color: Colors.white,
            size: 24,
          ),
          title: const Text(
            'Biometric Authentication',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            isEnabled ? 'Enabled for payments' : 'Disabled',
            style: TextStyle(
              color: isEnabled ? Colors.green : Colors.grey,
              fontSize: 14,
            ),
          ),
          trailing: Switch(
            value: isEnabled,
            onChanged: (value) => _toggleBiometric(value),
            activeColor: const Color(0xFF4F46E5),
          ),
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          iconColor: Colors.white,
          collapsedIconColor: Colors.white,
          children: [
            if (isEnabled) ...[
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1B23),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Authentication Method',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...AuthenticationMethod.values.map((method) {
                      String title, subtitle;
                      IconData icon;
                      
                      switch (method) {
                        case AuthenticationMethod.pin:
                          title = 'PIN Only';
                          subtitle = 'Use UPI PIN for all payments';
                          icon = Icons.pin;
                          break;
                        case AuthenticationMethod.biometric:
                          title = BiometricService.getBiometricTypeName(biometricType!);
                          subtitle = 'Use biometric for all payments';
                          icon = biometricType == BiometricType.face ? Icons.face : Icons.fingerprint;
                          break;
                        case AuthenticationMethod.both:
                          title = 'Biometric + PIN Fallback';
                          subtitle = 'Try biometric first, PIN if needed';
                          icon = Icons.security;
                          break;
                      }
                      
                      return RadioListTile<AuthenticationMethod>(
                        value: method,
                        groupValue: preferredMethod,
                        onChanged: (value) => _setPreferredAuthMethod(value!),
                        title: Text(
                          title,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        subtitle: Text(
                          subtitle,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        secondary: Icon(icon, color: Colors.white, size: 20),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: const Color(0xFF4F46E5),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildGeneralSettings() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D3A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Manage your notification preferences',
            onTap: () {
              // TODO: Navigate to notification settings
            },
          ),
          _buildDivider(),
          Consumer<LanguageProvider>(
            builder: (context, languageProvider, _) => _buildSettingsTile(
              icon: Icons.language,
              title: 'Language',
              subtitle: languageProvider.getCurrentLanguageName(),
              onTap: () => _showLanguageDialog(context, languageProvider),
            ),
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.dark_mode,
            title: 'Theme',
            subtitle: 'Dark mode',
            onTap: () {
              // TODO: Navigate to theme settings
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSettings() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D3A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help with QrPay',
            onTap: () {
              // TODO: Navigate to help screen
            },
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'Read our privacy policy',
            onTap: () {
              // TODO: Navigate to privacy policy
            },
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'About QrPay',
            subtitle: 'Version 1.0.0',
            onTap: () {
              // TODO: Show about dialog
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey.shade800,
      height: 1,
      indent: 56,
    );
  }

  Future<Map<String, dynamic>> _getBiometricInfo() async {
    final isAvailable = await BiometricService.isBiometricAvailable();
    final isEnabled = await BiometricService.isBiometricEnabledForPayments();
    final biometricType = await BiometricService.getPrimaryBiometricType();
    final preferredMethod = await BiometricService.getPreferredAuthMethod();

    return {
      'available': isAvailable,
      'enabled': isEnabled,
      'type': biometricType,
      'preferredMethod': preferredMethod,
    };
  }

  void _toggleBiometric(bool enabled) async {
    if (enabled) {
      // Test biometric authentication before enabling
      final success = await BiometricService.authenticateWithBiometrics(
        reason: 'Please authenticate to enable biometric payments',
      );
      
      if (success) {
        await BiometricService.setBiometricForPayments(true);
        setState(() {});
        _showSuccessSnackBar('Biometric authentication enabled for payments');
      } else {
        _showErrorSnackBar('Failed to authenticate. Biometric not enabled.');
      }
    } else {
      await BiometricService.setBiometricForPayments(false);
      setState(() {});
      _showSuccessSnackBar('Biometric authentication disabled');
    }
  }

  void _setPreferredAuthMethod(AuthenticationMethod method) async {
    await BiometricService.setPreferredAuthMethod(method);
    setState(() {});
    
    String methodName;
    switch (method) {
      case AuthenticationMethod.pin:
        methodName = 'PIN Only';
        break;
      case AuthenticationMethod.biometric:
        methodName = 'Biometric Only';
        break;
      case AuthenticationMethod.both:
        methodName = 'Biometric + PIN Fallback';
        break;
    }
    
    _showSuccessSnackBar('Authentication method set to $methodName');
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, LanguageProvider languageProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2D3A),
          title: const Text(
            'Select Language',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: languageProvider.getSupportedLanguages().length,
              itemBuilder: (context, index) {
                final languageName = languageProvider.getSupportedLanguages()[index];
                final isSelected = languageProvider.getCurrentLanguageName() == languageName;
                
                return ListTile(
                  title: Text(
                    languageName,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected 
                    ? const Icon(Icons.check, color: Color(0xFF4F46E5))
                    : null,
                  onTap: () async {
                    final locale = languageProvider.getLocaleFromName(languageName);
                    if (locale != null) {
                      await languageProvider.changeLanguage(locale);
                      Navigator.of(context).pop();
                      _showLanguageChangeDialog(languageName);
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLanguageChangeDialog(String languageName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2D3A),
          title: const Text(
            'Language Changed',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Language changed to $languageName.\n\nPlease restart the app to apply language changes completely.',
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showSuccessSnackBar('Language changed to $languageName');
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Color(0xFF4F46E5)),
              ),
            ),
          ],
        );
      },
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
}
