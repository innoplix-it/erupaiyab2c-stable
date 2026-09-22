import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../services/permission_service.dart';
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

class EducationContactSheet extends HookConsumerWidget {
  const EducationContactSheet({
    super.key,
    required this.onSelect,
    this.matchInviteContactAvatarStyle = false,
  });

  final ValueChanged<String> onSelect;
  final bool matchInviteContactAvatarStyle;

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

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          top: 12.h,
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
                onSelect: (value) {
                  onSelect(value);
                  Navigator.of(context).maybePop();
                },
                matchInviteContactAvatarStyle: matchInviteContactAvatarStyle,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 20.h),
        Container(
          height: 120.r,
          width: 120.r,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.phone_in_talk_outlined,
              color: AppColors.primary,
              size: 58.r,
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          'Provide Access To Contacts',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        SizedBox(height: 8.h),
        Text(
          'We need this to pick a recipient.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary.withOpacity(0.6),
              ),
        ),
        SizedBox(height: 18.h),
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: ElevatedButton(
            onPressed: onAllow,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              elevation: 0,
            ),
            child: Text(
              'Allow Contact Access',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
      ],
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
    required this.matchInviteContactAvatarStyle,
  });

  final bool isLoading;
  final List<Contact> contacts;
  final int visibleCount;
  final TextEditingController contactSearchController;
  final ValueChanged<String> onQueryChange;
  final VoidCallback onLoadMore;
  final ValueChanged<String> onSelect;
  final bool matchInviteContactAvatarStyle;

  @override
  Widget build(BuildContext context) {
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
            hintText: 'Search contacts',
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
  });

  final List<Contact> contacts;
  final int visibleCount;
  final ValueChanged<String> onSelect;
  final bool matchInviteContactAvatarStyle;

  @override
  Widget build(BuildContext context) {
    final displayContacts = contacts.length > visibleCount
        ? contacts.take(visibleCount).toList()
        : contacts;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayContacts.length,
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (context, index) {
        final contact = displayContacts[index];
        final phone =
            contact.phones.isNotEmpty ? contact.phones.first.number : '';
        final initials = contact.displayName.isNotEmpty
            ? contact.displayName
                .trim()
                .split(' ')
                .map((e) => e[0])
                .take(2)
                .join()
            : '';
        return InkWell(
          onTap: phone.isEmpty
              ? null
              : () => onSelect(normalizeEducationMobile(phone)),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AppColors.lightBorder),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: matchInviteContactAvatarStyle ? 22.r : 18.r,
                  backgroundColor: matchInviteContactAvatarStyle
                      ? const Color(0xFFD9D9D9)
                      : AppColors.primary.withOpacity(0.1),
                  child: Text(
                    initials.toUpperCase(),
                    style: (matchInviteContactAvatarStyle
                            ? Theme.of(context).textTheme.bodySmall
                            : Theme.of(context).textTheme.labelMedium)
                        ?.copyWith(
                      color: matchInviteContactAvatarStyle
                          ? AppColors.textPrimary
                          : AppColors.primary,
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        phone,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary.withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
