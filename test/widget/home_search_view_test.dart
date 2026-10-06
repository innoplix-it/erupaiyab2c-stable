import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:e_rupaiya/features/home/controllers/home_controller.dart';
import 'package:e_rupaiya/features/home/models/banner_model.dart';
import 'package:e_rupaiya/features/home/models/quick_action_model.dart';
import 'package:e_rupaiya/features/home/repositories/home_repository.dart';
import 'package:e_rupaiya/features/home/views/home_search_view.dart';

class _FakeHomeRepository implements HomeRepository {
  @override
  Future<List<BannerModel>> fetchExploreAllServicesBanners({String lang = 'en'}) async {
    return [];
  }

  @override
  Future<
      ({
        List<QuickActionCategory> categories,
        Map<String, List<BannerModel>> banners,
        bool? isNameEmailExist,
      })> fetchQuickActions({String? search}) async {
    return (
      categories: [
        const QuickActionCategory(
          category: 'Utilities',
          services: [
            QuickActionService(name: 'Electricity'),
            QuickActionService(name: 'Gas Cylinder'),
            QuickActionService(name: 'Water'),
          ],
        ),
        const QuickActionCategory(
          category: 'Recharge & Bills',
          services: [
            QuickActionService(name: 'Mobile Prepaid'),
            QuickActionService(name: 'Mobile Postpaid'),
            QuickActionService(name: 'DTH'),
            QuickActionService(name: 'Fastag'),
          ],
        ),
      ],
      banners: <String, List<BannerModel>>{},
      isNameEmailExist: true,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        homeRepositoryProvider.overrideWithValue(_FakeHomeRepository()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(392, 852),
        builder: (context, child) => const MaterialApp(
          home: HomeSearchView(),
        ),
      ),
    );
  }

  group('HomeSearchView Dynamic Search Functionality', () {
    testWidgets('Initial load shows all services', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Figma static containers render first; the API categories they
      // replace ('Utilities', 'Recharge & Bills') must not duplicate.
      expect(find.text('Recharge'), findsNWidgets(2));
      await tester.scrollUntilVisible(
        find.text('Utility Bills'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Utility Bills'), findsOneWidget);
      expect(find.text('Utilities'), findsNothing);
      expect(find.text('Recharge & Bills'), findsNothing);
    });

    testWidgets('Search with "electricity" (lowercase)', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final searchBar = find.byType(TextField);
      await tester.enterText(searchBar, 'electricity');
      await tester.pumpAndSettle();

      expect(find.text('Electricity'), findsOneWidget);
      expect(find.text('Mobile\nPrepaid'), findsNothing);
      expect(find.text('Dth'), findsNothing);
    });

    testWidgets('Search with "MOBILE" (uppercase)', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final searchBar = find.byType(TextField);
      await tester.enterText(searchBar, 'MOBILE');
      await tester.pumpAndSettle();

      expect(find.text('Mobile\nPrepaid'), findsOneWidget);
      expect(find.text('Mobile\nPostpaid'), findsOneWidget);
      expect(find.text('Electricity'), findsNothing);
      expect(find.text('Dth'), findsNothing);
    });

    testWidgets('Search with "dth" (partial / lowercase)', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final searchBar = find.byType(TextField);
      await tester.enterText(searchBar, 'dt');
      await tester.pumpAndSettle();

      expect(find.text('Dth'), findsOneWidget);
      expect(find.text('Electricity'), findsNothing);
      expect(find.text('Mobile\nPrepaid'), findsNothing);
    });

    testWidgets('Search with random text showing no result', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final searchBar = find.byType(TextField);
      await tester.enterText(searchBar, 'xyzrandom123');
      await tester.pumpAndSettle();

      expect(find.text('No services found'), findsOneWidget);
      expect(find.text('Electricity'), findsNothing);
      expect(find.text('Mobile\nPrepaid'), findsNothing);
    });

    testWidgets('Clear search restores all services', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final searchBar = find.byType(TextField);
      await tester.enterText(searchBar, 'electricity');
      await tester.pumpAndSettle();

      expect(find.text('Electricity'), findsOneWidget);
      expect(find.text('Mobile\nPrepaid'), findsNothing);

      await tester.enterText(searchBar, '');
      await tester.pumpAndSettle();

      // Browse mode restores the static Figma containers; the replaced API
      // categories stay hidden (they remain searchable only during search).
      expect(find.text('Recharge'), findsNWidgets(2));
      expect(find.text('Electricity'), findsNothing);
      expect(find.text('Utilities'), findsNothing);
    });
  });
}
