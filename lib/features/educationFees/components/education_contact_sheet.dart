import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../widgets/app_search_mode_toggle.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/contacts_permission_card.dart';
import '../../../widgets/search_textfield.dart';
import '../../auth/components/auth_step_parts.dart';
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

/// Search-field modes of the search-recipient layout, mirroring the Mobile
/// Prepaid ABC / 123 switch: ABC filters the contact list by name or number,
/// 123 takes a manually typed +91 number and continues with it.
enum _EducationContactSearchMode { abc, numeric }

/// ABC mode stays free-text for name search, but a typed number never grows
/// past 10 digits: extra digits are dropped, whether typed one by one or
/// pasted in bulk.
class _TenDigitNumberFormatter extends TextInputFormatter {
  static final RegExp _digit = RegExp(r'\d');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 10) return newValue;
    // Keep every non-digit and only the first 10 digits.
    final kept = StringBuffer();
    var seen = 0;
    for (final char in newValue.text.split('')) {
      if (_digit.hasMatch(char)) {
        seen++;
        if (seen > 10) continue;
      }
      kept.write(char);
    }
    final text = kept.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

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

    // ABC / 123 state for the search-recipient layout (Mobile Prepaid UI).
    final searchMode = useState(_EducationContactSearchMode.abc);
    final numericController = useTextEditingController();
    final numericFocusNode = useFocusNode();

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

    // Lookup in the whole device list (not the filtered view) by 10-digit no.
    Contact? contactForMobile(String mobile) {
      for (final contact in contactsState.contacts) {
        for (final phone in contact.phones) {
          if (normalizeEducationMobile(phone.number) == mobile) {
            return contact;
          }
        }
      }
      return null;
    }

    // 123 mode: continue with the typed number. It goes through the very same
    // picked-contact path, so the app-bar Verified / Unverified selector still
    // decides which tutor flow runs after the verification overlay.
    void handleNumericContinue() {
      final mobile = normalizeEducationMobile(numericController.text);
      if (mobile.length != 10) return;
      onPickContact(mobile, contactForMobile(mobile)?.displayName ?? '');
    }

    // ABC mode: a 10-digit number that has no contact jumps to 123 on its own,
    // which reveals the Continue button and then runs the identical flow.
    void handleQueryChange(String value) {
      contactQuery.value = value;
      if (!searchRecipientLayout) return;
      if (RegExp(r'[A-Za-z]').hasMatch(value)) return;
      final digits = normalizeEducationMobile(value);
      if (digits.length != 10) return;
      if (contactForMobile(digits) != null) return;
      searchMode.value = _EducationContactSearchMode.numeric;
      numericController.value = TextEditingValue(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
      FocusScope.of(context).requestFocus(numericFocusNode);
    }

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
                onQueryChange: handleQueryChange,
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
                searchMode: searchMode.value,
                onSearchModeChange: (mode) {
                  searchMode.value = mode;
                  if (mode == _EducationContactSearchMode.numeric) {
                    FocusScope.of(context).requestFocus(numericFocusNode);
                  } else {
                    numericFocusNode.unfocus();
                  }
                },
                numericController: numericController,
                numericFocusNode: numericFocusNode,
                onNumericContinue: handleNumericContinue,
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
    final buttonHeight = isSmallScreen ? 35.h : 40.h;

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
            SizedBox(
              width: double.infinity,
              height: buttonHeight,
              child: ElevatedButton(
                onPressed: onAllow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE85A2C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Allow Contact Access',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
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
    required this.searchMode,
    required this.onSearchModeChange,
    required this.numericController,
    required this.numericFocusNode,
    required this.onNumericContinue,
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
  final _EducationContactSearchMode searchMode;
  final ValueChanged<_EducationContactSearchMode> onSearchModeChange;
  final TextEditingController numericController;
  final FocusNode numericFocusNode;
  final VoidCallback onNumericContinue;

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
      final isNumeric = searchMode == _EducationContactSearchMode.numeric;
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
              // Same field as the Mobile Prepaid recharge search: +91 number
              // entry with the ABC / 123 switch in the trailing slot, or name
              // filtering of the contact list.
              hintText: isNumeric ? 'Enter mobile number' : searchHint,
              controller: isNumeric
                  ? numericController
                  : contactSearchController,
              focusNode: isNumeric ? numericFocusNode : null,
              keyboardType:
                  isNumeric ? TextInputType.phone : TextInputType.text,
              textInputAction:
                  isNumeric ? TextInputAction.done : TextInputAction.search,
              inputFormatters: isNumeric
                  ? [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ]
                  : [_TenDigitNumberFormatter()],
              onChanged: isNumeric ? null : onQueryChange,
              prefixText: isNumeric ? '+91 ' : null,
              prefixStyle: GoogleFonts.plusJakartaSans(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 14.sp,
              ),
              textStyle: GoogleFonts.plusJakartaSans(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w400,
                fontSize: 14.sp,
              ),
              showSearchIcon: false,
              prefixIcon: isNumeric
                  ? null
                  : Padding(
                      padding: EdgeInsets.only(left: 14.w, right: 4.w),
                      child: SvgPicture.asset(
                        FileConstants.educationSearchIconSvg,
                        width: 18.w,
                        height: 18.w,
                        fit: BoxFit.contain,
                      ),
                    ),
              trailing: AppSearchModeToggle<_EducationContactSearchMode>(
                mode: searchMode,
                onChanged: onSearchModeChange,
                options: const [
                  AppSearchModeOption(
                    label: 'ABC',
                    value: _EducationContactSearchMode.abc,
                  ),
                  AppSearchModeOption(
                    label: '123',
                    value: _EducationContactSearchMode.numeric,
                  ),
                ],
              ),
            ),
            // 123 mode gets the CTA, exactly like Mobile Prepaid; it stays
            // hidden while browsing the contact list in ABC mode.
            if (isNumeric)
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: numericController,
                builder: (context, value, _) {
                  final enabled =
                      normalizeEducationMobile(value.text).length == 10;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 14.h),
                      CustomElevatedButton(
                        onPressed: enabled ? onNumericContinue : null,
                        label: 'Continue',
                        uppercaseLabel: false,
                        // Shared CTA size (same as the auth flow buttons).
                        height: authButtonHeight(context),
                      ),
                    ],
                  );
                },
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
