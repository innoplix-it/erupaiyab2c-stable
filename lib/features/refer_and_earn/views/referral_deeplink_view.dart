import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/routes_constant.dart';
import '../../../constants/storage_keys.dart';
import '../../../services/secure_storage_service.dart';
import '../../../utils/utils.dart';
import '../../../widgets/app_snackbar.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../services/logger_service.dart';
import '../repositories/referral_repository.dart';

class ReferralDeepLinkView extends HookConsumerWidget {
  const ReferralDeepLinkView({super.key, required this.referralCode});

  final String referralCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = useMemoized(() => SecureStorageService.instance);

    useEffect(() {
      Future.microtask(() async {
        final code = referralCode.trim();
        if (code.isEmpty) {
          logger.debug('ReferralDeepLink: empty code');
          AppSnackbar.show('Invalid referral link.');
          if (context.mounted) {
            context.go(RouteConstants.home);
          }
          return;
        }

        logger.debug('ReferralDeepLink: received code=$code');
        final authState = ref.read(authControllerProvider);
        if (!authState.isAuthenticated) {
          logger
              .debug('ReferralDeepLink: user not authenticated, storing code');
          await storage.write(
            key: StorageKeys.pendingReferralCode,
            value: code,
          );
          if (context.mounted) {
            context.go(RouteConstants.login);
          }
          return;
        }

        final userId = await Utils.getUserId();
        if (userId == null || userId.trim().isEmpty) {
          logger
              .debug('ReferralDeepLink: missing userId, redirecting to login');
          AppSnackbar.show('Please login to continue.');
          if (context.mounted) {
            context.go(RouteConstants.login);
          }
          return;
        }

        try {
          logger.debug(
            'ReferralDeepLink: registering referral userId=$userId code=$code',
          );
          final response = await ReferralRepository().registerReferral(
            newUserId: userId,
            referralCode: code,
          );
          logger.debug(
            'ReferralDeepLink: register response status=${response.status} message=${response.message}',
          );
          if (response.message.isNotEmpty) {
            AppSnackbar.show(response.message);
          }
        } catch (_) {
          logger.error('ReferralDeepLink: register failed');
          AppSnackbar.show('Something went wrong. Please try again.');
        }

        if (context.mounted) {
          logger.debug('ReferralDeepLink: redirecting to home');
          context.go(RouteConstants.home);
        }
      });
      return null;
    }, [referralCode]);

    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
