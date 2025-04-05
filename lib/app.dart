import 'package:flutter/material.dart';
import 'routes.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';

class VotingApp extends StatelessWidget {
  const VotingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voting System',
      debugShowCheckedModeBanner: false, // This removes the debug banner
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: const OnboardingScreen(),
    );
  }
}
