import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_env.dart';
import '../constants/routes_constant.dart';

class ScreenSecurityService {
  ScreenSecurityService._();

  static const MethodChannel _channel =
      MethodChannel('com.innoplix.erupaiya/screen_security');

  static bool _isEnabled = false;
  static bool _isOnTransactionDetail = false;

  /// Transaction detail routes that must allow screenshots
  static const Set<String> _transactionDetailRoutes = {
    RouteConstants.transactionDetail,
    RouteConstants.transactionDetailSuccess,
    RouteConstants.transactionDetailFailed,
    RouteConstants.transactionDetailPending,
    RouteConstants.creditCardTransactionDetail,
  };

  /// Initialize screenshot protection based on AppEnv configuration
  /// Call this once at app startup
  static Future<void> initialize() async {
    if (AppEnv.enableScreenshotProtection) {
      await enableSecure();
      _isEnabled = true;
    }
  }

  /// Enable screenshot protection via native platform
  static Future<void> enableSecure() async {
    try {
      await _channel.invokeMethod('enableSecure');
      _isEnabled = true;
    } catch (_) {}
  }

  /// Disable screenshot protection via native platform
  static Future<void> disableSecure() async {
    try {
      await _channel.invokeMethod('disableSecure');
      _isEnabled = false;
    } catch (_) {}
  }

  /// Check if screenshot protection is currently enabled
  static bool get isEnabled => _isEnabled;

  /// Check if current route is a transaction detail screen
  static bool isTransactionDetailRoute(String route) {
    return _transactionDetailRoutes.any((detailRoute) =>
        route.startsWith(detailRoute) || route == detailRoute);
  }

  /// Update screenshot protection based on current route
  /// Call this on route changes
  static Future<void> updateForRoute(String route) async {
    _isOnTransactionDetail = isTransactionDetailRoute(route);

    if (_isOnTransactionDetail) {
      // Always disable on transaction detail screens
      await disableSecure();
    } else if (AppEnv.enableScreenshotProtection) {
      // Enable on other screens if flag is true
      await enableSecure();
    } else {
      // Keep disabled if flag is false
      await disableSecure();
    }
  }

  /// Create a Navigator observer for automatic route-based protection
  static NavigatorObserver createRouteObserver() {
    return _ScreenSecurityNavigatorObserver();
  }
}

class _ScreenSecurityNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _updateForRoute(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _updateForRoute(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _updateForRoute(newRoute);
  }

  void _updateForRoute(Route<dynamic>? route) {
    if (route == null) return;
    final routeName = route.settings.name ?? '';
    ScreenSecurityService.updateForRoute(routeName);
  }
}
