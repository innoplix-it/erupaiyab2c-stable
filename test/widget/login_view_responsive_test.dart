// Full LoginView coverage, so wiring that isolated step tests cannot see
// (referral banner, platform lookups, Scaffold insets) is exercised too.
//
// Uses the canonical `responsiveTestScreenSizes` matrix from
// test/helpers/responsive_test_sizes.dart - the device list is never
// duplicated here.

import 'package:e_rupaiya/features/auth/components/auth_mobile_step.dart';
import 'package:e_rupaiya/features/auth/components/auth_step_parts.dart';
import 'package:e_rupaiya/features/auth/controllers/auth_controller.dart';
import 'package:e_rupaiya/features/auth/models/auth_state.dart';
import 'package:e_rupaiya/features/auth/repositories/auth_repository.dart';
import 'package:e_rupaiya/features/auth/views/login_view.dart';
import 'package:e_rupaiya/widgets/custom_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/responsive_test_sizes.dart';

const _secureStorageChannel =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
const _appLinksChannel = MethodChannel('com.llfbandit.app_links/messages');
const _appLinksEvents = EventChannel('com.llfbandit.app_links/events');
const _phoneHintChannel = MethodChannel('com.innoplix.erupaiya/phone_hint');

class _MockAuthRepository extends Mock implements AuthRepository {}

class _FakeAuthController extends AuthController {
  _FakeAuthController()
      : super(
          repository: _MockAuthRepository(),
          shouldCheckInitialAuth: false,
        ) {
    state = const AuthState(
      isAuthenticated: false,
      hasTemporaryAccess: false,
      isLoading: false,
      isSubmitting: false,
    );
  }
}

String? _storedReferral;

void _mockPlatform() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(_secureStorageChannel, (call) async {
    if (call.method == 'read') return _storedReferral;
    return null;
  });
  messenger.setMockMethodCallHandler(_appLinksChannel, (_) async => null);
  messenger.setMockStreamHandler(
    _appLinksEvents,
    MockStreamHandler.inline(onListen: (_, __) {}),
  );
  messenger.setMockMethodCallHandler(_phoneHintChannel, (_) async => null);
}

void _clearPlatform() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(_secureStorageChannel, null);
  messenger.setMockMethodCallHandler(_appLinksChannel, null);
  messenger.setMockStreamHandler(_appLinksEvents, null);
  messenger.setMockMethodCallHandler(_phoneHintChannel, null);
}

Future<void> _pumpLoginView(
  WidgetTester tester, {
  Size size = const Size(360, 690),
  double textScale = 1.0,
  double keyboardInset = 0,
  EdgeInsets padding = EdgeInsets.zero,
}) async {
  const dpr = 2.0;
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = size * dpr;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith((ref) => _FakeAuthController()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        fontSizeResolver: FontSizeResolvers.radius,
        builder: (context, _) => MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              padding: padding,
              viewPadding: padding,
              viewInsets: EdgeInsets.only(bottom: keyboardInset),
            ),
            child: child!,
          ),
          home: const LoginView(),
        ),
      ),
    ),
  );
  // Lets the stored-referral and deep-link lookups settle.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Disposes the view so its deep-link subscription is cancelled.
Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

double _headingToLabelGap(WidgetTester tester) =>
    tester.getRect(find.text('Mobile Number')).top -
    tester.getRect(find.text('Enter your mobile number to continue.')).bottom;

