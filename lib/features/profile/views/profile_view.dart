// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:e_rupaiya/features/auth/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pinput/pinput.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/common_banner_slider.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/custom_textfield.dart';
import '../../../widgets/image_picker_helper.dart';
import '../../../widgets/k_dialog.dart';
import '../../../widgets/profile_image_picker_sheet.dart';
import '../../home/controllers/home_controller.dart';
import '../../home/models/banner_model.dart';
import '../../home/utils/banner_redirect_mapper.dart';
import '../components/profile_field.dart';
import '../components/profile_shimmer.dart';
import '../controllers/profile_controller.dart';
import '../models/profile_model.dart';
import 'bank_accounts_view.dart';

// ---------------------------------------------------------------------------
// Shared design tokens (taken from the Figma frames)
// ---------------------------------------------------------------------------
const Color _kBlue = Color(0xFF1D4E9E);
const Color _kPageBg = Color(0xFFF5F5F5);
const Color _kSheetBg = Color(0xFFFAFAFA);
const Color _kDivider = Color(0xFFE0E0E0);
const Color _kTextDark = Color(0xFF1C1C1E);
const Color _kTextGrey = Color(0xFF71717A);
const Color _kCardBorder = Color(0xFFE4E4E4);
const Color _kIconCircle = Color(0xFFFCEBE4);

TextStyle _ts(
  double size,
  FontWeight weight,
  Color color, {
  double? height,
  TextDecoration? decoration,
}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: size.sp,
    fontWeight: weight,
    color: color,
    height: height,
    decoration: decoration,
    decorationColor: color,
  );
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: _kDivider);
  }
}

