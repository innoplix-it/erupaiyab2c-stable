// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/routes_constant.dart';
import '../../../services/location_access_service.dart';
import '../../../services/secure_storage_service.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/my_app_bar.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/views/reset_mpin_view.dart';
import '../../onboarding/views/language_selection_view.dart';
import '../controllers/profile_controller.dart';
import '../controllers/theme_mode_controller.dart';
import '../repositories/settings_repository.dart';

class PreferencesView extends HookConsumerWidget {
  const PreferencesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = useMemoized(SettingsRepository.new);
    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState.profile;
    final isBillEnabled = useState(true);
    final isBillLoading = useState(false);
    final themeMode = ref.watch(themeModeControllerProvider);

    useEffect(() {
      if (profile == null && !profileState.isFetching) {
        Future.microtask(
          () => ref.read(profileControllerProvider.notifier).fetchProfile(),
        );
      }
      return null;
    }, [profile, profileState.isFetching]);

    useEffect(() {
      if (profile != null && !isBillLoading.value) {
        isBillEnabled.value = profile.isPushNotification;
      }
      return null;
    }, [profile?.isPushNotification, isBillLoading.value]);

    Future<void> toggleBillNotifications(bool enabled) async {
      if (isBillLoading.value) return;
      if (!enabled) {
        final confirmed = await showDialog<bool>(
              context: context,
              builder: (_) => const _DisableNotificationsDialog(),
            ) ??
            false;
        if (!confirmed) return;
      }

      final previous = isBillEnabled.value;
      isBillEnabled.value = enabled;
      isBillLoading.value = true;
      try {
        final result = await repository.setPushNotificationsEnabled(enabled);
        if (!result.success) {
          isBillEnabled.value = previous;
        } else {
          await ref.read(profileControllerProvider.notifier).fetchProfile();
        }
        if (result.message.isNotEmpty) {
          AppSnackbar.show(
            result.message,
            type: result.success
                ? AppSnackbarType.success
                : AppSnackbarType.error,
          );
        }
      } finally {
        isBillLoading.value = false;
      }
    }

    Future<void> startDeleteAccountFlow() async {
      final result = await repository.sendDeleteAccountOtp();
      if (result.message.isNotEmpty) {
        AppSnackbar.show(result.message);
      }
      if (!result.success || !context.mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _DeleteAccountOtpDialog(
          repository: repository,
          onVerified: () async {
            Navigator.of(context).pop();
            await ref.read(authControllerProvider.notifier).logout();
            if (context.mounted) {
              context.go(RouteConstants.login);
            }
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: MyAppBar(
        title: 'Preferences',
        onBack: () => context.pop(),
        onHelp: () {},
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(0.w, 8.h, 0.w, 24.h),
        children: [
          _SettingsListRow(
            icon: Icons.translate_outlined,
            title: 'Language',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const LanguageSelectionView(
                    isSettingsFlow: true,
                  ),
                ),
              );
            },
          ),
          _SettingsListRow(
            icon: Icons.notifications_none_outlined,
            title: 'Bill Notification',
            trailing: Transform.scale(
              scale: 0.78,
              child: Switch(
                value: isBillEnabled.value,
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFFDD5428),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFD9D9D9),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: isBillLoading.value ? null : toggleBillNotifications,
              ),
            ),
          ),
          _SettingsListRow(
            icon: Icons.description_outlined,
            title: 'Permissions',
            onTap: () => context.push(RouteConstants.profilePermissions),
          ),
          // _SettingsListRow(
          //   icon: Icons.alarm_outlined,
          //   title: 'Reminders',
          //   onTap: () => context.push(RouteConstants.notifications),
          // ),
          // _SettingsListRow(
          //   icon: Icons.contrast_outlined,
          //   title: 'Theme',
          //   subtitle: _themeLabel(themeMode),
          //   onTap: () => _showThemeSheet(context, ref, themeMode),
          // ),
          _SettingsListRow(
            icon: Icons.delete_outline,
            title: 'Delete Account',
            showDivider: false,
            onTap: () async {
              final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => const _DeleteAccountConfirmDialog(),
                  ) ??
                  false;
              if (!confirmed) return;
              await startDeleteAccountFlow();
            },
          ),
        ],
      ),
    );
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
    }
  }

  Future<void> _showThemeSheet(
    BuildContext context,
    WidgetRef ref,
    ThemeMode currentMode,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Theme',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                ),
                SizedBox(height: 14.h),
                for (final mode in ThemeMode.values)
                  RadioListTile<ThemeMode>(
                    value: mode,
                    groupValue: currentMode,
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _themeLabel(mode),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    onChanged: (value) async {
                      if (value == null) return;
                      await ref
                          .read(themeModeControllerProvider.notifier)
                          .setThemeMode(value);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SecurityView extends StatelessWidget {
  const SecurityView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: MyAppBar(
        title: 'Security',
        onBack: () => context.pop(),
        onHelp: () {},
      ),
      body: ListView(
        padding: EdgeInsets.only(top: 8.h),
        children: [
          _SettingsListRow(
            icon: Icons.translate_outlined,
            title: 'Biometric & Screen Lock',
            onTap: () => context.push(RouteConstants.biometricScreenLock),
          ),
          _SettingsListRow(
            icon: Icons.pin_outlined,
            title: 'Change Pin',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ResetMpinView(),
                ),
              );
            },
          ),
          _SettingsListRow(
            icon: Icons.location_on_outlined,
            title: 'Location Access',
            showDivider: false,
            onTap: () => context.push(RouteConstants.locationAccess),
          ),
        ],
      ),
    );
  }
}

