import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/ui_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isParentLoading = false;
  bool _isTeacherLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _loginAsParent() async {
    if (!_validateInputs()) return;

    setState(() {
      _isLoading = true;
      _isParentLoading = true;
    });
    
    try {
      // Sign in with Firebase Auth
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (mounted) {
        // Check user role in Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
        
        if (!userDoc.exists) {
          throw Exception('User data not found');
        }
        
        final userData = userDoc.data() as Map<String, dynamic>;
        final userRole = userData['role'] as String?;
        
        if (userRole != 'parent') {
          // Wrong role, sign out and show error
          await FirebaseAuth.instance.signOut();
          throw Exception('This account is not registered as a parent');
        }
        
        // Correct role, navigate to parent dashboard
        Navigator.pushReplacementNamed(context, '/parent/dashboard');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred during login';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Wrong password provided';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email format';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppTheme.accentColor2,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e is Exception ? e.toString().replaceAll('Exception: ', '') : 'Login failed. Please try again.'),
          backgroundColor: AppTheme.accentColor2,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isParentLoading = false;
        });
      }
    }
  }

  void _loginAsTeacher() async {
    if (!_validateInputs()) return;

    setState(() {
      _isLoading = true;
      _isTeacherLoading = true;
    });
    
    try {
      // Sign in with Firebase Auth
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (mounted) {
        // Check user role in Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
        
        if (!userDoc.exists) {
          throw Exception('User data not found');
        }
        
        final userData = userDoc.data() as Map<String, dynamic>;
        final userRole = userData['role'] as String?;
        
        if (userRole != 'teacher') {
          // Wrong role, sign out and show error
          await FirebaseAuth.instance.signOut();
          throw Exception('This account is not registered as a teacher');
        }
        
        // Correct role, navigate to teacher dashboard
        Navigator.pushReplacementNamed(context, '/teacher/dashboard');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred during login';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Wrong password provided';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email format';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppTheme.accentColor2,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e is Exception ? e.toString().replaceAll('Exception: ', '') : 'Login failed. Please try again.'),
          backgroundColor: AppTheme.accentColor2,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isTeacherLoading = false;
        });
      }
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
            child: Column(
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
                  text: 'Login as Parent',
                  onPressed: _isLoading ? null : _loginAsParent,
                  isLoading: _isParentLoading,
                  margin: const EdgeInsets.only(bottom: UIConstants.spacing16),
                ),
                CustomButton(
                  text: 'Login as Teacher',
                  variant: ButtonVariant.outline,
                  onPressed: _isLoading ? null : _loginAsTeacher,
                  isLoading: _isTeacherLoading,
                ),
                const SizedBox(height: UIConstants.spacing16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordScreen(),
                      ),
                    );
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text('Register'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 