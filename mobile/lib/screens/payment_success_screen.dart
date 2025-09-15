import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:math';

class PaymentSuccessScreen extends StatefulWidget {
  final double amount;
  final String recipientUpiId;
  final String transactionId;
  final String description;

  const PaymentSuccessScreen({
    super.key,
    required this.amount,
    required this.recipientUpiId,
    required this.transactionId,
    required this.description,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _checkmarkController;
  late AnimationController _confettiController;
  late AnimationController _pulseController;
  late Animation<double> _checkmarkAnimation;
  late Animation<double> _confettiAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _checkmarkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Initialize animations
    _checkmarkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _checkmarkController,
      curve: Curves.elasticOut,
    ));

    _confettiAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _confettiController,
      curve: Curves.easeOutQuart,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.elasticInOut,
    ));

    // Start animations sequence
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // Add haptic feedback
    HapticFeedback.lightImpact();
    
    // Start checkmark animation
    await _checkmarkController.forward();
    
    // Start confetti and pulse animations simultaneously
    _confettiController.forward();
    _pulseController.repeat(reverse: true);
    
    // Add success haptic feedback
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _checkmarkController.dispose();
    _confettiController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _copyTransactionId() {
    Clipboard.setData(ClipboardData(text: widget.transactionId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.copy, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            const Text('Transaction ID copied to clipboard'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                  ),
                ),
              ),
              
              Container(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 200,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated success icon with confetti
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Confetti particles
                        AnimatedBuilder(
                          animation: _confettiAnimation,
                          builder: (context, child) {
                            return CustomPaint(
                              size: const Size(200, 200),
                              painter: ConfettiPainter(_confettiAnimation.value),
                            );
                          },
                        ),
                        
                        // Pulsing background circle
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green.withOpacity(0.1),
                                ),
                              ),
                            );
                          },
                        ),
                        
                        // Main success circle
                        ScaleTransition(
                          scale: _checkmarkAnimation,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green,
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Success message
                    FadeInUp(
                      delay: const Duration(milliseconds: 500),
                      child: Column(
                        children: [
                          Text(
                            'Payment Successful!',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your money has been sent successfully',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Transaction details card
                    FadeInUp(
                      delay: const Duration(milliseconds: 700),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            // Amount
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Amount Sent',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '₹${widget.amount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            
                            const Divider(height: 32),
                            
                            // Recipient
                            _buildDetailRow('To', widget.recipientUpiId),
                            const SizedBox(height: 16),
                            
                            // Description
                            if (widget.description.isNotEmpty)
                              _buildDetailRow('Description', widget.description),
                            if (widget.description.isNotEmpty)
                              const SizedBox(height: 16),
                            
                            // Transaction ID
                            _buildDetailRow(
                              'Transaction ID',
                              widget.transactionId,
                              copyable: true,
                            ),
                            const SizedBox(height: 16),
                            
                            // Date & Time
                            _buildDetailRow(
                              'Date & Time',
                              _formatDateTime(DateTime.now()),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Action buttons
              FadeInUp(
                delay: const Duration(milliseconds: 900),
                child: Column(
                  children: [
                    // Share receipt button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Implement share receipt
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Share receipt feature coming soon!'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('Share Receipt'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Done button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool copyable = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              if (copyable) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _copyTransactionId,
                  child: Icon(
                    Icons.copy,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

// Custom painter for confetti animation
class ConfettiPainter extends CustomPainter {
  final double animationValue;
  final List<ConfettiParticle> particles;

  ConfettiPainter(this.animationValue) : particles = _generateParticles();

  static List<ConfettiParticle> _generateParticles() {
    final random = Random();
    return List.generate(20, (index) {
      return ConfettiParticle(
        x: random.nextDouble() * 200,
        y: random.nextDouble() * 200,
        color: [
          Colors.red,
          Colors.blue,
          Colors.green,
          Colors.yellow,
          Colors.purple,
          Colors.orange,
        ][random.nextInt(6)],
        size: random.nextDouble() * 6 + 2,
        angle: random.nextDouble() * 2 * pi,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    for (final particle in particles) {
      final progress = animationValue;
      final x = particle.x + sin(particle.angle + progress * 2 * pi) * 20 * progress;
      final y = particle.y - progress * 100;
      final opacity = (1 - progress).clamp(0.0, 1.0);
      
      paint.color = particle.color.withOpacity(opacity);
      canvas.drawCircle(
        Offset(x, y),
        particle.size * (1 - progress * 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ConfettiParticle {
  final double x;
  final double y;
  final Color color;
  final double size;
  final double angle;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.angle,
  });
}
