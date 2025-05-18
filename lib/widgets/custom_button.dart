import 'package:flutter/material.dart';
import '../core/constants/ui_constants.dart';
import '../core/theme/app_theme.dart';

enum ButtonVariant {
  primary,
  secondary,
  outline,
  text,
}

enum ButtonSize {
  small,
  medium,
  large,
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final EdgeInsets? margin;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: _buildButton(),
    );
  }

  Widget _buildButton() {
    switch (variant) {
      case ButtonVariant.primary:
        return _buildElevatedButton();
      case ButtonVariant.secondary:
        return _buildSecondaryButton();
      case ButtonVariant.outline:
        return _buildOutlinedButton();
      case ButtonVariant.text:
        return _buildTextButton();
    }
  }

  Widget _buildElevatedButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: _getButtonSize(),
        padding: const EdgeInsets.symmetric(horizontal: UIConstants.spacing16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      child: _buildButtonContent(Colors.white),
    );
  }

  Widget _buildSecondaryButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: _getButtonSize(),
        padding: const EdgeInsets.symmetric(horizontal: UIConstants.spacing16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
        ),
        backgroundColor: AppTheme.secondaryColor,
        foregroundColor: Colors.white,
      ),
      child: _buildButtonContent(Colors.white),
    );
  }

  Widget _buildOutlinedButton() {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: _getButtonSize(),
        padding: const EdgeInsets.symmetric(horizontal: UIConstants.spacing16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
        ),
        side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
      child: _buildButtonContent(AppTheme.primaryColor),
    );
  }

  Widget _buildTextButton() {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        minimumSize: _getButtonSize(),
        padding: const EdgeInsets.symmetric(horizontal: UIConstants.spacing16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
        ),
      ),
      child: _buildButtonContent(AppTheme.primaryColor),
    );
  }

  Size _getButtonSize() {
    double height;
    switch (size) {
      case ButtonSize.small:
        height = UIConstants.buttonHeightSmall;
        break;
      case ButtonSize.medium:
        height = UIConstants.buttonHeightMedium;
        break;
      case ButtonSize.large:
        height = UIConstants.buttonHeightLarge;
        break;
    }
    return Size(fullWidth ? double.infinity : 0, height);
  }

  Widget _buildButtonContent(Color textColor) {
    if (isLoading) {
      return SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: UIConstants.spacing8),
          Text(text),
        ],
      );
    }

    return Text(text);
  }
} 