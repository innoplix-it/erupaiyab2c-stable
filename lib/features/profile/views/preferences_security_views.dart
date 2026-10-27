// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import '../../../widgets/feature_turn_off_dialog.dart';
import '../../../widgets/my_app_bar.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/views/reset_mpin_view.dart';
// import '../../onboarding/views/language_selection_view.dart';
import '../controllers/profile_controller.dart';
import '../controllers/theme_mode_controller.dart';
import '../repositories/settings_repository.dart';
import 'delete_account_otp_view.dart';

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
      final verified = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => DeleteAccountOtpView(
            repository: repository,
            phoneNumber: profile?.mobile ?? '',
          ),
        ),
      );
      if (verified != true) return;
      await ref.read(authControllerProvider.notifier).logout();
      if (context.mounted) {
        context.go(RouteConstants.login);
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: MyAppBar(
        title: 'Preferences',
        showBharatConnect: false,
        // showBharatConnect: true,
        onBack: () => context.pop(),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(0.w, 8.h, 0.w, 24.h),
        children: [
          // _SettingsListRow(
          //   icon: Icons.translate_outlined,
          //   title: 'Language',
          //   onTap: () {
          //     Navigator.of(context).push(
          //       MaterialPageRoute<void>(
          //         builder: (_) => const LanguageSelectionView(
          //           isSettingsFlow: true,
          //         ),
          //       ),
          //     );
          //   },
          // ),
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
        showBharatConnect: false,
        // showBharatConnect: true,
        onBack: () => context.pop(),
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
    final screenSize = MediaQuery.sizeOf(context);
    final availableWidth = screenSize.width;

    // Responsive horizontal margin: ~3.8% of screen width (12-16px)
    final horizontalMargin = (availableWidth * 0.038).clamp(12.0, 16.0);
    // Responsive vertical spacing between cards: ~0.85% of screen height (5.5-8px)
    final cardVerticalSpacing = (screenSize.height * 0.0085).clamp(5.5, 8.0);

    final deviceState = useState(false);
    final smsRegistration = useState(false);
    final smsBillReminders = useState(false);
    final smsTransactionUpdates = useState(false);
    final smsFinancialSuggestions = useState(false);
    final camera = useState(false);
    final registration = useState(false);
    final location = useState(false);
    final notifications = useState(false);
    final contacts = useState(false);
    final phone = useState(false);
    final photosAndFiles = useState(false);

    useEffect(() {
      Future.microtask(() async {
        deviceState.value = await _readBool('permission_device_state', false);
        smsRegistration.value =
            await _readBool('permission_sms_registration', false);
        smsBillReminders.value =
            await _readBool('permission_sms_reminders', false);
        smsTransactionUpdates.value =
            await _readBool('permission_sms_transaction_updates', false);
        smsFinancialSuggestions.value =
            await _readBool('permission_sms_suggestions', false);
        camera.value = await _readBool('permission_camera', false);
        registration.value = await _readBool('permission_registration', false);
        location.value = await _readBool('permission_location', false);
        notifications.value =
            await _readBool('permission_notifications', false);
        contacts.value = await _readBool('permission_contacts', false);
        phone.value = await _readBool('permission_phone', false);
        photosAndFiles.value =
            await _readBool('permission_photos_files', false);
      });
      return null;
    }, const []);

    final isDialogShowing = useRef(false);

    Future<bool> update(
        String key, ValueNotifier<bool> state, bool value) async {
      try {
        await _storage.write(key: key, value: value ? '1' : '0');
        state.value = value;
        return true;
      } catch (e) {
        debugPrint('Failed to update permission $key: $e');
        return false;
      }
    }

    Future<void> handleToggle(
      String key,
      ValueNotifier<bool> state,
      bool newValue,
    ) async {
      if (newValue) {
        // Checking: direct update without confirmation dialog
        await update(key, state, true);
      } else {
        // Unchecking: show confirmation dialog before updating
        if (isDialogShowing.value) return;
        isDialogShowing.value = true;
        try {
          final confirmed = await FeatureTurnOffDialog.show(context);
          if (confirmed) {
            await update(key, state, false);
          }
        } finally {
          isDialogShowing.value = false;
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: MyAppBar(
        title: 'Permissions',
        showHelp: true,
        showBharatConnect: false,
        onBack: () => context.pop(),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          horizontalMargin,
          (screenSize.height * 0.008).clamp(5.0, 8.0),
          horizontalMargin,
          (screenSize.height * 0.030).clamp(18.0, 26.0),
        ),
        children: [
          // 1. Device State
          _PermissionGroupCard(
            children: [
              _PermissionTile(
                groupTitle: 'Device State',
                subtitle: 'Secure Payments',
                description:
                    'Allow eRupaiya to access and verify your device and SIM details for secure payments, as required.',
                value: deviceState.value,
                onChanged: (v) =>
                    handleToggle('permission_device_state', deviceState, v),
                showDivider: false,
              ),
            ],
          ),
          SizedBox(height: cardVerticalSpacing),
          // 2. SMS
          _PermissionGroupCard(
            children: [
              _PermissionTile(
                groupTitle: 'SMS',
                subtitle: 'Registration',
                description:
                    'Allow SMS access for registration/KYC and OTP verification, where required.',
                value: smsRegistration.value,
                onChanged: (v) => handleToggle(
                    'permission_sms_registration', smsRegistration, v),
              ),
              _PermissionTile(
                subtitle: 'Bill Payment Reminders',
                description:
                    'Allow access to relevant SMS information to identify bills and provide timely payment reminders, with your consent.',
                value: smsBillReminders.value,
                onChanged: (v) => handleToggle(
                    'permission_sms_reminders', smsBillReminders, v),
              ),
              _PermissionTile(
                subtitle: 'Transaction Updates',
                description:
                    'Allow access to relevant transaction messages to help track payments, where supported and permitted.',
                value: smsTransactionUpdates.value,
                onChanged: (v) => handleToggle(
                    'permission_sms_transaction_updates',
                    smsTransactionUpdates,
                    v),
              ),
              _PermissionTile(
                subtitle: 'Financial Product Suggestions',
                description:
                    'Allow access to permitted SMS data to provide personalized financial product recommendations, with your consent.',
                value: smsFinancialSuggestions.value,
                onChanged: (v) => handleToggle(
                    'permission_sms_suggestions', smsFinancialSuggestions, v),
                showDivider: false,
              ),
            ],
          ),
          SizedBox(height: cardVerticalSpacing),
          // 3. Camera
          _PermissionGroupCard(
            children: [
              _PermissionTile(
                groupTitle: 'Camera',
                subtitle: 'QR Scanning and KYC Verification',
                description:
                    'Allow camera access to scan payment QR codes and capture documents for identity verification.',
                value: camera.value,
                onChanged: (v) => handleToggle('permission_camera', camera, v),
                showDivider: false,
              ),
            ],
          ),
          SizedBox(height: cardVerticalSpacing),
          // 4. Registration
          _PermissionGroupCard(
            children: [
              _PermissionTile(
                groupTitle: 'Registration',
                subtitle: 'Secure Payments',
                description:
                    'Allow access to relevant SMS information to identify bills and provide timely payment reminders, with your consent.',
                value: registration.value,
                onChanged: (v) =>
                    handleToggle('permission_registration', registration, v),
                showDivider: false,
              ),
            ],
          ),
          SizedBox(height: cardVerticalSpacing),
          // 5. Location
          _PermissionGroupCard(
            children: [
              _PermissionTile(
                groupTitle: 'Location',
                subtitle: 'Security and Location Based Services',
                description:
                    'Allow location access for supported services and security checks, where required.',
                value: location.value,
                onChanged: (v) =>
                    handleToggle('permission_location', location, v),
                showDivider: false,
              ),
            ],
          ),
          SizedBox(height: cardVerticalSpacing),
          // 6. Notifications
          _PermissionGroupCard(
            children: [
              _PermissionTile(
                groupTitle: 'Notifications',
                subtitle: 'Payment and Account Alerts',
                description:
                    'Allow notifications for payment confirmations, transaction updates, bill reminders and important account alerts.',
                value: notifications.value,
                onChanged: (v) =>
                    handleToggle('permission_notifications', notifications, v),
                showDivider: false,
              ),
            ],
          ),
          SizedBox(height: cardVerticalSpacing),
          // 7. Contacts
          _PermissionGroupCard(
            children: [
              _PermissionTile(
                groupTitle: 'Contacts',
                subtitle: 'Contact Selection',
                description:
                    'Allow contacts access to select recipients for supported payment or transfer services, where applicable.',
                value: contacts.value,
                onChanged: (v) =>
                    handleToggle('permission_contacts', contacts, v),
                showDivider: false,
              ),
            ],
          ),
          SizedBox(height: cardVerticalSpacing),
          // 8. Phone
          _PermissionGroupCard(
            children: [
              _PermissionTile(
                groupTitle: 'Phone',
                subtitle: 'SIM Verification',
                description:
                    'Allow required phone and SIM verification for secure UPI registration, where supported.',
                value: phone.value,
                onChanged: (v) => handleToggle('permission_phone', phone, v),
                showDivider: false,
              ),
            ],
          ),
          SizedBox(height: cardVerticalSpacing),
          // 9. Photos and Files
          _PermissionGroupCard(
            children: [
              _PermissionTile(
                groupTitle: 'Photos and Files',
                subtitle: 'Document Uploads',
                description:
                    'Allow access to selected photos and files to upload KYC documents and supporting information.',
                value: photosAndFiles.value,
                onChanged: (v) =>
                    handleToggle('permission_photos_files', photosAndFiles, v),
                showDivider: false,
                trailingText: 'See another version',
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

/// A white permission card with rounded corners and subtle shadow,
/// matching the Figma screenshot design.
class _PermissionGroupCard extends StatelessWidget {
  const _PermissionGroupCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    // Card border radius: ~2.2% of screen width (approx 8-9px)
    final borderRadius = (screenWidth * 0.022).clamp(7.0, 10.0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: const Color(0xFFEEEEEE),
          width: 0.6,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

const _checkboxSvgUnchecked =
    '''<svg width="18" height="18" viewBox="0 0 18 18" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M0.666748 3.86797V13.468C0.666748 14.588 0.666748 15.148 0.884748 15.576C1.07649 15.9523 1.38244 16.2582 1.75875 16.45C2.18575 16.668 2.74575 16.668 3.86375 16.668H13.4697C14.5877 16.668 15.1467 16.668 15.5737 16.45C15.9507 16.258 16.2567 15.952 16.4487 15.576C16.6667 15.148 16.6667 14.59 16.6667 13.472V3.86497C16.6667 2.74697 16.6667 2.18697 16.4487 1.75997C16.2567 1.38351 15.9504 1.07754 15.5737 0.885969C15.1467 0.667969 14.5867 0.667969 13.4667 0.667969H3.86675C2.74675 0.667969 2.18675 0.667969 1.75875 0.885969C1.38244 1.07771 1.07649 1.38366 0.884748 1.75997C0.666748 2.18797 0.666748 2.74797 0.666748 3.86797Z" stroke-width="1.33333" stroke-linecap="round" stroke-linejoin="round" stroke="black"/>
</svg>''';

const _checkboxSvgChecked =
    '''<svg width="18" height="18" viewBox="0 0 18 18" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M0.666748 3.86797V13.468C0.666748 14.588 0.666748 15.148 0.884748 15.576C1.07649 15.9523 1.38244 16.2582 1.75875 16.45C2.18575 16.668 2.74575 16.668 3.86375 16.668H13.4697C14.5877 16.668 15.1467 16.668 15.5737 16.45C15.9507 16.258 16.2567 15.952 16.4487 15.576C16.6667 15.148 16.6667 14.59 16.6667 13.472V3.86497C16.6667 2.74697 16.6667 2.18697 16.4487 1.75997C16.2567 1.38351 15.9504 1.07754 15.5737 0.885969C15.1467 0.667969 14.5867 0.667969 13.4667 0.667969H3.86675C2.74675 0.667969 2.18675 0.667969 1.75875 0.885969C1.38244 1.07771 1.07649 1.38366 0.884748 1.75997C0.666748 2.18797 0.666748 2.74797 0.666748 3.86797Z" fill="black" stroke-width="1.33333" stroke-linecap="round" stroke-linejoin="round" stroke="black"/>
<path d="M5 9.2L7.5 11.7L13 6.2" stroke="white" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''';

/// A single permission item inside a [_PermissionGroupCard].
///
/// [groupTitle] is the bold section header (e.g. "Device State", "SMS") - 14sp via MediaQuery.
/// [subtitle] is the semi-bold sub-heading (e.g. "Secure Payments") - 12sp via MediaQuery.
/// [description] is the description text ("Allow access...") - 10sp via MediaQuery with color #27272A.
/// An SVG checkbox icon is aligned to the upper-right of each tile.
class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.description,
    required this.value,
    required this.onChanged,
    this.groupTitle,
    this.subtitle,
    this.showDivider = true,
    this.trailingText,
  });

  /// Bold section title shown above the subtitle (e.g. "Device State").
  final String? groupTitle;

  /// Semi-bold sub-heading (e.g. "Secure Payments", "Registration").
  final String? subtitle;

  /// Description text that wraps naturally.
  final String description;

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  /// Optional trailing text below description (e.g. "See another version").
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;

    // Font sizes using MediaQuery scaling:
    // 1st line (groupTitle): 14
    // 2nd line (subtitle): 12
    // 3rd line (description - "Allow access..."): 10
    final textScaleRatio = (screenWidth / 390.0).clamp(0.85, 1.2);
    final firstLineFontSize = (14.0 * textScaleRatio).clamp(12.0, 16.0);
    final secondLineFontSize = (12.0 * textScaleRatio).clamp(10.5, 14.0);
    final thirdLineFontSize = (10.0 * textScaleRatio).clamp(8.5, 12.0);

    // Compact internal card padding: ~3.3% horizontal (~12-13px), ~0.9% vertical (~7-8px)
    final tilePaddingH = (screenWidth * 0.033).clamp(11.0, 14.0);
    final tilePaddingV = (screenSize.height * 0.009).clamp(6.5, 8.5);
    // Gap between text column and checkbox: ~2.5% of screen width (~9-10px)
    final textCheckboxGap = (screenWidth * 0.025).clamp(8.0, 11.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tilePaddingH,
        tilePaddingV,
        tilePaddingH,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (groupTitle != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2.0),
                        child: Text(
                          groupTitle!,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF09090B),
                                    fontSize: firstLineFontSize,
                                    letterSpacing: -0.1,
                                  ),
                        ),
                      ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2.0),
                        child: Text(
                          subtitle!,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF18181B),
                                    fontSize: secondLineFontSize,
                                    letterSpacing: -0.05,
                                  ),
                        ),
                      ),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF27272A),
                            height: 1.3,
                            fontSize: thirdLineFontSize,
                          ),
                    ),
                    if (trailingText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          trailingText!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF71717A),
                                    height: 1.3,
                                    fontSize: thirdLineFontSize,
                                  ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: textCheckboxGap),
              // SVG Checkbox matching user-provided spec
              GestureDetector(
                onTap: () => onChanged(!value),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(top: 1.0),
                  child: SvgPicture.string(
                    value ? _checkboxSvgChecked : _checkboxSvgUnchecked,
                    width: 18,
                    height: 18,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: tilePaddingV),
          if (showDivider)
            const Divider(
              height: 1,
              thickness: 0.5,
              color: Color(0xFFEEEEEE),
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
