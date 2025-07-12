import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final bool obscureText;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final Color? customFillColor;

  const CustomTextField({
    super.key,
    required this.hintText,
    this.obscureText = false,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.customFillColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fillColor = customFillColor ??
        (theme.brightness == Brightness.dark
            ? Colors.grey.shade800
            : Colors.grey.shade200);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        style: TextStyle(color: theme.textTheme.bodyLarge?.color),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: theme.hintColor),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: theme.iconTheme.color) : null,
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: fillColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.0),
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
