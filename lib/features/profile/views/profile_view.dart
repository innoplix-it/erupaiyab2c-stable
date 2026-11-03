// ignore_for_file: deprecated_member_use

import 'dart:async';
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
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/custom_textfield.dart';
import '../../../widgets/image_picker_helper.dart';
import '../../../widgets/k_dialog.dart';
import '../../../widgets/profile_image_picker_sheet.dart';
import '../components/profile_shimmer.dart';
import '../controllers/profile_controller.dart';
import '../models/profile_model.dart';
import 'bank_accounts_view.dart';

// ---------------------------------------------------------------------------
// Responsive helpers
//
// Every width / height / padding / radius / icon size in this file is a
// PERCENTAGE of the screen taken from MediaQuery (no fixed pixel sizes):
//   context.wp(5.64)  -> 5.64 % of screen width
//   context.hp(5.21)  -> 5.21 % of screen height
// Percentages were derived from the Figma frame (390 x 844):
//   width %  = figmaValue / 390 * 100
//   height % = figmaValue / 844 * 100
// Font sizes use flutter_screenutil (.sp) inside _ts().
// ---------------------------------------------------------------------------
extension _ResponsiveContext on BuildContext {
  double wp(double percent) => MediaQuery.sizeOf(this).width * percent / 100;
  double hp(double percent) => MediaQuery.sizeOf(this).height * percent / 100;
}

// ---------------------------------------------------------------------------
// Shared design tokens (colours from Figma)
// ---------------------------------------------------------------------------
const Color _kBlue = Color(0xFF1D4E9E);
const Color _kPageBg = Color(0xFFF5F5F5);
const Color _kSheetBg = Color(0xFFFAFAFA);
const Color _kDivider = Color(0xFFE0E0E0);
const Color _kTextDark = Color(0xFF1C1C1E);
const Color _kTextGrey = Color(0xFF71717A);
const Color _kCardBorder = Color(0xFFE4E4E4);
const Color _kIconCircle = Color(0xFFFCEBE4);
const Color _kFieldBorder = Color(0xFFE4E4E7);
const Color _kHint = Color(0xFFA1A1AA);
const Color _kDanger = Color(0xFFB20003);

/// Every text in the app goes through this so it is always Plus Jakarta Sans.
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

