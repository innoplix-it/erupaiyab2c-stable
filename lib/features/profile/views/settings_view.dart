// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pinput/pinput.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/routes_constant.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../services/location_access_service.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/k_dialog.dart';
import '../controllers/profile_controller.dart';
import '../repositories/settings_repository.dart';

class SettingsView extends HookConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = useMemoized(() => SettingsRepository());
    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState.profile;
    final isPushEnabled = useState(true);
    final isPushLoading = useState(false);
    final isLocationEnabled = useState(false);
    final isLocationLoading = useState(false);

    useEffect(() {
      if (profile == null && !profileState.isFetching) {
        Future.microtask(
          () => ref.read(profileControllerProvider.notifier).fetchProfile(),
        );
      }
      return null;
    }, [profile, profileState.isFetching]);

    useEffect(() {
      if (profile != null && !isPushLoading.value) {
        isPushEnabled.value = profile.isPushNotification;
      }
      return null;
    }, [profile?.isPushNotification, isPushLoading.value]);

    useEffect(() {
      Future.microtask(() async {
        final enabledPref = await LocationAccessService.isEnabledPreference();
        final granted = await LocationAccessService.isPermissionGranted();
        if (!context.mounted) return;
        isLocationEnabled.value = enabledPref && granted;
      });
      return null;
    }, const []);

    Future<void> togglePush(bool enabled) async {
      if (isPushLoading.value) return;
      if (!enabled) {
        final confirmed = await showDialog<bool>(
              context: context,
              barrierDismissible: true,
              builder: (_) => const _DisableNotificationsDialog(),
            ) ??
            false;
        if (!confirmed) {
          // Revert immediately; no API call.
          isPushEnabled.value = true;
          return;
        }
      }
      final previous = isPushEnabled.value;
      isPushEnabled.value = enabled;
      isPushLoading.value = true;
      try {
        final result =
            await repository.setPushNotificationsEnabled(isPushEnabled.value);
        if (!result.success) {
          isPushEnabled.value = previous;
        } else {
          // Keep loading true until the updated profile arrives, otherwise
          // the effect that syncs `isPushEnabled` from profile can briefly
          // revert the switch to the stale profile value (toggle flicker).
          await ref.read(profileControllerProvider.notifier).fetchProfile();
        }
        if (result.message.isNotEmpty) {
          AppSnackbar.show(
            result.message,
            type: !enabled
                ? AppSnackbarType.error
                : (result.success
                    ? AppSnackbarType.success
                    : AppSnackbarType.error),
          );
        }
      } finally {
        isPushLoading.value = false;
      }
    }

    Future<void> handleDeleteSuccess() async {
      await ref.read(authControllerProvider.notifier).logout();
      if (context.mounted) {
        context.go(RouteConstants.login);
      }
    }

    Future<void> toggleLocation(bool enabled) async {
      if (isLocationLoading.value) return;
      if (!enabled) {
        final confirmed = await showDialog<bool>(
              context: context,
              barrierDismissible: true,
              builder: (_) => const _DisableLocationDialog(),
            ) ??
            false;
        if (!confirmed) {
          isLocationEnabled.value = true;
          return;
        }
      }

      isLocationLoading.value = true;
      try {
        if (enabled) {
          final granted =
              await LocationAccessService.enableWithPermissionRequest();
          if (!granted) {
            await LocationAccessService.setEnabledPreference(false);
            if (context.mounted) {
              AppSnackbar.show(
                'Location permission is not enabled. You can allow it from Settings.',
                type: AppSnackbarType.error,
              );
            }
          }
          isLocationEnabled.value = granted;
        } else {
          await LocationAccessService.disable();
          isLocationEnabled.value = false;
          if (context.mounted) {
            AppSnackbar.show(
              'Location access turned off.',
              type: AppSnackbarType.success,
            );
          }
        }
      } finally {
        isLocationLoading.value = false;
      }
    }

    Future<void> startDeleteAccountFlow() async {
      final result = await repository.sendDeleteAccountOtp();
      if (result.message.isNotEmpty) {
        AppSnackbar.show(result.message);
      }
      if (!result.success) return;
      await KDialog.instance.openDialog(
        dialog: _DeleteAccountOtpDialog(
          repository: repository,
          onVerified: () async {
            navigatorKey.currentState?.pop();
            await handleDeleteSuccess();
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F3),
      body: Stack(
        children: [
          const _SettingsBackground(),
          SafeArea(
            child: Column(
              children: [
                const _SettingsHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                    child: Column(
                      children: [
                        // _SettingsTile(
                        //   icon: Icons.translate,
                        //   title: 'Change language',
                        //   onTap: () {
                        //     context.push(RouteConstants.languageSelection);
                        //   },
                        //   trailing: _GradientPill(
                        //     child: Icon(
                        //       Icons.arrow_forward_ios,
                        //       color: Colors.white,
                        //       size: 18.sp,
                        //     ),
                        //   ),
                        // ),
                        // SizedBox(height: 14.h),
                        _SettingsTile(
                          icon: Icons.notifications_none,
                          title: 'Notifications',
                          trailing: Switch(
                            value: isPushEnabled.value,
                            onChanged: isPushLoading.value ? null : togglePush,
                            activeThumbColor: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 14.h),
                        _SettingsTile(
                          icon: Icons.location_on_outlined,
                          title: 'Location Access',
                          trailing: Switch(
                            value: isLocationEnabled.value,
                            onChanged:
                                isLocationLoading.value ? null : toggleLocation,
                            activeThumbColor: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        _DeleteAccountCard(
                          onDelete: () {
                            KDialog.instance.openDialog(
                              dialog: _DeleteAccountConfirmDialog(
                                onConfirm: () async {
                                  navigatorKey.currentState?.pop();
                                  await startDeleteAccountFlow();
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsBackground extends StatelessWidget {
  const _SettingsBackground();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 120.h,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFE2D7), Color(0xFFFFF7F3)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        const Expanded(
          child: ColoredBox(color: Color(0xFFFFF7F3)),
        ),
      ],
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(8.w, 6.h, 16.w, 6.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(Icons.arrow_back, color: Colors.black, size: 22.sp),
          ),
          SizedBox(width: 4.w),
          Text(
            'Settings',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: AppColors.lightBorder),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 14.r,
              offset: Offset(0.w, 6.h),
            ),
          ],
        ),
        child: Row(
          children: [
            _IconBadge(icon: icon),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44.r,
      width: 44.r,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFFFE6DC),
      ),
      child: Icon(
        icon,
        color: AppColors.primary,
        size: 22.sp,
      ),
    );
  }
}

class _DeleteAccountCard extends StatelessWidget {
  const _DeleteAccountCard({required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 14.r,
            offset: Offset(0.w, 6.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconBadge(icon: Icons.delete_outline),
              SizedBox(width: 12.w),
              Text(
                'Delete account',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Deleting your account will permanently remove all your data, '
            'including your profile, preferences, and activity history.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.7),
                  height: 1.4,
                ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            height: 44.h,
            child: ElevatedButton(
              onPressed: onDelete,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22.r),
                ),
              ),
              child: Text(
                'Delete Account',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteAccountConfirmDialog extends StatelessWidget {
  const _DeleteAccountConfirmDialog({required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(22.w, 22.h, 22.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 64.r,
              height: 64.r,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1EB),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF2B9A6)),
              ),
              child: Icon(
                Icons.delete_outline,
                color: AppColors.primary,
                size: 34.sp,
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              'Delete Account',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Are you sure you want to delete your account?\nWe will send an OTP to confirm this action.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.75),
                    height: 1.35,
                  ),
            ),
            SizedBox(height: 18.h),
            Row(
              children: [
                Expanded(
                  child: SizedBox(height: 40.h,
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: const Color.fromARGB(255, 0, 0, 0)
                                .withOpacity(0.18),
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Yes, delete',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color.fromARGB(255, 0, 0, 0),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: SizedBox(height: 40.h,
                    child: OutlinedButton(
                      onPressed: () => navigatorKey.currentState?.pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide.none,
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color.fromARGB(255, 255, 255, 255)
                                  .withOpacity(0.8),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DisableNotificationsDialog extends StatelessWidget {
  const _DisableNotificationsDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(22.w, 22.h, 22.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 64.r,
              height: 64.r,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1EB),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF2B9A6)),
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                color: AppColors.primary,
                size: 34.sp,
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              'Disable Notifications?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: 8.h),
            Text(
              'If you disable notifications, you may miss important updates and reminders.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.75),
                    height: 1.35,
                  ),
            ),
            SizedBox(height: 18.h),
            Row(
              children: [
                Expanded(
                  child: SizedBox(height: 44.h,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: AppColors.textPrimary.withOpacity(0.18),
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Disable',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary.withOpacity(0.8),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: SizedBox(height: 44.h,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide.none,
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DisableLocationDialog extends StatelessWidget {
  const _DisableLocationDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(22.w, 22.h, 22.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 64.r,
              height: 64.r,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1EB),
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: const Color(0xFFF2B9A6)),
              ),
              child: Icon(
                Icons.location_off_outlined,
                color: AppColors.primary,
                size: 34.sp,
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              'Turn Off Location Access?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: 8.h),
            Text(
              'If you turn off location access, some features may not work correctly.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.75),
                    height: 1.35,
                  ),
            ),
            SizedBox(height: 18.h),
            Row(
              children: [
                Expanded(
                  child: SizedBox(height: 44.h,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: AppColors.textPrimary.withOpacity(0.18),
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Turn off',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary.withOpacity(0.8),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: SizedBox(height: 44.h,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide.none,
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteAccountOtpDialog extends HookWidget {
  const _DeleteAccountOtpDialog({
    required this.repository,
    required this.onVerified,
  });

  final SettingsRepository repository;
  final Future<void> Function() onVerified;

  @override
  Widget build(BuildContext context) {
    final otpController = useTextEditingController();
    final isLoading = useState(false);
    final errorText = useState<String?>(null);

    Future<void> verifyOtp() async {
      final otp = otpController.text.trim();
      if (otp.length < 6) {
        errorText.value = 'Please enter the 6-digit OTP.';
        return;
      }
      errorText.value = null;
      isLoading.value = true;
      final result = await repository.verifyDeleteAccountOtp(otp);
      isLoading.value = false;
      if (result.message.isNotEmpty) {
        AppSnackbar.show(result.message);
      }
      if (result.success) {
        await onVerified();
      } else {
        errorText.value =
            'That OTP is not valid. Please check it and try again.';
      }
    }

    final defaultPinTheme = PinTheme(
      width: 44.w,
      height: 44.w,
      textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFD6D6D6)),
      ),
    );

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(22.w, 22.h, 22.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter OTP',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Please enter the 6-digit OTP sent to your registered number.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.7),
                    height: 1.4,
                  ),
            ),
            SizedBox(height: 18.h),
            Pinput(
              length: 6,
              controller: otpController,
              keyboardType: TextInputType.number,
              onChanged: (_) => errorText.value = null,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration?.copyWith(
                  border: Border.all(color: AppColors.primary),
                ),
              ),
              errorPinTheme: defaultPinTheme.copyBorderWith(
                border: Border.all(color: Colors.red),
              ),
              errorTextStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            if (errorText.value != null && errorText.value!.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Text(
                errorText.value!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: SizedBox(height: 42.h,
                    child: OutlinedButton(
                      onPressed: isLoading.value
                          ? null
                          : () => navigatorKey.currentState?.pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.textPrimary.withOpacity(0.18),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary.withOpacity(0.8),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: SizedBox(height: 42.h,
                    child: ElevatedButton(
                      onPressed: isLoading.value ? null : verifyOtp,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        isLoading.value ? 'Verifying...' : 'Verify',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
