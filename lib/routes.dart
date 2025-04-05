import 'package:flutter/material.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/get_code_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/results/results_screen.dart';
import 'presentation/screens/my_vote/my_vote_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/get-code':
        return MaterialPageRoute(builder: (_) => GetCodeScreen());
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/results':
        return MaterialPageRoute(builder: (_) => const ResultsScreen());
      case '/my-vote':
        return MaterialPageRoute(builder: (_) => const MyVoteScreen());
      default:
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                body: Center(
                  child: Text('No route defined for ${settings.name}'),
                ),
              ),
        );
    }
  }
}
