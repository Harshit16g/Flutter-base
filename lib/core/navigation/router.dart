// lib/core/navigation/router.dart
//USAGE
//// Basic navigation
// NavigationService.navigateTo(Routes.profile, arguments: {'userId': '123'});
//
// // Navigation with custom transition
// NavigationService.navigateTo(
//   Routes.settings,
//   transition: RouteTransition.fade,
// );
//
// // Replace current route
// NavigationService.replace(
//   Routes.home,
//   transition: RouteTransition.slideRight,
// );
//
// // Clear stack and navigate
// NavigationService.pushAndRemoveUntil(
//   Routes.login,
//   (route) => false,
//   transition: RouteTransition.slideUp,
// );


import 'package:flutter/material.dart';
import '../error/route_exception.dart';
import 'routes.dart';
import 'transitions/fade_route.dart';
import 'transitions/slide_route.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

enum RouteTransition {
  material,
  cupertino,
  fade,
  slideRight,
  slideLeft,
  slideUp,
  slideDown,
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments as Map<String, dynamic>?;
    final transition = args?['transition'] as RouteTransition? ??
        RouteTransition.material;

    try {
      switch (settings.name) {
        case Routes.splash:
          return _buildRoute(
            const SplashScreen(),
            settings,
            transition,
          );

        case Routes.login:
          return _buildRoute(
            const LoginScreen(),
            settings,
            transition,
          );

        case Routes.register:
          return _buildRoute(
            const RegisterScreen(),
            settings,
            transition,
          );

        case Routes.home:
          return _buildRoute(
            const HomeScreen(),
            settings,
            transition,
          );

        case Routes.profile:
          final userId = args?['userId'] as String?;
          return _buildRoute(
            ProfileScreen(userId: userId),
            settings,
            transition,
          );

        case Routes.settings:
          return _buildRoute(
            const SettingsScreen(),
            settings,
            transition,
          );

        default:
          throw RouteException('Route not found');
      }
    } catch (e) {
      return MaterialPageRoute(
        builder: (_) => _ErrorScreen(
          message: 'Navigation error: ${e.toString()}',
        ),
      );
    }
  }

  static Route<dynamic> _buildRoute(
      Widget page,
      RouteSettings settings,
      RouteTransition transition,
      ) {
    switch (transition) {
      case RouteTransition.material:
        return MaterialPageRoute(
          builder: (_) => page,
          settings: settings,
        );

      case RouteTransition.cupertino:
        return CupertinoPageRoute(
          builder: (_) => page,
          settings: settings,
        );

      case RouteTransition.fade:
        return FadeRoute(
          page: page,
          settings: settings,
        );

      case RouteTransition.slideRight:
        return SlideRoute(
          page: page,
          settings: settings,
          direction: SlideDirection.right,
        );

      case RouteTransition.slideLeft:
        return SlideRoute(
          page: page,
          settings: settings,
          direction: SlideDirection.left,
        );

      case RouteTransition.slideUp:
        return SlideRoute(
          page: page,
          settings: settings,
          direction: SlideDirection.up,
        );

      case RouteTransition.slideDown:
        return SlideRoute(
          page: page,
          settings: settings,
          direction: SlideDirection.down,
        );
    }
  }
}

@immutable
class NavigationService {
  static final GlobalKey<NavigatorState> _navigatorKey =
  GlobalKey<NavigatorState>();

  static GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  static Future<T?> navigateTo<T>(
      String routeName, {
        Map<String, dynamic>? arguments,
        RouteTransition transition = RouteTransition.material,
      }) {
    final args = {
      ...?arguments,
      'transition': transition,
    };
    return _navigatorKey.currentState!.pushNamed<T>(
      routeName,
      arguments: args,
    );
  }

  static Future<T?> replace<T>(
      String routeName, {
        Map<String, dynamic>? arguments,
        RouteTransition transition = RouteTransition.material,
      }) {
    final args = {
      ...?arguments,
      'transition': transition,
    };
    return _navigatorKey.currentState!.pushReplacementNamed<dynamic, T>(
      routeName,
      arguments: args,
    );
  }

  static Future<T?> pushAndRemoveUntil<T>(
      String newRoute,
      bool Function(Route<dynamic>) predicate, {
        Map<String, dynamic>? arguments,
        RouteTransition transition = RouteTransition.material,
      }) {
    final args = {
      ...?arguments,
      'transition': transition,
    };
    return _navigatorKey.currentState!.pushNamedAndRemoveUntil<T>(
      newRoute,
      predicate,
      arguments: args,
    );
  }

  static void pop<T>([T? result]) {
    return _navigatorKey.currentState!.pop<T>(result);
  }

  static void popUntil(String routeName) {
    _navigatorKey.currentState!.popUntil(ModalRoute.withName(routeName));
  }

  static bool canPop() {
    return _navigatorKey.currentState!.canPop();
  }
}

class _ErrorScreen extends StatelessWidget {
  final String message;

  const _ErrorScreen({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(message),
      ),
    );
  }
}