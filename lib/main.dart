import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/habit_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/welcome_back_screen.dart';
import 'screens/initial_welcome_screen.dart';
import 'screens/email_verification_screen.dart';
import 'theme/app_theme.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, HabitProvider>(
          create: (_) => HabitProvider(),
          update: (_, auth, habit) => habit!..updateUserId(auth.userId),
        ),
      ],
      child: const HabitSpecApp(),
    ),
  );
}

class HabitSpecApp extends StatelessWidget {
  const HabitSpecApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HabitSpec',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (!auth.isInitialized) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (!auth.isLoggedIn) {
            return const AuthScreen();
          }
          // If email is not verified (only for email/password signups, not Google)
          if (!auth.isEmailVerified) {
            return const EmailVerificationScreen();
          }
          // If first time signup, show the "Welcome" message
          if (auth.isFirstTimeSignup) {
            return const InitialWelcomeScreen();
          }
          // If logged in but no name set, show welcome (onboarding)
          if (auth.userName == null) {
            return const WelcomeScreen();
          }
          // If returning user who hasn't seen the welcome back screen yet
          if (!auth.hasSeenWelcomeBack) {
            return const WelcomeBackScreen();
          }
          return const MainNavigationScreen();
        },
      ),
    );
  }
}
