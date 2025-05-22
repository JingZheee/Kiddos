import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/parent/parent_dashboard_screen.dart';
import 'features/teacher/teacher_dashboard_screen.dart';

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
    return MaterialApp(
      title: 'Kiddos',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      home: const AuthenticationWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/parent/dashboard': (context) => const ParentDashboardScreen(),
        '/teacher/dashboard': (context) => const TeacherDashboardScreen(),
      },
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user != null) {
            // User is signed in, check user role from Firestore
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final userData = snapshot.data!.data() as Map<String, dynamic>;
                    final userRole = userData['role'] as String?;
                    
                    if (userRole == 'teacher') {
                      return const TeacherDashboardScreen();
                    } else {
                      // Default to parent dashboard
                      return const ParentDashboardScreen();
                    }
                  }
                  
                  // No user data found, redirect to login
                  return const LoginScreen();
                }
                
                // While waiting for Firestore
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              },
            );
          }
          return const LoginScreen();
        }
        
        // While waiting for connection to be established
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
