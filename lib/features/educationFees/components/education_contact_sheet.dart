import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../services/permission_service.dart';
import '../../../widgets/app_search_bar.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/search_textfield.dart';
import '../../mobile_prepaid/controllers/contacts_cache_controller.dart';

List<int> _filterContactIndices(Map<String, dynamic> payload) {
  final rawEntries = payload['entries'] as List<dynamic>? ?? const [];
  final query = (payload['query'] as String? ?? '').toLowerCase();
  if (rawEntries.isEmpty) return const [];
  if (query.isEmpty) {
    return List<int>.generate(rawEntries.length, (index) => index);
  }
  final matches = <int>[];
  for (var i = 0; i < rawEntries.length; i++) {
    final entry = rawEntries[i] as Map;
    final name = (entry['name'] as String? ?? '');
    final phone = (entry['phone'] as String? ?? '');
    if (name.contains(query) || phone.contains(query)) {
      matches.add(i);
    }
  }
  return matches;
}

String normalizeEducationMobile(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.length > 10 && digits.startsWith('91')) {
    return digits.substring(digits.length - 10);
  }
  return digits;
}

String educationContactDisplayPhone(String phone) {
  final normalized = normalizeEducationMobile(phone);
  if (normalized.length == 10) {
    return '+91$normalized';
  }
  return phone;
}

typedef EducationContactPickedHandler = void Function(
  String mobile,
  String displayName,
);

class EducationContactSheet extends HookConsumerWidget {
  const EducationContactSheet({
    super.key,
    required this.onSelect,
    this.onContactPicked,
    this.closeOnSelect = true,
    this.searchHint = 'Search contacts',
    this.matchInviteContactAvatarStyle = false,
    this.searchRecipientLayout = false,
  });

  final ValueChanged<String> onSelect;
  final EducationContactPickedHandler? onContactPicked;
  final bool closeOnSelect;
  final String searchHint;
  final bool matchInviteContactAvatarStyle;
  final bool searchRecipientLayout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionService = useMemoized(() => const PermissionService());
    final hasPermission = useState(false);
    final contactsState = ref.watch(contactsCacheControllerProvider);
    final contactsController =
        ref.read(contactsCacheControllerProvider.notifier);
    final filteredContacts = useState<List<Contact>>([]);
    final visibleCount = useState(100);
    final contactQuery = useState('');
    final contactSearchController = useTextEditingController();
    final isMounted = useIsMounted();
    final filterToken = useRef(0);

    Future<void> loadContacts() async {
      await contactsController.fetchIfNeeded();
    }

    useEffect(() {
      Future.microtask(() async {
        final granted = await permissionService.hasContactsPermission();
        if (!isMounted()) return;
        hasPermission.value = granted;
        if (granted) {
          await loadContacts();
        }
      });
      return null;
    }, const []);

    useEffect(() {
      if (contactSearchController.text != contactQuery.value) {
        contactSearchController.text = contactQuery.value;
      }
      return null;
    }, [contactQuery.value]);

    Future<void> rebuildFilteredContacts() async {
      final entries = contactsState.searchIndex;
      if (entries.isEmpty) {
        filteredContacts.value = [];
        return;
      }
      final token = ++filterToken.value;
      final query = contactQuery.value.trim().toLowerCase();
      final indices = await compute(
        _filterContactIndices,
        <String, dynamic>{
          'entries': entries,
          'query': query,
        },
      );
      if (!isMounted() || token != filterToken.value) return;
      filteredContacts.value = [
        for (final i in indices)
          if (i >= 0 && i < contactsState.contacts.length)
            contactsState.contacts[i],
      ];
      visibleCount.value = 100;
    }

    useEffect(() {
      Future.microtask(rebuildFilteredContacts);
      return null;
    }, [contactQuery.value, contactsState.searchIndex]);

    Future<void> handleRequestPermission() async {
      final granted = await permissionService.requestContacts();
      if (!isMounted()) return;
      hasPermission.value = granted;
      if (granted) {
        await contactsController.reload();
      }
    }

