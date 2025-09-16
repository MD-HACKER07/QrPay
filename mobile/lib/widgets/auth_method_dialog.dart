import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/biometric_service.dart';

class AuthMethodDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBiometricSelected;
  final VoidCallback onPinSelected;

  const AuthMethodDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onBiometricSelected,
    required this.onPinSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2A2D3A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.security,
                color: Color(0xFF4F46E5),
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Authentication Options
            FutureBuilder<bool>(
              future: BiometricService.isBiometricAvailable(),
              builder: (context, snapshot) {
                final isBiometricAvailable = snapshot.data ?? false;
                
                return Column(
                  children: [
                    // Biometric Option
                    if (!kIsWeb && isBiometricAvailable) ...[
                      _buildAuthOption(
                        context: context,
                        icon: Icons.fingerprint,
                        title: 'Use Biometric',
                        subtitle: 'Fingerprint or Face ID',
                        onTap: () {
                          Navigator.pop(context);
                          onBiometricSelected();
                        },
                        color: const Color(0xFF4F46E5),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // PIN Option
                    _buildAuthOption(
                      context: context,
                      icon: Icons.pin,
                      title: 'Use PIN',
                      subtitle: 'Enter your 6-digit UPI PIN',
                      onTap: () {
                        Navigator.pop(context);
                        onPinSelected();
                      },
                      color: const Color(0xFF059669),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Cancel Button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1B23),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
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
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
