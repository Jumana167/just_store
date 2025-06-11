import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'login_page_v2.dart';
import 'sign_up_screen.dart';
import 'app_theme.dart';
import 'dart:math' as math;

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _logoController;
  late AnimationController _buttonsController;
  late AnimationController _floatingController;

  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<Offset> _logoSlideAnimation;
  late Animation<double> _buttonsSlideAnimation;
  late Animation<double> _buttonsFadeAnimation;
  late Animation<double> _floatingAnimation;

  // Bag image state
  String _bagImage = 'assets/snapedit_1749604181301.png';

  @override
  void initState() {
    super.initState();

    // Background animation controller
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Buttons animation controller
    _buttonsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Floating elements controller
    _floatingController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    // Logo animations
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );

    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
      ),
    );

    // Buttons animations
    _buttonsSlideAnimation = Tween<double>(begin: 100.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _buttonsController,
        curve: Curves.easeOutBack,
      ),
    );

    _buttonsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonsController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    // Floating animation
    _floatingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.linear),
    );

    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    _backgroundController.repeat();
    _floatingController.repeat();

    await Future.delayed(const Duration(milliseconds: 500));
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 1200));
    _buttonsController.forward();
  }

  void _showSadBag() {
    setState(() {
      _bagImage = 'assets/snapedit_1749603572121.png';
    });
  }

  void _showNormalBag() {
    setState(() {
      _bagImage = 'assets/snapedit_1749604181301.png';
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _logoController.dispose();
    _buttonsController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ إضافة null check آمن
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Animated background
            _buildAnimatedBackground(size),

            // Floating particles
            _buildFloatingParticles(size),

            // Main content
            _buildMainContent(l10n, size),

            // Decorative elements
            _buildDecorativeElements(size),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground(Size size) {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryBlue,
                AppTheme.accentBlue,
                const Color(0xFF1565C0),
                const Color(0xFF0D47A1),
              ],
              stops: [
                0.0 + (math.sin(_backgroundController.value * 2 * math.pi) * 0.1),
                0.3 + (math.cos(_backgroundController.value * 2 * math.pi) * 0.1),
                0.7 + (math.sin(_backgroundController.value * 2 * math.pi) * 0.1),
                1.0,
              ],
            ),
          ),
          child: CustomPaint(
            painter: BackgroundWavesPainter(_backgroundController.value),
            size: size,
          ),
        );
      },
    );
  }

  Widget _buildFloatingParticles(Size size) {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        return CustomPaint(
          painter: FloatingParticlesPainter(_floatingAnimation.value),
          size: size,
        );
      },
    );
  }

  Widget _buildMainContent(AppLocalizations l10n, Size size) {
    return SafeArea(
      child: Container(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            // Logo section
            _buildLogoSection(l10n),

            const Spacer(flex: 3),

            // Buttons section
            _buildButtonsSection(l10n),

            const Spacer(flex: 2),

            // Footer
            _buildFooter(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSection(AppLocalizations l10n) {
    return SlideTransition(
      position: _logoSlideAnimation,
      child: FadeTransition(
        opacity: _logoFadeAnimation,
        child: ScaleTransition(
          scale: _logoScaleAnimation,
          child: Container(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // App icon/logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.3),
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      _bagImage,
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to icon if image fails to load
                        return const Icon(
                          Icons.shopping_bag_outlined,
                          size: 60,
                          color: Colors.white,
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // App name with glow effect
                Container(
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            Colors.white,
                            Colors.white.withOpacity(0.8),
                            Colors.white,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ).createShader(bounds),
                        child: const Text(
                          "JUST STORE",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 3,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(2, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            // ✅ تحقق آمن من وجود القيمة
                            l10n.welcomeTagline ?? "Buy. Sell. Connect.",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
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
    );
  }

  Widget _buildButtonsSection(AppLocalizations l10n) {
    return AnimatedBuilder(
      animation: _buttonsController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _buttonsSlideAnimation.value),
          child: FadeTransition(
            opacity: _buttonsFadeAnimation,
            child: Container(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Login button
                  Center(
                    child: _buildEnhancedButton(
                      text: l10n.login ?? "Login", // ✅ قيمة افتراضية
                      onPressed: () {
                        Navigator.push(
                          context,
                          _createSlideRoute(const LoginPageV2()),
                        );
                      },
                      isPrimary: true,
                      icon: Icons.login,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Sign up button
                  Center(
                    child: _buildEnhancedButton(
                      text: l10n.signUp ?? "Sign Up", // ✅ قيمة افتراضية
                      onPressed: () {
                        Navigator.push(
                          context,
                          _createSlideRoute(const SignUpScreen()),
                        );
                      },
                      isPrimary: false,
                      icon: Icons.person_add,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedButton({
    required String text,
    required VoidCallback onPressed,
    required bool isPrimary,
    required IconData icon,
  }) {
    return Container(
      width: 280,
      height: 56,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isPrimary
                ? Colors.white
                : Colors.transparent,
            foregroundColor: isPrimary
                ? AppTheme.primaryBlue
                : Colors.white,
            elevation: isPrimary ? 8 : 0,
            shadowColor: isPrimary
                ? Colors.white.withOpacity(0.3)
                : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: isPrimary
                  ? BorderSide.none
                  : BorderSide(
                color: Colors.white.withOpacity(0.5),
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: isPrimary
                    ? AppTheme.primaryBlue
                    : Colors.white,
              ),
              const SizedBox(width: 12),
              Text(
                text,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: isPrimary
                      ? AppTheme.primaryBlue
                      : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return FadeTransition(
      opacity: _buttonsFadeAnimation,
      child: Container(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Welcome to the future of shopping",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorativeElements(Size size) {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        return Stack(
          children: [
            // Top right decoration
            Positioned(
              top: 100,
              right: -50,
              child: Transform.rotate(
                angle: _floatingAnimation.value * 2 * math.pi,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom left decoration
            Positioned(
              bottom: 200,
              left: -30,
              child: Transform.rotate(
                angle: -_floatingAnimation.value * 1.5 * math.pi,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Route _createSlideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 600),
    );
  }
}

// Custom painter for background waves
class BackgroundWavesPainter extends CustomPainter {
  final double animationValue;

  BackgroundWavesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Draw flowing waves
    for (int i = 0; i < 3; i++) {
      final path = Path();
      final waveHeight = 30 + (i * 20);
      final waveSpeed = 1.0 + (i * 0.5);
      final opacity = 0.1 - (i * 0.02);

      paint.color = Colors.white.withOpacity(opacity);

      path.moveTo(0, size.height * 0.7 + waveHeight);

      for (double x = 0; x <= size.width; x += 1) {
        final y = size.height * 0.7 +
            waveHeight * math.sin((x / 100) + (animationValue * waveSpeed * 2 * math.pi));
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom painter for floating particles
class FloatingParticlesPainter extends CustomPainter {
  final double animationValue;

  FloatingParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Draw floating particles
    for (int i = 0; i < 15; i++) {
      final x = (size.width * (i / 15)) +
          (30 * math.sin(animationValue * 2 * math.pi + i));
      final y = (size.height * 0.2) +
          (animationValue * size.height * 0.8 + i * 50) % size.height;

      final radius = 2 + (3 * math.sin(animationValue * 4 * math.pi + i));
      final opacity = 0.3 + (0.4 * math.sin(animationValue * 3 * math.pi + i));

      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Draw sparkles
    for (int i = 0; i < 8; i++) {
      final x = size.width * (0.1 + (i * 0.12)) +
          (20 * math.cos(animationValue * 1.5 * math.pi + i));
      final y = size.height * (0.15 + (i * 0.1)) +
          (15 * math.sin(animationValue * 2 * math.pi + i));

      final sparkleSize = 1 + (2 * math.sin(animationValue * 5 * math.pi + i));
      final opacity = 0.4 + (0.5 * math.cos(animationValue * 3 * math.pi + i));

      paint.color = Colors.white.withOpacity(opacity);

      // Draw star shape
      final path = Path();
      for (int j = 0; j < 4; j++) {
        final angle = (j * math.pi / 2) + (animationValue * 2 * math.pi);
        final px = x + sparkleSize * math.cos(angle);
        final py = y + sparkleSize * math.sin(angle);

        if (j == 0) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}