    final onPickContact = (String mobile, String displayName) {
      if (onContactPicked != null) {
        onContactPicked!(mobile, displayName);
      } else {
        onSelect(mobile);
      }
      if (closeOnSelect) {
        Navigator.of(context).maybePop();
      }
    };

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          top: searchRecipientLayout ? 8.h : 12.h,
          bottom: 16.h,
        ),
        child: hasPermission.value
            ? _ContactsListSection(
                isLoading: contactsState.isLoading,
                contacts: filteredContacts.value,
                visibleCount: visibleCount.value,
                contactSearchController: contactSearchController,
                onQueryChange: (value) => contactQuery.value = value,
                onLoadMore: () {
                  if (visibleCount.value >= filteredContacts.value.length) {
                    return;
                  }
                  visibleCount.value =
                      (visibleCount.value + 100).clamp(0, 999999);
                },
                searchHint: searchHint,
                onSelect: onPickContact,
                matchInviteContactAvatarStyle: matchInviteContactAvatarStyle,
                searchRecipientLayout: searchRecipientLayout,
              )
            : _PermissionEmptyState(onAllow: handleRequestPermission),
      ),
    );
  }
}

class _PermissionEmptyState extends StatelessWidget {
  const _PermissionEmptyState({required this.onAllow});

  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isSmallScreen = screenWidth < 360;
    final iconSize = isSmallScreen ? 100.r : 120.r;
    final iconInnerSize = isSmallScreen ? 48.r : 58.r;
    final titleFontSize = isSmallScreen ? 16.sp : 18.sp;
    final descFontSize = isSmallScreen ? 13.sp : 14.sp;
    final buttonHeight = isSmallScreen ? 44.h : 48.h;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: screenWidth * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 20.h),
            Container(
              height: iconSize,
              width: iconSize,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.phone_in_talk_outlined,
                  color: AppColors.primary,
                  size: iconInnerSize,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Provide Access To Contacts',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: titleFontSize,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'We need this to pick a recipient.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textPrimary.withOpacity(0.6),
                fontSize: descFontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 18.h),
            CustomElevatedButton(
              onPressed: onAllow,
              label: 'Allow Contact Access',
              uppercaseLabel: true,
              height: buttonHeight,
              backgroundColor: const Color(0xFFDD5428),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactsListSection extends StatelessWidget {
  const _ContactsListSection({
    required this.isLoading,
    required this.contacts,
    required this.visibleCount,
    required this.contactSearchController,
    required this.onQueryChange,
    required this.onLoadMore,
    required this.onSelect,
    required this.searchHint,
    required this.matchInviteContactAvatarStyle,
    required this.searchRecipientLayout,
  });

  final bool isLoading;
  final List<Contact> contacts;
  final int visibleCount;
  final TextEditingController contactSearchController;
  final ValueChanged<String> onQueryChange;
  final VoidCallback onLoadMore;
  final void Function(String mobile, String displayName) onSelect;
  final String searchHint;
  final bool matchInviteContactAvatarStyle;
  final bool searchRecipientLayout;

  Widget _buildContactBody(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: SpinKitCircle(
          color: AppColors.primary,
          size: 48,
        ),
      );
    }
    if (contacts.isEmpty) {
      return Center(
        child: Text(
          'No contacts found',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary.withOpacity(0.6),
              ),
        ),
      );
    }
    return _ContactsList(
      contacts: contacts,
      visibleCount: visibleCount,
      onSelect: onSelect,
      matchInviteContactAvatarStyle: matchInviteContactAvatarStyle,
      searchRecipientLayout: searchRecipientLayout,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (searchRecipientLayout) {
      return NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent - 200) {
            onLoadMore();
          }
          return false;
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSearchBar(
              // Common bar styling (same defaults as the credit card
              // listing search); only the leading glyph is Education's own.
              hintText: searchHint,
              controller: contactSearchController,
              onChanged: onQueryChange,
              showSearchIcon: false,
              prefixIcon: Padding(
                padding: EdgeInsets.only(left: 14.w, right: 4.w),
                child: SvgPicture.asset(
                  FileConstants.educationSearchIconSvg,
                  width: 18.w,
                  height: 18.w,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Expanded(child: _buildContactBody(context)),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
          onLoadMore();
        }
        return false;
      },
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(
            'Contacts',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          SizedBox(height: 10.h),
          SearchTextfield(
            hintText: searchHint,
            controller: contactSearchController,
            onChange: onQueryChange,
          ),
          SizedBox(height: 12.h),
          if (isLoading)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: const Center(
                child: SpinKitCircle(
                  color: AppColors.primary,
                  size: 48,
                ),
              ),
            )
          else if (contacts.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Center(
                child: Text(
                  'No contacts found',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary.withOpacity(0.6),
                      ),
                ),
              ),
            )
          else
            _ContactsList(
              contacts: contacts,
              visibleCount: visibleCount,
              onSelect: onSelect,
              matchInviteContactAvatarStyle: matchInviteContactAvatarStyle,
              searchRecipientLayout: false,
            ),
        ],
      ),
    );
  }
}

