import 'package:e_rupaiya/constants/app_colors.dart';
import 'package:flutter/material.dart';

import 'k_dialog.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppSnackbar {
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();
  static OverlayEntry? _currentEntry;
  static bool _pending = false;

  static void show(
    String message, {
    Color? backgroundColor,
    Color? textColor,
    Duration duration = const Duration(seconds: 2),
    SnackBarBehavior? behavior,
    EdgeInsetsGeometry? margin,
    AppSnackbarType type = AppSnackbarType.info,
    AppSnackbarPosition position = AppSnackbarPosition.top,
  }) {
    final context = navigatorKey.currentContext ?? messengerKey.currentContext;
    if (context == null) return;

    OverlayState? overlay;
    try {
      overlay = navigatorKey.currentState?.overlay ??
          Overlay.of(context, rootOverlay: true);
    } catch (_) {
      overlay = null;
    }

    final resolvedType = _inferType(
      message,
      fallback: type,
      hasOverride: backgroundColor != null || textColor != null,
    );

    // Slightly longer by default for warnings/errors so the message is readable.
    final resolvedDuration = duration == const Duration(seconds: 2) &&
            (resolvedType == AppSnackbarType.error ||
                resolvedType == AppSnackbarType.warning)
        ? const Duration(seconds: 4)
        : duration;

    if (position == AppSnackbarPosition.bottom) {
      final messenger = messengerKey.currentState;
      if (messenger != null) {
        _currentEntry?.remove();
        _currentEntry = null;

        final theme = _SnackbarTheme.resolve(
          resolvedType,
          backgroundOverride: backgroundColor,
          textOverride: textColor,
        );

        final accent = _SnackbarAccent.resolve(resolvedType);
        final bottomInset = MediaQuery.of(context).viewPadding.bottom;
        final resolvedMargin = margin ??
            EdgeInsets.fromLTRB(
              16,
              0,
              16,
              12 + bottomInset,
            );

        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              behavior: behavior ?? SnackBarBehavior.floating,
              backgroundColor: Colors.transparent,
              elevation: 0,
              duration: resolvedDuration,
              margin: resolvedMargin,
              padding: EdgeInsets.zero,
              content: _BottomSnackBarContent(
                message: message,
                accentColor: accent,
                backgroundColor: backgroundColor ?? Colors.white,
                textColor: textColor ?? AppColors.textPrimary,
                icon: theme.icon,
                onClose: messenger.hideCurrentSnackBar,
              ),
            ),
          );
        return;
      }
    }

    if (overlay == null) {
      if (!_pending) {
        _pending = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pending = false;
          show(
            message,
            backgroundColor: backgroundColor,
            textColor: textColor,
            duration: resolvedDuration,
            behavior: behavior,
            margin: margin,
            position: position,
          );
        });
      }
      return;
    }

    _currentEntry?.remove();
    final resolved = _SnackbarTheme.resolve(
      resolvedType,
      backgroundOverride: backgroundColor,
      textOverride: textColor,
    );

    _currentEntry = OverlayEntry(
      builder: (_) => _TopSnackBar(
        message: message,
        backgroundColor: resolved.background,
        textColor: resolved.text,
        icon: resolved.icon,
        duration: resolvedDuration,
        onDismissed: () {
          _currentEntry?.remove();
          _currentEntry = null;
        },
      ),
    );

    overlay.insert(_currentEntry!);
  }
}

class _BottomSnackBarContent extends StatelessWidget {
  const _BottomSnackBarContent({
    required this.message,
    required this.accentColor,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    required this.onClose,
  });

