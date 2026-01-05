import 'package:flutter/material.dart';
import 'package:e_signature/route/route_name.dart';
import '../features/authentication/presentation/views/login_screen.dart';
import '../features/authentication/presentation/views/register_screen.dart';
import '../features/editor/presentation/views/document_editor_screen.dart';
import '../shared/entities/document_entity.dart';
import '../shared/widgets/main_navigation.dart';

class RouteConfig {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteName.splash:
      case RouteName.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case RouteName.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case RouteName.home:
        return MaterialPageRoute(builder: (_) => const MainNavigation());

      case RouteName.editor:
        final document = settings.arguments as DocumentEntity;
        return MaterialPageRoute(builder: (_) => DocumentEditorScreen(document: document));

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(body: Center(child: Text('Page not found: ${settings.name}'))),
        );
    }
  }
}
