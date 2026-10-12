// ignore_for_file: deprecated_member_use

import 'package:e_rupaiya/features/refer_and_earn/services/referral_share_service.dart';
import 'package:e_rupaiya/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../services/permission_service.dart';
import '../../educationFees/components/education_contact_sheet.dart';
import '../../mobile_prepaid/controllers/contacts_cache_controller.dart';
import '../components/refer_and_earn_app_bar.dart';
import '../components/referral_share_actions.dart';
import 'referral_works_view.dart';
import 'track_referrals_view.dart';

// The Figma frame for this screen is 440 x 956 while ScreenUtil's design size
// is 360 x 690. Figma pixel values are converted once here and then scaled
// exactly once by ScreenUtil (never both), so a 440-wide phone renders the
// Figma pixel size and every other width scales proportionally.
double _figmaW(double px) => (px * 360 / 440).w;
double _figmaH(double px) => (px * 690 / 956).h;
double _figmaR(double px) => (px * 360 / 440).r;

/// Horizontal padding of the white content panel; the divider behind the
/// "My Referral Earnings" pill bleeds by exactly this amount.
double get _panelPadH => _figmaW(21);

/// Height the white panel pulls up over the hero; matches the white strip
/// drawn by [ReferAndEarnAppBar] (36.h + 1) so no background peeks through.
double get _heroOverlap => 37.h;

