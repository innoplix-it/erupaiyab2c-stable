import 'package:dio/dio.dart';
import 'package:e_rupaiya/features/profile/controllers/profile_controller.dart';
import 'package:e_rupaiya/features/profile/models/profile_model.dart';
import 'package:e_rupaiya/features/profile/repositories/profile_repository.dart';
import 'package:e_rupaiya/features/profile/views/profile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Repository stub so ProfileView's auto-fetch resolves with a canned profile
/// (no network) and the completion badge has a deterministic backend value.
class _FakeProfileRepository extends ProfileRepository {
  _FakeProfileRepository() : super(dio: Dio());

  @override
  Future<ProfileModel> fetchProfile() async => const ProfileModel(
        id: '1',
        name: 'Rajiv Kumar',
        mobile: '8055851920',
        profileCompletionPercent: 50,
      );
}

Future<void> _pumpProfile(
  WidgetTester tester, {
  required Size size,
  double textScale = 1.0,
}) async {
  const dpr = 2.0;
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = size * dpr;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profileRepositoryProvider.overrideWithValue(_FakeProfileRepository()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        fontSizeResolver: FontSizeResolvers.radius,
        builder: (context, _) => MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScale),
              ),
              child: const ProfileView(),
            ),
          ),
        ),
      ),
    ),
  );
  // Let the microtask fetch resolve and the profile data paint.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const expectedLabels = [
    'My Profile',
    'Manage',
    'Rajiv Kumar',
    '+918055851920',
    'Invite & earn eCoins daily',
    'Open Zero Balance Account',
    'My Account',
    'Personal Details',
    '50% Complete',
    'Wallet (eCoins)',
    'My Loans',
    'My Credit Score',
    'Settings',
    'Preferences',
    'Security',
    'Support',
    'Help & Support',
    'About eRupaiya',
    'Log Out',
  ];

  group('ProfileView redesign renders all sections without overflow', () {
    for (final size in const [
      Size(320, 568), // narrow (iPhone SE 1st gen)
      Size(360, 690), // design base
      Size(430, 932), // large (iPhone 15 Pro Max)
    ]) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpProfile(tester, size: size);
        for (final label in expectedLabels) {
          expect(
            find.text(label),
            findsWidgets,
            reason: '"$label" missing at ${size.width}x${size.height}',
          );
        }
      });
    }

    testWidgets('large text scale (1.3) keeps layout intact', (tester) async {
      await _pumpProfile(
        tester,
        size: const Size(360, 690),
        textScale: 1.3,
      );
      // A RenderFlex overflow would have failed the test via FlutterError.
      expect(find.text('Log Out'), findsOneWidget);
      expect(find.text('50% Complete'), findsOneWidget);
    });

    testWidgets('zero percent from backend still renders badge as 0',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileRepositoryProvider.overrideWithValue(
              _ZeroPercentRepository(),
            ),
          ],
          child: ScreenUtilInit(
            designSize: const Size(360, 690),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, _) => const MaterialApp(home: ProfileView()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('0% Complete'), findsOneWidget);
    });
  });
}

class _ZeroPercentRepository extends ProfileRepository {
  _ZeroPercentRepository() : super(dio: Dio());

  @override
  Future<ProfileModel> fetchProfile() async => const ProfileModel(
        id: '1',
        name: 'Rajiv Kumar',
        mobile: '8055851920',
      );
}
