
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
  final IconData? icon;
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
      textColor = Colors.white;
      borderColor = null;
    } else if (isPrimary) {
      backgroundColor = AppColors.gold;
      textColor = Colors.white;
      borderColor = null;
    } else {
      backgroundColor = Colors.white;
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: fontSize + 2),
              SizedBox(width: 8),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: fontWeight,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
