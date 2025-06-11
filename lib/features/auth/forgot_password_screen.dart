import 'package:flutter/material.dart';
import '../../core/constants/ui_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_services.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final result = await AuthService.sendPasswordResetEmail(email);
    
    setState(() {
      _isLoading = false;
      if (result.isSuccess) {
        _successMessage = 'If an account exists with this email, a password reset link has been sent';
      } else {
        _errorMessage = result.errorMessage;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: AppTheme.textPrimaryColor,
        ),
        title: const Text(
          'Forgot Password',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(UIConstants.spacing24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reset your password',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: UIConstants.spacing16),
                const Text(
                  'Enter your email address and we\'ll send you instructions to reset your password',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: UIConstants.spacing32),
                
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(UIConstants.spacing16),
                    margin: const EdgeInsets.only(bottom: UIConstants.spacing16),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor2.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
                      border: Border.all(color: AppTheme.accentColor2),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.accentColor2,
                        ),
                        const SizedBox(width: UIConstants.spacing8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                if (_successMessage != null)
                  Container(
                    padding: const EdgeInsets.all(UIConstants.spacing16),
                    margin: const EdgeInsets.only(bottom: UIConstants.spacing16),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor1.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
                      border: Border.all(color: AppTheme.accentColor1),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: AppTheme.accentColor1,
                        ),
                        const SizedBox(width: UIConstants.spacing8),
                        Expanded(
                          child: Text(
                            _successMessage!,
                            style: const TextStyle(
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                CustomTextField(
                  label: 'Email',
                  hint: 'Enter your email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  margin: const EdgeInsets.only(bottom: UIConstants.spacing32),
                ),
                
                CustomButton(
                  text: 'Send Reset Link',
                  onPressed: _isLoading ? null : _resetPassword,
                  isLoading: _isLoading,
                  margin: const EdgeInsets.only(bottom: UIConstants.spacing16),
                ),
                
                if (_successMessage != null)
                  CustomButton(
                    text: 'Back to Login',
                    variant: ButtonVariant.outline,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 