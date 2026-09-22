import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/routes_constant.dart';
import '../../../services/secure_storage_service.dart';
import '../../../services/logger_service.dart';
import '../../../utils/utils.dart';
import '../../auth/controllers/auth_controller.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppDrawer extends HookConsumerWidget {
  const AppDrawer({super.key});

  Future<Map<String, String>> _getUserDetails() async {
    const secureStorage = SecureStorageService.instance;
    final userId = await secureStorage.read(key: 'userId');

    final initials = (userId ?? '')
        .split(' ')
        .map((part) => part.isNotEmpty ? part[0].toUpperCase() : '')
        .join();

    return {
      'userId': userId ?? '',
      'initials': initials.isNotEmpty
          ? initials
          : (userId != null && userId.isNotEmpty ? userId[0].toUpperCase() : ''),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: Column(
        children: <Widget>[
          FutureBuilder(
            future: _getUserDetails(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasData) {
                final userData = snapshot.data!;
                final userId = userData['userId'] ?? 'Not Available';
                final initials = userData['initials'] ?? '';
                return UserAccountsDrawerHeader(
                  accountName: Text(
                    userId,
                    style: TextStyle(fontSize: 18.sp),
                  ),
                  accountEmail: Text(userId),
                  currentAccountPictureSize: const Size.square(70),
                  currentAccountPicture: CircleAvatar(
                    child: Text(
                      initials,
                      style: TextStyle(fontSize: 30.sp),
                    ),
                  ),
                );
              } else {
                return const Text('User ID not found');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              try {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) {
                  context.go(RouteConstants.login);
                }
              } catch (e, stackTrace) {
                logger.error(
                  'Error while logging out from drawer',
                  error: e,
                  stackTrace: stackTrace,
                );
              }
            },
          ),
          const Spacer(),
          ListTile(
            title: FutureBuilder(
              future: Utils.getAppVersion(),
              builder: (context, snapshot) {
                logger.info(snapshot);
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasData) {
                  return Text(
                    'App Version: ${snapshot.data}',
                    style: TextStyle(fontSize: 16.sp),
                  );
                } else {
                  return const Text('App version not found');
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
