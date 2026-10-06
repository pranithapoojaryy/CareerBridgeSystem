import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Using NotifierProvider instead of StateProvider to ensure compatibility
final currentRouteProvider = NotifierProvider<CurrentRouteNotifier, String>(
  CurrentRouteNotifier.new,
);

class CurrentRouteNotifier extends Notifier<String> {
  @override
  String build() {
    return '/';
  }

  void setRoute(String route) {
    state = route;
  }
}

// Navigator Observer to track route changes
class AppRouteObserver extends NavigatorObserver {
  final WidgetRef ref;

  AppRouteObserver(this.ref);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name != null) {
      // Using implicit read via the ref passed from UI
      ref.read(currentRouteProvider.notifier).setRoute(route.settings.name!);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute?.settings.name != null) {
      ref
          .read(currentRouteProvider.notifier)
          .setRoute(previousRoute!.settings.name!);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute?.settings.name != null) {
      ref
          .read(currentRouteProvider.notifier)
          .setRoute(newRoute!.settings.name!);
    }
  }
}
