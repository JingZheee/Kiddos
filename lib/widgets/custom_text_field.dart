import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/ui_constants.dart';
import '../core/theme/app_theme.dart';

enum TextFieldVariant {
  outlined,
  filled,
}

class CustomTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final String? prefix;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextFieldVariant variant;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;
  final EdgeInsets? margin;

  const CustomTextField({
    Key? key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.prefix,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.variant = TextFieldVariant.filled,
    this.enabled = true,
    this.inputFormatters,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: UIConstants.spacing8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            validator: validator,
            onChanged: onChanged,
            maxLines: maxLines,
            minLines: minLines,
            maxLength: maxLength,
            enabled: enabled,
            inputFormatters: inputFormatters,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textPrimaryColor,
            ),
            decoration: _getInputDecoration(),
          ),
        ],
      ),
    );
  }

  InputDecoration _getInputDecoration() {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: AppTheme.textLightColor,
      ),
      prefixIcon: prefixIcon != null
          ? Icon(
              prefixIcon,
              color: AppTheme.textSecondaryColor,
              size: UIConstants.iconSizeMedium,
            )
          : null,
      prefixText: prefix,
      suffixIcon: suffixIcon != null
          ? IconButton(
              icon: Icon(
                suffixIcon,
                color: AppTheme.textSecondaryColor,
                size: UIConstants.iconSizeMedium,
              ),
              onPressed: onSuffixIconPressed,
            )
          : null,
      filled: variant == TextFieldVariant.filled,
      fillColor: variant == TextFieldVariant.filled
          ? Colors.white
          : Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: UIConstants.spacing16,
        vertical: UIConstants.spacing12,
      ),
      border: _getBorder(),
      enabledBorder: _getBorder(),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
        borderSide: const BorderSide(
          color: AppTheme.primaryColor,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
        borderSide: const BorderSide(
          color: AppTheme.accentColor2,
          width: 1.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
        borderSide: const BorderSide(
          color: AppTheme.accentColor2,
          width: 1.5,
        ),
      ),
      errorStyle: const TextStyle(
        color: AppTheme.accentColor2,
      ),
    );
  }

  InputBorder _getBorder() {
    return variant == TextFieldVariant.outlined
        ? OutlineInputBorder(
            borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
            borderSide: const BorderSide(
              color: AppTheme.textLightColor,
              width: 1.0,
            ),
          )
        : OutlineInputBorder(
            borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
            borderSide: BorderSide.none,
          );
  }
} 