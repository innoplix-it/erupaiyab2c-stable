import 'dart:io';

import 'package:dio/dio.dart';
import 'package:e_rupaiya/features/home/models/banner_model.dart';
import 'package:e_rupaiya/features/mobile_prepaid/controllers/mobile_prepaid_controller.dart';
import 'package:e_rupaiya/features/mobile_prepaid/models/latest_transaction.dart';
import 'package:e_rupaiya/features/mobile_prepaid/models/mobile_prepaid_state.dart';
import 'package:e_rupaiya/features/mobile_prepaid/models/my_number_info.dart';
import 'package:e_rupaiya/features/mobile_prepaid/models/operator_info.dart';
import 'package:e_rupaiya/features/mobile_prepaid/models/plan_item.dart';
import 'package:e_rupaiya/features/mobile_prepaid/repositories/mobile_prepaid_repository.dart';
import 'package:e_rupaiya/features/mobile_prepaid/views/mobile_prepaid_view.dart';
import 'package:e_rupaiya/features/profile/controllers/profile_controller.dart';
import 'package:e_rupaiya/features/profile/models/profile_model.dart';
import 'package:e_rupaiya/features/profile/models/profile_state.dart';
import 'package:e_rupaiya/features/profile/repositories/profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _permissionChannel =
    MethodChannel('flutter.baseflow.com/permissions/methods');
const _contactsChannel = MethodChannel('github.com/QuisApp/flutter_contacts');
const _contactsPermission = 2;

class _FakeRepository extends MobilePrepaidRepository {
  _FakeRepository() : super(dio: Dio());

  @override
  Future<List<BannerModel>> fetchMobilePrepaidBanners({
    String lang = 'en',
  }) async =>
      const [];

  @override
  Future<MyNumberInfo> fetchMyNumber({required String number}) async =>
      MyNumberInfo(number: number, operatorName: 'Airtel', lastOn: '05-02-2026');

  @override
  Future<List<LatestTransaction>> fetchLatestTransactions({
    required String service,
  }) async =>
      const [
        LatestTransaction(
          id: '1',
          paymentType: 'recharge',
          billerName: 'Ivanshu Patil Mumbai (Dombiwali)',
          amount: 199,
          status: 'success',
          transactionRef: 'ref',
          serviceNo: '911234567890',
          icon: '',
          transactionTime: '05-02-2026, 10:00',
        ),
      ];
}

class _FakeProfileController extends ProfileController {
  _FakeProfileController() : super(repository: ProfileRepository(dio: Dio())) {
    state = const ProfileState(
      profile: ProfileModel(id: '1', name: 'Test', mobile: '8055851920'),
    );
  }
}

class _FakePrepaidController extends MobilePrepaidController {
  _FakePrepaidController(MobilePrepaidState initial)
      : super(repository: _FakeRepository()) {
    state = initial;
  }

  final fetchedNumbers = <String>[];

  @override
  Future<void> fetchOperatorAndPlans(String mobileInput) async {
    fetchedNumbers.add(mobileInput);
    state = _plansState(mobile: mobileInput);
  }
}

const _longDescription =
    'Calls : Unlimited Local, STD & Roaming | Data : 2GB/Day | 100 SMS Per '
    'Day | Additional Benefit : Airtel Xstream Play Premium, Disney+ Hotstar';

MobilePrepaidState _plansState({String mobile = '9876543210'}) {
  final plans = [
    for (final amount in [39, 199, 2999, 19999])
      PlanItem(
        amount: amount,
        validity: '28 Days Unlimited Validity Pack',
        description: _longDescription,
        data: 'Unlimited 5G+4G',
        planName: 'Entertainment Pack With OTT Benefits',
        eCoins: 20,
      ),
  ];
  return MobilePrepaidState(
    mobile: mobile,
    operatorInfo: const OperatorInfo(
      operatorName: 'Jio Prepaid',
      circle: 'Maharashtra, Goa',
      circleCode: 'MH',
    ),
    plansByCategory: {
      'Popular': plans,
      'True 5G Unlimited': plans,
      'Top Up': plans,
      'Smart Phone Plans': plans,
    },
    filterTags: const [
      'Unlimited 5G + 2GB/Day Data',
      '1.5GB/Day Data',
      '1.5GB/Day',
    ],
  );
}

// The default test font draws every glyph as a full em square, which makes
// text far wider than on device and turns wrap checks into noise. When real
// Plus Jakarta Sans files are present (build/test_fonts/PJS-<weight>.ttf,
// fetched from fontsource), register them under the family names
// google_fonts generates so widths match the device.
var _realFontsLoaded = false;

