import 'package:dio/dio.dart';
import 'package:e_rupaiya/features/home/controllers/notifications_controller.dart';
import 'package:e_rupaiya/features/home/models/notification_item.dart';
import 'package:e_rupaiya/features/home/models/notifications_feed.dart';
import 'package:e_rupaiya/features/home/repositories/notifications_repository.dart';
import 'package:e_rupaiya/features/home/views/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Fake repository: serves a fixed feed (1 unread + 1 read) without network
/// and records API calls so tests can verify the Clear All flow goes through
/// the verified `clear-read` endpoint and refreshes from the server response.
class _FakeNotificationsRepository extends NotificationsRepository {
  _FakeNotificationsRepository() : super(dio: Dio());

  int markReadCalls = 0;
  int clearReadCalls = 0;

  /// Mirrors the server: after a successful clear-read the read items are
  /// gone from subsequent list responses.
  bool cleared = false;

  /// When true the clear-read call fails and nothing changes server-side.
  bool failClear = false;

  static const NotificationItem unreadItem = NotificationItem(
    id: 'n-unread',
    title: 'Unread alert title',
    subtitle: 'Unread alert body',
    actionLabel: 'View',
    iconAsset: 'assets/images/png/erupaiyaLogo.png',
    section: 'Today',
  );

  static const NotificationItem readItem = NotificationItem(
    id: 'n-read',
    title: 'Read alert title',
    subtitle: 'Read alert body',
    actionLabel: 'View',
    iconAsset: 'assets/images/png/erupaiyaLogo.png',
    section: 'Today',
    isRead: true,
  );

  @override
  Future<NotificationsFeed> fetchNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    return NotificationsFeed(
      unreadCount: 1,
      updates: const [],
      notifications:
          cleared ? const [unreadItem] : const [unreadItem, readItem],
      currentPage: 1,
      totalPages: 1,
      limit: 20,
      totalRecords: cleared ? 1 : 2,
    );
  }

  @override
  Future<bool> clearReadNotifications() async {
    clearReadCalls += 1;
    if (failClear) return false;
    cleared = true;
    return true;
  }

  @override
  Future<bool> markNotificationRead(String id) async {
    markReadCalls += 1;
    return true;
  }
}

Widget _buildNotificationsTestApp(NotificationsRepository repository) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, _) => ProviderScope(
      overrides: [
        notificationsRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(
        home: NotificationsScreen(),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<_FakeNotificationsRepository> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = _FakeNotificationsRepository();
    await tester.pumpWidget(_buildNotificationsTestApp(repo));
    // Let the initial fetch microtask + skeleton transition settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    return repo;
  }

  group('Notifications — Clear All', () {
    testWidgets('Clear All button is shown and opens the confirmation popup',
        (tester) async {
      await pumpScreen(tester);

      expect(find.text('Unread alert title'), findsOneWidget);
      expect(find.text('Read alert title'), findsOneWidget);
      expect(find.text('Clear All'), findsOneWidget);

      await tester.tap(find.text('Clear All'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.text('Are you sure you want to clear all notifications?'),
        findsOneWidget,
      );
      expect(find.widgetWithText(OutlinedButton, 'No'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Yes'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('No closes the popup without clearing anything',
        (tester) async {
      final repo = await pumpScreen(tester);

      await tester.tap(find.text('Clear All'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.widgetWithText(OutlinedButton, 'No'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Dialog gone, both notifications untouched.
      expect(
        find.text('Are you sure you want to clear all notifications?'),
        findsNothing,
      );
      expect(find.text('Unread alert title'), findsOneWidget);
      expect(find.text('Read alert title'), findsOneWidget);
      // "No" must never hit the clear-read API.
      expect(repo.clearReadCalls, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Yes calls the clear-read API and refreshes, keeping unread',
        (tester) async {
      final repo = await pumpScreen(tester);

      await tester.tap(find.text('Clear All'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Yes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Verified endpoint called once, then the feed was refreshed.
      expect(repo.clearReadCalls, 1);
      // Read item removed together with the Updates heading; unread kept.
      expect(find.text('Read alert title'), findsNothing);
      expect(find.text('Updates'), findsNothing);
      expect(find.text('Unread alert title'), findsOneWidget);
      expect(find.text('Unread'), findsOneWidget);
      expect(repo.markReadCalls, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('API failure preserves the current notifications',
        (tester) async {
      final repo = await pumpScreen(tester);
      repo.failClear = true;

      await tester.tap(find.text('Clear All'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Yes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(repo.clearReadCalls, 1);
      // Failed request: nothing is deleted locally, both items remain.
      expect(find.text('Read alert title'), findsOneWidget);
      expect(find.text('Unread alert title'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
