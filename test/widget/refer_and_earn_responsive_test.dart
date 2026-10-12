import 'dart:io';

import 'package:e_rupaiya/features/mobile_prepaid/controllers/contacts_cache_controller.dart';
import 'package:e_rupaiya/features/refer_and_earn/views/refer_and_earn_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../helpers/responsive_test_sizes.dart';

const _permissionChannel =
    MethodChannel('flutter.baseflow.com/permissions/methods');
const _contactsPermission = 2;

/// Fake controller that serves in-memory contacts so the Invite Contacts
/// strip renders deterministically without touching the platform.
class _FakeContactsCacheController extends ContactsCacheController {
  _FakeContactsCacheController(List<Contact> contacts) {
    state = ContactsCacheState(contacts: contacts);
  }

  @override
  Future<void> fetchIfNeeded() async {}
}

Contact _contact(String name) => Contact(
      displayName: name,
      phones: [Phone('9876543210')],
    );

// Long names exercise the truncation path; the Ahem test font draws every
// glyph as a full em square, so these are intentionally aggressive.
final _testContacts = [
  _contact('Ivanshu Patil'),
  _contact('Monu Ali'),
  _contact('Surpiya Ithappully Kerala'),
  _contact('Aakanksha Bhattacharyya'),
];

// The default test font (Ahem) draws square glyphs far wider than Plus
// Jakarta Sans, which turns legitimate layouts into false overflow errors.
// When real font files are present (build/test_fonts/PJS-<weight>.ttf),
// register them so text widths match the device.
Future<void> _loadRealFonts() async {
  const weights = [400, 500, 600, 700, 800];
  final files = {
    for (final w in weights) w: File('build/test_fonts/PJS-$w.ttf'),
  };
  if (files.values.any((f) => !f.existsSync())) return;
  final bytes = {
    for (final e in files.entries)
      e.key: ByteData.sublistView(e.value.readAsBytesSync()),
  };
  Future<void> register(String family, int weight) =>
      (FontLoader(family)..addFont(Future.value(bytes[weight]!))).load();
  for (final family in ['PlusJakartaSans']) {
    await register('${family}_regular', 400);
    for (var w = 100; w <= 900; w += 100) {
      await register('${family}_$w', w);
    }
  }
}

Future<void> _pumpView(
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
        contactsCacheControllerProvider
            .overrideWith((ref) => _FakeContactsCacheController(_testContacts)),
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
              child: const ReferAndEarnView(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await _loadRealFonts();
  });

  setUp(() {
    // Contacts permission is granted so the Invite Contacts strip renders.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_permissionChannel, (call) async {
      if (call.method == 'checkPermissionStatus') return 1;
      if (call.method == 'requestPermissions') {
        return {_contactsPermission: 1};
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_permissionChannel, null);
  });

  for (final size in responsiveTestScreenSizes) {
    testWidgets(
      'renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await _pumpView(tester, size: size);
        expect(tester.takeException(), isNull);

        // Key Figma elements are present.
        expect(find.text('Refer Friends & Earn Coins'), findsOneWidget);
        expect(find.text('Earn E-Coins Lifetime'), findsOneWidget);
        expect(find.text('Refer & Earn Lifetime'), findsOneWidget);
        expect(
          find.text('Refer Once, Earn Rewards For A Lifetime.'),
          findsOneWidget,
        );
        expect(find.text('My Referral Earnings'), findsOneWidget);
        expect(find.text('Track Your\nReferrals'), findsOneWidget);
        expect(find.text('How It\nWorks ?'), findsOneWidget);
        expect(find.text('Invite Contacts'), findsOneWidget);
        expect(find.text('Invite Contact'), findsOneWidget);

        // The supplied arrow SVG is used in both feature cards.
        expect(find.byType(SvgPicture), findsNWidgets(2));

        // Bottom actions are visible and inside the viewport.
        expect(find.text('Refer On Whatsapp'), findsOneWidget);
        final buttonRect = tester.getRect(find.text('Refer On Whatsapp'));
        expect(buttonRect.bottom, lessThanOrEqualTo(size.height));
        expect(buttonRect.top, greaterThanOrEqualTo(0));
      },
    );
  }

  testWidgets('supports large text scaling without overflow', (tester) async {
    await _pumpView(
      tester,
      size: const Size(360, 690),
      textScale: 1.3,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Refer On Whatsapp'), findsOneWidget);
  });

  testWidgets('feature cards sit side by side with the arrow bottom-right',
      (tester) async {
    await _pumpView(tester, size: const Size(440, 956));
    expect(tester.takeException(), isNull);

    final track = tester.getRect(find.text('Track Your\nReferrals'));
    final works = tester.getRect(find.text('How It\nWorks ?'));
    expect(works.left, greaterThan(track.right));

    final arrows = [
      tester.getRect(find.byType(SvgPicture).at(0)),
      tester.getRect(find.byType(SvgPicture).at(1)),
    ];
    for (final arrow in arrows) {
      // Square viewport: no stretching or distortion.
      expect(arrow.width, closeTo(arrow.height, 0.5));
    }
    // First arrow is in the bottom-right of the left card.
    final cardRect = tester.getRect(find.text('Track Your\nReferrals'));
    expect(arrows.first.center.dx, greaterThan(cardRect.center.dx));
    expect(arrows.first.center.dy, greaterThan(cardRect.center.dy));
  });

  testWidgets('info section uses the Figma typography spec',
      (tester) async {
    await _pumpView(tester, size: const Size(440, 956));
    final title = tester.widget<Text>(find.text('Refer Once, Earn Forever'));
    expect(title.style?.fontWeight, FontWeight.w700);
    expect(title.style?.height, closeTo(28 / 14, 0.01));

    final description = tester.widget<Text>(
      find.textContaining('Refer Once And Earn Coins Every Time'),
    );
    expect(description.style?.fontWeight, FontWeight.w400);
    expect(description.style?.height, closeTo(25 / 12, 0.01));
  });
}
