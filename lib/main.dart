import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/user_role_provider.dart';
import 'core/providers/user_provider.dart';
import 'core/providers/survey_provider.dart';
import 'core/routing/app_router.dart';

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
  const NurseryApp({super.key});  @override
  Widget build(BuildContext context) {
    return MultiProvider(      providers: [
        ChangeNotifierProvider(create: (_) => UserRoleProvider()),
        ChangeNotifierProvider(create: (_) => SurveyProvider()),
        ChangeNotifierProxyProvider<UserRoleProvider, UserProvider>(
          create: (context) => UserProvider(context.read<UserRoleProvider>()),
          update: (_, userRoleProvider, userProvider) => 
              userProvider ?? UserProvider(userRoleProvider),
        ),
      ],
      child: Consumer2<UserProvider, UserRoleProvider>(
        builder: (context, userProvider, userRoleProvider, child) {
          // Initialize roles when app starts
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!userRoleProvider.isInitialized && !userRoleProvider.isLoading) {
              userRoleProvider.initializeRoles();
            }
          });

          return MaterialApp.router(
            title: 'Kiddos',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(),
            routerConfig: AppRouter.createRouter(
              userProvider: userProvider,
              userRoleProvider: userRoleProvider,
            ),
          );
        },
      ),
    );
  }
}
