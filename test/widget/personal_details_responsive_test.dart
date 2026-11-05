import 'package:dio/dio.dart';
import 'package:e_rupaiya/features/profile/controllers/profile_controller.dart';
import 'package:e_rupaiya/features/profile/models/profile_model.dart';
import 'package:e_rupaiya/features/profile/repositories/profile_repository.dart';
import 'package:e_rupaiya/features/profile/views/profile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Canned KYC-verified profile matching the Figma reference values.
class _FakeProfileRepository extends ProfileRepository {
  _FakeProfileRepository() : super(dio: Dio());

  @override
  Future<ProfileModel> fetchProfile() async => const ProfileModel(
        id: '1',
        name: 'Test User Name',
        mobile: '9876500002',
        email: 'user@gmail.com',
        kycStatus: ProfileKycStatus.verified,
        aadhaarMasked: 'XXXX XXXX XXXX 9999',
        panMasked: 'XXXXX9999X',
        dob: '01-01-2000',
        permanentAddress:
            'Office No 2, 2nd Floor, Mahesh Plaza, Bengaluru - Mumbai Hwy, '
            'Above KTM Showroom, Near Lodha Hospital, Popular Nagar, Girdhar '
            'Nagar, Warje, Pune, Maharashtra 411058',
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const cannedProfile = ProfileModel(
    id: '1',
    name: 'Test User Name',
    mobile: '9876500002',
    email: 'user@gmail.com',
    kycStatus: ProfileKycStatus.verified,
    aadhaarMasked: 'XXXX XXXX XXXX 9999',
    panMasked: 'XXXXX9999X',
    dob: '01-01-2000',
    permanentAddress: 'Warje, Pune, Maharashtra 411058',
  );

  Future<void> pump(WidgetTester tester, Size size) async {
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
          builder: (context, _) => const MaterialApp(
            home: UpdateProfileView(profile: cannedProfile),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('Personal Details screen redesign renders without overflow', () {
    for (final size in const [
      Size(320, 568), // narrow
      Size(360, 690), // design base
      Size(430, 932), // large
    ]) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await pump(tester, size);

        for (final label in const [
          'Personal Details',
          'Personal & Banking',
          'Billing Address',
          'Full name (as per PAN)',
          'Test User Name',
          'Mobile Number',
          '+91 9876500002',
          'Email ID',
          'user@gmail.com',
          'Adhaar Number',
          'XXXX XXXX XXXX 9999',
          'PAN Number',
          'XXXXX9999X',
          'Date Of Birth',
          '01-01-2000',
          'Permanent Address',
        ]) {
          expect(
            find.text(label),
            findsWidgets,
            reason: '"$label" missing at ${size.width}x${size.height}',
          );
        }

        // Save bar must be hidden in the clean state (per reference).
        expect(find.text('Save & Update'), findsNothing);
      });
    }

    testWidgets('Billing Address tab switches', (tester) async {
      await pump(tester, const Size(360, 690));
      await tester.tap(find.text('Billing Address'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Billing Address Details'), findsOneWidget);
      expect(find.text('Save & Update'), findsOneWidget);
    });
  });
}
