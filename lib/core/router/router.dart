import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../services/profile_service.dart';
import '../../controllers/auth_controller.dart';
import '../../view/error_screen.dart';
import 'routes.dart';

class WillRouter {
  const WillRouter._();

  static final navigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: WillRoutes.root,
    debugLogDiagnostics: kDebugMode,
    routes: WillRoutes.allRoutes,
    errorBuilder: (context, state) =>
        const ErrorScreen(type: ErrorType.notFound),
    redirect: (context, state) {
      final auth = Get.find<AuthController>();
      final user = auth.user.value;
      final hasSeenSetup = ProfileService.hasSeenDeviceSetup();
      final location = state.matchedLocation;

      // Signed out: only public routes are reachable.
      if (user == null) {
        return WillRoutes.isPublicRoute(location) ? null : WillRoutes.welcome;
      }

      // Signed in (or guest) but hasn't seen device setup yet.
      if (!hasSeenSetup) {
        return location == WillRoutes.deviceSetup
            ? null
            : WillRoutes.deviceSetup;
      }

      // Fully onboarded: bounce out of any pre-home screens.
      if (WillRoutes.isPublicRoute(location) ||
          location == WillRoutes.deviceSetup) {
        return WillRoutes.home;
      }
      return null;
    },
  );
}
