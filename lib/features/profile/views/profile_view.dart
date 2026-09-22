// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:e_rupaiya/features/auth/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pinput/pinput.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/custom_textfield.dart';
import '../../../widgets/image_picker_helper.dart';
import '../../../widgets/k_dialog.dart';
import '../../../widgets/profile_image_picker_sheet.dart';
import '../components/profile_field.dart';
import '../components/profile_shimmer.dart';
import '../controllers/profile_controller.dart';
import '../models/profile_model.dart';
import 'bank_accounts_view.dart';

class ProfileView extends HookConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState.profile;

    useEffect(() {
      Future.microtask(
        () => ref.read(profileControllerProvider.notifier).fetchProfile(),
      );
      return null;
    }, const []);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: profileState.isFetching && profile == null
            ? const ProfileShimmer()
            : Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(12.w, 6.h, 12.w, 4.h),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            final navigator = Navigator.of(context);
                            if (navigator.canPop()) {
                              navigator.pop();
                            }
                          },
                          icon: const Icon(
                            Icons.arrow_back,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'My Profile',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.help_outline,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.lightBorder),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(0.w, 16.h, 0.w, 24.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: _ProfileHeaderCard(
                              profile: profile,
                              onEdit: () {
                                if (profile == null) return;
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => UpdateProfileView(
                                      profile: profile,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 16.h),
                          if ((profile?.kycStatus ??
                                  ProfileKycStatus.pending) ==
                              ProfileKycStatus.verified)
                            _InviteEarnCard(
                              onInvite: () =>
                                  context.push(RouteConstants.referAndEarn),
                            )
                          else
                            _ProfileKycStatusCard(
                              profile: profile,
                              onTap: () {
                                final latestProfile = profile;
                                final startFromAadhaar = latestProfile
                                            ?.kycStatus ==
                                        ProfileKycStatus.inProgress &&
                                    latestProfile?.isKycStep1Completed == true;
                                context.push(
                                  RouteConstants.kycVerification,
                                  extra: startFromAadhaar,
                                );
                              },
                            ),
                          SizedBox(height: 20.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _ProfileSectionTitle(title: 'Settings'),
                                SizedBox(height: 12.h),
                                _ProfileActionTile(
                                  icon: Icons.tune,
                                  title: 'Preferences',
                                  subtitle: 'Languages, Permissions, Reminders',
                                  onTap: () =>
                                      context.push(RouteConstants.preferences),
                                ),
                                const Divider(
                                    height: 1, color: AppColors.lightBorder),
                                _ProfileActionTile(
                                  icon: Icons.security,
                                  title: 'Security',
                                  subtitle: 'Screen Lock, Passcode',
                                  onTap: () =>
                                      context.push(RouteConstants.security),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20.h),
                          // Padding(
                          //   padding: EdgeInsets.symmetric(horizontal: 16.w),
                          //   child: _ProfilePromoCard(
                          //     onStart: () =>
                          //         context.push(RouteConstants.referAndEarn),
                          //   ),
                          // ),
                          // SizedBox(height: 20.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _ProfileSectionTitle(title: 'Support'),
                                SizedBox(height: 12.h),
                                _ProfileActionTile(
                                  icon: Icons.support_agent_outlined,
                                  title: 'Help & Support',
                                  onTap: () =>
                                      context.push(RouteConstants.helpSupport),
                                ),
                                const Divider(
                                    height: 1, color: AppColors.lightBorder),
                                _ProfileActionTile(
                                  icon: Icons.info_outline,
                                  title: 'About e-Rupaiya',
                                  onTap: () =>
                                      context.push(RouteConstants.policies),
                                ),
                                const Divider(
                                    height: 1, color: AppColors.lightBorder),
                                _ProfileLogoutTile(
                                  onTap: () {
                                    KDialog.instance.openSheet(
                                      dialog: _LogoutBottomSheet(
                                        onLogout: () async {
                                          navigatorKey.currentState?.pop();
                                          await ref
                                              .read(authControllerProvider
                                                  .notifier)
                                              .logout();
                                          if (context.mounted) {
                                            context.go(RouteConstants.login);
                                          }
                                        },
                                        onStay: () =>
                                            navigatorKey.currentState?.pop(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.profile,
    required this.onEdit,
  });

  final ProfileModel? profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final name = profile?.name ?? '';
    final rawMobile = profile?.mobile ?? '';
    final mobile = rawMobile.startsWith('+') ? rawMobile : '+91$rawMobile';
    return Row(
      children: [
        CircleAvatar(
          radius: 26.r,
          backgroundColor: AppColors.primary,
          child: profile?.profilePhotoUrl?.isNotEmpty == true
              ? ClipOval(
                  child: AppNetworkImage(
                    url: profile!.profilePhotoUrl,
                    width: 52.r,
                    height: 52.r,
                    fit: BoxFit.cover,
                    showShimmer: false,
                  ),
                )
              : Text(
                  profile?.initials ?? '',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              SizedBox(height: 2.h),
              Text(
                mobile,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onEdit,
          child: Row(
            children: [
              // const Icon(Icons.edit, size: 18.r, color: AppColors.primary),
              // SizedBox(width: 4.w),
              Text(
                'Manage',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InviteEarnCard extends StatelessWidget {
  const _InviteEarnCard({required this.onInvite});

  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: const BoxDecoration(
        color: Color(0xFFFDE7DD),
      ),
      child: Row(
        children: [
          Container(
            width: 54.r,
            height: 54.r,
            decoration: const BoxDecoration(
              color: Color(0xFF1A56A1),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Padding(
                padding: EdgeInsets.all(8.r),
                child: Image.asset(
                  FileConstants.referAndEarn,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invite & Earn E-Coins Daily',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Refer Your First Friend And Unlock Bonus Rewards',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary.withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          SizedBox(height: 32.h,
            child: CustomElevatedButton(
              onPressed: onInvite,
              label: 'Invite Now',
              uppercaseLabel: false,
              width: 100.w,
              height: 32.h,
              showArrow: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileKycStatusCard extends StatelessWidget {
  const _ProfileKycStatusCard({
    required this.profile,
    required this.onTap,
    this.statusOverride,
  });

  final ProfileModel? profile;
  final VoidCallback onTap;
  final ProfileKycStatus? statusOverride;

  @override
  Widget build(BuildContext context) {
    final status =
        statusOverride ?? profile?.kycStatus ?? ProfileKycStatus.pending;
    final config = switch (status) {
      ProfileKycStatus.inProgress => const _ProfileKycCardConfig(
          title: 'KYC In Progress',
          subtitle: 'KYC has been partially completed',
          cta: 'Continue KYC',
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFFBFD7FF),
              Color(0xFFEAF2FF),
            ],
          ),
          accent: Color(0xFF2F6FDB),
          icon: Icons.access_time_rounded,
        ),
      ProfileKycStatus.rejected => const _ProfileKycCardConfig(
          title: 'KYC Rejected',
          subtitle: 'KYC verification failed and requires resubmission',
          cta: 'Resubmit KYC',
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFFFF8F8F),
              Color(0xFFFFE9E9),
            ],
            stops: [0, 0.775],
          ),
          accent: Color(0xFFD94242),
          icon: Icons.error_outline_rounded,
        ),
      ProfileKycStatus.pending ||
      ProfileKycStatus.verified =>
        const _ProfileKycCardConfig(
          title: 'KYC Pending',
          subtitle: 'KYC has not been completed yet',
          cta: 'Start KYC',
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFFFFF4C5),
              Color(0xFFFFFFFF),
            ],
            stops: [0, 1],
          ),
          accent: Color(0xFFD08A00),
          icon: Icons.verified_user_outlined,
        ),
    };

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: config.gradient,
        borderRadius: BorderRadius.circular(0.r),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -12.w,
            top: 0,
            bottom: 0,
            child: Opacity(
              opacity: 1,
              child: Align(
                alignment: Alignment.centerRight,
                child: Image.asset(
                  FileConstants.kycBgIcon,
                  width: 92.w,
                  height: 84.h,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
            child: Row(
              children: [
                Container(
                  width: 48.r,
                  height: 48.r,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    config.icon,
                    color: config.accent,
                    size: 20.r,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 12.sp,
                            ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        config.subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.black,
                              fontWeight: FontWeight.w500,
                              fontSize: 12.sp,
                            ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10.w),
                SizedBox(height: 30.h,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(horizontal: 14.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.r),
                      ),
                    ),
                    child: Text(
                      config.cta,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 8.sp,
                          ),
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

class _ProfileKycCardConfig {
  const _ProfileKycCardConfig({
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.gradient,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String cta;
  final LinearGradient gradient;
  final Color accent;
  final IconData icon;
}

class _ProfileSectionTitle extends StatelessWidget {
  const _ProfileSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 22.r),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary.withOpacity(0.6),
                          ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textPrimary.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileLogoutTile extends StatelessWidget {
  const _ProfileLogoutTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            const Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'Log Out',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTabChip extends StatelessWidget {
  const _ProfileTabChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.isEnabled = true,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFFFDE7DD)
              : (isEnabled ? Colors.white : const Color(0xFFF6F6F6)),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isActive
                ? AppColors.primary.withOpacity(0.7)
                : (isEnabled
                    ? AppColors.lightBorder
                    : AppColors.lightBorder.withOpacity(0.6)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16.r,
              color: isEnabled
                  ? AppColors.textPrimary
                  : AppColors.textPrimary.withOpacity(0.45),
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isEnabled
                        ? AppColors.textPrimary
                        : AppColors.textPrimary.withOpacity(0.45),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutBottomSheet extends StatelessWidget {
  const _LogoutBottomSheet({
    required this.onLogout,
    required this.onStay,
  });

  final VoidCallback onLogout;
  final VoidCallback onStay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Log Out Of Your Account?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ),
          SizedBox(height: 6.h),
          Text(
            "You'll Need To Sign In Again To Access Your Account.",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.6),
                ),
          ),
          SizedBox(height: 18.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onLogout,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: Text(
                    'Log Out',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: onStay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: Text(
                    'Stay loged in',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class UpdateProfileView extends HookConsumerWidget {
  const UpdateProfileView({super.key, required this.profile});

  final ProfileModel profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(profileControllerProvider.notifier);
    final state = ref.watch(profileControllerProvider);
    final latestProfile = state.profile ?? profile;
    final initialFullNameState = useState(profile.name.trim());
    final initialAddressState = useState((profile.address ?? '').trim());
    final initialEmailState = useState((profile.email ?? '').trim());
    final pickedImage = useState<File?>(null);
    final fullNameController = useTextEditingController();
    final emailController = useTextEditingController(
      text: profile.email ?? '',
    );
    final mobileController = useTextEditingController(text: profile.mobile);
    final addressController = useTextEditingController(
      text: profile.address ?? '',
    );
    final aadhaarController = useTextEditingController(
      text: profile.aadhaarMasked ?? '',
    );
    final panController = useTextEditingController(
      text: profile.panMasked ?? '',
    );
    final dobController = useTextEditingController(
      text: profile.dob ?? '',
    );
    final permanentAddressController = useTextEditingController();
    final deliveryAddressSummaryController = useTextEditingController();
    final billingAddress1Controller = useTextEditingController();
    final billingAddress2Controller = useTextEditingController();
    final billingCountryController = useTextEditingController();
    final billingStateController = useTextEditingController();
    final billingCityController = useTextEditingController();
    final billingStateCodeController = useTextEditingController();
    final billingZipController = useTextEditingController();
    final billingMobileController = useTextEditingController();

    final deliveryAddress1Controller = useTextEditingController();
    final deliveryAddress2Controller = useTextEditingController();
    final deliveryCountryController = useTextEditingController();
    final deliveryStateController = useTextEditingController();
    final deliveryCityController = useTextEditingController();
    final deliveryStateCodeController = useTextEditingController();
    final deliveryZipController = useTextEditingController();
    final deliveryMobileController = useTextEditingController();
    useListenable(fullNameController);
    useListenable(addressController);
    useListenable(mobileController);

    useEffect(() {
      fullNameController.text = profile.name.trim();
      return null;
    }, const []);

    final canEdit = !latestProfile.isKycVerified;
    final isKycVerified = latestProfile.kycStatus == ProfileKycStatus.verified;
    final initialFullName = initialFullNameState.value;
    final initialAddress = initialAddressState.value;
    final initialMobile = profile.mobile.trim();
    final initialEmail = initialEmailState.value;

    final currentFullName = fullNameController.text.trim();
    final currentAddress = addressController.text.trim();
    final currentMobile = mobileController.text.trim();
    final currentEmail = emailController.text.trim();
    final hasCommunicationChange = currentAddress != initialAddress;
    final hasNonEmailChanges = currentFullName != initialFullName ||
        currentMobile != initialMobile ||
        hasCommunicationChange;
    final hasEmailChange = canEdit &&
        !latestProfile.isEmailVerified &&
        currentEmail != initialEmail;
    final canSave = hasNonEmailChanges && (canEdit || hasCommunicationChange);
    final hasUnsavedChanges = hasNonEmailChanges || hasEmailChange;

    final selectedTab = useState<int>(0);
    final deliveryScrollController = useScrollController();
    final deliverySectionKey = useMemoized(() => GlobalKey(), const []);
    final deliveryFirstFieldKey = useMemoized(() => GlobalKey(), const []);

    Future<void> saveDeliveryInfo() async {
      final ok = await controller.updateDeliveryInfo(
        billingAddressLine1: billingAddress1Controller.text.trim(),
        billingAddressLine2: billingAddress2Controller.text.trim(),
        billingCity: billingCityController.text.trim(),
        billingState: billingStateController.text.trim(),
        billingZip: billingZipController.text.trim(),
        billingCountry: billingCountryController.text.trim(),
        billingMobile: billingMobileController.text.trim(),
        deliveryAddressLine1: deliveryAddress1Controller.text.trim(),
        deliveryAddressLine2: deliveryAddress2Controller.text.trim(),
        deliveryCity: deliveryCityController.text.trim(),
        deliveryState: deliveryStateController.text.trim(),
        deliveryZip: deliveryZipController.text.trim(),
        deliveryCountry: deliveryCountryController.text.trim(),
        deliveryMobile: deliveryMobileController.text.trim(),
      );
      if (!context.mounted) return;
      if (ok) {
        await controller.fetchProfile();
        if (!context.mounted) return;
        AppSnackbar.show(
          'Delivery information updated successfully.',
          type: AppSnackbarType.success,
        );
      } else {
        AppSnackbar.show(
          state.updateErrorMessage ?? 'Failed to update delivery info.',
          type: AppSnackbarType.error,
        );
      }
    }

    void openDeliverySection() {
      selectedTab.value = 2;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = deliveryFirstFieldKey.currentContext ??
            deliverySectionKey.currentContext;
        if (ctx == null) return;
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
      });
    }

    void openBankingSection() {
      if (!isKycVerified) {
        AppSnackbar.show('Please complete kyc first');
        return;
      }
      selectedTab.value = 1;
    }

    Future<bool> confirmDiscard() async {
      if (!hasUnsavedChanges) return true;
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: const Text('Discard changes?'),
            content: const Text(
              'You have unsaved changes. Are you sure you want to leave?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppColors.textPrimary.withOpacity(0.7),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text(
                  'Discard',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      );
      return result ?? false;
    }

    useEffect(() {
      final updatedEmail = state.profile?.email ?? '';
      if (emailController.text != updatedEmail) {
        emailController.text = updatedEmail;
      }
      return null;
    }, [state.profile?.email]);

    useEffect(() {
      if (state.isUpdating) return null;
      final updatedProfile = state.profile;
      if (updatedProfile == null) return null;
      void setIfNotEmpty(TextEditingController controller, String value) {
        if (value.isNotEmpty || controller.text.isEmpty) {
          controller.text = value;
        }
      }

      final updatedAadhaar = updatedProfile.aadhaarMasked ?? '';
      if (aadhaarController.text != updatedAadhaar) {
        aadhaarController.text = updatedAadhaar;
      }
      final updatedPan = updatedProfile.panMasked ?? '';
      if (panController.text != updatedPan) {
        panController.text = updatedPan;
      }
      final updatedDob = updatedProfile.dob ?? '';
      if (dobController.text != updatedDob) {
        dobController.text = updatedDob;
      }
      permanentAddressController.text = updatedProfile.permanentAddress ?? '';
      final billingEntry = updatedProfile.billingAddressEntry;
      final deliveryEntry = updatedProfile.deliveryAddressEntry;
      setIfNotEmpty(
          billingAddress1Controller, billingEntry?.addressLine1 ?? '');
      setIfNotEmpty(
          billingAddress2Controller, billingEntry?.addressLine2 ?? '');
      setIfNotEmpty(billingCountryController, billingEntry?.country ?? '');
      setIfNotEmpty(billingStateController, billingEntry?.state ?? '');
      setIfNotEmpty(billingCityController, billingEntry?.city ?? '');
      setIfNotEmpty(billingStateCodeController, billingEntry?.stateCode ?? '');
      setIfNotEmpty(billingZipController, billingEntry?.zip ?? '');
      setIfNotEmpty(billingMobileController, billingEntry?.mobile ?? '');

      setIfNotEmpty(
          deliveryAddress1Controller, deliveryEntry?.addressLine1 ?? '');
      setIfNotEmpty(
          deliveryAddress2Controller, deliveryEntry?.addressLine2 ?? '');
      setIfNotEmpty(deliveryCountryController, deliveryEntry?.country ?? '');
      setIfNotEmpty(deliveryStateController, deliveryEntry?.state ?? '');
      setIfNotEmpty(deliveryCityController, deliveryEntry?.city ?? '');
      setIfNotEmpty(
          deliveryStateCodeController, deliveryEntry?.stateCode ?? '');
      setIfNotEmpty(deliveryZipController, deliveryEntry?.zip ?? '');
      setIfNotEmpty(deliveryMobileController, deliveryEntry?.mobile ?? '');

      if (deliveryEntry != null) {
        final parts = [
          deliveryEntry.addressLine1,
          deliveryEntry.addressLine2,
          deliveryEntry.city,
          deliveryEntry.state,
          deliveryEntry.zip,
          deliveryEntry.country,
        ].where((part) => part.trim().isNotEmpty).toList();
        deliveryAddressSummaryController.text = parts.join(', ');
      } else {
        deliveryAddressSummaryController.text = '';
      }
      return null;
    }, [
      state.profile?.aadhaarMasked,
      state.profile?.panMasked,
      state.profile?.dob,
      state.profile?.billingAddress,
      state.profile?.addresses,
      state.isUpdating,
    ]);

    final headerHeight = 170.h;

    return WillPopScope(
      onWillPop: confirmDiscard,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Column(
              children: [
                Container(
                  height: headerHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(22.r),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () async {
                                  final okToLeave = await confirmDiscard();
                                  if (!context.mounted || !okToLeave) return;
                                  Navigator.of(context).pop();
                                },
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'My Profile',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.help_outline,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          Row(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 26.r,
                                    backgroundColor:
                                        Colors.white.withOpacity(0.25),
                                    child: ClipOval(
                                      child: pickedImage.value != null
                                          ? Image.file(
                                              pickedImage.value!,
                                              width: 52.r,
                                              height: 52.r,
                                              fit: BoxFit.cover,
                                            )
                                          : profile.profilePhotoUrl
                                                      ?.isNotEmpty ==
                                                  true
                                              ? AppNetworkImage(
                                                  url: profile.profilePhotoUrl,
                                                  width: 52.r,
                                                  height: 52.r,
                                                  fit: BoxFit.cover,
                                                  showShimmer: false,
                                                )
                                              : Text(
                                                  profile.initials,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: GestureDetector(
                                      onTap: () {
                                        KDialog.instance.openSheet(
                                          dialog: ProfileImagePickerSheet(
                                            onCamera: () async {
                                              navigatorKey.currentState?.pop();
                                              final image =
                                                  await ImagePickerHelper
                                                      .pickFromCamera();
                                              if (image == null) return;
                                              pickedImage.value = image;
                                              final ok = await controller
                                                  .updateProfileImage(
                                                image,
                                              );
                                              if (ok) {
                                                await controller.fetchProfile();
                                              } else {
                                                pickedImage.value = null;
                                              }
                                            },
                                            onGallery: () async {
                                              navigatorKey.currentState?.pop();
                                              final image =
                                                  await ImagePickerHelper
                                                      .pickFromGallery();
                                              if (image == null) return;
                                              pickedImage.value = image;
                                              final ok = await controller
                                                  .updateProfileImage(
                                                image,
                                              );
                                              if (ok) {
                                                await controller.fetchProfile();
                                              } else {
                                                pickedImage.value = null;
                                              }
                                            },
                                          ),
                                        );
                                      },
                                      child: Container(
                                        height: 20.r,
                                        width: 20.r,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.15),
                                              blurRadius: 6.r,
                                              offset: Offset(0.w, 2.h),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.camera_alt_outlined,
                                          size: 12.r,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 12.w),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    latestProfile.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    latestProfile.mobile.startsWith('+')
                                        ? latestProfile.mobile
                                        : '+91${latestProfile.mobile}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.white.withOpacity(0.85),
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(child: Container(color: Colors.white)),
              ],
            ),
            Positioned.fill(
              top: headerHeight - 22.h,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(22.r),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(height: 14.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _ProfileTabChip(
                              icon: Icons.person_outline,
                              label: 'Personal information',
                              isActive: selectedTab.value == 0,
                              onTap: () => selectedTab.value = 0,
                            ),
                            SizedBox(width: 10.w),
                            _ProfileTabChip(
                              icon: Icons.account_balance_outlined,
                              label: 'Banking information',
                              isActive: selectedTab.value == 1,
                              onTap: openBankingSection,
                              isEnabled: isKycVerified,
                            ),
                            SizedBox(width: 10.w),
                            _ProfileTabChip(
                              icon: Icons.local_shipping_outlined,
                              label: 'Delivery Information',
                              isActive: selectedTab.value == 2,
                              onTap: () => selectedTab.value = 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Expanded(
                      child: selectedTab.value == 0
                          ? SingleChildScrollView(
                              padding:
                                  EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 90.h),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Personal information',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  SizedBox(height: 14.h),
                                  ProfileField(
                                    label: 'Full Name (as per PAN)',
                                    controller: fullNameController,
                                    enabled: canEdit,
                                  ),
                                  SizedBox(height: 14.h),
                                  ProfileField(
                                    label: 'Mobile Number',
                                    controller: mobileController,
                                    enabled: false,
                                  ),
                                  SizedBox(height: 14.h),
                                  ProfileField(
                                    label: 'Email ID',
                                    controller: emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    enabled: canEdit &&
                                        !latestProfile.isEmailVerified,
                                    trailingText: latestProfile.isEmailVerified
                                        ? 'VERIFIED'
                                        : 'VERIFY',
                                    onTrailingTap: latestProfile
                                                .isEmailVerified ||
                                            !canEdit
                                        ? null
                                        : () {
                                            KDialog.instance.openSheet(
                                              dialog: _EmailUpdateSheet(
                                                currentEmail:
                                                    emailController.text.trim(),
                                              ),
                                            );
                                          },
                                  ),
                                  SizedBox(height: 14.h),
                                  ProfileField(
                                    label: 'Adhaar Number',
                                    controller: aadhaarController,
                                    enabled: false,
                                  ),
                                  SizedBox(height: 14.h),
                                  ProfileField(
                                    label: 'PAN Number',
                                    controller: panController,
                                    enabled: false,
                                  ),
                                  SizedBox(height: 14.h),
                                  ProfileField(
                                    label: 'Date Of Birth',
                                    controller: dobController,
                                    enabled: false,
                                  ),
                                  SizedBox(height: 14.h),
                                  ProfileField(
                                    label: 'Permanent Address',
                                    controller: permanentAddressController,
                                    maxLines: 2,
                                    enabled: false,
                                  ),
                                  SizedBox(height: 14.h),
                                  ProfileField(
                                    label: 'Delivery Address',
                                    controller:
                                        deliveryAddressSummaryController,
                                    maxLines: 2,
                                    enabled: false,
                                    trailingIcon: Icons.edit,
                                    onTrailingTap: openDeliverySection,
                                    onTap: openDeliverySection,
                                    textColor: AppColors.textPrimary,
                                  ),
                                ],
                              ),
                            )
                          : selectedTab.value == 1
                              ? Column(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 6.h),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'Banking Information',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: BankAccountsSection(
                                        padding: EdgeInsets.fromLTRB(16.w, 0.h, 16.w, 12.h),
                                      ),
                                    ),
                                  ],
                                )
                              : SingleChildScrollView(
                                  controller: deliveryScrollController,
                                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 90.h),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Billing Address Details',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      SizedBox(height: 12.h),
                                      ProfileField(
                                        label: 'Billing Address Line 1',
                                        controller: billingAddress1Controller,
                                        enabled: true,
                                      ),
                                      SizedBox(height: 14.h),
                                      ProfileField(
                                        label: 'Billing Address Line 2',
                                        controller: billingAddress2Controller,
                                        enabled: true,
                                      ),
                                      SizedBox(height: 14.h),
                                      ProfileField(
                                        label: 'Billing Country',
                                        controller: billingCountryController,
                                        enabled: true,
                                      ),
                                      SizedBox(height: 14.h),
                                      ProfileField(
                                        label: 'Billing State',
                                        controller: billingStateController,
                                        enabled: true,
                                      ),
                                      SizedBox(height: 14.h),
                                      ProfileField(
                                        label: 'Billing City',
                                        controller: billingCityController,
                                        enabled: true,
                                      ),
                                      SizedBox(height: 14.h),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ProfileField(
                                              label: 'Billing State Code',
                                              controller:
                                                  billingStateCodeController,
                                              enabled: true,
                                            ),
                                          ),
                                          SizedBox(width: 12.w),
                                          Expanded(
                                            child: ProfileField(
                                              label: 'Billing Zip Code',
                                              controller: billingZipController,
                                              enabled: true,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 14.h),
                                      ProfileField(
                                        label: 'Billing Mobile Number',
                                        controller: billingMobileController,
                                        enabled: true,
                                      ),
                                      SizedBox(height: 18.h),
                                      Text(
                                        'Delivery Address Details',
                                        key: deliverySectionKey,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      SizedBox(height: 12.h),
                                      ProfileField(
                                        key: deliveryFirstFieldKey,
                                        label: 'Delivery Address Line 1',
                                        controller: deliveryAddress1Controller,
                                        enabled: true,
                                      ),
                                      SizedBox(height: 14.h),
                                      ProfileField(
                                        label: 'Delivery Address Line 2',
                                        controller: deliveryAddress2Controller,
                                        enabled: true,
                                      ),
                                      SizedBox(height: 14.h),
                                      ProfileField(
                                        label: 'Delivery Country',
                                        controller: deliveryCountryController,
                                        enabled: true,
                                      ),
                                      SizedBox(height: 14.h),
                                      ProfileField(
                                        label: 'Delivery State',
                                        controller: deliveryStateController,
                                        enabled: true,
                                      ),
                                      SizedBox(height: 14.h),
                                      ProfileField(
                                        label: 'Delivery City',
                                        controller: deliveryCityController,
                                        enabled: true,
                                      ),
                                      SizedBox(height: 14.h),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ProfileField(
                                              label: 'Delivery State Code',
                                              controller:
                                                  deliveryStateCodeController,
                                              enabled: true,
                                            ),
                                          ),
                                          SizedBox(width: 12.w),
                                          Expanded(
                                            child: ProfileField(
                                              label: 'Delivery Zip Code',
                                              controller: deliveryZipController,
                                              enabled: true,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 14.h),
                                      ProfileField(
                                        label: 'Delivery Mobile Number',
                                        controller: deliveryMobileController,
                                        enabled: true,
                                      ),
                                    ],
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
            ),
            if (state.isUpdating) const _UpdateProfileLoading(),
          ],
        ),
        bottomNavigationBar: (selectedTab.value == 0 || selectedTab.value == 2)
            ? SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 0.h, 16.w, 16.h),
                  child: CustomElevatedButton(
                    onPressed: state.isUpdating ||
                            (selectedTab.value == 0 && !canSave)
                        ? null
                        : () async {
                            FocusScope.of(context).unfocus();
                            if (selectedTab.value == 2) {
                              await saveDeliveryInfo();
                              return;
                            }
                            final name = fullNameController.text.trim();
                            if (name.isEmpty) {
                              AppSnackbar.show('Please enter your full name.');
                              return;
                            }
                            final address = addressController.text.trim();
                            final email = state.profile?.email ??
                                profile.email ??
                                emailController.text.trim();
                            final ok = await controller.updateProfile(
                              name: name,
                              email: email,
                              address: address,
                            );
                            if (!context.mounted) return;
                            if (ok) {
                              await controller.fetchProfile();
                              if (!context.mounted) return;
                              final refreshed =
                                  ref.read(profileControllerProvider).profile;
                              initialFullNameState.value =
                                  (refreshed?.name ?? name).trim();
                              initialAddressState.value =
                                  (refreshed?.address ?? address).trim();
                              initialEmailState.value =
                                  (refreshed?.email ?? email).trim();
                              AppSnackbar.show(
                                'Profile updated successfully.',
                                type: AppSnackbarType.success,
                              );
                            } else {
                              AppSnackbar.show(
                                state.updateErrorMessage ??
                                    'Failed to update profile.',
                                type: AppSnackbarType.error,
                              );
                            }
                          },
                    label: state.isUpdating ? 'Saving...' : 'Save & Update',
                    uppercaseLabel: false,
                    showArrow: false,
                    height: 42.h,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class _UpdateProfileLoading extends StatefulWidget {
  const _UpdateProfileLoading();

  @override
  State<_UpdateProfileLoading> createState() => _UpdateProfileLoadingState();
}

class _UpdateProfileLoadingState extends State<_UpdateProfileLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      child: Container(
        color: Colors.white.withOpacity(0.75),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final value = _controller.value * 3 - 1;
              return ShaderMask(
                shaderCallback: (rect) {
                  return LinearGradient(
                    colors: [
                      AppColors.lightBorder.withOpacity(0.2),
                      AppColors.lightBorder.withOpacity(0.6),
                      AppColors.lightBorder.withOpacity(0.2),
                    ],
                    stops: const [0.25, 0.5, 0.75],
                    begin: const Alignment(-1, -0.3),
                    end: const Alignment(1, 0.3),
                    transform: _SlidingGradientTransform(value),
                  ).createShader(rect);
                },
                blendMode: BlendMode.srcATop,
                child: Container(
                  width: 260.w,
                  padding: EdgeInsets.symmetric(
                    horizontal: 18.w,
                    vertical: 16.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 18.r,
                        offset: Offset(0.w, 10.h),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 36.r,
                        width: 36.r,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Icon(
                          Icons.cloud_upload_outlined,
                          color: AppColors.primary,
                          size: 20.r,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Updating profile',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        height: 10.h,
                        width: 140.w,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        height: 10.h,
                        width: 110.w,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slidePercent);

  final double slidePercent;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

class _EmailUpdateSheet extends HookConsumerWidget {
  const _EmailUpdateSheet({required this.currentEmail});

  final String currentEmail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController(text: currentEmail.trim());
    final isSending = useState(false);
    final otpSent = useState(false);
    final otpErrorText = useState<String?>(null);
    final isVerifying = useState(false);
    final pinController = useTextEditingController();
    final pinFocusNode = useFocusNode();

    Future<void> sendOtp() async {
      final email = emailController.text.trim();
      if (email.isEmpty || !email.contains('@')) {
        AppSnackbar.show('Please enter a valid email address.');
        return;
      }
      isSending.value = true;
      final ok = await ref.read(profileControllerProvider.notifier).updateEmail(
            email,
          );
      isSending.value = false;
      if (!context.mounted) return;
      if (ok) {
        otpSent.value = true;
        pinController.clear();
        otpErrorText.value = null;
        pinFocusNode.requestFocus();
        AppSnackbar.show('OTP sent successfully');
      } else {
        final error = ref.read(profileControllerProvider).updateErrorMessage ??
            'Failed to send OTP. Please try again.';
        AppSnackbar.show(
          error,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }

    Future<void> verifyOtp() async {
      final otp = pinController.text.trim();
      if (otp.length < 6) {
        otpErrorText.value = 'Please enter the 6-digit OTP.';
        return;
      }
      otpErrorText.value = null;
      isVerifying.value = true;
      final ok = await ref
          .read(profileControllerProvider.notifier)
          .verifyEmailOtp(otp);
      isVerifying.value = false;
      if (!context.mounted) return;
      if (ok) {
        await ref.read(profileControllerProvider.notifier).fetchProfile();
        if (!context.mounted) return;
        Navigator.of(context).pop();
        AppSnackbar.show('Email updated successfully.');
      } else {
        final profileState = ref.read(profileControllerProvider);
        otpErrorText.value = profileState.updateErrorMessage ??
            'OTP verification failed. Please try again.';
      }
    }

    return Padding(
      padding: MediaQuery.of(context).viewInsets +
          EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Change Email',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Current email: $currentEmail',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.7),
                ),
          ),
          SizedBox(height: 12.h),
          CustomTextField(
            labelText: 'New Email',
            enabled: true,
            textEditingController: emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 12.h),
          if (!otpSent.value)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSending.value ? null : sendOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  elevation: 0,
                ),
                child: isSending.value
                    ? const Center(
                        child: SpinKitCircle(
                          color: AppColors.primary,
                          size: 48,
                        ),
                      )
                    : const Text(
                        'Send OTP',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          if (otpSent.value) ...[
            SizedBox(height: 20.h),
            Text(
              'Enter OTP',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: 10.h),
            Center(
              child: Pinput(
                length: 6,
                controller: pinController,
                focusNode: pinFocusNode,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => otpErrorText.value = null,
                defaultPinTheme: PinTheme(
                  width: 42.w,
                  height: 46.h,
                  textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                    border:
                        Border.all(color: const Color(0xFFD9D9D9), width: 1.4),
                  ),
                ),
                focusedPinTheme: PinTheme(
                  width: 42.w,
                  height: 46.h,
                  textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: AppColors.primary, width: 1.6),
                  ),
                ),
                errorPinTheme: PinTheme(
                  width: 42.w,
                  height: 46.h,
                  textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: Colors.red, width: 1.6),
                  ),
                ),
                errorTextStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                errorText: otpErrorText.value,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                TextButton(
                  onPressed: isSending.value ? null : sendOtp,
                  child: const Text(
                    'Resend OTP',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const Spacer(),
                CustomElevatedButton(
                  onPressed: isVerifying.value ? null : verifyOtp,
                  label: isVerifying.value ? 'Saving...' : 'Update',
                  showArrow: false,
                  width: 140.w,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
