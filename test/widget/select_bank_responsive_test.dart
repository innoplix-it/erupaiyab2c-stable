import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:e_rupaiya/features/refer_and_earn/views/select_bank_view.dart';
import 'package:e_rupaiya/services/dio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/responsive_test_sizes.dart';

/// A deterministic bank list mirroring the `/api/banks` shape consumed by
/// [BankAccountRepository.fetchBanks]. Popular and all-bank names are kept
/// distinct so widget finders stay unambiguous.
const _banksPayload = {
  'status': true,
  'code': 200,
  'message': 'ok',
  'data': {
    'popular_banks': [
      {'id': '1', 'bank_name': 'HDFC Bank', 'bank_code': 'HDFC0000060'},
      {'id': '2', 'bank_name': 'ICICI Bank', 'bank_code': 'ICIC0000087'},
      {'id': '3', 'bank_name': 'Axis Bank', 'bank_code': 'UTIB0000049'},
    ],
    'all_banks': [
      {'id': '11', 'bank_name': 'Punjab National Bank', 'bank_code': 'PUNB0000000'},
      {'id': '12', 'bank_name': 'State Bank of India', 'bank_code': 'SBIN0000001'},
      {'id': '13', 'bank_name': 'Bank of Baroda', 'bank_code': 'BARB0000001'},
      {'id': '14', 'bank_name': 'Kotak Mahindra Bank', 'bank_code': 'KKBK0000001'},
      {'id': '15', 'bank_name': 'Yes Bank', 'bank_code': 'YESB0000001'},
    ],
  },
};

class _FakeBanksAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(_banksPayload),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<void> _pumpSelectBank(
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
    ScreenUtilInit(
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
            child: const SelectBankView(),
          ),
        ),
      ),
    ),
  );

  // Drain the fetchBanks microtask chain (the fake adapter resolves
  // immediately) so the populated grid/list renders rather than the spinner.
  // runAsync lets Dio's real async pipeline complete inside the fake-async
  // test zone; a following pump() then renders the loaded state.
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 30)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 120));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final dio = DioService.instance.client;
    // The shared client carries an auth interceptor that reads secure
    // storage; that platform channel is unavailable under test and would
    // reject fetchBanks. Clear it so the request reaches the fake adapter.
    dio.interceptors.clear();
    dio.httpClientAdapter = _FakeBanksAdapter();
  });

  group('renders without overflow across shared sizes', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpSelectBank(tester, size: size);
        expect(tester.takeException(), isNull);

        expect(find.text('Add Bank Account'), findsOneWidget);
        expect(find.text('Search bank name'), findsOneWidget);
        expect(find.text('Popular Banks'), findsOneWidget);
        expect(find.text('All Banks'), findsOneWidget);
        // The list actually loaded (not stuck on the spinner / error state).
        expect(find.text('HDFC Bank'), findsOneWidget);
        expect(find.textContaining('State Bank of India'), findsOneWidget);
      });
    }
  });

  group('bank content stays inside the screen on every shared size', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpSelectBank(tester, size: size);
        final screen = tester.view.physicalSize / tester.view.devicePixelRatio;

        for (final finder in [
          find.text('HDFC Bank'),
          find.text('ICICI Bank'),
          find.text('Axis Bank'),
          find.text('Search bank name'),
        ]) {
          final rect = tester.getRect(finder);
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(screen.width));
        }
      });
    }
  });

  testWidgets('search field filters the popular grid by name', (tester) async {
    await _pumpSelectBank(tester, size: const Size(390, 844));

    await tester.enterText(find.byType(TextField).first, 'icici');
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('ICICI Bank'), findsOneWidget);
    expect(find.text('HDFC Bank'), findsNothing);
    expect(find.text('Axis Bank'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'zzzz');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('No popular banks found.'), findsOneWidget);
  });

  testWidgets('selecting a bank pops with the chosen item', (tester) async {
    await _pumpSelectBank(tester, size: const Size(390, 844));
    await tester.tap(find.text('Axis Bank'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  group('supported text scales', () {
    for (final scale in [0.85, 1.0, 1.15]) {
      testWidgets('textScale $scale at 360x690', (tester) async {
        await _pumpSelectBank(
          tester,
          size: const Size(360, 690),
          textScale: scale,
        );
        expect(find.text('Popular Banks'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
