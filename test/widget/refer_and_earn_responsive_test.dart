import 'dart:io';
import 'dart:math' as math;

import 'package:e_rupaiya/features/mobile_prepaid/controllers/contacts_cache_controller.dart';
import 'package:e_rupaiya/features/refer_and_earn/components/refer_and_earn_app_bar.dart';
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

  void setContacts(List<Contact> contacts) {
    state = ContactsCacheState(contacts: contacts);
  }
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

// Native proportion of the hero artwork
// (assets/images/svg/refer_and_earn_hero.svg, 317 x 164).
const _heroAspect = 317 / 164;

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

Future<_FakeContactsCacheController> _pumpView(
  WidgetTester tester, {
  required Size size,
  double textScale = 1.0,
  List<Contact>? contacts,
}) async {
  const dpr = 2.0;
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = size * dpr;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final controller =
      _FakeContactsCacheController(contacts ?? _testContacts);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        contactsCacheControllerProvider.overrideWith((ref) => controller),
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
  return controller;
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
        expect(find.text('View all'), findsOneWidget);

        // Arrow SVGs: earnings pill + both feature cards.
        expect(find.byType(SvgPicture), findsNWidgets(4));

        // Bottom actions are visible and inside the viewport.
        expect(find.text('Refer On Whatsapp'), findsOneWidget);
        final buttonRect = tester.getRect(find.text('Refer On Whatsapp'));
        expect(buttonRect.bottom, lessThanOrEqualTo(size.height));
        expect(buttonRect.top, greaterThanOrEqualTo(0));
      },
    );

    testWidgets(
      'hero artwork stays attached to the card at '
      '${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await _pumpView(tester, size: size);
        expect(tester.takeException(), isNull);

        final image = tester
            .getRect(find.byKey(const ValueKey('refer-earn-hero')));
        final panel =
            tester.getRect(find.byKey(const ValueKey('refer-earn-panel')));
        final appBarTitle =
            tester.getRect(find.text('Refer Friends & Earn Coins'));

        // Original aspect ratio is preserved (no stretching, no cropping).
        expect(image.width / image.height, closeTo(_heroAspect, 0.02));

        // Horizontally centred in the hero.
        expect(math.pow(image.center.dx - size.width / 2, 2),
            lessThan(4)); // |dx| < 2px

        // The characters sit on the card: the artwork bottom reaches the
        // panel top and tucks only slightly behind it (no visible gap).
        expect(image.bottom, greaterThanOrEqualTo(panel.top));
        expect(image.bottom, lessThan(panel.top + size.height * 0.05));

        // The artwork sits close to the AppBar: it starts below the nav
        // row and the empty gap under the nav row is at most a fifth of
        // the screen instead of a large float.
        expect(image.top, greaterThan(appBarTitle.bottom));
        expect(image.top - appBarTitle.bottom, lessThan(size.height * 0.2));

        // Hero, panel and AppBar do not collide.
        expect(panel.top, lessThan(image.bottom + size.height));
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
    expect(find.text('Refer & Earn Lifetime'), findsOneWidget);
  });

  testWidgets('reuses the common ReferAndEarnAppBar', (tester) async {
    await _pumpView(tester, size: const Size(390, 844));
    expect(find.byType(ReferAndEarnAppBar), findsOneWidget);
    // Back action present (help button keeps its default no-op behaviour).
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byIcon(Icons.help_outline), findsOneWidget);
  });

  testWidgets('feature cards sit side by side with the arrow bottom-right',
      (tester) async {
    await _pumpView(tester, size: const Size(440, 956));
    expect(tester.takeException(), isNull);

    final track = tester.getRect(find.text('Track Your\nReferrals'));
    final works = tester.getRect(find.text('How It\nWorks ?'));
    expect(works.left, greaterThan(track.right));

    // The last two SVGs are the card arrows (0 is the hero artwork,
    // 1 the earnings pill arrow).
    final arrows = [
      tester.getRect(find.byType(SvgPicture).at(2)),
      tester.getRect(find.byType(SvgPicture).at(3)),
    ];
    for (final arrow in arrows) {
      // Square viewport: no stretching or distortion.
      expect(arrow.width, closeTo(arrow.height, 0.5));
    }
    // First arrow is in the bottom-right of the left card.
    expect(arrows.first.center.dx, greaterThan(track.center.dx));
    expect(arrows.first.center.dy, greaterThan(track.center.dy));
  });

  testWidgets('info section keeps its Figma line-heights', (tester) async {
    await _pumpView(tester, size: const Size(440, 956));
    final title = tester.widget<Text>(find.text('Refer Once, Earn Forever'));
    expect(title.style?.fontWeight, FontWeight.w600);
    expect(title.style?.height, closeTo(28 / 16, 0.01));

    final description = tester.widget<Text>(
      find.textContaining('Refer Once And Earn Coins Every Time'),
    );
    expect(description.style?.fontWeight, FontWeight.w400);
    expect(description.style?.height, closeTo(25 / 14, 0.01));
  });

  group('contact avatar initials', () {
    testWidgets('first + last word for multi-word names', (tester) async {
      await _pumpView(
        tester,
        size: const Size(440, 956),
        contacts: [
          _contact('Aakanksha Patil'),
          _contact('Monu Ali'),
          _contact('Surpiya Ithappully Kerala'),
        ],
      );
      expect(tester.takeException(), isNull);
      expect(find.text('AP'), findsOneWidget);
      expect(find.text('MA'), findsOneWidget);
      // First and LAST word, not the middle one.
      expect(find.text('SK'), findsOneWidget);
    });

    testWidgets('single word, extra whitespace and empty names are safe',
        (tester) async {
      await _pumpView(
        tester,
        size: const Size(440, 956),
        contacts: [
          _contact('Aannnya'),
          _contact('  Monu   Ali  '),
          _contact('   '),
        ],
      );
      expect(tester.takeException(), isNull);
      expect(find.text('A'), findsOneWidget);
      // Multiple inner spaces collapse; leading/trailing are trimmed.
      expect(find.text('MA'), findsOneWidget);
      // Blank name renders no initials (and no exception); the invite
      // tile stays initial-free.
      expect(find.text('Invite Contact'), findsOneWidget);
      expect(find.text('IC'), findsNothing);
    });

    testWidgets('initials update when the contact list changes',
        (tester) async {
      final controller = await _pumpView(
        tester,
        size: const Size(440, 956),
        contacts: [_contact('Monu Ali')],
      );
      expect(find.text('MA'), findsOneWidget);

      controller.setContacts([
        _contact('Surpiya Temkar'),
        _contact('Aannnya'),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('MA'), findsNothing);
      expect(find.text('ST'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
