import 'package:dio/dio.dart';
import 'package:e_rupaiya/features/home/controllers/home_controller.dart';
import 'package:e_rupaiya/features/home/models/banner_model.dart';
import 'package:e_rupaiya/features/home/models/credit_card_item.dart';
import 'package:e_rupaiya/features/home/models/home_state.dart';
import 'package:e_rupaiya/features/home/repositories/home_repository.dart';
import 'package:e_rupaiya/features/services/controllers/service_extras_controller.dart';
import 'package:e_rupaiya/features/services/views/credit_card_my_cards_view.dart';
import 'package:e_rupaiya/widgets/k_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _saraswat = CreditCardItem(
  billerName: 'Saraswat Co-Operative Bank Ltd',
  maskedIdentifier: '****2656',
  lastAmount: 1,
  lastPaidDate: '2026-07-08',
);

const _hsbc = CreditCardItem(
  billerName: 'HSBC Credit Card',
  maskedIdentifier: '***7355055961',
  lastAmount: 1,
  lastPaidDate: '2026-06-03',
);

class _RecordingHomeController extends HomeController {
  _RecordingHomeController(this.onRemove)
      : super(repository: HomeRepository(dio: Dio())) {
    state = const HomeState(
      isFetchingCreditCards: false,
      creditCardActions: [_hsbc, _saraswat],
    );
  }

  final Future<bool> Function(String maskedIdentifier) onRemove;
  int calls = 0;

  @override
  Future<void> fetchCreditCardActions() async {}

  @override
  Future<bool> removeCreditCard(String maskedIdentifier) {
    calls++;
    return onRemove(maskedIdentifier);
  }
}

Future<void> _pumpCards(
  WidgetTester tester,
  _RecordingHomeController controller, {
  Size size = const Size(360, 800),
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.view.padding = const FakeViewPadding(top: 24, bottom: 0);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (_, __) => ProviderScope(
        overrides: [
          homeControllerProvider.overrideWith((ref) => controller),
          servicePageBannersProvider.overrideWith(
            (ref, slug) async => const <BannerModel>[],
          ),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
          home: const CreditCardMyCardsView(),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Remove Card posts the tapped card masked_identifier',
      (tester) async {
    String? sent;
    final controller = _RecordingHomeController((id) async {
      sent = id;
      return true;
    });

    await _pumpCards(tester, controller);
    expect(find.text('Saraswat Co-Operative Bank Ltd'), findsOneWidget);

    final menus = find.byIcon(Icons.more_vert);
    expect(menus, findsNWidgets(2));
    await tester.tap(menus.at(1));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remove Card'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remove'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(sent, '****2656');
    expect(controller.calls, 1);
    expect(find.text('HSBC Credit Card'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('failed remove leaves both cards on screen', (tester) async {
    String? sent;
    final controller = _RecordingHomeController((id) async {
      sent = id;
      return false;
    });

    await _pumpCards(tester, controller);
    await tester.tap(find.byIcon(Icons.more_vert).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove Card'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(sent, '****2656');
    expect(find.text('Saraswat Co-Operative Bank Ltd'), findsOneWidget);
    expect(find.text('HSBC Credit Card'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Remove Card sheet and dialog fit 320x568 at 1.15 text',
      (tester) async {
    final controller = _RecordingHomeController((_) async => false);

    await _pumpCards(
      tester,
      controller,
      size: const Size(320, 568),
      textScale: 1.15,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    expect(find.text('Remove Card'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Remove Card'));
    await tester.pumpAndSettle();
    expect(find.text('Remove Card?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Remove'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
