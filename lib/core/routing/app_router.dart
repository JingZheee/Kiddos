import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/medications/parent_add_medication.dart';
import '../../features/medications/parent_edit_medication.dart';
import '../../features/medications/parent_medications.dart';
import '../providers/user_provider.dart';
import '../providers/user_role_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/parent/parent_dashboard_screen.dart';
import '../../features/teacher/teacher_dashboard_screen.dart';
import '../../examples/user_role_usage_example.dart';

class AppRouter {
  static GoRouter createRouter({
    required UserProvider userProvider,
    required UserRoleProvider userRoleProvider,
  }) {
    return GoRouter(
      debugLogDiagnostics: true,
      initialLocation: '/splash',
      refreshListenable: Listenable.merge([userProvider, userRoleProvider]),
      redirect: (context, state) {
        final isInitialized = userRoleProvider.isInitialized && userProvider.isInitialized;
        final isAuthenticated = userProvider.isAuthenticated;
        final userModel = userProvider.userModel;
        final path = state.matchedLocation;

        // Show splash while initializing
        if (!isInitialized && path != '/splash') {
          return '/splash';
        }

        // If user is not authenticated and trying to access protected routes
        if (isInitialized && !isAuthenticated) {
          if (path != '/login' && path != '/register' && path != '/forgot-password') {
            return '/login';
          }
          return null; // Allow access to auth pages
        }

        // If user is authenticated
        if (isAuthenticated && userModel != null) {
          // Redirect from auth pages to appropriate dashboard
          if (path == '/login' || path == '/register' || path == '/splash') {
            if (userModel.isParent) {
              return '/parent/dashboard';
            } else if (userModel.isTeacher) {
              return '/teacher/dashboard';
            } else if (userModel.isAdmin) {
              return '/teacher/dashboard';
            }
          }

          // Role-based access control
          if (path.startsWith('/parent/') && !userModel.isParent) {
            return '/unauthorized';
          }
          if (path.startsWith('/teacher/') && !userModel.isTeacher) {
            return '/unauthorized';
          }
          if (path.startsWith('/admin/') && !userModel.isAdmin) {
            return '/unauthorized';
          }
        }

        return null; // No redirect needed
      },
      routes: [
        // Splash/Loading route
        GoRoute(
          path: '/splash',
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),

        // Authentication routes
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          name: 'forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),

        // Parent routes
        GoRoute(
          path: '/parent/dashboard',
          name: 'parent-dashboard',
          builder: (context, state) => const ParentDashboardScreen(),
          routes: [
            // Add child routes for parent here
            // GoRoute(
            //   path: 'profile',
            //   name: 'parent-profile',
            //   builder: (context, state) => const ParentProfileScreen(),
            // ),
          ],
        ),

        // Parent Medications routes 
        GoRoute(
          path: '/parent/medications',
          name: 'parent-medications',
          builder: (context, state) => const ParentMedicationsScreen(),
          routes: [
            // Add child routes for parent here
            GoRoute(
              path: 'add',
              name: 'parent-add-medication',
              builder: (context, state) => const ParentAddMedicationScreen(),
            ),
            GoRoute(
              path: 'edit/:medicationId',
              name: 'parent-edit-medication',
              builder: (context, state) => ParentEditMedication(
                medicationId: state.pathParameters['medicationId']!,
              ),
            ),
          ],
        ),

        // Teacher routes
        GoRoute(
          path: '/teacher/dashboard',
          name: 'teacher-dashboard',
          builder: (context, state) => const TeacherDashboardScreen(),
          routes: [
            // Add child routes for teacher here
            // GoRoute(
            //   path: 'classes',
            //   name: 'teacher-classes',
            //   builder: (context, state) => const TeacherClassesScreen(),
            // ),
          ],
        ),

        // Admin routes (you can add these later)
        GoRoute(
          path: '/admin/dashboard',
          name: 'admin-dashboard',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Admin Dashboard - Coming Soon')),
          ),
        ),

        // Example routes
        GoRoute(
          path: '/example/user-roles',
          name: 'user-roles-example',
          builder: (context, state) => const UserRoleExampleScreen(),
        ),

        // Error routes
        GoRoute(
          path: '/unauthorized',
          name: 'unauthorized',
          builder: (context, state) => const UnauthorizedScreen(),
        ),
      ],
      errorBuilder: (context, state) => ErrorScreen(error: state.error),
    );
  }
}

// Splash screen for app initialization
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserRoleProvider, UserProvider>(
      builder: (context, userRoleProvider, userProvider, child) {
        // Show loading
        if ((userRoleProvider.isLoading && !userRoleProvider.isInitialized) ||
            !userProvider.isInitialized) {
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

        // Show error
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
                    onPressed: () {
                      userRoleProvider.initializeRoles();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // This will trigger the redirect logic
        return const SizedBox.shrink();
      },
    );
  }
}

// Unauthorized access screen
class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Denied'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.block,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'You don\'t have permission to access this page.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    );
  }
}

// Error screen for routing errors
class ErrorScreen extends StatelessWidget {
  final Exception? error;
  
  const ErrorScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            const Text(
              'Oops! The page you\'re looking for doesn\'t exist.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                'Error: ${error.toString()}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
} 