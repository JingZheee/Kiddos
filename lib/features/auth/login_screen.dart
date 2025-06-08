import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/ui_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/user_provider.dart';
import '../../core/routing/app_navigation.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (!_validateInputs()) return;

    final userProvider = context.read<UserProvider>();
    
    final result = await userProvider.loginUser(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (mounted) {
      if (!result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Login failed. Please try again.'),
            backgroundColor: AppTheme.accentColor2,
          ),
        );
      }
      // No need to handle success case - the UserProvider will automatically
      // trigger navigation through the AuthenticationWrapper
    }
  }

  bool _validateInputs() {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both email and password'),
          backgroundColor: AppTheme.accentColor2,
        ),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(UIConstants.spacing24),
            child: Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                const SizedBox(height: UIConstants.spacing32),
                // App logo placeholder
                Container(
                  height: 120,
                  width: 120,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(bottom: UIConstants.spacing24),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryLightColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.child_care,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Welcome to\nNursery App',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: UIConstants.spacing16),
                const Text(
                  'Sign in to continue',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: UIConstants.spacing48),
                CustomTextField(
                  label: 'Email',
                  hint: 'Enter your email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  margin: const EdgeInsets.only(bottom: UIConstants.spacing16),
                ),
                CustomTextField(
                  label: 'Password',
                  hint: 'Enter your password',
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  onSuffixIconPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                  margin: const EdgeInsets.only(bottom: UIConstants.spacing32),
                ),
                CustomButton(
                  text: 'Login',
                  onPressed: userProvider.isLoading ? null : _login,
                  isLoading: userProvider.isLoading,
                  margin: const EdgeInsets.only(bottom: UIConstants.spacing16),
                ),
                const SizedBox(height: UIConstants.spacing16),
                TextButton(
                  onPressed: () {
                    AppNavigation.pushForgotPassword(context);
                  },
                  child: const Text('Forgot Password?'),
                ),
                const SizedBox(height: UIConstants.spacing32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(color: AppTheme.textSecondaryColor),
                    ),
                    TextButton(
                      onPressed: () {
                        AppNavigation.pushRegister(context);
                      },
                      child: const Text('Register'),
                    ),
                  ],
                ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
} 