class PermissionsView extends HookWidget {
  const PermissionsView({super.key});

  static const _storage = SecureStorageService.instance;

  @override
  Widget build(BuildContext context) {
    final deviceState = useState(true);
    final smsSecure = useState(true);
    final smsReminder = useState(true);
    final smsSuggestions = useState(true);
    final contactDetails = useState(true);

    useEffect(() {
      Future.microtask(() async {
        deviceState.value = await _readBool('permission_device_state', true);
        smsSecure.value = await _readBool('permission_sms_secure', true);
        smsReminder.value = await _readBool('permission_sms_reminders', true);
        smsSuggestions.value =
            await _readBool('permission_sms_suggestions', true);
        contactDetails.value =
            await _readBool('permission_contact_details', true);
      });
      return null;
    }, const []);

    Future<void> update(
        String key, ValueNotifier<bool> state, bool value) async {
      state.value = value;
      await _storage.write(key: key, value: value ? '1' : '0');
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: MyAppBar(
        title: 'Permissions',
        onBack: () => context.pop(),
        onHelp: () {},
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
        children: [
          _PermissionGroupCard(
            children: [
              _PermissionTile(
                title: 'Device State',
                subtitle: 'Secure UPI Payments',
                description:
                    'Allow eRupaiya to access and verify your device and SIM details for using UPI payments (as mandated by NPCI).',
                value: deviceState.value,
                onChanged: (value) =>
                    update('permission_device_state', deviceState, value),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _PermissionGroupCard(
            children: [
              _PermissionTile(
                title: 'SMS',
                subtitle: 'Secure UPI Payments',
                description:
                    'Allow eRupaiya to send SMS (for UPI registration) and read your transactional messages (for OTPs).',
                value: smsSecure.value,
                onChanged: (value) =>
                    update('permission_sms_secure', smsSecure, value),
              ),
              _PermissionTile(
                title: 'Bill Payment Reminders',
                description:
                    'Allow access to your text messages to fetch your bills and send timely payment reminders.',
                value: smsReminder.value,
                onChanged: (value) =>
                    update('permission_sms_reminders', smsReminder, value),
              ),
              _PermissionTile(
                title: 'Get Financial Product Suggestions',
                description:
                    'Allow us to access SMS data stored on your device and provide personalized financial product recommendations.',
                value: smsSuggestions.value,
                onChanged: (value) =>
                    update('permission_sms_suggestions', smsSuggestions, value),
                showDivider: false,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _PermissionGroupCard(
            children: [
              _PermissionTile(
                title: 'Address & Contact Details',
                subtitle: 'Order Delivery by External Merchants',
                description:
                    'Allow eRupaiya to share your address and contact details with merchant partners for order delivery and service fulfilment.',
                value: contactDetails.value,
                onChanged: (value) =>
                    update('permission_contact_details', contactDetails, value),
                showDivider: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool> _readBool(String key, bool fallback) async {
    final raw = await _storage.read(key: key);
    if (raw == null) return fallback;
    return raw == '1' || raw.toLowerCase() == 'true';
  }
}

class LocationAccessView extends HookWidget {
  const LocationAccessView({super.key});

  @override
  Widget build(BuildContext context) {
    final isEnabled = useState(false);
    final isLoading = useState(true);

    useEffect(() {
      Future.microtask(() async {
        final enabledPref = await LocationAccessService.isEnabledPreference();
        final granted = await LocationAccessService.isPermissionGranted();
        isEnabled.value = enabledPref && granted;
        isLoading.value = false;
      });
      return null;
    }, const []);

    Future<void> toggleLocation(bool enabled) async {
      if (isLoading.value) return;
      isLoading.value = true;
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
          isEnabled.value = granted;
        } else {
          final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => const _DisableLocationDialog(),
              ) ??
              false;
          if (!confirmed) return;
          await LocationAccessService.disable();
          isEnabled.value = false;
          if (context.mounted) {
            AppSnackbar.show(
              'Location access turned off.',
              type: AppSnackbarType.success,
            );
          }
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: MyAppBar(
        title: 'Location Access',
        onBack: () => context.pop(),
        onHelp: () {},
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
        children: [
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Allow Location Access',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    Switch(
                      value: isEnabled.value,
                      activeColor: AppColors.primary,
                      onChanged: isLoading.value ? null : toggleLocation,
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  'Location helps us provide relevant services and improve nearby availability where applicable.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary.withOpacity(0.7),
                        height: 1.45,
                      ),
                ),
                SizedBox(height: 12.h),
                CustomElevatedButton(
                  onPressed: openAppSettings,
                  label: 'Open App Settings',
                  uppercaseLabel: false,
                  height: 34.h,
                  width: 180.w,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BiometricScreenLockView extends HookWidget {
  const BiometricScreenLockView({super.key});

  @override
  Widget build(BuildContext context) {
    final biometricAvailable = useState(false);
    final isLoading = useState(true);

    useEffect(() {
      Future.microtask(() async {
        final localAuth = LocalAuthentication();
        final canCheck = await localAuth.canCheckBiometrics;
        final supported = await localAuth.isDeviceSupported();
        final enrolled = await localAuth.getAvailableBiometrics();
        biometricAvailable.value = canCheck && supported && enrolled.isNotEmpty;
        isLoading.value = false;
      });
      return null;
    }, const []);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: MyAppBar(
        title: 'Biometric & Screen Lock',
        onBack: () => context.pop(),
        onHelp: () {},
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
        children: [
          const _InfoCard(
            title: 'Screen Lock',
            description:
                'Your app already locks on reopen and after inactivity to protect account access.',
          ),
          SizedBox(height: 12.h),
          _InfoCard(
            title: 'Biometric Unlock',
            description: isLoading.value
                ? 'Checking biometric availability...'
                : biometricAvailable.value
                    ? 'Biometric unlock is available on this device and will be used on the app lock screen when possible.'
                    : 'Biometric unlock is not currently available on this device.',
          ),
        ],
      ),
    );
  }
}

class _SettingsListRow extends StatelessWidget {
  const _SettingsListRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final hasAction = onTap != null;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, size: 22.r, color: AppColors.textPrimary),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: 2.h),
                        Text(
                          subtitle!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppColors.textPrimary.withOpacity(0.55),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                trailing ??
                    (hasAction
                        ? Icon(
                            Icons.chevron_right,
                            size: 22.sp,
                            color: AppColors.textPrimary.withOpacity(0.7),
                          )
                        : const SizedBox.shrink()),
              ],
            ),
            if (showDivider) ...[
              SizedBox(height: 10.h),
              const Divider(height: 1, color: AppColors.lightBorder),
            ],
          ],
        ),
      ),
    );
  }
}

class _PermissionGroupCard extends StatelessWidget {
  const _PermissionGroupCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(children: children),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.showDivider = true,
  });

  final String title;
  final String? subtitle;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 0.h),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ],
                    SizedBox(height: 4.h),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary.withOpacity(0.78),
                            height: 1.45,
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              SizedBox(height: 24.r,
                width: 24.r,
                child: Checkbox(
                  value: value,
                  onChanged: (next) => onChanged(next ?? false),
                  activeColor: Colors.black,
                  checkColor: Colors.white,
                  side: const BorderSide(color: Colors.black, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          if (showDivider)
            Divider(
              height: 1,
              color: Colors.black.withOpacity(0.08),
            ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          SizedBox(height: 8.h),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.72),
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }
}

class _DeleteAccountConfirmDialog extends StatelessWidget {
  const _DeleteAccountConfirmDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(22.w, 22.h, 22.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Delete Account',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: 10.h),
            Text(
              'Are you sure you want to delete your account? We will send an OTP to confirm this action.',
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
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel',
                        style: TextStyle(color: AppColors.textPrimary)),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Delete',
                        style: TextStyle(color: Colors.white)),
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
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              onChanged: (_) => errorText.value = null,
              decoration: InputDecoration(
                counterText: '',
                hintText: 'OTP',
                errorText: errorText.value,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              height: 42.h,
              child: ElevatedButton(
                onPressed: isLoading.value ? null : verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: Text(isLoading.value ? 'Verifying...' : 'Verify OTP'),
              ),
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
          children: [
            Text(
              'Disable Notifications',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: 10.h),
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
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text(
                      'Disable',
                      style: TextStyle(color: Colors.white),
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
    return AlertDialog(
      title: const Text('Turn Off Location Access?'),
      content: const Text(
        'If you turn off location access, some features may not work correctly.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Turn Off'),
        ),
      ],
    );
  }
}
