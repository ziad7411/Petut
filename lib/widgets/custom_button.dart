import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);
    Color backgroundColor;
    Color textColor;
    Color? borderColor;

    // -- تعديل: تحديد الألوان بناءً على الثيم --
    if (customColor != null) {
      backgroundColor = customColor!;
      textColor =
          ThemeData.estimateBrightnessForColor(backgroundColor) ==
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
      height: height ?? 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: padding,
          elevation: isPrimary ? 4 : 0,
          shadowColor:
              isPrimary
                  ? theme.colorScheme.primary.withOpacity(0.3)
                  : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side:
                borderColor != null
                    ? BorderSide(color: borderColor, width: 1.5)
                    : BorderSide.none,
          ),
          disabledBackgroundColor: backgroundColor.withOpacity(0.6),
        ),
        child:
            icon != null
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
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
      ),
    );
  }
}
