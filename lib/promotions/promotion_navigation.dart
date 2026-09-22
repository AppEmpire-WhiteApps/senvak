import 'dart:async';

import 'package:flutter/widgets.dart';

/// A popped dialog/sheet can still be animating after the shell is current.
class PromotionNavigation extends NavigatorObserver {
  final _departing = <TransitionRoute<dynamic>>{};
  bool _disposed = false;

  static bool isSettled(NavigatorState navigator) {
    final observer = navigator.widget.observers
        .whereType<PromotionNavigation>()
        .firstOrNull;
    return observer != null &&
        !observer._disposed &&
        observer._departing.isEmpty;
  }

  void _trackDeparture(Route<dynamic>? route) {
    if (_disposed || route is! TransitionRoute<dynamic>) return;
    if (!_departing.add(route)) return;
    unawaited(
      route.completed.then<void>((_) {
        _departing.remove(route);
      }),
    );
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _trackDeparture(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _trackDeparture(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _trackDeparture(oldRoute);
  }

  void dispose() {
    _disposed = true;
    _departing.clear();
  }
}
