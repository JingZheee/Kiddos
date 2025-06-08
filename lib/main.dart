import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/user_role_provider.dart';
import 'core/providers/user_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/parent/parent_dashboard_screen.dart';
import 'features/teacher/teacher_dashboard_screen.dart';
import 'examples/user_role_usage_example.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const NurseryApp());
}

class NurseryApp extends StatelessWidget {
  const NurseryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserRoleProvider()),
        ChangeNotifierProxyProvider<UserRoleProvider, UserProvider>(
          create: (context) => UserProvider(context.read<UserRoleProvider>()),
          update: (_, userRoleProvider, userProvider) => 
              userProvider ?? UserProvider(userRoleProvider),
        ),
      ],
      child: MaterialApp(
        title: 'Kiddos',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        home: const AppInitializer(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/parent/dashboard': (context) => const ParentDashboardScreen(),
          '/teacher/dashboard': (context) => const TeacherDashboardScreen(),
          '/example/user-roles': (context) => const UserRoleExampleScreen(),
        },
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize user roles from Firebase/cache
    final userRoleProvider = context.read<UserRoleProvider>();
    await userRoleProvider.initializeRoles();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserRoleProvider>(
      builder: (context, userRoleProvider, child) {
        if (userRoleProvider.isLoading && !userRoleProvider.isInitialized) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading app data...'),
                ],
              ),
            ),
          );
        }
        
        if (userRoleProvider.hasError && !userRoleProvider.isInitialized) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to initialize app:\n${userRoleProvider.errorMessage}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _initializeApp,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        
        // App is initialized, proceed to authentication
        return const AuthenticationWrapper();
      },
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, UserRoleProvider>(
      builder: (context, userProvider, userRoleProvider, child) {
        // Show loading screen while initializing
        if (!userProvider.isInitialized) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing...'),
                ],
              ),
            ),
          );
        }
        
        // User is authenticated, route based on role
        if (userProvider.isAuthenticated) {
          final userModel = userProvider.userModel;
          
          if (userModel != null) {
            // Route based on role type using the user model's built-in getters
            if (userModel.isParent) {
              return const ParentDashboardScreen();
            } else if (userModel.isTeacher) {
              return const TeacherDashboardScreen();
            } else if (userModel.isAdmin) {
              // Add admin dashboard when you create it
              return const TeacherDashboardScreen(); // Temporary fallback
            }
          }
          
          // User data not complete, redirect to login
          return const LoginScreen();
        }
        
        // User not authenticated
        return const LoginScreen();
      },
    );
  }
}
