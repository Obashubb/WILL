import 'package:go_router/go_router.dart';

import '../../view/auth/guest_screen.dart';
import '../../view/auth/login_screen.dart';
import '../../view/auth/signup_screen.dart';
import '../../view/auth/welcome_screen.dart';
import '../../view/error_screen.dart';
import '../../view/home/home_shell.dart';
import '../../view/onboarding/device_setup_screen.dart';

class WillRoutes {
  const WillRoutes._();

  static const String root = welcome;

  // region AUTH
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String guest = '/guest';
  // endregion

  // region ONBOARDING
  static const String deviceSetup = '/device-setup';
  // endregion

  // region APP
  static const String home = '/home';
  static const String error = '/error';
  // endregion

  /// Routes a not-yet-signed-in user is allowed to visit.
  /// Anything else triggers a redirect to `welcome`.
  static bool isPublicRoute(String location) {
    if (location.startsWith(error)) return true;
    return location == welcome ||
        location == login ||
        location == signup ||
        location == guest;
  }

  static final List<RouteBase> allRoutes = [
    GoRoute(path: welcome, builder: (context, state) => const WelcomeScreen()),
    GoRoute(path: login, builder: (context, state) => const LoginScreen()),
    GoRoute(path: signup, builder: (context, state) => const SignUpScreen()),
    GoRoute(path: guest, builder: (context, state) => const GuestScreen()),
    GoRoute(
      path: deviceSetup,
      builder: (context, state) => const DeviceSetupScreen(),
    ),
    GoRoute(path: home, builder: (context, state) => const HomeShell()),
    GoRoute(
      path: error,
      builder: (context, state) {
        final typeStr = state.uri.queryParameters['type'] ?? 'generic';
        final type = ErrorType.values.firstWhere(
          (e) => e.name == typeStr,
          orElse: () => ErrorType.generic,
        );
        return ErrorScreen(type: type);
      },
    ),
  ];
}