/// Keeps layouts stable when the user has a very large system font size.
Widget _clampTextScale(BuildContext context, Widget child) {
  return MediaQuery.withClampedTextScaling(
    minScaleFactor: 0.9,
    maxScaleFactor: 1.15,
    child: child,
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

    final sidePad = context.wp(5.13);

    return _clampTextScale(
      context,
      AnnotatedRegion<SystemUiOverlayStyle>(
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
                        padding: EdgeInsets.only(bottom: context.hp(2.84)),
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
                            SizedBox(height: context.hp(1.9)),
                            Padding(
                              padding:
                                  EdgeInsets.symmetric(horizontal: sidePad),
                              child: _ZeroBalanceSlider(
                                onTap: () => context.push(
                                  RouteConstants.zeroBalanceChooseBank,
                                ),
                              ),
                            ),
                            SizedBox(height: context.hp(1.9)),
                            Padding(
                              padding:
                                  EdgeInsets.symmetric(horizontal: sidePad),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _ProfileSectionTitle(
                                    title: 'My Account',
                                  ),
                                  SizedBox(height: context.hp(0.24)),
                                  _ProfileActionTile(
                                    icon: Icons.help_outline_rounded,
                                    title: 'Personal Details',
                                    trailing: _CompletionBadge(
                                      percent:
                                          profile?.profileCompletionPercent ??
                                              0,
                                    ),
                                    onTap: openPersonalDetails,
                                  ),
                                  const _TileDivider(),
                                  _ProfileActionTile(
                                    svgAsset: FileConstants.profileWalletSvg,
                                    title: 'My eCoins',
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
                                  SizedBox(height: context.hp(1.9)),
                                  const _ProfileSectionTitle(title: 'Settings'),
                                  SizedBox(height: context.hp(0.24)),
                                  _ProfileActionTile(
                                    icon: Icons.tune_rounded,
                                    title: 'Preferences',
                                    subtitle:
                                        'Languages, Permissions, Reminders',
                                    onTap: () => context
                                        .push(RouteConstants.preferences),
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
                                  SizedBox(height: context.hp(1.9)),
                                  const _ProfileSectionTitle(title: 'Support'),
                                  SizedBox(height: context.hp(0.24)),
                                  _ProfileActionTile(
                                    icon: Icons.help_outline_rounded,
                                    title: 'Help & Support',
                                    onTap: () => context
                                        .push(RouteConstants.helpSupport),
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
    // Fixed square box so the initials sit dead-center of the avatar circle
    // (a bare Text sizes to its glyphs and can drift off the centre).
    final box = context.wp(10.26);
    return SizedBox(
      width: box,
      height: box,
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
    final avatarBox = context.wp(10.26);
    return Container(
      width: double.infinity,
      color: _kBlue,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.wp(4.62),
                context.hp(0.95),
                context.wp(5.13),
                0,
              ),
              child: SizedBox(
                height: context.hp(4.27),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: onBack,
                      behavior: HitTestBehavior.opaque,
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: context.wp(4.62),
                      ),
                    ),
                    SizedBox(width: context.wp(3.08)),
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
              padding: EdgeInsets.fromLTRB(
                context.wp(5.13),
                context.hp(1.42),
                context.wp(5.13),
                context.hp(2.73),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: avatarBox / 2,
                    backgroundColor: const Color(0xFFE4E4E7),
                    child: ClipOval(
                      child: profile?.profilePhotoUrl?.isNotEmpty == true
                          ? AppNetworkImage(
                              url: profile!.profilePhotoUrl,
                              width: avatarBox,
                              height: avatarBox,
                              fit: BoxFit.cover,
                              showShimmer: false,
                              placeholder: _buildInitials(context, profile),
                              errorWidget: _buildInitials(context, profile),
                            )
                          : _buildInitials(context, profile),
                    ),
                  ),
                  SizedBox(width: context.wp(2.56)),
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
                        SizedBox(height: context.hp(0.24)),
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
                  SizedBox(width: context.wp(2.05)),
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
    final pillRadius = BorderRadius.circular(context.wp(100));
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.wp(5.13),
        vertical: context.hp(0.95),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE7E0),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.wp(3.59)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: context.wp(17.95),
            height: context.hp(4.74),
            decoration: BoxDecoration(
              color: _kBlue,
              borderRadius: pillRadius,
            ),
            child: ClipRRect(
              borderRadius: pillRadius,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.wp(1.54),
                  vertical: context.hp(0.47),
                ),
                child: Image.asset(
                  FileConstants.referAndEarn,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          SizedBox(width: context.wp(2.56)),
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
                SizedBox(height: context.hp(0.36)),
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
          SizedBox(width: context.wp(2.05)),
          InkWell(
            onTap: onInvite,
            borderRadius: pillRadius,
            child: Container(
              width: context.wp(20.26),
              height: context.hp(2.37),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: pillRadius,
              ),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.wp(1.03)),
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
    final iconSize = context.wp(3.59);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.hp(1.54)),
        child: Row(
          children: [
            _ProfileIconCircle(
              child: svgAsset != null
                  ? SvgPicture.asset(
                      svgAsset!,
                      width: iconSize,
                      height: iconSize,
                      fit: BoxFit.contain,
                    )
                  : Icon(icon, color: AppColors.primary, size: iconSize),
            ),
            SizedBox(width: context.wp(2.56)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _ts(13, FontWeight.w500, const Color(0xFF27272A)),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    SizedBox(height: context.hp(0.24)),
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
              SizedBox(width: context.wp(2.05)),
              trailing!,
            ],
            SizedBox(width: context.wp(2.05)),
            Icon(
              Icons.chevron_right,
              size: context.wp(4.62),
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
    final size = context.wp(6.67);
    return Container(
      width: size,
      height: size,
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
      padding: EdgeInsets.symmetric(
        horizontal: context.wp(2.05),
        vertical: context.hp(0.36),
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(context.wp(1.03)),
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

// ---------------------------------------------------------------------------
// Zero Balance Account slider
// ---------------------------------------------------------------------------
class _ZeroBalanceSlide {
  const _ZeroBalanceSlide(this.icon, this.text);

  final IconData icon;
  final String text;
}

class _ZeroBalanceSlider extends StatefulWidget {
  const _ZeroBalanceSlider({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_ZeroBalanceSlider> createState() => _ZeroBalanceSliderState();
}

class _ZeroBalanceSliderState extends State<_ZeroBalanceSlider> {
  static const List<_ZeroBalanceSlide> _slides = [
    _ZeroBalanceSlide(Icons.account_balance, 'Open Zero Balance Account'),
    _ZeroBalanceSlide(
      Icons.savings_outlined,
      'Start Banking With Zero Balance',
    ),
    _ZeroBalanceSlide(
      Icons.account_balance_wallet_outlined,
      'Choose Your Bank & Get Started',
    ),
  ];

  final PageController _pageController = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final next = (_index + 1) % _slides.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = context.wp(0.77);
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: context.hp(3.91),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.wp(1.54)),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF0A4B28), Color(0xFF4973A8)],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final slide = _slides[i];
                  return Padding(
                    padding: EdgeInsets.only(left: context.wp(3.59)),
                    child: Row(
                      children: [
                        Icon(
                          slide.icon,
                          color: Colors.white,
                          size: context.wp(3.59),
                        ),
                        SizedBox(width: context.wp(2.05)),
                        Expanded(
                          child: Text(
                            slide.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _ts(12, FontWeight.w400, Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: context.wp(1.54)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_slides.length, (i) {
                final active = i == _index;
                return Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : context.wp(0.51)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: active ? context.wp(2.05) : dot,
                    height: dot,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(active ? 1 : 0.6),
                      borderRadius: BorderRadius.circular(context.wp(0.51)),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(width: context.wp(3.59)),
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
        padding: EdgeInsets.symmetric(vertical: context.hp(2.13)),
        child: Row(
          children: [
            SvgPicture.asset(
              FileConstants.profileLogoutSvg,
              width: context.wp(4.1),
              height: context.wp(4.1),
            ),
            SizedBox(width: context.wp(3.08)),
            Expanded(
              child: Text(
                'Log Out',
                style: _ts(13, FontWeight.w500, _kDanger),
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
        height: context.hp(4.15),
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: context.wp(2.05)),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : _kSheetBg,
          borderRadius: BorderRadius.circular(context.wp(2.05)),
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
    final valueStyle = _ts(
      13,
      FontWeight.w500,
      const Color(0xFF18181B),
      height: 1.5,
    );
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.hp(0.65)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: _ts(
                    12,
                    FontWeight.w400,
                    const Color(0xFF52525B),
                    height: 1.5,
                  ),
                ),
                SizedBox(height: context.hp(0.12)),
                if (editableController != null)
                  TextField(
                    controller: editableController,
                    maxLines: 1,
                    style: valueStyle,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                  )
                else
                  Text(value, style: valueStyle),
              ],
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: context.wp(2.05)),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Label on top + a white bordered box of fixed (percentage) height.
///
/// FIX: the old version used `expands: true`, which pinned the text to the
/// top of the box. Now the box centres a normal single-line TextField, so the
/// typed text AND the hint are vertically centred.
class _AddressField extends StatelessWidget {
  const _AddressField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _ts(13, FontWeight.w500, _kTextDark, height: 1.3)),
        SizedBox(height: context.hp(1.07)),
        Container(
          width: double.infinity,
          height: context.hp(5.21),
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.symmetric(horizontal: context.wp(4.62)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.wp(2.56)),
            border: Border.all(color: _kFieldBorder),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType ?? TextInputType.text,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.singleLineFormatter,
              // No leading spaces, so what the user types is already trimmed.
              FilteringTextInputFormatter.deny(RegExp(r'^\s')),
              ...?inputFormatters,
            ],
            maxLength: maxLength,
            maxLines: 1,
            textAlignVertical: TextAlignVertical.center,
            style: _ts(13, FontWeight.w500, const Color(0xFF18181B)),
            decoration: InputDecoration(
              isCollapsed: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              counterText: '',
              hintText: hint,
              hintStyle: _ts(13, FontWeight.w400, _kHint),
            ),
          ),
        ),
      ],
    );
  }
}

/// Thin "V" chevron that flips when the section opens.
class _ChevronPainter extends CustomPainter {
  const _ChevronPainter({required this.color, required this.stroke});

  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final inset = stroke / 2;
    final path = Path()
      ..moveTo(inset, inset)
      ..lineTo(size.width / 2, size.height - inset)
      ..lineTo(size.width - inset, inset);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ChevronPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.stroke != stroke;
}

/// Full-width pill CTA used by Save & Update.
class _PrimaryPillButton extends StatelessWidget {
  const _PrimaryPillButton({
    required this.label,
    required this.onTap,
    this.fontSize = 14,
  });

  final String label;
  final VoidCallback? onTap;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(context.wp(100));
    return Opacity(
      opacity: onTap == null ? 0.6 : 1,
      child: Material(
        color: AppColors.primary,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: SizedBox(
            width: double.infinity,
            height: context.hp(5.21),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                style: _ts(fontSize, FontWeight.w500, Colors.white),
              ),
            ),
          ),
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
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(context.wp(7.18)),
    );
    final buttonPad = EdgeInsets.symmetric(vertical: context.hp(1.42));
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.wp(5.13),
        context.hp(2.37),
        context.wp(5.13),
        context.hp(2.84),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.wp(6.15)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Log Out Of Your Account?',
            style: _ts(16, FontWeight.w800, AppColors.textPrimary),
          ),
          SizedBox(height: context.hp(0.71)),
          Text(
            "You'll Need To Sign In Again To Access Your Account.",
            style: _ts(
              12,
              FontWeight.w400,
              AppColors.textPrimary.withOpacity(0.6),
            ),
          ),
          SizedBox(height: context.hp(2.13)),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onLogout,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: buttonShape,
                    padding: buttonPad,
                  ),
                  child: Text(
                    'Log Out',
                    style: _ts(14, FontWeight.w700, AppColors.primary),
                  ),
                ),
              ),
              SizedBox(width: context.wp(3.08)),
              Expanded(
                child: ElevatedButton(
                  onPressed: onStay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: buttonShape,
                    padding: buttonPad,
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
    // Communication address (edited through the pencil icon sheet).
    final addressController = useTextEditingController(
      text: profile.address ?? '',
    );

    // Billing & delivery: typed MANUALLY by the user. Never prefilled.
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
    // Rebuild whenever a billing / delivery field changes so the
    // "unsaved changes" state stays live.
    final addressListenable = useMemoized(
      () => Listenable.merge([
        billingAddress1Controller,
        billingAddress2Controller,
        billingCountryController,
        billingStateController,
        billingCityController,
        billingStateCodeController,
        billingZipController,
        billingMobileController,
        deliveryAddress1Controller,
        deliveryAddress2Controller,
        deliveryCountryController,
        deliveryStateController,
        deliveryCityController,
        deliveryStateCodeController,
        deliveryZipController,
        deliveryMobileController,
      ]),
      const [],
    );
    useListenable(addressListenable);

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
    final canSaveProfile = hasPendingImage ||
        (hasNonEmailChanges && (canEdit || hasCommunicationChange));

    // Baseline is "all empty"; after a successful save it becomes whatever
    // was saved.
    final savedAddressSnapshot =
        useState<String>(List.filled(16, '').join('|'));
    String addressSnapshot() => [
          billingAddress1Controller,
          billingAddress2Controller,
          billingCountryController,
          billingStateController,
          billingCityController,
          billingStateCodeController,
          billingZipController,
          billingMobileController,
          deliveryAddress1Controller,
          deliveryAddress2Controller,
          deliveryCountryController,
          deliveryStateController,
          deliveryCityController,
          deliveryStateCodeController,
          deliveryZipController,
          deliveryMobileController,
        ].map((c) => c.text.trim()).join('|');

    final hasAddressChange = addressSnapshot() != savedAddressSnapshot.value;

    // "Billing & Delivery" badge: the percentage the backend reports, exactly
    // as sent. No client-side math, no invented value — the API not sending it
    // means 0%.
    final billingPercent = latestProfile.billingDeliveryPercent;

    final hasUnsavedChanges = hasNonEmailChanges ||
        hasEmailChange ||
        hasPendingImage ||
        hasAddressChange;

    final selectedTab = useState<int>(0);
    final billingExpanded = useState<bool>(false);

    Future<bool> confirmDiscard() async {
      if (!hasUnsavedChanges) return true;
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(dialogContext.wp(4.1)),
            ),
            title: Text(
              'Discard changes?',
              style: _ts(16, FontWeight.w700, AppColors.textPrimary),
            ),
            content: Text(
              'You have unsaved changes. Are you sure you want to leave?',
              style: _ts(13, FontWeight.w400, AppColors.textPrimary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(
                  'Cancel',
                  style: _ts(
                    13,
                    FontWeight.w500,
                    AppColors.textPrimary.withOpacity(0.7),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(
                  'Discard',
                  style: _ts(13, FontWeight.w600, AppColors.primary),
                ),
              ),
            ],
          );
        },
      );
      return result ?? false;
    }

    // Keep the email field in sync with the server (email flow only).
    // NOTE: billing / delivery controllers are intentionally NOT synced from
    // the API any more - the user types them manually.
    useEffect(() {
      final updatedEmail = state.profile?.email ?? '';
      if (emailController.text != updatedEmail) {
        emailController.text = updatedEmail;
      }
      return null;
    }, [state.profile?.email]);

    String displayValue(String? value) {
      final trimmed = (value ?? '').trim();
      return trimmed.isEmpty ? '--' : trimmed;
    }

    final rawMobile = latestProfile.mobile;
    final mobileDisplay =
        rawMobile.startsWith('+') ? rawMobile : '+91 $rawMobile';

    Future<void> handleSave() async {
      FocusScope.of(context).unfocus();
      if (!canSaveProfile && !hasAddressChange) {
        AppSnackbar.show('No changes to save.');
        return;
      }

      final name = fullNameController.text.trim();
      final address = addressController.text.trim();
      final email =
          state.profile?.email ?? profile.email ?? emailController.text.trim();

      if (canSaveProfile) {
        if (name.isEmpty) {
          AppSnackbar.show('Please enter your full name.');
          return;
        }
        final ok = await controller.updateProfile(
          name: name,
          email: email,
          address: address,
          image: pickedImage.value,
        );
        if (!context.mounted) return;
        if (!ok) {
          AppSnackbar.show(
            ref.read(profileControllerProvider).updateErrorMessage ??
                'Failed to update profile.',
            type: AppSnackbarType.error,
          );
          return;
        }
        pickedImage.value = null;
      }

      if (hasAddressChange) {
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
        if (!ok) {
          AppSnackbar.show(
            ref.read(profileControllerProvider).updateErrorMessage ??
                'Failed to update delivery info.',
            type: AppSnackbarType.error,
          );
          return;
        }
        savedAddressSnapshot.value = addressSnapshot();
      }

      await controller.fetchProfile();
      if (!context.mounted) return;
      final refreshed = ref.read(profileControllerProvider).profile;
      initialFullNameState.value = (refreshed?.name ?? name).trim();
      initialAddressState.value = (refreshed?.address ?? address).trim();
      initialEmailState.value = (refreshed?.email ?? email).trim();
      AppSnackbar.show(
        'Profile updated successfully.',
        type: AppSnackbarType.success,
      );
    }

    // ---- Shared responsive values (percent of screen) ----
    final sidePad = context.wp(5.64);
    // Avatar identical to the My Profile header (_ProfileHeaderCard).
    final avatarBox = context.wp(10.26);

    // Fixed square box so the initials sit dead-centre of the avatar circle
    // (a bare Text sizes to its glyphs and can drift off the centre).
    Widget avatarInitials() {
      return SizedBox(
        width: avatarBox,
        height: avatarBox,
        child: Center(
          child: Text(
            profile.initials,
            textAlign: TextAlign.center,
            style: _ts(13, FontWeight.w700, _kBlue, height: 1.0),
          ),
        ),
      );
    }

    Widget avatarChild() {
      if (pickedImage.value != null) {
        return Image.file(
          pickedImage.value!,
          width: avatarBox,
          height: avatarBox,
          fit: BoxFit.cover,
        );
      }
      if (profile.profilePhotoUrl?.isNotEmpty == true) {
        return AppNetworkImage(
          url: profile.profilePhotoUrl,
          width: avatarBox,
          height: avatarBox,
          fit: BoxFit.cover,
          showShimmer: false,
          placeholder: avatarInitials(),
          errorWidget: avatarInitials(),
        );
      }
      return avatarInitials();
    }

    // Pencil icon, flush with the card's inner right edge.
    Widget editIcon(VoidCallback onTap) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SvgPicture.asset(
          FileConstants.profileEmailEditSvg,
          width: context.wp(4.36),
          height: context.wp(4.36),
        ),
      );
    }

    Widget sectionHeading(String text) {
      return Text(
        text,
        style: _ts(17, FontWeight.w500, _kTextDark, height: 1.5),
      );
    }

    Widget fieldGap() => SizedBox(height: context.hp(1.78));

    // ---------------- Tab 0 : Personal & Billing ----------------
    Widget personalAndBillingTab() {
      return SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(sidePad, 0, sidePad, context.hp(2.84)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: context.wp(3.59),
                vertical: context.hp(0.95),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(context.wp(3.08)),
                border: Border.all(color: _kCardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileInfoRow(
                    label: 'Full name (as per PAN)',
                    value: displayValue(latestProfile.name),
                    editableController: canEdit ? fullNameController : null,
                  ),
                  _ProfileInfoRow(
                    label: 'Mobile Number',
                    value: mobileDisplay,
                  ),
                  _ProfileInfoRow(
                    label: 'Email ID',
                    value: displayValue(currentEmail),
                    trailing: editIcon(() {
                      KDialog.instance.openSheet(
                        dialog: _EmailUpdateSheet(
                          currentEmail: emailController.text.trim(),
                        ),
                      );
                    }),
                  ),
                  _ProfileInfoRow(
                    label: 'Adhaar Number',
                    value: displayValue(latestProfile.aadhaarMasked),
                  ),
                  _ProfileInfoRow(
                    label: 'PAN Number',
                    value: displayValue(latestProfile.panMasked),
                  ),
                  _ProfileInfoRow(
                    label: 'Date Of Birth',
                    value: displayValue(latestProfile.dob),
                  ),
                  _ProfileInfoRow(
                    label: 'Permanent Address',
                    value: displayValue(latestProfile.permanentAddress),
                  ),
                  _ProfileInfoRow(
                    label: 'Communication Address',
                    value: currentAddress.isEmpty ? 'NA' : currentAddress,
                    trailing: editIcon(() {
                      KDialog.instance.openSheet(
                        dialog: _CommunicationAddressSheet(
                          initial: addressController.text.trim(),
                          onDone: (value) =>
                              addressController.text = value.trim(),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.hp(1.78)),
            // ---------------- Billing & Delivery (collapsible) ----------------
            InkWell(
              onTap: () => billingExpanded.value = !billingExpanded.value,
              borderRadius: BorderRadius.circular(context.wp(3.08)),
              child: Container(
                width: double.infinity,
                height: context.hp(5.69),
                padding: EdgeInsets.symmetric(horizontal: context.wp(3.59)),
                decoration: BoxDecoration(
                  color: _kSheetBg,
                  borderRadius: BorderRadius.circular(context.wp(3.08)),
                  border: Border.all(color: _kCardBorder),
                ),
                child: Row(
                  children: [
                    Text(
                      'Billing & Delivery',
                      style: _ts(14, FontWeight.w600, _kTextDark),
                    ),
                    SizedBox(width: context.wp(2.05)),
                    Container(
                      height: context.hp(2.25),
                      alignment: Alignment.center,
                      padding:
                          EdgeInsets.symmetric(horizontal: context.wp(2.05)),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(context.wp(100)),
                      ),
                      child: Text(
                        '$billingPercent%',
                        style: _ts(
                          11,
                          FontWeight.w500,
                          Colors.white,
                          height: 1.0,
                        ),
                      ),
                    ),
                    const Spacer(),
                    AnimatedRotation(
                      turns: billingExpanded.value ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: CustomPaint(
                        size: Size(context.wp(4.1), context.hp(1.0)),
                        painter: _ChevronPainter(
                          color: _kTextDark,
                          stroke: context.wp(0.56),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (billingExpanded.value) ...[
              SizedBox(height: context.hp(1.66)),
              sectionHeading('Billing Address'),
              SizedBox(height: context.hp(1.3)),
              _AddressField(
                label: 'Address Line 1',
                hint: 'Billing Address Line 1',
                controller: billingAddress1Controller,
              ),
              fieldGap(),
              _AddressField(
                label: 'Country',
                hint: 'Country',
                controller: billingCountryController,
              ),
              fieldGap(),
              _AddressField(
                label: 'State',
                hint: 'State',
                controller: billingStateController,
              ),
              fieldGap(),
              _AddressField(
                label: 'City',
                hint: 'City',
                controller: billingCityController,
              ),
              fieldGap(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _AddressField(
                      label: 'State Code',
                      hint: 'Code',
                      controller: billingStateCodeController,
                    ),
                  ),
                  SizedBox(width: context.wp(3.59)),
                  Expanded(
                    child: _AddressField(
                      label: 'ZIP Code',
                      hint: 'Code',
                      controller: billingZipController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              fieldGap(),
              _AddressField(
                label: 'Mobile Number',
                hint: '1234567890',
                controller: billingMobileController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              SizedBox(height: context.hp(1.42)),
              sectionHeading('Delivery Address'),
              SizedBox(height: context.hp(1.3)),
              _AddressField(
                label: 'Address Line 1',
                hint: 'Delivery Address Line 1',
                controller: deliveryAddress1Controller,
              ),
              fieldGap(),
              _AddressField(
                label: 'Country',
                hint: 'Country',
                controller: deliveryCountryController,
              ),
              fieldGap(),
              _AddressField(
                label: 'State',
                hint: 'State',
                controller: deliveryStateController,
              ),
              fieldGap(),
              _AddressField(
                label: 'City',
                hint: 'City',
                controller: deliveryCityController,
              ),
              fieldGap(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _AddressField(
                      label: 'State Code',
                      hint: 'Code',
                      controller: deliveryStateCodeController,
                    ),
                  ),
                  SizedBox(width: context.wp(3.59)),
                  Expanded(
                    child: _AddressField(
                      label: 'ZIP Code',
                      hint: 'Code',
                      controller: deliveryZipController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              fieldGap(),
              _AddressField(
                label: 'Mobile Number',
                hint: '1234567890',
                controller: deliveryMobileController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ],
        ),
      );
    }

    // ---------------- Tab 1 : Bank Account ----------------
    // BankAccountsSection (bank_accounts_view.dart) owns the data + actions and
    // renders the shared Figma widgets (BankEmptyState / BankAccountCard from
    // components/bank_account_tab_ui.dart). It scrolls itself, so the tab only
    // pads it — that also lets the empty state centre in the free space.
    Widget bankAccountTab() {
      return Padding(
        padding: EdgeInsets.fromLTRB(sidePad, 0, sidePad, context.hp(2.84)),
        child: isKycVerified
            ? const BankAccountsSection(padding: EdgeInsets.zero)
            : Text(
                'Please complete KYC first to manage bank details.',
                style: _ts(
                  12,
                  FontWeight.w400,
                  AppColors.textPrimary.withOpacity(0.6),
                ),
              ),
      );
    }

    final cameraBadge = context.wp(3.85);

    return _clampTextScale(
      context,
      WillPopScope(
        onWillPop: confirmDiscard,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: _kBlue,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          child: Scaffold(
            backgroundColor: _kSheetBg,
            resizeToAvoidBottomInset: true,
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
                            // Back arrow + title.
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                context.wp(4.1),
                                context.hp(0.95),
                                sidePad,
                                0,
                              ),
                              child: SizedBox(
                                height: context.hp(3.32),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () async {
                                        final okToLeave =
                                            await confirmDiscard();
                                        if (!context.mounted || !okToLeave) {
                                          return;
                                        }
                                        Navigator.of(context).pop();
                                      },
                                      child: Icon(
                                        Icons.arrow_back,
                                        color: Colors.white,
                                        size: context.wp(6.15),
                                      ),
                                    ),
                                    SizedBox(width: context.wp(2.56)),
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
                            // Avatar (orange ring) + name + phone.
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                sidePad,
                                context.hp(3.08),
                                sidePad,
                                context.hp(2.13),
                              ),
                              child: Row(
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      CircleAvatar(
                                        radius: avatarBox / 2,
                                        backgroundColor:
                                            const Color(0xFFE4E4E7),
                                        child: ClipOval(child: avatarChild()),
                                      ),
                                      // Camera badge only on the Personal tab
                                      // (not shown on the Bank Account design).
                                      if (selectedTab.value == 0)
                                        Positioned(
                                          right: -context.wp(0.26),
                                          bottom: -context.wp(0.26),
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
                                              height: cameraBadge,
                                              width: cameraBadge,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.15),
                                                    blurRadius:
                                                        context.wp(1.03),
                                                    offset: Offset(
                                                      0,
                                                      context.hp(0.12),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                Icons.camera_alt_outlined,
                                                size: context.wp(2.31),
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(width: context.wp(3.08)),
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
                                        SizedBox(height: context.hp(0.12)),
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
                              height: context.wp(5.13),
                              decoration: BoxDecoration(
                                color: _kSheetBg,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(context.wp(5.13)),
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
                            SizedBox(height: context.hp(0.24)),
                            Padding(
                              padding:
                                  EdgeInsets.symmetric(horizontal: sidePad),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _PillTab(
                                      label: 'Personal & Billing',
                                      isActive: selectedTab.value == 0,
                                      onTap: () => selectedTab.value = 0,
                                    ),
                                  ),
                                  SizedBox(width: context.wp(3.59)),
                                  Expanded(
                                    child: _PillTab(
                                      label: 'Bank Account',
                                      isActive: selectedTab.value == 1,
                                      onTap: () => selectedTab.value = 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: context.hp(1.66)),
                            Expanded(
                              child: selectedTab.value == 0
                                  ? personalAndBillingTab()
                                  : bankAccountTab(),
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
            bottomNavigationBar: selectedTab.value == 0
                ? Container(
                    color: _kSheetBg,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          sidePad,
                          context.hp(1.18),
                          sidePad,
                          context.hp(1.9),
                        ),
                        child: _PrimaryPillButton(
                          onTap: state.isUpdating ? null : handleSave,
                          label:
                              state.isUpdating ? 'Saving...' : 'Save & Update',
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet used by the pencil icon next to "Communication Address".
class _CommunicationAddressSheet extends HookWidget {
  const _CommunicationAddressSheet({
    required this.initial,
    required this.onDone,
  });

  final String initial;
  final ValueChanged<String> onDone;

  @override
  Widget build(BuildContext context) {
    final textController = useTextEditingController(text: initial);
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(context.wp(2.56)),
      borderSide: const BorderSide(color: _kFieldBorder),
    );

    return Padding(
      padding: MediaQuery.of(context).viewInsets +
          EdgeInsets.fromLTRB(
            context.wp(5.13),
            context.hp(2.37),
            context.wp(5.13),
            context.hp(2.84),
          ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Communication Address',
            style: _ts(16, FontWeight.w700, AppColors.textPrimary),
          ),
          SizedBox(height: context.hp(1.42)),
          TextField(
            controller: textController,
            maxLines: 3,
            minLines: 3,
            textCapitalization: TextCapitalization.words,
            style: _ts(13, FontWeight.w500, const Color(0xFF18181B)),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              hintText: 'Enter your communication address',
              hintStyle: _ts(13, FontWeight.w400, _kHint),
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.wp(4.62),
                vertical: context.hp(1.66),
              ),
              border: fieldBorder,
              enabledBorder: fieldBorder,
              focusedBorder: fieldBorder.copyWith(
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          SizedBox(height: context.hp(1.9)),
          _PrimaryPillButton(
            label: 'Done',
            onTap: () {
              onDone(textController.text);
              Navigator.of(context).pop();
            },
          ),
        ],
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
    final barRadius = BorderRadius.circular(context.wp(1.54));
    final iconCircle = context.wp(9.23);
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
                    width: context.wp(66.67),
                    padding: EdgeInsets.symmetric(
                      horizontal: context.wp(4.62),
                      vertical: context.hp(1.9),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(context.wp(4.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: context.wp(4.62),
                          offset: Offset(0, context.hp(1.18)),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: iconCircle,
                          width: iconCircle,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Icon(
                            Icons.cloud_upload_outlined,
                            color: AppColors.primary,
                            size: context.wp(5.13),
                          ),
                        ),
                        SizedBox(height: context.hp(1.42)),
                        Text(
                          'Updating profile',
                          style:
                              _ts(14, FontWeight.w700, AppColors.textPrimary),
                        ),
                        SizedBox(height: context.hp(0.95)),
                        Container(
                          height: context.hp(1.18),
                          width: context.wp(35.9),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: barRadius,
                          ),
                        ),
                        SizedBox(height: context.hp(0.71)),
                        Container(
                          height: context.hp(1.18),
                          width: context.wp(28.2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: barRadius,
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
          width: context.wp(10.77),
          height: context.hp(5.45),
          textStyle: _ts(16, FontWeight.w700, AppColors.textPrimary),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.wp(2.56)),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
        );

    return Padding(
      padding: MediaQuery.of(context).viewInsets +
          EdgeInsets.fromLTRB(
            context.wp(5.13),
            context.hp(2.37),
            context.wp(5.13),
            context.hp(2.84),
          ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Change Email',
            style: _ts(16, FontWeight.w700, AppColors.textPrimary),
          ),
          SizedBox(height: context.hp(1.42)),
          Text(
            'Current email: $currentEmail',
            style: _ts(
              13,
              FontWeight.w400,
              AppColors.textPrimary.withOpacity(0.7),
            ),
          ),
          SizedBox(height: context.hp(1.42)),
          CustomTextField(
            labelText: 'New Email',
            enabled: true,
            textEditingController: emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: context.hp(1.42)),
          if (!otpSent.value)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSending.value ? null : sendOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.wp(3.08)),
                  ),
                  padding: EdgeInsets.symmetric(vertical: context.hp(1.42)),
                  elevation: 0,
                ),
                child: isSending.value
                    ? Center(
                        child: SpinKitCircle(
                          color: AppColors.primary,
                          size: context.wp(12.31),
                        ),
                      )
                    : Text(
                        'Send OTP',
                        style: _ts(14, FontWeight.w700, Colors.white),
                      ),
              ),
            ),
          if (otpSent.value) ...[
            SizedBox(height: context.hp(2.37)),
            Text(
              'Enter OTP',
              style: _ts(13, FontWeight.w600, AppColors.textPrimary),
            ),
            SizedBox(height: context.hp(1.18)),
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
            SizedBox(height: context.hp(1.9)),
            Row(
              children: [
                TextButton(
                  onPressed: isSending.value ? null : sendOtp,
                  child: Text(
                    'Resend OTP',
                    style: _ts(13, FontWeight.w700, AppColors.primary),
                  ),
                ),
                const Spacer(),
                CustomElevatedButton(
                  onPressed: isVerifying.value ? null : verifyOtp,
                  label: isVerifying.value ? 'Saving...' : 'Update',
                  showArrow: false,
                  width: context.wp(35.9),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
