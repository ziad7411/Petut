import 'package:flutter/material.dart';
import 'package:petut/app_colors.dart';
import 'custom_button.dart';
class FloatingHelpButton extends StatefulWidget {
  final VoidCallback? onIdentifyPressed;

  const FloatingHelpButton({super.key, this.onIdentifyPressed});

  @override
  State<FloatingHelpButton> createState() => _FloatingHelpButtonState();
}

class _FloatingHelpButtonState extends State<FloatingHelpButton>
    with TickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _animationController;
  late AnimationController _glowController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Glow animation controller
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.2, end: 0.6).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _toggleHelp() {
    setState(() {
      _isOpen = !_isOpen;
    });

    if (_isOpen) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _navigateToClassifier() {
    _toggleHelp();
    Navigator.pushNamed(context, '/petClassifier');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = AppColors.getPrimaryColor(context);

    return Stack(
      children: [
        // Background overlay
        if (_isOpen)
          Positioned.fill(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: GestureDetector(
                onTap: _toggleHelp,
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),
            ),
          ),

        // Help panel
        if (_isOpen)
          Positioned(
            bottom: 180,
            right: 16,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Help Center',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.getTextPrimaryColor(context),
                            ),
                          ),
                          GestureDetector(
                            onTap: _toggleHelp,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.close,
                                size: 20,
                                color: AppColors.getTextSecondaryColor(context),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Divider
                      Container(height: 1, color: Colors.grey.withOpacity(0.2)),
                      const SizedBox(height: 16),

                      // AI Breed Identifier Button
                      CustomButton(
                        text: 'AI Breed Identifier',
                        onPressed: _navigateToClassifier,
                        icon: const Text('🧠', style: TextStyle(fontSize: 20)),
                        width: double.infinity,
                        height: 50,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Floating button
        Positioned(
          bottom: 100,
          right: 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow effects
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(_glowAnimation.value),
                          spreadRadius: 8,
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Ripple effect
              if (!_isOpen)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 1000),
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withOpacity(0.3),
                  ),
                ),

              // Main button
              AnimatedRotation(
                duration: const Duration(milliseconds: 300),
                turns: _isOpen ? 0.5 : 0.0,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.4),
                        spreadRadius: 2,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(28),
                      onTap: _toggleHelp,
                      child: Icon(
                        _isOpen ? Icons.close : Icons.chat_bubble_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