Rect _continueRect(WidgetTester tester) =>
    tester.getRect(find.byType(CustomElevatedButton));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _storedReferral = null;
    _mockPlatform();
  });

  tearDown(_clearPlatform);

  group('LoginView mobile step across shared sizes', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpLoginView(tester, size: size);
        expect(tester.takeException(), isNull);

        expect(
          tester.widget<AuthMobileStep>(find.byType(AuthMobileStep))
              .referralBanner,
          isNull,
          reason: 'no referral code means no banner slot and no extra gap',
        );
        expect(find.textContaining('Referral code applied'), findsNothing);
        expect(_headingToLabelGap(tester), closeTo(22.h, 0.5));

        final field = tester.getRect(find.byType(AuthMobileField));
        expect(field.left, greaterThanOrEqualTo(0));
        expect(field.right, lessThanOrEqualTo(size.width));
        final button = _continueRect(tester);
        expect(button.left, greaterThanOrEqualTo(0));
        expect(button.right, lessThanOrEqualTo(size.width));
        expect(button.bottom, lessThanOrEqualTo(size.height));
        await _unmount(tester);
      });
    }
  });

  group('LoginView MediaQuery sizing follows the screen width', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpLoginView(tester, size: size);
        expect(tester.takeException(), isNull);

        final field = tester.getRect(find.byType(AuthMobileField));
        expect(
          field.height,
          closeTo((size.width * 46 / 360).clamp(40.0, 64.0), 0.01),
        );

        final checkbox = tester.getSize(
          find.ancestor(
            of: find.byType(Checkbox),
            matching: find.byType(SizedBox),
          ).first,
        );
        expect(checkbox.width, checkbox.height, reason: 'checkbox stays square');
        expect(
          checkbox.width,
          closeTo((size.width * 28 / 360).clamp(24.0, 36.0), 0.01),
        );

        // Phones use the full gutter-to-gutter width; tablets cap the form
        // column at 60% of the screen.
        final expectedMax =
            size.width > 600 ? size.width * 0.6 : double.infinity;
        expect(field.width, lessThanOrEqualTo(expectedMax + 0.01));
        if (size.width > 600) {
          expect(field.center.dx, closeTo(size.width / 2, 1));
        }
        await _unmount(tester);
      });
    }
  });

  group('LoginView keeps Continue above the keyboard', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        final inset = size.height * 0.4;
        await _pumpLoginView(tester, size: size, keyboardInset: inset);
        expect(tester.takeException(), isNull);
        expect(_continueRect(tester).bottom,
            lessThanOrEqualTo(size.height - inset));
        await _unmount(tester);
      });
    }
  });

  group('LoginView respects safe-area insets', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpLoginView(
          tester,
          size: size,
          padding: const EdgeInsets.only(top: 47, bottom: 34),
        );
        expect(tester.takeException(), isNull);
        expect(tester.getRect(find.text('eRupaiya')).top,
            greaterThanOrEqualTo(47));
        expect(_continueRect(tester).bottom,
            lessThanOrEqualTo(size.height - 34));
        await _unmount(tester);
      });
    }
  });

  group('LoginView supported text scales', () {
    for (final scale in const [0.85, 1.15]) {
      for (final size in responsiveTestScreenSizes) {
        testWidgets('${size.width}x${size.height} @${scale}x', (tester) async {
          await _pumpLoginView(tester, size: size, textScale: scale);
          expect(tester.takeException(), isNull);
          final button = _continueRect(tester);
          expect(button.right, lessThanOrEqualTo(size.width));
          expect(button.bottom, lessThanOrEqualTo(size.height));
          await _unmount(tester);
        });
      }
    }
  });

  group('LoginView with a stored referral code', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        _storedReferral = 'REF123';
        await _pumpLoginView(tester, size: size);
        expect(tester.takeException(), isNull);

        final banner = find.text('Referral code applied REF123');
        expect(banner, findsOneWidget);
        expect(
          tester.getRect(find.text('Mobile Number')).top,
          greaterThan(tester.getRect(banner).bottom),
        );
        expect(_continueRect(tester).bottom, lessThanOrEqualTo(size.height));
        await _unmount(tester);
      });
    }
  });

  testWidgets('keyboard reopens after the phone-number hint is picked',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            _phoneHintChannel, (_) async => '+91 98765 43210');
    await _pumpLoginView(tester);

    final editable =
        tester.widget<EditableText>(find.byType(EditableText).first);
    expect(editable.controller.text, '9876543210');
    expect(editable.focusNode.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
    await _unmount(tester);
  });

  testWidgets('brand row shows the TM mark beside the wordmark',
      (tester) async {
    await _pumpLoginView(tester);
    final wordmark = tester.getRect(find.text('eRupaiya'));
    final tm = tester.getRect(find.text('TM'));
    expect(tm.left, greaterThanOrEqualTo(wordmark.right));
    expect(tm.top, lessThan(wordmark.center.dy));
    await _unmount(tester);
  });

  testWidgets('mobile number field takes focus on open', (tester) async {
    await _pumpLoginView(tester);
    final editable =
        tester.widget<EditableText>(find.byType(EditableText).first);
    expect(editable.focusNode.hasFocus, isTrue);
    await _unmount(tester);
  });
}
