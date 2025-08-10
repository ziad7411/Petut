import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final Widget? icon;
  final double? fontSize;
  final FontWeight fontWeight;
  final Color? customColor;
  final double? iconSpacing;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isPrimary = true,
    this.borderRadius = 12.0,
    this.padding,
    this.width,
    this.height,
    this.icon,
    this.fontSize,
    this.fontWeight = FontWeight.w600,
    this.customColor,
    this.iconSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // 🔹 قياسات Responsive
    final responsiveHeight = height ?? (screenWidth < 360 ? 48 : 56);
    final responsiveFontSize = fontSize ?? (screenWidth < 360 ? 14 : 16);
    final responsiveIconSpacing = iconSpacing ?? (screenWidth < 360 ? 6 : 8);
    final responsivePadding = padding ??
        EdgeInsets.symmetric(
          horizontal: screenWidth < 360 ? 16 : 20,
        );

    Color backgroundColor;
    Color textColor;
    Color? borderColor;

    if (customColor != null) {
      backgroundColor = customColor!;
      textColor = ThemeData.estimateBrightnessForColor(backgroundColor) ==
              Brightness.dark
          ? Colors.white
          : Colors.black;
      borderColor = null;
    } else if (isPrimary) {
      backgroundColor = theme.colorScheme.primary;
      textColor = theme.colorScheme.onPrimary;
      borderColor = null;
    } else {
      backgroundColor = theme.colorScheme.surface;
      textColor = theme.colorScheme.primary;
      borderColor = theme.colorScheme.primary;
    }

    return SizedBox(
      width: width,
      height: responsiveHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: responsivePadding,
          elevation: isPrimary ? 4 : 0,
          shadowColor: isPrimary
              ? theme.colorScheme.primary.withOpacity(0.3)
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: borderColor != null
                ? BorderSide(color: borderColor, width: 1.5)
                : BorderSide.none,
          ),
          disabledBackgroundColor: backgroundColor.withOpacity(0.6),
        ),
        child: icon != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon!,
                  SizedBox(width: responsiveIconSpacing),
                  Flexible(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: responsiveFontSize,
                        fontWeight: fontWeight,
                        letterSpacing: 0.7,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: responsiveFontSize,
                  fontWeight: fontWeight,
                  letterSpacing: 0.7,
                ),
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }
}
