import 'package:dio/dio.dart';
import 'package:e_rupaiya/features/home/controllers/home_controller.dart';
import 'package:e_rupaiya/features/home/models/home_state.dart';
import 'package:e_rupaiya/features/home/repositories/home_repository.dart';
import 'package:e_rupaiya/features/mobile_prepaid/models/latest_transaction.dart';
import 'package:e_rupaiya/features/profile/controllers/profile_controller.dart';
import 'package:e_rupaiya/features/profile/models/profile_model.dart';
import 'package:e_rupaiya/features/profile/models/profile_state.dart';
import 'package:e_rupaiya/features/profile/repositories/profile_repository.dart';
import 'package:e_rupaiya/features/services/controllers/biller_listing_controller.dart';
import 'package:e_rupaiya/features/services/controllers/service_extras_controller.dart';
import 'package:e_rupaiya/features/services/models/biller_model.dart';
import 'package:e_rupaiya/features/services/repositories/biller_repository.dart';
import 'package:e_rupaiya/features/services/views/credit_card_listing_view.dart';
import 'package:e_rupaiya/widgets/app_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../helpers/responsive_test_sizes.dart';

/// The nine portrait sizes required for listing responsive audits, taken from
/// [responsiveTestScreenSizes] (no duplicate matrix).
final _nineListingSizes = responsiveTestScreenSizes.where((s) {
  const allowed = <String>{
    '320x568',
    '360x640',
    '360x690',
    '360x800',
    '375x812',
    '390x844',
    '412x915',
    '440x956',
    '458x1024',
  };
  return allowed.contains('${s.width.toInt()}x${s.height.toInt()}');
}).toList(growable: false);

class _FakeBillerRepository extends BillerRepository {
  _FakeBillerRepository() : super(dio: Dio());

  @override
  Future<BillerListResponse> fetchBillers({
    required String categoryName,
    int page = 1,
    int limit = 20,
    String? search,
  }) async =>
      const BillerListResponse(
        categoryName: 'Credit Card',
        billers: [
          Biller(billerId: '1', billerName: 'HDFC Bank Credit Card'),
          Biller(billerId: '2', billerName: 'ICICI Bank Credit Card'),
          Biller(billerId: '3', billerName: 'SBI Card'),
          Biller(billerId: '4', billerName: 'Axis Bank Credit Card'),
          Biller(billerId: '5', billerName: 'Kotak Mahindra Bank'),
          Biller(billerId: '6', billerName: 'Yes Bank Credit Card'),
        ],
      );
}

class _FakeProfileController extends ProfileController {
  _FakeProfileController() : super(repository: ProfileRepository(dio: Dio())) {
    state = const ProfileState(
      profile: ProfileModel(
        id: '1',
        name: 'Test User',
        mobile: '9999999999',
        kycStatus: ProfileKycStatus.verified,
      ),
    );
  }
}

class _IdleHomeController extends HomeController {
  _IdleHomeController() : super(repository: HomeRepository(dio: Dio())) {
    state = const HomeState(creditCardActions: []);
  }

  @override
  Future<void> fetchCreditCardActions() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pump(
    WidgetTester tester,
    Size size, {
    double textScale = 1.15,
  }) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = size * 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const CreditCardListingView(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          billerRepositoryProvider.overrideWithValue(_FakeBillerRepository()),
          serviceLatestTransactionsProvider.overrideWith(
            (ref, service) async => const <LatestTransaction>[],
          ),
          profileControllerProvider
              .overrideWith((ref) => _FakeProfileController()),
        ],
        child: ScreenUtilInit(
          designSize: const Size(360, 690),
          minTextAdapt: true,
          splitScreenMode: true,
          fontSizeResolver: FontSizeResolvers.radius,
          builder: (context, _) => MaterialApp.router(
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScale),
              ),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  for (final size in _nineListingSizes) {
    for (final textScale in const [0.85, 1.15]) {
      testWidgets(
        'Credit Card listing fits ${size.width.toInt()}x'
        '${size.height.toInt()} at $textScale text',
        (tester) async {
          await pump(tester, size, textScale: textScale);
          expect(tester.takeException(), isNull);
          expect(find.text('Popular Banks'), findsOneWidget);
          expect(find.text('Search by billers'), findsOneWidget);
          expect(find.byType(AppSearchBar), findsOneWidget);
          expect(find.text('HDFC Bank Credit Card'), findsWidgets);

          final search = tester.getRect(find.byType(AppSearchBar));
          expect(search.left, moreOrLessEquals(AppSearchBar.sideInset));
          expect(
            search.right,
            moreOrLessEquals(size.width - AppSearchBar.sideInset),
          );
        },
      );
    }
  }

  testWidgets(
    'Recent card shows Last Paid and Due On at 320x568 with 1.15 text',
    (tester) async {
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(320, 568) * 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const txn = LatestTransaction(
        id: 'cc-1',
        billerId: '1',
        paymentType: 'Credit Card',
        billerName: 'HDFC Bank Credit Card',
        amount: 1200,
        status: 'SUCCESS',
        transactionRef: 'ref-1',
        serviceNo: '9513',
        dueDate: '2026-05-06',
        lastPaidDate: '2026-10-01',
      );

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const CreditCardListingView(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            billerRepositoryProvider.overrideWithValue(_FakeBillerRepository()),
            serviceLatestTransactionsProvider.overrideWith(
              (ref, service) async => const [txn],
            ),
            homeControllerProvider.overrideWith((ref) => _IdleHomeController()),
            profileControllerProvider
                .overrideWith((ref) => _FakeProfileController()),
          ],
          child: ScreenUtilInit(
            designSize: const Size(360, 690),
            minTextAdapt: true,
            splitScreenMode: true,
            fontSizeResolver: FontSizeResolvers.radius,
            builder: (context, _) => MaterialApp.router(
              routerConfig: router,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.15),
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.textContaining('Last Paid On'), findsOneWidget);
      expect(find.textContaining('Due On'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
