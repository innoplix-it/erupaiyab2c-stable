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

import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../services/permission_service.dart';
import '../../educationFees/components/education_contact_sheet.dart';
import '../../mobile_prepaid/controllers/contacts_cache_controller.dart';
import '../components/refer_and_earn_app_bar.dart';
import '../components/referral_share_actions.dart';
import 'referral_works_view.dart';
import 'track_referrals_view.dart';

double _figmaW(double px) => (px * 360 / 440).w;
double _figmaH(double px) => (px * 690 / 956).h;
double _figmaR(double px) => (px * 360 / 440).r;
double _figmaSp(double px) => (px * 360 / 440).sp;


const Color _kOrange = Color(0xFFE85A2C);

String _capitalizeWords(String text) => text
    .split(' ')
    .map((word) =>
word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
    .join(' ');

String _initialsFor(String name) {
  final words =
      name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '';
  if (words.length == 1) return words.first[0].toUpperCase();
  return '${words.first[0]}${words.last[0]}'.toUpperCase();
}

double get _panelPadH => _figmaW(16);

double get _heroOverlap => 37.h;

double get _illustrationOverlap => _figmaH(10);

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

    final heroHeight =
        MediaQuery.paddingOf(context).top + _figmaH(260) + _heroOverlap;

    return Scaffold(
      backgroundColor: Colors.white,

      bottomNavigationBar: const ReferralShareFooter(),
      body: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ReferAndEarnAppBar(
                title: 'Refer Friends & Earn Coins',
                height: heroHeight,
                bottomReserve: _heroOverlap - _illustrationOverlap,
                titleStyle: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: _figmaSp(19),
                  letterSpacing: 0,
                ),
                body: Column(
                  children: [
                    SizedBox(height: _figmaH(12)),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: _figmaW(317)),
                          child: AspectRatio(
                            aspectRatio: 317 / 164,
                            child: SvgPicture.asset(
                              key: const ValueKey('refer-earn-hero'),
                              FileConstants.referEarnHeroSvg,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: heroHeight - _heroOverlap),
                child: Container(
                  key: const ValueKey('refer-earn-panel'),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(_figmaR(26)),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: _figmaH(28),
                      bottom: _figmaH(30),
                    ),
                    child: Column(
                      children: [
                        _PanelPadding(child: _ReferSummarySection()),
                        SizedBox(height: _figmaH(27)),
                        _PanelPadding(
                          child: Row(
                            children: [
                              Expanded(
                                child: _ActionMiniCard(
                                  title: 'Track Your\nReferrals',
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                        const TrackReferralsView(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(width: _figmaW(15)),
                              Expanded(
                                child: _ActionMiniCard(
                                  title: 'How It\nWorks ?',
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                        const ReferralWorksView(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (showInviteContacts) ...[
                          SizedBox(height: _figmaH(28)),
                          _PanelPadding(
                            child: _InviteContactsHeader(
                              onViewAll: () => _openContactSheet(context),
                            ),
                          ),
                          SizedBox(height: _figmaH(27)),

                          _ContactsRow(
                            contacts: contactsState.contacts,
                            onInviteTap: () => _openContactSheet(context),
                          ),
                        ],
                        SizedBox(height: _figmaH(29)),
                        _ReferForeverCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
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
class _PanelPadding extends HookWidget {
  const _PanelPadding({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _panelPadH),
      child: child,
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
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: _figmaSp(21),
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: _figmaH(10)),
        Text(
          'Refer Once, Earn Rewards For A Lifetime.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.black.withOpacity(0.55),
            fontWeight: FontWeight.w400,
            fontSize: _figmaSp(14),
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: _figmaH(26)),
        // Figma: a hairline runs edge to edge behind the pill, crossing it
        // through its vertical centre. The full-width SizedBox makes the
        // Stack as wide as the panel content, so the Positioned line can
        // bleed by exactly the panel padding on both sides.
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
                  color: const Color(0xFFE6E6E6),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: Center(
                child: _PrimaryPillButton(
                  label: 'My Referral Earnings',
                  onTap: () {
                    context.push(RouteConstants.referAndEarnWallet);
                  },
                ),
              ),
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
        padding: EdgeInsets.fromLTRB(
          _figmaW(24),
          _figmaH(12),
          _figmaW(22),
          _figmaH(12),
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF06458F), Color(0xFF053C80)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(_figmaR(40)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              FileConstants.coin_3d,
              width: _figmaW(25),
              height: _figmaW(25),
            ),
            SizedBox(width: _figmaW(10)),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: _figmaSp(15.5),
                  letterSpacing: 0,
                ),
              ),
            ),
            SizedBox(width: _figmaW(3)),
            SvgPicture.string(
              _cardArrowSvg,
              width: _figmaW(30),
              height: _figmaW(30),
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
        height: _figmaH(114),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2F68B0), Color(0xFF1B3A66)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(_figmaR(16)),
        ),
        child: Stack(
          children: [
            // Figma: the title sits in the lower-left of the card.
            Positioned(
              left: _figmaW(22),
              bottom: _figmaH(18),
              child: Text(
                title,
                maxLines: 2,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: _figmaSp(16),
                  height: 1.3,
                  letterSpacing: 0,
                ),
              ),
            ),
            // Figma: the thin diagonal arrow sits in the bottom-right corner.
            Positioned(
              right: _figmaW(12),
              bottom: _figmaH(4),
              child: SvgPicture.string(
                _cardArrowSvg,
                width: _figmaW(57),
                height: _figmaW(57),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Invite Contacts" title on the left and the "View all" link on the right.
/// "View all" opens the full contact sheet.
class _InviteContactsHeader extends HookWidget {
  const _InviteContactsHeader({required this.onViewAll});

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            'Invite Contacts',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: _figmaSp(16),
              letterSpacing: 0,
            ),
          ),
        ),
        GestureDetector(
          onTap: onViewAll,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            // Larger tap area without changing the visual position.
            padding: EdgeInsets.symmetric(
              vertical: _figmaH(6),
              horizontal: _figmaW(4),
            ),
            child: Text(
              'View all',
              maxLines: 1,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _kOrange,
                fontWeight: FontWeight.w600,
                fontSize: _figmaSp(14),
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Figma row: up to three real contacts plus an "Invite Contact" tile that
/// opens the full contact sheet.
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

/// Grey circle (Figma 50) with the contact's dynamic initials centred in
/// it, and the name below. Name typography from Figma: SemiBold 600, 10px,
/// line-height 100%, 0% letter-spacing, centred, capitalised, #000000.
/// The invite tile keeps the plain circle (it is not a real contact).
class _ContactTile extends HookWidget {
  const _ContactTile({
    required this.name,
    required this.onTap,
    this.isInvite = false,
  });

  final String name;
  final VoidCallback onTap;
  final bool isInvite;

  @override
  Widget build(BuildContext context) {
    final circleSize = _figmaW(50);
    final initials = isInvite ? '' : _initialsFor(name);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: circleSize,
            height: circleSize,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0x26DD5428),
              shape: BoxShape.circle,
            ),
            child: initials.isEmpty
                ? null
                : Text(
              initials,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFFDD5428),
                fontWeight: FontWeight.w600,
                fontSize: _figmaSp(15),
                height: 1.0,
                letterSpacing: 0,
              ),
            ),
          ),
          SizedBox(height: _figmaH(11)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: _figmaW(18)),
            child: Text(
              _capitalizeWords(name),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF000000),
                fontWeight: FontWeight.w600,
                fontSize: _figmaSp(10),
                height: 1.0,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Figma: full bleed, ~173 high. Padding top 31 / bottom 29 / sides 16, with
/// 9 between the 28px-line title and the 25px-line body (three lines).
class _ReferForeverCard extends HookWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        _figmaW(16),
        _figmaH(31),
        _figmaW(16),
        _figmaH(29),
      ),
      color: const Color(0xFFFDF3EF),
      child: Column(
        children: [
          Text(
            // Figma: 600 weight, 28px line-height, 0% letter-spacing,
            // centred, capitalised.
            'Refer Once, Earn Forever',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: _figmaSp(16),
              height: 28 / 16,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: _figmaH(9)),
          Text(
            // Figma: Regular 400, 25px line-height, 0% letter-spacing,
            // centred, capitalised.
            'Refer Once And Earn Coins Every Time Your Friend Spends In '
                'The App. Use Your Coins Like Real Money For Payments Anytime.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w400,
              fontSize: _figmaSp(14),
              height: 25 / 14,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}