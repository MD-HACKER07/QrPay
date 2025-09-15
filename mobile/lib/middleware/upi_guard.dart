import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';

class UpiGuard extends StatelessWidget {
  final Widget child;
  
  const UpiGuard({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkUpiSetup(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!) {
          // Redirect to UPI setup if not configured
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/upi-setup');
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return child;
      },
    );
  }

  Future<bool> _checkUpiSetup() async {
    try {
      final currentUser = AuthService.getCurrentUser();
      if (currentUser == null) return false;
      
      // Check if user has UPI ID configured
      return currentUser.upiId != null && currentUser.upiId!.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
