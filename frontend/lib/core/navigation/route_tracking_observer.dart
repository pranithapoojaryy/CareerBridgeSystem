import 'package:flutter/material.dart';

class RouteTrackingObserver extends NavigatorObserver {
  // Singleton instance
  static final RouteTrackingObserver instance = RouteTrackingObserver();

  // ValueNotifier to broadcast changes
  final ValueNotifier<String> currentRouteNotifier = ValueNotifier<String>('/');

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name != null) {
      currentRouteNotifier.value = route.settings.name!;
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute?.settings.name != null) {
      currentRouteNotifier.value = previousRoute!.settings.name!;
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute?.settings.name != null) {
      currentRouteNotifier.value = newRoute!.settings.name!;
    }
  }
}
