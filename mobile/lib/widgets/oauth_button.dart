import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class OAuthButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;

  const OAuthButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: backgroundColor == Colors.white 
                    ? Colors.grey.withValues(alpha: 0.1)
                    : backgroundColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: OutlinedButton(
            onPressed: authProvider.isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              backgroundColor: backgroundColor,
              side: BorderSide(color: borderColor ?? backgroundColor, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: authProvider.isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildIcon(),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildIcon() {
    if (icon.contains('google')) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: CustomPaint(
          painter: GoogleIconPainter(),
        ),
      );
    } else {
      return Icon(
        Icons.apple,
        size: 24,
        color: textColor,
      );
    }
  }
}

class GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Google "G" logo colors and paths
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Blue section
    paint.color = const Color(0xFF4285F4);
    final bluePath = Path()
      ..moveTo(center.dx, center.dy - radius * 0.8)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius * 0.8),
        -1.57, // -90 degrees
        1.57,  // 90 degrees
        false,
      )
      ..lineTo(center.dx + radius * 0.3, center.dy)
      ..lineTo(center.dx + radius * 0.3, center.dy - radius * 0.3)
      ..lineTo(center.dx, center.dy - radius * 0.3)
      ..close();
    canvas.drawPath(bluePath, paint);
    
    // Red section
    paint.color = const Color(0xFFEA4335);
    final redPath = Path()
      ..moveTo(center.dx, center.dy - radius * 0.8)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius * 0.8),
        -1.57, // -90 degrees
        -1.57, // -90 degrees
        false,
      )
      ..lineTo(center.dx - radius * 0.8, center.dy)
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(redPath, paint);
    
    // Yellow section
    paint.color = const Color(0xFFFBBC04);
    final yellowPath = Path()
      ..moveTo(center.dx - radius * 0.8, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius * 0.8),
        3.14, // 180 degrees
        1.57, // 90 degrees
        false,
      )
      ..lineTo(center.dx, center.dy + radius * 0.8)
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(yellowPath, paint);
    
    // Green section
    paint.color = const Color(0xFF34A853);
    final greenPath = Path()
      ..moveTo(center.dx, center.dy + radius * 0.8)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius * 0.8),
        1.57, // 90 degrees
        1.57, // 90 degrees
        false,
      )
      ..lineTo(center.dx + radius * 0.3, center.dy)
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(greenPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