Future<void> _loadRealFonts() async {
  const weights = [400, 500, 600, 700, 800];
  final files = {
    for (final w in weights) w: File('build/test_fonts/PJS-$w.ttf'),
  };
  if (files.values.any((f) => !f.existsSync())) return;
  _realFontsLoaded = true;
  final bytes = {
    for (final e in files.entries)
      e.key: ByteData.sublistView(e.value.readAsBytesSync()),
  };
  int nearest(int w) =>
      weights.reduce((a, b) => (a - w).abs() <= (b - w).abs() ? a : b);
  Future<void> register(String family, int weight) =>
      (FontLoader(family)..addFont(Future.value(bytes[nearest(weight)]!)))
          .load();

  for (final family in ['PlusJakartaSans', 'BricolageGrotesque']) {
    await register('${family}_regular', 400);
    await register('${family}_italic', 400);
    for (var w = 100; w <= 900; w += 100) {
      await register('${family}_$w', w);
      await register('${family}_${w}italic', w);
    }
  }
  await register('Roboto', 400);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await _loadRealFonts();
  });

  late bool permissionGranted;
  late List<String> permissionCalls;

  setUp(() {
    permissionGranted = false;
    permissionCalls = [];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_permissionChannel, (call) async {
      permissionCalls.add(call.method);
      final status = permissionGranted ? 1 : 0;
      if (call.method == 'checkPermissionStatus') return status;
      if (call.method == 'requestPermissions') {
        return {_contactsPermission: status};
      }
      return null;
    });
    messenger.setMockMethodCallHandler(
      _contactsChannel,
      (call) async => call.method == 'select' ? <dynamic>[] : null,
    );
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_permissionChannel, null);
    messenger.setMockMethodCallHandler(_contactsChannel, null);
  });

  Future<_FakePrepaidController> pumpView(
    WidgetTester tester, {
    required Size size,
    MobilePrepaidState initial = const MobilePrepaidState(),
    double textScale = 1.15,
  }) async {
    const dpr = 2.0;
    tester.view.devicePixelRatio = dpr;
    tester.view.physicalSize = size * dpr;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = _FakePrepaidController(initial);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mobilePrepaidRepositoryProvider.overrideWithValue(_FakeRepository()),
          mobilePrepaidControllerProvider.overrideWith((ref) => controller),
          profileControllerProvider
              .overrideWith((ref) => _FakeProfileController()),
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
                child: const MobilePrepaidView(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    return controller;
  }

  // Contact filtering and the ABC -> 123 switch run in microtasks after the
  // frame, so a few frames are needed; pumpAndSettle would spin on the caret.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  // Text taller than its box is silently clipped (no overflow error), so
  // compare each paragraph's laid-out height with the height it needs.
  final clipped = <String>{};
  void collectClippedText(WidgetTester tester) {
    for (final element in find.byType(RichText).evaluate()) {
      final paragraph = element.renderObject;
      if (paragraph is! RenderParagraph || !paragraph.hasSize) continue;
      // Icons use overflow: visible and paint outside their box, uncut.
      if (paragraph.overflow == TextOverflow.visible) continue;
      // +1: a paragraph shrink-wrapped to its exact line width can re-wrap on
      // float rounding when measured at that same width.
      final needed = paragraph.getMaxIntrinsicHeight(paragraph.size.width + 1);
      if (needed > paragraph.size.height + 0.5) {
        clipped.add(
          '"${paragraph.text.toPlainText()}" needs '
          '${needed.toStringAsFixed(1)} but has '
          '${paragraph.size.height.toStringAsFixed(1)}',
        );
      }
    }
  }

  void expectNoClippedText() {
    final found = clipped.toList();
    clipped.clear();
    // Wrap-dependent heights are meaningless with the square test font.
    if (!_realFontsLoaded) return;
    expect(found, isEmpty, reason: found.join('\n'));
  }

  Future<void> scrollThrough(WidgetTester tester) async {
    collectClippedText(tester);
    final list = find.byType(Scrollable).first;
    for (var i = 0; i < 4; i++) {
      await tester.drag(list, const Offset(0, -400));
      await tester.pump(const Duration(milliseconds: 100));
      collectClippedText(tester);
    }
  }

  const sizes = <Size>[
    Size(320, 568),
    Size(320, 700),
    Size(360, 740),
    Size(375, 812),
    Size(390, 844),
    Size(412, 915),
    Size(440, 956),
  ];

  for (final size in sizes) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('Mobile Prepaid screen fits $label', (tester) async {
      await pumpView(tester, size: size);
      expect(find.text('Mobile Prepaid'), findsOneWidget);
      expect(find.text('Allow Contact Access'), findsOneWidget);
      await scrollThrough(tester);
      expect(tester.takeException(), isNull);
      expectNoClippedText();
    });

    testWidgets('Mobile Prepaid numeric mode fits $label with keyboard', (
      tester,
    ) async {
      await pumpView(tester, size: size);
      await tester.tap(find.text('123'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(find.byType(TextField), '9876543210');
      await settle(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 2.0);
      addTearDown(tester.view.resetViewInsets);
      await settle(tester);
      expect(find.text('Proceed'), findsOneWidget);
      await scrollThrough(tester);
      expect(tester.takeException(), isNull);
      expectNoClippedText();
    });

    testWidgets('Select A Recharge Plan screen fits $label', (tester) async {
      await pumpView(tester, size: size, initial: _plansState());
      expect(find.text('Select A Recharge Plan'), findsOneWidget);
      expect(find.text('Suggested Plans'), findsOneWidget);
      await scrollThrough(tester);
      expect(tester.takeException(), isNull);
      expectNoClippedText();
    });

    testWidgets('Pay Now screen fits $label', (tester) async {
      final plans = _plansState();
      await pumpView(
        tester,
        size: size,
        initial: plans.copyWith(selectedPlan: plans.allPlans[3]),
      );
      expect(find.text('Pay Now'), findsOneWidget);
      expect(find.text('Proceed to Pay'), findsOneWidget);
      await scrollThrough(tester);
      expect(tester.takeException(), isNull);
      expectNoClippedText();
    });
  }

  group('manual mobile number entry', () {
    const size = Size(390, 844);

    ElevatedButton proceedButton(WidgetTester tester) => tester.widget(
          find.ancestor(
            of: find.text('Proceed'),
            matching: find.byType(ElevatedButton),
          ),
        );

    testWidgets('permission allowed: contacts flow still loads', (
      tester,
    ) async {
      permissionGranted = true;
      await pumpView(tester, size: size);
      expect(find.text('Allow Contact Access'), findsNothing);
      expect(permissionCalls, isNot(contains('requestPermissions')));
    });

    testWidgets('permission denied: typed number is accepted and proceeds', (
      tester,
    ) async {
      final controller = await pumpView(tester, size: size);
      expect(find.text('Allow Contact Access'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '9876543210');
      await settle(tester);

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, '9876543210');
      expect(field.keyboardType, TextInputType.phone);
      expect(proceedButton(tester).onPressed, isNotNull);

      await tester.tap(find.text('Proceed'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(controller.fetchedNumbers, ['9876543210']);
      expect(find.text('Select A Recharge Plan'), findsOneWidget);
      expect(permissionCalls, isNot(contains('requestPermissions')));
    });

    testWidgets('permission denied: ABC/123 toggle keeps the typed number', (
      tester,
    ) async {
      await pumpView(tester, size: size);
      await tester.enterText(find.byType(TextField), '9876543210');
      await settle(tester);

      await tester.tap(find.text('ABC'));
      await tester.pump(const Duration(milliseconds: 300));
      var field = tester.widget<TextField>(find.byType(TextField));
      expect(field.keyboardType, TextInputType.text);
      expect(field.controller!.text, '9876543210');

      await tester.tap(find.text('123'));
      await tester.pump(const Duration(milliseconds: 300));
      field = tester.widget<TextField>(find.byType(TextField));
      expect(field.keyboardType, TextInputType.phone);
      expect(field.controller!.text, '9876543210');
      expect(proceedButton(tester).onPressed, isNotNull);
      expect(permissionCalls, isNot(contains('requestPermissions')));
    });

    testWidgets('permission denied: incomplete number keeps Proceed disabled', (
      tester,
    ) async {
      final controller = await pumpView(tester, size: size);
      await tester.enterText(find.byType(TextField), '98765');
      await settle(tester);

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, '98765');
      expect(proceedButton(tester).onPressed, isNull);
      expect(controller.fetchedNumbers, isEmpty);
    });

    testWidgets('permission denied: +91 / 0 prefixed numbers are trimmed', (
      tester,
    ) async {
      await pumpView(tester, size: size);
      await tester.enterText(find.byType(TextField), '09876543210');
      await settle(tester);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, '9876543210');
      expect(proceedButton(tester).onPressed, isNotNull);
    });
  });
}
