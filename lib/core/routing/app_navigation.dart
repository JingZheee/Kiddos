import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

/// Navigation helper class with convenient methods for app navigation
class AppNavigation {
  // Private constructor to prevent instantiation
  AppNavigation._();

  // Authentication routes
  static void goToLogin(BuildContext context) {
    context.go('/login');
  }

  static void goToRegister(BuildContext context) {
    context.go('/register');
  }

  static void goToForgotPassword(BuildContext context) {
    context.go('/forgot-password');
  }

  // Dashboard routes
  static void goToParentDashboard(BuildContext context) {
    context.go('/parent/dashboard');
  }

  static void goToTeacherDashboard(BuildContext context) {
    context.go('/teacher/dashboard');
  }

  static void goToAdminDashboard(BuildContext context) {
    context.go('/admin/dashboard');
  }

  // Medications routes
  static void goToParentMedications(BuildContext context) {
    context.go('/parent/medications');
  }

  static void goToParentAddMedication(BuildContext context) {
    context.go('/parent/medications/add');
  }

  static void goToParentEditMedication(BuildContext context, String medicationId) {
    context.go('/parent/medications/edit/$medicationId');
  }

  static void goToTeacherMedications(BuildContext context) {
    context.go('/teacher/medications');
  }

  static void goToTeacherEditMedication(BuildContext context, String medicationId) {
    context.go('/teacher/medications/edit/$medicationId');
  }

  // Utility routes
  static void goToUserRoleExample(BuildContext context) {
    context.go('/example/user-roles');
  }

  static void goToUnauthorized(BuildContext context) {
    context.go('/unauthorized');
  }

  // Navigation methods that preserve stack (push instead of go)
  static void pushLogin(BuildContext context) {
    context.push('/login');
  }

  static void pushRegister(BuildContext context) {
    context.push('/register');
  }

  static void pushForgotPassword(BuildContext context) {
    context.push('/forgot-password');
  }

  // Replace current screen (useful for logout)
  static void replaceWithLogin(BuildContext context) {
    context.pushReplacement('/login');
  }

  // Pop and push (useful for navigation after actions)
  static void popAndPushLogin(BuildContext context) {
    context.pop();
    context.push('/login');
  }

  static void popAndPushRegister(BuildContext context) {
    context.pop();
    context.push('/register');
  }

  // Navigate based on user role
  static void goToDashboardForRole(BuildContext context, String role) {
    switch (role.toLowerCase()) {
      case 'parent':
        goToParentDashboard(context);
        break;
      case 'teacher':
        goToTeacherDashboard(context);
        break;
      case 'admin':
        goToAdminDashboard(context);
        break;
      default:
        goToLogin(context);
    }
  }

  // Check if currently on a specific route
  static bool isCurrentRoute(BuildContext context, String routeName) {
    final location = GoRouter.of(context).routerDelegate.currentConfiguration.uri.toString();
    return location == routeName;
  }

  // Get current route name
  static String getCurrentRoute(BuildContext context) {
    return GoRouter.of(context).routerDelegate.currentConfiguration.uri.toString();
  }

  // Navigate back if possible, otherwise go to login
  static void goBackOrLogin(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      goToLogin(context);
    }
  }

  // Navigate back if possible, otherwise go to appropriate dashboard
  static void goBackOrDashboard(BuildContext context, String userRole) {
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      goToDashboardForRole(context, userRole);
    }
  }

  // Clear navigation stack and go to route
  static void clearStackAndGo(BuildContext context, String route) {
    while (Navigator.of(context).canPop()) {
      context.pop();
    }
    context.go(route);
  }

  // Common navigation patterns
  static void logoutAndGoToLogin(BuildContext context) {
    clearStackAndGo(context, '/login');
  }

  // Future: Add methods for nested routes when you implement them
  // Example for parent routes:
  // static void goToParentProfile(BuildContext context) {
  //   context.go('/parent/dashboard/profile');
  // }
  //
  // static void goToParentChildren(BuildContext context) {
  //   context.go('/parent/dashboard/children');
  // }
  //
  // Example for teacher routes:
  // static void goToTeacherClasses(BuildContext context) {
  //   context.go('/teacher/dashboard/classes');
  // }
  //
  // static void goToTeacherStudents(BuildContext context) {
  //   context.go('/teacher/dashboard/students');
  // }
} 