class _ContactsList extends StatelessWidget {
  const _ContactsList({
    required this.contacts,
    required this.visibleCount,
    required this.onSelect,
    required this.matchInviteContactAvatarStyle,
    required this.searchRecipientLayout,
  });

  final List<Contact> contacts;
  final int visibleCount;
  final void Function(String mobile, String displayName) onSelect;
  final bool matchInviteContactAvatarStyle;
  final bool searchRecipientLayout;

  @override
  Widget build(BuildContext context) {
    final displayContacts = contacts.length > visibleCount
        ? contacts.take(visibleCount).toList()
        : contacts;
    final flatList = searchRecipientLayout;
    return ListView.separated(
      shrinkWrap: !flatList,
      physics: flatList
          ? const AlwaysScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      itemCount: displayContacts.length,
      separatorBuilder: (_, __) => SizedBox(height: flatList ? 20.h : 8.h),
      itemBuilder: (context, index) {
        final contact = displayContacts[index];
        final phone =
            contact.phones.isNotEmpty ? contact.phones.first.number : '';
        final initials = contact.displayName.isNotEmpty
            ? contact.displayName
                .trim()
                .split(' ')
                .where((part) => part.isNotEmpty)
                .map((e) => e[0])
                .take(2)
                .join()
            : '';
        final useInviteStyle =
            matchInviteContactAvatarStyle || searchRecipientLayout;
        final avatarBg = useInviteStyle
            ? const Color(0xFFFFEFE7)
            : AppColors.primary.withOpacity(0.1);
        final initialsColor =
            useInviteStyle ? const Color(0xFFDD5428) : AppColors.primary;

        final row = Row(
          children: [
            CircleAvatar(
              radius: useInviteStyle ? 24.r : 18.r,
              backgroundColor: avatarBg,
              child: Text(
                initials.toUpperCase(),
                style: useInviteStyle
                    ? GoogleFonts.plusJakartaSans(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: initialsColor,
                      )
                    : Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: initialsColor,
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
                    contact.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: searchRecipientLayout
                        ? GoogleFonts.plusJakartaSans(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF18181B),
                          )
                        : Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    searchRecipientLayout
                        ? educationContactDisplayPhone(phone)
                        : phone,
                    style: searchRecipientLayout
                        ? GoogleFonts.plusJakartaSans(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF52525B),
                          )
                        : Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary.withOpacity(0.6),
                            ),
                  ),
                ],
              ),
            ),
          ],
        );

        return InkWell(
          onTap: phone.isEmpty
              ? null
              : () => onSelect(
                    normalizeEducationMobile(phone),
                    contact.displayName,
                  ),
          child: flatList
              ? row
              : Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: AppColors.lightBorder),
                  ),
                  child: row,
                ),
        );
      },
    );
  }
}