  final String message;
  final Color accentColor;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: accentColor.withOpacity(0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 18.r,
              offset: Offset(0.w, 10.h),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30.r,
                height: 30.r,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 18.r,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                ),
              ),
              SizedBox(width: 6.w),
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(14.r),
                child: Padding(
                  padding: EdgeInsets.all(6.w),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18.r,
                    color: textColor.withOpacity(0.75),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopSnackBar extends StatefulWidget {
  const _TopSnackBar({
    required this.message,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    required this.duration,
    required this.onDismissed,
  });

  final String message;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_TopSnackBar> createState() => _TopSnackBarState();
}

class _TopSnackBarState extends State<_TopSnackBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
      reverseDuration: const Duration(milliseconds: 320),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.35),
      end: Offset.zero,
    ).animate(curve);
    _fade = Tween<double>(begin: 0, end: 1).animate(curve);
    _scale = Tween<double>(begin: 0.96, end: 1).animate(curve);
    _glow = Tween<double>(begin: 0.2, end: 1).animate(curve);

    _controller.forward();
    Future.delayed(widget.duration, _hide);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _hide() async {
    if (!mounted) return;
    await _controller.reverse();
    if (mounted) widget.onDismissed();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final safeTop = topPadding + 10;
    return Positioned(
      top: safeTop,
      left: 16,
      right: 16,
      child: IgnorePointer(
        ignoring: false,
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: AnimatedBuilder(
                animation: _glow,
                builder: (context, _) {
                  return Material(
                    color: Colors.transparent,
                    child: GestureDetector(
                      onTap: _hide,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final sheenX = (width + 120) * _controller.value - 60;
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 14.h,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  widget.backgroundColor.withOpacity(0.98),
                                  widget.backgroundColor.withOpacity(0.9),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18.r),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.backgroundColor
                                      .withOpacity(0.25 * _glow.value),
                                  blurRadius: 26.r,
                                  offset: Offset(0.w, 12.h),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                                width: 1,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 0,
                                  top: 8,
                                  bottom: 8,
                                  child: Container(
                                    width: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.55),
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -40,
                                  left: sheenX,
                                  child: Container(
                                    width: 80.r,
                                    height: 80.r,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.12),
                                          blurRadius: 24.r,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      width: 28.r,
                                      height: 28.r,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.18),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        widget.icon,
                                        color:
                                            widget.textColor.withOpacity(0.95),
                                        size: 16,
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: Text(
                                        widget.message,
                                        style: TextStyle(
                                          color: widget.textColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14.5.sp,
                                          height: 1.25,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum AppSnackbarType { info, success, error, warning }

enum AppSnackbarPosition { top, bottom }

class _SnackbarTheme {
  const _SnackbarTheme({
    required this.background,
    required this.text,
    required this.icon,
  });

  final Color background;
  final Color text;
  final IconData icon;

  static _SnackbarTheme resolve(
    AppSnackbarType type, {
    Color? backgroundOverride,
    Color? textOverride,
  }) {
    const baseInfo = _SnackbarTheme(
      background: AppColors.primary,
      text: Colors.white,
      icon: Icons.notifications_active_outlined,
    );
    const baseSuccess = _SnackbarTheme(
      background: AppColors.green,
      text: Colors.white,
      icon: Icons.check_circle_outline,
    );
    const baseError = _SnackbarTheme(
      background: Color(0xFFE53935),
      text: Colors.white,
      icon: Icons.error_outline,
    );
    const baseWarning = _SnackbarTheme(
      background: Color(0xFFF57C00),
      text: Colors.white,
      icon: Icons.warning_amber_outlined,
    );

    final base = switch (type) {
      AppSnackbarType.success => baseSuccess,
      AppSnackbarType.error => baseError,
      AppSnackbarType.warning => baseWarning,
      AppSnackbarType.info => baseInfo,
    };

    return _SnackbarTheme(
      background: backgroundOverride ?? base.background,
      text: textOverride ?? base.text,
      icon: base.icon,
    );
  }

  static IconData _iconFor(AppSnackbarType type) {
    switch (type) {
      case AppSnackbarType.success:
        return Icons.check_circle_outline;
      case AppSnackbarType.error:
        return Icons.error_outline;
      case AppSnackbarType.warning:
        return Icons.warning_amber_outlined;
      case AppSnackbarType.info:
      default:
        return Icons.notifications_active_outlined;
    }
  }
}

class _SnackbarAccent {
  const _SnackbarAccent._();

  static Color resolve(AppSnackbarType type) {
    switch (type) {
      case AppSnackbarType.success:
        return AppColors.green;
      case AppSnackbarType.error:
        return AppColors.red;
      case AppSnackbarType.warning:
        return const Color(0xFFF57C00);
      case AppSnackbarType.info:
      default:
        return AppColors.primary;
    }
  }
}

AppSnackbarType _inferType(
  String message, {
  required AppSnackbarType fallback,
  required bool hasOverride,
}) {
  if (hasOverride || fallback != AppSnackbarType.info) return fallback;
  final text = message.toLowerCase();
  const successHints = [
    'success',
    'sent',
    'updated',
    'saved',
    'copied',
    'verified',
    'registered',
    'completed',
  ];
  const errorHints = [
    'fail',
    'error',
    'invalid',
    'unable',
    'missing',
    'required',
    'please enter',
    'not',
    'denied',
  ];
  if (successHints.any(text.contains)) return AppSnackbarType.success;
  if (errorHints.any(text.contains)) return AppSnackbarType.error;
  return fallback;
}