// ---------------------------------------------------------------------------
// My Profile
// ---------------------------------------------------------------------------
class ProfileView extends HookConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState.profile;
    // Same "Banking & Investments" banners the Home carousel shows, reused for
    // the common slider below the Zero Balance Account banner.
    final bankingBanners =
        ref.watch(homeControllerProvider).banners?['banking_investment'] ??
            const <BannerModel>[];

    useEffect(() {
      Future.microtask(
        () => ref.read(profileControllerProvider.notifier).fetchProfile(),
      );
      return null;
    }, const []);

    void openPersonalDetails() {
      if (profile == null) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => UpdateProfileView(profile: profile),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: _kBlue,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _kPageBg,
        body: profileState.isFetching && profile == null
            ? const SafeArea(child: ProfileShimmer())
            : Column(
                children: [
                  _ProfileHeaderCard(
                    profile: profile,
                    onBack: () {
                      final navigator = Navigator.of(context);
                      if (navigator.canPop()) {
                        navigator.pop();
                      }
                    },
                    onManage: openPersonalDetails,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(bottom: 24.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            color: _kBlue,
                            child: _InviteEarnCard(
                              onInvite: () =>
                                  context.push(RouteConstants.referAndEarn),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: _ZeroBalanceBanner(
                              onTap: () => context.push(
                                RouteConstants.zeroBalanceChooseBank,
                              ),
                            ),
                          ),
                          if (bankingBanners.isNotEmpty) ...[
                            SizedBox(height: 12.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.w),
                              child: CommonBannerSlider(
                                banners: bankingBanners,
                                height: 90.h,
                                onTap: (banner) => BannerRedirectMapper.handle(
                                  context,
                                  banner.redirectUrl,
                                ),
                              ),
                            ),
                          ],
                          SizedBox(height: 16.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _ProfileSectionTitle(
                                  title: 'My Account',
                                ),
                                SizedBox(height: 2.h),
                                _ProfileActionTile(
                                  icon: Icons.help_outline_rounded,
                                  title: 'Personal Details',
                                  trailing: _CompletionBadge(
                                    percent:
                                        profile?.profileCompletionPercent ?? 0,
                                  ),
                                  onTap: openPersonalDetails,
                                ),
                                const _TileDivider(),
                                _ProfileActionTile(
                                  svgAsset: FileConstants.profileWalletSvg,
                                  title: 'Wallet (eCoins)',
                                  onTap: () => context.push(
                                    RouteConstants.referAndEarnWallet,
                                  ),
                                ),
                                const _TileDivider(),
                                _ProfileActionTile(
                                  svgAsset: FileConstants.profileLoansSvg,
                                  title: 'My Loans',
                                ),
                                const _TileDivider(),
                                const _ProfileActionTile(
                                  icon: Icons.speed_rounded,
                                  title: 'My Credit Score',
                                ),
                                const _TileDivider(),
                                SizedBox(height: 16.h),
                                const _ProfileSectionTitle(title: 'Settings'),
                                SizedBox(height: 2.h),
                                _ProfileActionTile(
                                  icon: Icons.tune_rounded,
                                  title: 'Preferences',
                                  subtitle: 'Languages, Permissions, Reminders',
                                  onTap: () =>
                                      context.push(RouteConstants.preferences),
                                ),
                                const _TileDivider(),
                                _ProfileActionTile(
                                  icon: Icons.shield_outlined,
                                  title: 'Security',
                                  subtitle: 'Screen Lock, Passcode',
                                  onTap: () =>
                                      context.push(RouteConstants.security),
                                ),
                                const _TileDivider(),
                                SizedBox(height: 16.h),
                                const _ProfileSectionTitle(title: 'Support'),
                                SizedBox(height: 2.h),
                                _ProfileActionTile(
                                  icon: Icons.help_outline_rounded,
                                  title: 'Help & Support',
                                  onTap: () =>
                                      context.push(RouteConstants.helpSupport),
                                ),
                                const _TileDivider(),
                                _ProfileActionTile(
                                  icon: Icons.info_outline_rounded,
                                  title: 'About eRupaiya',
                                  onTap: () =>
                                      context.push(RouteConstants.policies),
                                ),
                                const _TileDivider(),
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
    required this.onBack,
    required this.onManage,
  });

  final ProfileModel? profile;
  final VoidCallback onBack;
  final VoidCallback onManage;

  Widget _buildInitials(BuildContext context, ProfileModel? profile) {
    // Fixed 40x40 box so the initials sit dead-center of the 20.r circle
    // (a bare Text sizes to its glyphs and can drift off the centre).
    return SizedBox(
      width: 40.r,
      height: 40.r,
      child: Center(
        child: Text(
          profile?.initials ?? '',
          textAlign: TextAlign.center,
          style: _ts(13, FontWeight.w700, _kBlue, height: 1.0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = profile?.name ?? '';
    final rawMobile = profile?.mobile ?? '';
    final mobile = rawMobile.startsWith('+') ? rawMobile : '+91$rawMobile';
    return Container(
      width: double.infinity,
      color: _kBlue,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 8.h, 20.w, 0),
              child: SizedBox(
                height: 36.h,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: onBack,
                      behavior: HitTestBehavior.opaque,
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 18.r,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'My Profile',
                        style: _ts(15, FontWeight.w500, Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 23.h),
              child: Row(
                children: [
                  // Same avatar as the Personal Details header: backend photo
                  // when present, otherwise the name initials on zinc/200.
                  CircleAvatar(
                    radius: 20.r,
                    backgroundColor: const Color(0xFFE4E4E7),
                    child: ClipOval(
                      child: profile?.profilePhotoUrl?.isNotEmpty == true
                          ? AppNetworkImage(
                              url: profile!.profilePhotoUrl,
                              width: 40.r,
                              height: 40.r,
                              fit: BoxFit.cover,
                              showShimmer: false,
                              placeholder: _buildInitials(context, profile),
                              errorWidget: _buildInitials(context, profile),
                            )
                          : _buildInitials(context, profile),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _ts(16, FontWeight.w600, Colors.white),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          mobile,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _ts(
                            12,
                            FontWeight.w400,
                            Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: onManage,
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      'Manage',
                      textAlign: TextAlign.right,
                      style: _ts(
                        12,
                        FontWeight.w500,
                        Colors.white,
                        height: 1.0,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteEarnCard extends StatelessWidget {
  const _InviteEarnCard({required this.onInvite});

  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE7E0),
        borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 70.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: _kBlue,
              borderRadius: BorderRadius.circular(999.r),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999.r),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                child: Image.asset(
                  FileConstants.referAndEarn,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Invite & earn eCoins',
                    maxLines: 1,
                    style: _ts(13, FontWeight.w600, AppColors.textPrimary),
                  ),
                ),
                SizedBox(height: 3.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'ReferFriends & Unlock Bonus Rewards',
                    maxLines: 1,
                    style: _ts(13, FontWeight.w600, AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          // Invite Now button: fixed 79 x 20 pill, text 13 / w500.
          InkWell(
            onTap: onInvite,
            borderRadius: BorderRadius.circular(999.r),
            child: Container(
              width: 79.w,
              height: 20.h,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(999.r),
              ),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Text(
                    'Invite Now',
                    maxLines: 1,
                    style: _ts(10, FontWeight.w500, Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSectionTitle extends StatelessWidget {
  const _ProfileSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: _ts(13, FontWeight.w400, _kTextGrey));
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    this.icon,
    this.svgAsset,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData? icon;
  final String? svgAsset;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 13.h),
        child: Row(
          children: [
            _ProfileIconCircle(
              child: svgAsset != null
                  ? SvgPicture.asset(
                      svgAsset!,
                      width: 14.r,
                      height: 14.r,
                      fit: BoxFit.contain,
                    )
                  : Icon(icon, color: AppColors.primary, size: 14.r),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF27272A),
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _ts(11, FontWeight.w400, _kTextGrey),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              SizedBox(width: 8.w),
              trailing!,
            ],
            SizedBox(width: 8.w),
            Icon(
              Icons.chevron_right,
              size: 18.r,
              color: _kTextDark,
            ),
          ],
        ),
      ),
    );
  }
}

/// Light-peach circular container that frames a menu row's orange icon.
class _ProfileIconCircle extends StatelessWidget {
  const _ProfileIconCircle({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26.r,
      height: 26.r,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: _kIconCircle,
        shape: BoxShape.circle,
      ),
      child: child,
    );
  }
}

/// Orange completion badge shown on the Personal Details row.
class _CompletionBadge extends StatelessWidget {
  const _CompletionBadge({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        '$percent% Complete',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: _ts(11, FontWeight.w500, Colors.white),
      ),
    );
  }
}

/// Green-to-blue horizontal banner promoting the zero balance account.
class _ZeroBalanceBanner extends StatelessWidget {
  const _ZeroBalanceBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6.r),
      child: Container(
        height: 33.h,
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.r),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF0A4B28), Color(0xFF4973A8)],
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.account_balance,
              color: Colors.white,
              size: 14.r,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'Open Zero Balance Account',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _ts(12, FontWeight.w400, Colors.white),
              ),
            ),
            SizedBox(width: 6.w),
            Container(
              width: 3.r,
              height: 3.r,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 2.w),
            Container(
              width: 8.w,
              height: 3.r,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2.r),
              ),
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
        padding: EdgeInsets.symmetric(vertical: 18.h),
        child: Row(
          children: [
            SvgPicture.asset(
              FileConstants.profileLogoutSvg,
              width: 16.r,
              height: 16.r,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'Log Out',
                style: _ts(13, FontWeight.w500, const Color(0xFFB20003)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two-up pill tab used by the Personal Details screen (solid orange when
/// active, orange outline when inactive) per the Figma reference.
class _PillTab extends StatelessWidget {
  const _PillTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 33.h,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : _kSheetBg,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColors.primary, width: 1.0),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: _ts(
            13,
            FontWeight.w500,
            isActive ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }
}

/// Grey-label / dark-value read-only row for the Personal Details card.
/// When [editableController] is provided the value renders as a borderless
/// text field (pre-KYC name editing keeps the existing save flow).
class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.label,
    required this.value,
    this.editableController,
    this.trailing,
  });

  final String label;
  final String value;
  final TextEditingController? editableController;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: _ts(12, FontWeight.w400, const Color(0xFF52525B)),
                ),
                SizedBox(height: 2.h),
                if (editableController != null)
                  TextField(
                    controller: editableController,
                    maxLines: 1,
                    style: _ts(13, FontWeight.w500, const Color(0xFF18181B)),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                  )
                else
                  Text(
                    value,
                    style: _ts(13, FontWeight.w500, const Color(0xFF18181B)),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: 8.w),
            trailing!,
          ],
        ],
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
            style: _ts(16, FontWeight.w800, AppColors.textPrimary),
          ),
          SizedBox(height: 6.h),
          Text(
            "You'll Need To Sign In Again To Access Your Account.",
            style: _ts(
              12,
              FontWeight.w400,
              AppColors.textPrimary.withOpacity(0.6),
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
                    style: _ts(14, FontWeight.w700, AppColors.primary),
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
                    'Stay logged in',
                    style: _ts(14, FontWeight.w700, Colors.white),
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

// ---------------------------------------------------------------------------
// Personal Details
// ---------------------------------------------------------------------------
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
    final addressController = useTextEditingController(
      text: profile.address ?? '',
    );
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

    useEffect(() {
      fullNameController.text = profile.name.trim();
      return null;
    }, const []);

    final canEdit = !latestProfile.isKycVerified;
    final isKycVerified = latestProfile.kycStatus == ProfileKycStatus.verified;
    final initialFullName = initialFullNameState.value;
    final initialAddress = initialAddressState.value;
    final initialEmail = initialEmailState.value;

    final currentFullName = fullNameController.text.trim();
    final currentAddress = addressController.text.trim();
    final currentEmail = emailController.text.trim();
    final hasCommunicationChange = currentAddress != initialAddress;
    final hasNonEmailChanges =
        currentFullName != initialFullName || hasCommunicationChange;
    final hasEmailChange = canEdit &&
        !latestProfile.isEmailVerified &&
        currentEmail != initialEmail;
    final hasPendingImage = pickedImage.value != null;
    final canSave = hasPendingImage ||
        (hasNonEmailChanges && (canEdit || hasCommunicationChange));
    final hasUnsavedChanges =
        hasNonEmailChanges || hasEmailChange || hasPendingImage;

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
          ref.read(profileControllerProvider).updateErrorMessage ??
              'Failed to update delivery info.',
          type: AppSnackbarType.error,
        );
      }
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
      return null;
    }, [
      state.profile?.aadhaarMasked,
      state.profile?.panMasked,
      state.profile?.dob,
      state.profile?.billingAddress,
      state.profile?.addresses,
      state.isUpdating,
    ]);

    String displayValue(String? value) {
      final trimmed = (value ?? '').trim();
      return trimmed.isEmpty ? '--' : trimmed;
    }

    final rawMobile = latestProfile.mobile;
    final mobileDisplay =
        rawMobile.startsWith('+') ? rawMobile : '+91 $rawMobile';

    Widget avatarChild() {
      if (pickedImage.value != null) {
        return Image.file(
          pickedImage.value!,
          width: 40.r,
          height: 40.r,
          fit: BoxFit.cover,
        );
      }
      if (profile.profilePhotoUrl?.isNotEmpty == true) {
        return AppNetworkImage(
          url: profile.profilePhotoUrl,
          width: 40.r,
          height: 40.r,
          fit: BoxFit.cover,
          showShimmer: false,
        );
      }
      return SizedBox(
        width: 40.r,
        height: 40.r,
        child: Center(
          child: Text(
            profile.initials,
            textAlign: TextAlign.center,
            style: _ts(13, FontWeight.w700, Colors.white, height: 1.0),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: confirmDiscard,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: _kBlue,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: _kSheetBg,
          body: Stack(
            children: [
              Column(
                children: [
                  // ---------------- Blue header ----------------
                  Container(
                    width: double.infinity,
                    color: _kBlue,
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(18.w, 8.h, 20.w, 0),
                            child: SizedBox(
                              height: 36.h,
                              child: Row(
                                children: [
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () async {
                                      final okToLeave = await confirmDiscard();
                                      if (!context.mounted || !okToLeave) {
                                        return;
                                      }
                                      Navigator.of(context).pop();
                                    },
                                    child: Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                      size: 18.r,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Text(
                                      'Personal Details',
                                      style: _ts(
                                        15,
                                        FontWeight.w500,
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding:
                                EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 20.r,
                                      backgroundColor:
                                          Colors.white.withOpacity(0.25),
                                      child: ClipOval(child: avatarChild()),
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: GestureDetector(
                                        onTap: () {
                                          KDialog.instance.openSheet(
                                            dialog: ProfileImagePickerSheet(
                                              onCamera: () async {
                                                navigatorKey.currentState
                                                    ?.pop();
                                                final image =
                                                    await ImagePickerHelper
                                                        .pickFromCamera();
                                                if (image == null) return;
                                                pickedImage.value = image;
                                              },
                                              onGallery: () async {
                                                navigatorKey.currentState
                                                    ?.pop();
                                                final image =
                                                    await ImagePickerHelper
                                                        .pickFromGallery();
                                                if (image == null) return;
                                                pickedImage.value = image;
                                              },
                                            ),
                                          );
                                        },
                                        child: Container(
                                          height: 16.r,
                                          width: 16.r,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.15),
                                                blurRadius: 4.r,
                                                offset: Offset(0, 1.h),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.camera_alt_outlined,
                                            size: 10.r,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        latestProfile.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: _ts(
                                          18,
                                          FontWeight.w500,
                                          Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        rawMobile.startsWith('+')
                                            ? rawMobile
                                            : '+91$rawMobile',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: _ts(
                                          12,
                                          FontWeight.w400,
                                          Colors.white.withOpacity(0.85),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Rounded top edge of the white sheet.
                          Container(
                            height: 16.h,
                            decoration: BoxDecoration(
                              color: _kSheetBg,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16.r),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ---------------- Sheet content ----------------
                  Expanded(
                    child: Container(
                      color: _kSheetBg,
                      child: Column(
                        children: [
                          SizedBox(height: 4.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _PillTab(
                                    label: 'Personal & Banking',
                                    isActive: selectedTab.value == 0,
                                    onTap: () => selectedTab.value = 0,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: _PillTab(
                                    label: 'Billing Address',
                                    isActive: selectedTab.value == 1,
                                    onTap: () => selectedTab.value = 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 14.h),
                          Expanded(
                            child: selectedTab.value == 0
                                ? SingleChildScrollView(
                                    padding: EdgeInsets.fromLTRB(
                                        20.w, 0, 20.w, 24.h),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 14.w,
                                            vertical: 8.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(12.r),
                                            border: Border.all(
                                              color: _kCardBorder,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _ProfileInfoRow(
                                                label: 'Full name (as per PAN)',
                                                value: displayValue(
                                                    latestProfile.name),
                                                editableController: canEdit
                                                    ? fullNameController
                                                    : null,
                                              ),
                                              _ProfileInfoRow(
                                                label: 'Mobile Number',
                                                value: mobileDisplay,
                                              ),
                                              _ProfileInfoRow(
                                                label: 'Email ID',
                                                value:
                                                    displayValue(currentEmail),
                                                trailing: GestureDetector(
                                                  behavior:
                                                      HitTestBehavior.opaque,
                                                  onTap: () {
                                                    KDialog.instance.openSheet(
                                                      dialog: _EmailUpdateSheet(
                                                        currentEmail:
                                                            emailController.text
                                                                .trim(),
                                                      ),
                                                    );
                                                  },
                                                  child: SvgPicture.asset(
                                                    FileConstants
                                                        .profileEmailEditSvg,
                                                    width: 16.r,
                                                    height: 16.r,
                                                  ),
                                                ),
                                              ),
                                              _ProfileInfoRow(
                                                label: 'Adhaar Number',
                                                value: displayValue(
                                                    latestProfile
                                                        .aadhaarMasked),
                                              ),
                                              _ProfileInfoRow(
                                                label: 'PAN Number',
                                                value: displayValue(
                                                    latestProfile.panMasked),
                                              ),
                                              _ProfileInfoRow(
                                                label: 'Date Of Birth',
                                                value: displayValue(
                                                    latestProfile.dob),
                                              ),
                                              _ProfileInfoRow(
                                                label: 'Permanent Address',
                                                value: displayValue(
                                                    latestProfile
                                                        .permanentAddress),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 14.h),
                                        if (isKycVerified)
                                          const BankAccountsSection(
                                            padding: EdgeInsets.zero,
                                          )
                                        else
                                          Text(
                                            'Please complete KYC first to '
                                            'manage bank details.',
                                            style: _ts(
                                              12,
                                              FontWeight.w400,
                                              AppColors.textPrimary
                                                  .withOpacity(0.6),
                                            ),
                                          ),
                                      ],
                                    ),
                                  )
                                : SingleChildScrollView(
                                    controller: deliveryScrollController,
                                    padding: EdgeInsets.fromLTRB(
                                        20.w, 0, 20.w, 90.h),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Billing Address Details',
                                          style: _ts(
                                            15,
                                            FontWeight.w700,
                                            _kTextDark,
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
                                                controller:
                                                    billingZipController,
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
                                          style: _ts(
                                            15,
                                            FontWeight.w700,
                                            _kTextDark,
                                          ),
                                        ),
                                        SizedBox(height: 12.h),
                                        ProfileField(
                                          key: deliveryFirstFieldKey,
                                          label: 'Delivery Address Line 1',
                                          controller:
                                              deliveryAddress1Controller,
                                          enabled: true,
                                        ),
                                        SizedBox(height: 14.h),
                                        ProfileField(
                                          label: 'Delivery Address Line 2',
                                          controller:
                                              deliveryAddress2Controller,
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
                                                controller:
                                                    deliveryZipController,
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
                ],
              ),
              if (state.isUpdating) const _UpdateProfileLoading(),
            ],
          ),
          bottomNavigationBar: selectedTab.value == 1 ||
                  (selectedTab.value == 0 && (canSave || state.isUpdating))
              ? Container(
                  color: _kSheetBg,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
                      child: CustomElevatedButton(
                        onPressed: state.isUpdating ||
                                (selectedTab.value == 0 && !canSave)
                            ? null
                            : () async {
                                FocusScope.of(context).unfocus();
                                if (selectedTab.value == 1) {
                                  await saveDeliveryInfo();
                                  return;
                                }
                                final name = fullNameController.text.trim();
                                if (name.isEmpty) {
                                  AppSnackbar.show(
                                      'Please enter your full name.');
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
                                  image: pickedImage.value,
                                );
                                if (!context.mounted) return;
                                if (ok) {
                                  pickedImage.value = null;
                                  await controller.fetchProfile();
                                  if (!context.mounted) return;
                                  final refreshed = ref
                                      .read(profileControllerProvider)
                                      .profile;
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
                                    ref
                                            .read(profileControllerProvider)
                                            .updateErrorMessage ??
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
                  ),
                )
              : null,
        ),
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
    return Positioned.fill(
      child: AbsorbPointer(
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
                          offset: Offset(0, 10.h),
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
                          style:
                              _ts(14, FontWeight.w700, AppColors.textPrimary),
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

    PinTheme pinTheme(Color borderColor, double borderWidth) => PinTheme(
          width: 42.w,
          height: 46.h,
          textStyle: _ts(16, FontWeight.w700, AppColors.textPrimary),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
        );

    return Padding(
      padding: MediaQuery.of(context).viewInsets +
          EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Change Email',
            style: _ts(16, FontWeight.w700, AppColors.textPrimary),
          ),
          SizedBox(height: 12.h),
          Text(
            'Current email: $currentEmail',
            style: _ts(
              13,
              FontWeight.w400,
              AppColors.textPrimary.withOpacity(0.7),
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
                    ? Center(
                        child: SpinKitCircle(
                          color: AppColors.primary,
                          size: 48.r,
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
              style: _ts(13, FontWeight.w600, AppColors.textPrimary),
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
                defaultPinTheme: pinTheme(const Color(0xFFD9D9D9), 1.4),
                focusedPinTheme: pinTheme(AppColors.primary, 1.6),
                errorPinTheme: pinTheme(Colors.red, 1.6),
                errorTextStyle: _ts(12, FontWeight.w600, Colors.red.shade700),
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
