import 'package:flutter/material.dart';
import '../../features/authentication/presentation/views/login_screen.dart';
import '../../features/authentication/presentation/views/register_screen.dart';
import '../../core/constants/route_constants.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteConstants.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case RouteConstants.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case RouteConstants.home:
        return MaterialPageRoute(
          // Temporary placeholder until Home phase is started
          builder: (_) => const Scaffold(body: Center(child: Text('Home Screen'))),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(body: Center(child: Text('Page not found'))),
        );
    }
  }
}
