import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../services/firebase_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final walletProvider = Provider.of<WalletProvider>(
        context,
        listen: false,
      );

      // Initialize auth provider first
      await authProvider.initialize();

      // Wait for splash animation
      await Future.delayed(const Duration(seconds: 2));

      // Navigate based on authentication and wallet/KYC status
      if (mounted) {
        if (!authProvider.isAuthenticated) {
          if (mounted) context.go('/login');
        } else {
          // Refresh user from Firestore to avoid stale local cache
          try {
            final remote = await FirebaseService.getUser(authProvider.user!.id);
            if (remote != null) {
              authProvider.updateUser(remote);
            }
          } catch (_) {}

          // Check if user has completed setup before
          await walletProvider.initialize();
          final hasWallet = walletProvider.hasWallet;
          final user = authProvider.user;

          // Check local storage for setup completion flag
          const storage = FlutterSecureStorage();
          final setupCompleted = await storage.read(key: 'setup_completed');

          // Check multiple indicators of completed setup
          final isKycDone = user?.isKycCompleted == true;
          final hasBasicProfile =
              user?.dateOfBirth != null &&
              user?.gender != null &&
              user?.occupation != null;
          final hasAddress = user?.address != null && user?.city != null;
          final hasKycDocs =
              user?.panNumber != null && user?.aadharNumber != null;

          // Consider setup complete if user has any of these combinations
          final setupComplete =
              setupCompleted == 'true' ||
              isKycDone ||
              (hasBasicProfile && hasAddress) ||
              (hasBasicProfile && hasKycDocs) ||
              (hasWallet && hasBasicProfile);

          if (mounted) {
            if (setupComplete) {
              context.go('/home');
            } else {
              context.go('/upi-setup');
            }
          }
        }
      }
    } catch (e) {
      // If initialization fails, go to login
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // QrPay Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.qr_code_2,
                size: 60,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 32),

            // App Name
            Text(
              'QrPay',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Tagline
            Text(
              'Quantum-Resistant UPI Wallet',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 48),

            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 16),

            Text(
              'Securing your future...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
