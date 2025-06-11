import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'home_page.dart';
import 'post_details_page.dart';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';

class SuccessPage extends StatefulWidget {
  final String postId;
  
  const SuccessPage({
    super.key,
    required this.postId,
  });

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _confettiController;
  late AnimationController _slideController;
  late AnimationController _iconController;
  
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _iconRotateAnim;
  late Animation<double> _iconScaleAnim;

  @override
  void initState() {
    super.initState();
    
    // Main controller for the icon
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Confetti controller
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Text slide controller
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Icon animation controller
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.elasticOut),
    );
    
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    _iconRotateAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.elasticOut),
    );
    
    _iconScaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.bounceOut),
    );

    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _mainController.forward();
    _iconController.forward();
    
    await Future.delayed(const Duration(milliseconds: 600));
    _slideController.forward();
    
    await Future.delayed(const Duration(milliseconds: 400));
    _confettiController.repeat();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _confettiController.dispose();
    _slideController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryBlue,
              AppTheme.accentBlue,
              AppTheme.lightGrey,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Animated background
              _buildAnimatedBackground(),
              
              // Main content
              Column(
                children: [
                  const Spacer(flex: 2),
                  
                  // Success icon
                  _buildSuccessIcon(),
                  
                  const SizedBox(height: 40),
                  
                  // Success text
                  _buildSuccessText(),
                  
                  const SizedBox(height: 60),
                  
                  // Action buttons
                  _buildActionButtons(),
                  
                  const Spacer(flex: 1),
                ],
              ),
              
              // Confetti
              _buildConfetti(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _confettiController,
      builder: (context, child) {
        return CustomPaint(
          painter: BackgroundShapesPainter(_confettiController.value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildSuccessIcon() {
    return ScaleTransition(
      scale: _scaleAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          width: 160,
          height: 160,
          alignment: Alignment.center,
          child: Image.asset(
            'assets/result.png',
            width: 140,
            height: 140,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessText() {
    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            Text(
              "🎉 Success! 🎉",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 32,
                letterSpacing: 1.2,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Your Product Has Been\nPublished Successfully",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                  height: 1.4,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.2),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Text(
                "Customers can now view and purchase your product",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          children: [
            // Primary button - using theme
            AppWidgets.buildPrimaryButton(
              text: "Continue",
              onPressed: () {
                // Navigate to home page and clear all previous routes
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomePage()),
                  (Route<dynamic> route) => false,
                );
              },
              width: double.infinity,
              icon: Icons.home,
            ),
            
            const SizedBox(height: 16),
            
            // Secondary button - using theme
            AppWidgets.buildSecondaryButton(
              text: "View Product",
              onPressed: () async {
                // Fetch post data before navigation
                final doc = await FirebaseFirestore.instance
                    .collection('posts')
                    .doc(widget.postId)
                    .get();
                
                if (doc.exists && mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PostDetailsPage(
                        postId: widget.postId,
                        postData: doc.data()!,
                      ),
                    ),
                  );
                }
              },
              width: double.infinity,
              icon: Icons.visibility,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfetti() {
    return AnimatedBuilder(
      animation: _confettiController,
      builder: (context, child) {
        return CustomPaint(
          painter: ConfettiPainter(_confettiController.value),
          size: Size.infinite,
        );
      },
    );
  }
}

// Background shapes painter
class BackgroundShapesPainter extends CustomPainter {
  final double animation;

  BackgroundShapesPainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Animated circles in background
    for (int i = 0; i < 6; i++) {
      final offset = Offset(
        (size.width * 0.2) + (i * size.width * 0.2) + 
        (30 * math.sin(animation * 2 * math.pi + i)),
        (size.height * 0.15) + (i * size.height * 0.15) + 
        (20 * math.cos(animation * 2 * math.pi + i)),
      );
      
      paint.color = [
        Colors.white.withOpacity(0.1),
        AppTheme.accentBlue.withOpacity(0.1),
        AppTheme.success.withOpacity(0.1),
      ][i % 3];
      
      canvas.drawCircle(
        offset, 
        12 + (8 * math.sin(animation * 3 * math.pi)), 
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Confetti painter
class ConfettiPainter extends CustomPainter {
  final double animation;

  ConfettiPainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    final colors = [
      AppTheme.success,
      AppTheme.warning,
      AppTheme.info,
      AppTheme.primaryBlue,
      AppTheme.accentBlue,
      Colors.orange,
      Colors.pink,
      Colors.purple,
    ];

    for (int i = 0; i < 25; i++) {
      final x = (size.width * (i / 25)) + 
                (40 * math.sin(animation * 3 * math.pi + i));
      final y = (size.height * 0.1) + 
                (animation * size.height * 1.2 + i * 40) % size.height;
      
      paint.color = colors[i % colors.length].withOpacity(0.8);
      
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(animation * 6.28 + i);
      
      // Different confetti shapes
      if (i % 4 == 0) {
        // Square
        canvas.drawRect(const Rect.fromLTWH(-4, -4, 8, 8), paint);
      } else if (i % 4 == 1) {
        // Circle
        canvas.drawCircle(Offset.zero, 4, paint);
      } else if (i % 4 == 2) {
        // Triangle
        final path = Path()
          ..moveTo(0, -5)
          ..lineTo(-4, 4)
          ..lineTo(4, 4)
          ..close();
        canvas.drawPath(path, paint);
      } else {
        // Diamond
        final path = Path()
          ..moveTo(0, -4)
          ..lineTo(3, 0)
          ..lineTo(0, 4)
          ..lineTo(-3, 0)
          ..close();
        canvas.drawPath(path, paint);
      }
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}