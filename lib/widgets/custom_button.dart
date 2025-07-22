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
  final double iconSpacing;

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
    this.iconSpacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = AppColors.getPrimaryColor(context);
    final Color backgroundColor = AppColors.getBackgroundColor(context);
    final Color textPrimary = AppColors.getTextPrimaryColor(context);

    Color finalBackgroundColor;
    Color finalTextColor;
    Color? borderColor;

    if (customColor != null) {
      finalBackgroundColor = customColor!;
      finalTextColor = backgroundColor;
      borderColor = null;
    } else if (isPrimary) {
      finalBackgroundColor = primaryColor;
      finalTextColor = backgroundColor;
      borderColor = null;
    } else {
      finalBackgroundColor = backgroundColor;
      finalTextColor = primaryColor;
      borderColor = primaryColor;
    }

    return SizedBox(
      width: width,
      height: height ?? 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: finalBackgroundColor,
          foregroundColor: finalTextColor,
          padding: padding,
          elevation: isPrimary ? 4 : 0,
          shadowColor: isPrimary ? primaryColor.withOpacity(0.3) : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: borderColor != null
                ? BorderSide(color: borderColor, width: 1.5)
                : BorderSide.none,
          ),
          disabledBackgroundColor: finalBackgroundColor.withOpacity(0.6),
        ),
        child: icon != null
            ? Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: iconSpacing),
                      child: icon,
                    ),
                  ),
                  Center(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: fontWeight,
                        letterSpacing: 0.7,
                        color: finalTextColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            : Center(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                    letterSpacing: 0.7,
                    color: finalTextColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
      ),
    );
  }
}
