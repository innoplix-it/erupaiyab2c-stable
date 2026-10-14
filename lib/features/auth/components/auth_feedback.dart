import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../constants/app_error_messages.dart';
import 'auth_step_parts.dart';

const String authInvalidPinMessage = 'Please enter a valid PIN';
const String authInvalidOtpMessage = 'Please enter a valid OTP';

/// Failures caused by the connection or session rather than the entered
/// code. These keep their own message instead of "Please enter a valid ...".
bool isAuthConnectivityError(String? message) {
  const messages = {
    AppErrorMessages.timeout,
    AppErrorMessages.network,
    AppErrorMessages.secureConnection,
    AppErrorMessages.serverUnavailable,
    AppErrorMessages.sessionExpired,
    AppErrorMessages.sessionRefreshFailed,
  };
  return messages.contains(message);
}

/// Triggers [AuthShake] after a failed PIN/OTP check.
class AuthShakeController extends ChangeNotifier {
  int _playCount = 0;

  /// Shakes that actually started; requests made mid-shake are ignored.
  int get playCount => _playCount;

  void shake() => notifyListeners();
}

/// [AuthShakeController] owned by a hook widget and disposed with it.
AuthShakeController useAuthShakeController() {
  final controller = useMemoized(AuthShakeController.new);
  useEffect(() => controller.dispose, [controller]);
  return controller;
}

/// Horizontal jiggle for PIN/OTP boxes. A shake requested while one is
/// running is ignored, so animations never overlap.
class AuthShake extends StatefulWidget {
  const AuthShake({super.key, required this.controller, required this.child});

  final AuthShakeController controller;
  final Widget child;

  @override
  State<AuthShake> createState() => _AuthShakeState();
}

class _AuthShakeState extends State<AuthShake>
    with SingleTickerProviderStateMixin {
  static const int _oscillations = 3;

  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onShake);
  }

  @override
  void didUpdateWidget(AuthShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onShake);
      widget.controller.addListener(_onShake);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onShake);
    _animation.dispose();
    super.dispose();
  }

  void _onShake() {
    if (_animation.isAnimating) return;
    widget.controller._playCount++;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return;
    _animation.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final amplitude = authWidthFraction(context, 8 / 360, min: 6, max: 12);
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        final t = _animation.value;
        final dx = math.sin(t * _oscillations * 2 * math.pi) *
            amplitude *
            (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}