/// Diagonal arrow used by both blue feature cards (verbatim Figma export).
const String _cardArrowSvg = '''
<svg width="57" height="57" viewBox="0 0 57 57" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M27.2322 17.0934L41.6464 21.4612L37.2786 35.8754" stroke="white" stroke-width="1.5" stroke-miterlimit="10" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M15.3454 35.5309L41.3834 21.6034" stroke="white" stroke-width="1.5" stroke-miterlimit="10" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

class ReferAndEarnView extends HookConsumerWidget {
  const ReferAndEarnView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsState = ref.watch(contactsCacheControllerProvider);
    final contactsController =
        ref.read(contactsCacheControllerProvider.notifier);
    final permissionService = useMemoized(() => const PermissionService());
    final hasPermission = useState<bool?>(null);
    final showInviteContacts =
        hasPermission.value == true && contactsState.contacts.isNotEmpty;

    useEffect(() {
      Future<void> load() async {
        final granted = await permissionService.hasContactsPermission();
        hasPermission.value = granted;
        if (!granted) {
          final requested = await permissionService.requestContacts();
          hasPermission.value = requested;
        }
        if (hasPermission.value == true) {
          await contactsController.fetchIfNeeded();
        }
      }

      load();
      return null;
    }, const []);

    // Figma: the white panel starts 356 design-px below the status bar.
    final heroHeight =
        MediaQuery.paddingOf(context).top + _figmaH(356) + _heroOverlap;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFBF3EE),
          border: Border(top: BorderSide(color: Color(0x14000000))),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              _panelPadH,
              _figmaH(12),
              _panelPadH,
              _figmaH(14),
            ),
            child: const ReferralShareActions(),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ReferAndEarnAppBar(
              title: 'Refer Friends & Earn Coins',
              height: heroHeight,
              body: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Earn E-Coins Lifetime',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 20.sp,
                        ),
                  ),
                  SizedBox(height: _figmaH(26)),
                  // Width-driven so the illustration keeps its native
                  // aspect ratio; Flexible lets it shrink on short screens.
                  Flexible(
                    child: Image.asset(
                      FileConstants.referAndEarn,
                      width: _figmaW(300),
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: Offset(0, -_heroOverlap),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(_figmaR(26)),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    _panelPadH,
                    _figmaH(20),
                    _panelPadH,
                    _figmaH(28),
                  ),
                  child: Column(
                    children: [
                      _ReferSummarySection(),
                      SizedBox(height: _figmaH(26)),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionMiniCard(
                              title: 'Track Your\nReferrals',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const TrackReferralsView(),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(width: _figmaW(14)),
                          Expanded(
                            child: _ActionMiniCard(
                              title: 'How It\nWorks ?',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ReferralWorksView(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      if (showInviteContacts) ...[
                        SizedBox(height: _figmaH(30)),
                        const _SectionTitle('Invite Contacts'),
                        SizedBox(height: _figmaH(16)),
                        _ContactsRow(
                          contacts: contactsState.contacts,
                          onInviteTap: () => _openContactSheet(context),
                        ),
                      ],
                      SizedBox(height: _figmaH(24)),
                      _ReferForeverCard(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openContactSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20.r),
        ),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: FractionallySizedBox(
          heightFactor: 0.9,
          child: EducationContactSheet(
            onSelect: (phone) {
              ReferralShareService.shareSMS(
                context,
                phone: phone,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ReferSummarySection extends HookWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Refer & Earn Lifetime',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16.sp,
              ),
        ),
        SizedBox(height: _figmaH(8)),
        Text(
          'Refer Once, Earn Rewards For A Lifetime.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary.withOpacity(0.6),
                fontSize: 14.sp,
              ),
        ),
        SizedBox(height: _figmaH(22)),
        // Figma: a hairline runs edge to edge behind the pill, crossing it
        // through its vertical centre.
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -_panelPadH,
              right: -_panelPadH,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  height: 1,
                  width: double.infinity,
                  color: AppColors.lightBorder.withOpacity(0.6),
                ),
              ),
            ),
            _PrimaryPillButton(
              label: 'My Referral Earnings',
              onTap: () {
                context.push(RouteConstants.referAndEarnWallet);
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _PrimaryPillButton extends HookWidget {
  const _PrimaryPillButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _figmaW(26),
          vertical: _figmaH(16),
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0C5AA6), Color(0xFF154A8C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(_figmaR(30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              FileConstants.coin_3d,
              width: _figmaW(24),
              height: _figmaW(24),
            ),
            SizedBox(width: _figmaW(10)),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15.sp,
                    ),
              ),
            ),
            SizedBox(width: _figmaW(12)),
            Icon(
              Icons.arrow_outward,
              color: Colors.white,
              size: _figmaR(18),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionMiniCard extends HookWidget {
  const _ActionMiniCard({required this.title, this.onTap});

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_figmaR(16)),
      child: Container(
        height: _figmaH(110),
        padding: EdgeInsets.symmetric(horizontal: _figmaW(18)),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2C64A5), Color(0xFF154A8C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(_figmaR(16)),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                maxLines: 2,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15.sp,
                    ),
              ),
            ),
            // Figma: the thin diagonal arrow sits in the bottom-right corner.
            Positioned(
              right: _figmaW(12),
              bottom: _figmaH(14),
              child: SvgPicture.string(
                _cardArrowSvg,
                width: _figmaW(40),
                height: _figmaW(40),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends HookWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: 17.sp,
            ),
      ),
    );
  }
}

/// Figma row: up to three real contacts plus an "Invite Contact" tile that
/// opens the full contact sheet (replaces the old "View all" link).
class _ContactsRow extends HookWidget {
  const _ContactsRow({required this.contacts, required this.onInviteTap});

  final List<Contact> contacts;
  final VoidCallback onInviteTap;

  @override
  Widget build(BuildContext context) {
    final visible = contacts.take(3).toList();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final contact in visible)
          Expanded(
            child: _ContactTile(
              name: contact.displayName,
              onTap: () {
                if (contact.phones.isEmpty) {
                  AppSnackbar.show('No phone number found');
                  return;
                }
                ReferralShareService.shareSMS(
                  context,
                  phone: contact.phones.first.number,
                );
              },
            ),
          ),
        Expanded(
          child: _ContactTile(
            name: 'Invite Contact',
            isInvite: true,
            onTap: onInviteTap,
          ),
        ),
      ],
    );
  }
}

class _ContactTile extends HookWidget {
  const _ContactTile({
    required this.name,
    required this.onTap,
    this.isInvite = false,
  });

  final String name;
  final VoidCallback onTap;
  final bool isInvite;

  String get _initials => name
      .split(' ')
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((e) => e[0])
      .join();

  @override
  Widget build(BuildContext context) {
    final circleSize = _figmaW(50);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: circleSize,
            height: circleSize,
            decoration: const BoxDecoration(
              color: Color(0xFFD9D9D9),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isInvite
                  ? Icon(
                      Icons.person_add_alt,
                      color: Colors.white,
                      size: _figmaR(24),
                    )
                  : Text(
                      _initials.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12.sp,
                            color: AppColors.textPrimary.withOpacity(0.55),
                          ),
                    ),
            ),
          ),
          SizedBox(height: _figmaH(10)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: _figmaW(3)),
            child: Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 12.sp,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferForeverCard extends HookWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: _figmaW(16),
        vertical: _figmaH(14),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFDEFE8),
        borderRadius: BorderRadius.circular(_figmaR(16)),
      ),
      child: Column(
        children: [
          Text(
            // Figma typography: Bold 700, 14px, 28px line-height (200%),
            // 0% letter-spacing, centred, capitalised.
            'Refer Once, Earn Forever',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.sp,
                  height: 28 / 14,
                ),
          ),
          SizedBox(height: _figmaH(4)),
          Text(
            // Figma typography: Regular 400, 12px, 25px line-height,
            // 0% letter-spacing, centred, capitalised.
            'Refer Once And Earn Coins Every Time Your Friend Spends In '
            'The App. Use Your Coins Like Real Money For Payments Anytime.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.7),
                  fontWeight: FontWeight.w400,
                  fontSize: 12.sp,
                  height: 25 / 12,
                ),
          ),
        ],
      ),
    );
  }
}
