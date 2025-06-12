import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nursery_app/core/providers/user_provider.dart';
import '../../core/providers/user_role_provider.dart';
import 'package:nursery_app/core/routing/app_navigation.dart';
import 'package:nursery_app/models/user/user_role_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  String? _errorMessage;
  String? _selectedRoleId; // Selected role ID

  @override
  void initState() {
    super.initState();
    // Initialize roles when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final roleProvider = Provider.of<UserRoleProvider>(context, listen: false);
      if (!roleProvider.isInitialized) {
        roleProvider.initializeRoles();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    if (_selectedRoleId == null) {
      setState(() {
        _errorMessage = 'Please select a role';
      });
      return;
    }

    final userProvider = context.read<UserProvider>();
    
    final result = await userProvider.registerUser(
      email: _emailController.text,
      password: _passwordController.text,
      name: _nameController.text,
      roleId: _selectedRoleId!,
    );

    if (mounted) {
      if (result.isSuccess) {
        // Navigate back to login screen
        AppNavigation.goToLogin(context);
      } else {
        setState(() {
          _errorMessage = result.errorMessage;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            return Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              const SizedBox(height: 20),
              Text(
                'Join Kiddos',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Consumer<UserRoleProvider>(
                builder: (context, roleProvider, child) {
                  if (roleProvider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (roleProvider.hasError || roleProvider.roles.isEmpty) {
                    return Column(
                      children: [
                        Text(
                          roleProvider.errorMessage ?? 'No roles available',
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => roleProvider.refreshRoles(),
                          child: const Text('Retry'),
                        ),
                      ],
                    );
                  }

                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select Role',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    value: _selectedRoleId,
                    items: roleProvider.roles.map((UserRole role) {
                      return DropdownMenuItem<String>(
                        value: role.id,
                        child: Text(role.roleName),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        _selectedRoleId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a role';
                      }
                      return null;
                    },
                  );
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: userProvider.isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: userProvider.isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Register'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => AppNavigation.goToLogin(context),
                child: const Text('Already have an account? Sign In'),
              ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
