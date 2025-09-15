import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' as math;

class PaymentSuccessAnimation extends StatefulWidget {
  final double amount;
  final String recipientName;
  final String recipientUpiId;
  final VoidCallback onComplete;

  const PaymentSuccessAnimation({
    super.key,
    required this.amount,
    required this.recipientName,
    required this.recipientUpiId,
    required this.onComplete,
  });

  @override
  State<PaymentSuccessAnimation> createState() => _PaymentSuccessAnimationState();
}

class _PaymentSuccessAnimationState extends State<PaymentSuccessAnimation>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _rippleController;
  late AnimationController _sparkleController;
  late ConfettiController _confettiController;
  late ConfettiController _confettiController2;
  
  late Animation<double> _checkAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    
    _confettiController2 = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    // Initialize animations
    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );
    
    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );
    
    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.linear),
    );

    // Start animations sequence
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // Start background animations
    _sparkleController.repeat();
    _rotationController.repeat();
    
    // Start confetti burst
    _confettiController.play();
    Future.delayed(const Duration(milliseconds: 500), () {
      _confettiController2.play();
    });
    
    // Start ripple effect
    _rippleController.forward();
    
    // Start scale animation with bounce
    await _scaleController.forward();
    
    // Start pulse animation
    _pulseController.repeat(reverse: true);
    
    // Then check animation with delay
    await Future.delayed(const Duration(milliseconds: 200));
    await _checkController.forward();
    
    // Finally slide up content
    await _slideController.forward();
    
    // Auto close after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _checkController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    _rippleController.dispose();
    _sparkleController.dispose();
    _confettiController.dispose();
    _confettiController2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.8),
      body: Stack(
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _sparkleAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    colors: [
                      Colors.purple.withValues(alpha: 0.1 + _sparkleAnimation.value * 0.2),
                      Colors.blue.withValues(alpha: 0.05 + _sparkleAnimation.value * 0.1),
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: CustomPaint(
                  painter: SparklesPainter(_sparkleAnimation.value),
                  size: Size.infinite,
                ),
              );
            },
          ),
          
          // Multiple Confetti layers
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.yellow,
                Colors.red,
                Colors.cyan,
              ],
              numberOfParticles: 100,
              gravity: 0.2,
              emissionFrequency: 0.05,
            ),
          ),
          
          Align(
            alignment: Alignment.bottomCenter,
            child: ConfettiWidget(
              confettiController: _confettiController2,
              blastDirection: -math.pi / 2,
              blastDirectionality: BlastDirectionality.directional,
              shouldLoop: false,
              colors: const [
                Colors.yellow,
                Colors.amber,
                Colors.orange,
                Colors.deepOrange,
              ],
              numberOfParticles: 50,
              gravity: 0.1,
            ),
          ),
          
          // Main content
          Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated check mark with multiple effects
                    AnimatedBuilder(
                      animation: Listenable.merge([_scaleAnimation, _pulseAnimation, _rippleAnimation, _rotationAnimation]),
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Ripple effect
                            if (_rippleAnimation.value > 0)
                              ...List.generate(3, (index) {
                                final delay = index * 0.3;
                                final rippleValue = math.max(0.0, (_rippleAnimation.value - delay) / (1.0 - delay));
                                return Transform.scale(
                                  scale: 1 + rippleValue * 2,
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.green.withValues(alpha: 0.3 * (1 - rippleValue)),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            
                            // Rotating glow effect
                            Transform.rotate(
                              angle: _rotationAnimation.value,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: SweepGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.green.withValues(alpha: 0.3),
                                      Colors.transparent,
                                      Colors.blue.withValues(alpha: 0.3),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            
                            // Main check mark with pulse
                            Transform.scale(
                              scale: _scaleAnimation.value * _pulseAnimation.value,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF4CAF50),
                                      Color(0xFF45A049),
                                      Color(0xFF2E7D32),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withValues(alpha: 0.4),
                                      blurRadius: 25,
                                      spreadRadius: 8,
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      spreadRadius: -5,
                                    ),
                                  ],
                                ),
                                child: AnimatedBuilder(
                                  animation: _checkAnimation,
                                  builder: (context, child) {
                                    return CustomPaint(
                                      painter: CheckMarkPainter(_checkAnimation.value),
                                      size: const Size(120, 120),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Success content with slide animation
                    SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          // Success title
                          FadeInUp(
                            duration: const Duration(milliseconds: 800),
                            delay: const Duration(milliseconds: 400),
                            child: const Text(
                              'Payment Successful!',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Amount
                          FadeInUp(
                            duration: const Duration(milliseconds: 800),
                            delay: const Duration(milliseconds: 600),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.shade50,
                                    Colors.green.shade100,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '₹${widget.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Recipient info
                          FadeInUp(
                            duration: const Duration(milliseconds: 800),
                            delay: const Duration(milliseconds: 800),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            widget.recipientName.isNotEmpty 
                                                ? widget.recipientName[0].toUpperCase()
                                                : 'U',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Sent to',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            Text(
                                              widget.recipientName.isNotEmpty 
                                                  ? widget.recipientName
                                                  : widget.recipientUpiId,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (widget.recipientName.isNotEmpty)
                                              Text(
                                                widget.recipientUpiId,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Success message
                          FadeInUp(
                            duration: const Duration(milliseconds: 800),
                            delay: const Duration(milliseconds: 1000),
                            child: Text(
                              'Your money has been sent successfully!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Done button
                          FadeInUp(
                            duration: const Duration(milliseconds: 800),
                            delay: const Duration(milliseconds: 1200),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: widget.onComplete,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CAF50),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
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
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CheckMarkPainter extends CustomPainter {
  final double progress;
  
  CheckMarkPainter(this.progress);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    final center = Offset(size.width / 2, size.height / 2);
    final checkPath = Path();
    
    // Define check mark points
    final startPoint = Offset(center.dx - 18, center.dy);
    final middlePoint = Offset(center.dx - 6, center.dy + 12);
    final endPoint = Offset(center.dx + 18, center.dy - 12);
    
    if (progress > 0) {
      checkPath.moveTo(startPoint.dx, startPoint.dy);
      
      if (progress <= 0.5) {
        // First half: draw to middle point
        final currentPoint = Offset.lerp(
          startPoint,
          middlePoint,
          progress * 2,
        )!;
        checkPath.lineTo(currentPoint.dx, currentPoint.dy);
      } else {
        // Second half: draw to end point
        checkPath.lineTo(middlePoint.dx, middlePoint.dy);
        final currentPoint = Offset.lerp(
          middlePoint,
          endPoint,
          (progress - 0.5) * 2,
        )!;
        checkPath.lineTo(currentPoint.dx, currentPoint.dy);
      }
      
      canvas.drawPath(checkPath, paint);
    }
  }
  
  @override
  bool shouldRepaint(CheckMarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class SparklesPainter extends CustomPainter {
  final double animationValue;
  
  SparklesPainter(this.animationValue);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    final random = math.Random(42); // Fixed seed for consistent sparkles
    
    // Generate sparkles
    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      
      // Create twinkling effect
      final twinkle = math.sin((animationValue * 2 * math.pi) + (i * 0.5)) * 0.5 + 0.5;
      final opacity = twinkle * 0.8;
      
      if (opacity > 0.1) {
        final sparkleSize = (2 + random.nextDouble() * 4) * twinkle;
        
        // Different colors for sparkles
        final colors = [
          Colors.white,
          Colors.yellow,
          Colors.cyan,
          Colors.pink,
          Colors.green,
        ];
        
        paint.color = colors[i % colors.length].withValues(alpha: opacity);
        
        // Draw sparkle as a star
        _drawStar(canvas, paint, Offset(x, y), sparkleSize);
      }
    }
  }
  
  void _drawStar(Canvas canvas, Paint paint, Offset center, double size) {
    final path = Path();
    
    // Create a 4-pointed star
    final points = [
      Offset(center.dx, center.dy - size), // Top
      Offset(center.dx + size * 0.3, center.dy - size * 0.3), // Top-right
      Offset(center.dx + size, center.dy), // Right
      Offset(center.dx + size * 0.3, center.dy + size * 0.3), // Bottom-right
      Offset(center.dx, center.dy + size), // Bottom
      Offset(center.dx - size * 0.3, center.dy + size * 0.3), // Bottom-left
      Offset(center.dx - size, center.dy), // Left
      Offset(center.dx - size * 0.3, center.dy - size * 0.3), // Top-left
    ];
    
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(SparklesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
