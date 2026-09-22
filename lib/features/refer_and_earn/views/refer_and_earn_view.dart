// ignore_for_file: deprecated_member_use

import 'package:e_rupaiya/features/refer_and_earn/services/referral_share_service.dart';
import 'package:e_rupaiya/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
          child: const ReferralShareActions(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ReferAndEarnAppBar(
              title: 'Refer Friends & Earn Coins',
              onHelp: () {},
              body: Column(
                children: [
                  SizedBox(height: 46.h),
                  Text(
                    'Earn E-Coins Lifetime',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  SizedBox(height: 10.h),
                  Image.asset(
                    FileConstants.referAndEarn,
                    height: 100.h,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: Offset(0, -100.h),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(26.r),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                  child: Column(
                    children: [
                      _ReferSummarySection(),
                      SizedBox(height: 14.h),
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
                          SizedBox(width: 12.w),
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
                        SizedBox(height: 18.h),
                        Row(
                          children: [
                            const Expanded(
                              child: _SectionTitle('Invite Contacts'),
                            ),
                            TextButton(
                              onPressed: () {
                                showModalBottomSheet<void>(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20.r),
                                    ),
                                  ),
                                  builder: (_) => FractionallySizedBox(
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
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: EdgeInsets.symmetric(horizontal: 4.w),
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'View all',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        _ContactsStrip(
                          contacts: contactsState.contacts,
                        ),
                      ],
                      SizedBox(height: 16.h),
                      _ReferForeverCard(),
                      SizedBox(height: 2.h),
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
}

class _ReferSummarySection extends HookWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Refer & Earn Lifetime',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        SizedBox(height: 6.h),
        Text(
          'Refer Once, Earn Rewards For A Lifetime.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary.withOpacity(0.6),
              ),
        ),
        SizedBox(height: 12.h),
        Container(
          height: 1,
          width: double.infinity,
          color: AppColors.lightBorder.withOpacity(0.6),
        ),
        SizedBox(height: 12.h),
        _PrimaryPillButton(
          label: 'My Referral Earnings',
          onTap: () {
            context.push(RouteConstants.referAndEarnWallet);
          },
        ),
      ],
    );
  }
}

class _ContactsStrip extends HookWidget {
  const _ContactsStrip({
    required this.contacts,
  });

  final List<Contact> contacts;

  @override
  Widget build(BuildContext context) {
    final items = contacts.take(6).toList();
    return SizedBox(height: 84.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(width: 14.w),
        itemBuilder: (context, index) {
          final item = items[index];

          if (item is Contact) {
            return GestureDetector(
              onTap: () {
                if (item.phones.isEmpty) {
                  AppSnackbar.show('No phone number found');
                  return;
                }

                final phone = item.phones.first.number;

                ReferralShareService.shareSMS(
                  context,
                  phone: phone,
                );
              },
              child: _ContactAvatar(
                item: _ContactItem(name: item.displayName),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
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
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0C5AA6), Color(0xFF154A8C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Image.asset(
                FileConstants.coin_3d,
                width: 20.w,
                height: 20.w,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(width: 8.w),
            Icon(Icons.arrow_forward, color: Colors.white, size: 16.r),
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
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        height: 74.h,
        padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2C64A5), Color(0xFF154A8C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Icon(Icons.arrow_forward, color: Colors.white, size: 18.r),
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
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _ContactItem {
  const _ContactItem({required this.name});

  final String name;
}

class _ContactAvatar extends HookWidget {
  const _ContactAvatar({required this.item});

  final _ContactItem item;

  @override
  Widget build(BuildContext context) {
    final initials = item.name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((e) => e[0])
        .join();
    return Column(
      children: [
        CircleAvatar(
          radius: 26.r,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            initials.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
          ),
        ),
        SizedBox(height: 6.h),
        SizedBox(width: 70.w,
          child: Text(
            item.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
        ),
      ],
    );
  }
}

class _ReferForeverCard extends HookWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFDEFE8),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Text(
            'Refer Once, Earn Forever',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Refer Once And Earn Coins Every Time Your Friend Spends In\n'
            'The App. Use Your Coins Like Real Money For Payments\n'
            'Anytime.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.7),
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}
