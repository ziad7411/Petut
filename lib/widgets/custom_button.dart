import 'package:flutter/material.dart';
import '../app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final Widget? icon;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? customColor;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isPrimary = true,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.width,
    this.height,
    this.icon,
    this.fontSize = 16.0,
    this.fontWeight = FontWeight.w600,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    Color? borderColor;

    if (customColor != null) {
      backgroundColor = customColor!;
      textColor = AppColors.background;
      borderColor = null;
    } else if (isPrimary) {
      backgroundColor = AppColors.gold;
      textColor = AppColors.background;
      borderColor = null;
    } else {
      backgroundColor = AppColors.background;
      textColor = AppColors.gold;
      borderColor = AppColors.gold;
    }

    return SizedBox(
      width: width,
      height: height ?? 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: padding,
          elevation: isPrimary ? 4 : 0,
          shadowColor:
              isPrimary ? AppColors.gold.withOpacity(0.3) : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side:
                borderColor != null
                    ? BorderSide(color: borderColor, width: 1.5)
                    : BorderSide.none,
          ),
          disabledBackgroundColor: backgroundColor.withOpacity(0.6),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // النص في المنتصف دايمًا
            Center(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                  letterSpacing: 0.7,
                ),
              ),
            ),

            // الأيقونة على الشمال
            if (icon != null)
              Align(
                alignment: Alignment.centerLeft,
                child: icon,
              ),
          ],
        ),
      ),
    );
  }
}
