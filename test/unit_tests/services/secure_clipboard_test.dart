import 'dart:io';

import 'package:e_rupaiya/services/secure_clipboard.dart';
import 'package:e_rupaiya/widgets/grey_text_form_field.dart';
import 'package:e_rupaiya/widgets/k_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

// App-wide clipboard security (AUD-038 follow-up) — every clipboard write must
// go through SecureClipboard.copy. These tests are fully behavioral: the real
// platform channel is mocked, only dummy (never real) identity values are used.
void main() {
  final clipboardWrites = <String?>[];

  setUp(() {
    clipboardWrites.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboardWrites.add((call.arguments as Map)['text'] as String?);
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('containsSensitiveData — blocked patterns', () {
    const blocked = <String, String>{
      'PAN plain': 'ABCDE1234F',
      'PAN lower-case inside labelled text': 'pan no: abcde1234f',
      'Aadhaar spaced': '2345 6789 0123',
      'Aadhaar hyphenated': '2345-6789-0123',
      'Aadhaar plain with label': 'Your Aadhaar number is 234567890123',
      'Aadhaar old-brand label': 'aadhar: 234567890123',
      'Bank account labelled': 'Account No: 50100123456789',
      'Bank account label in text': ' beneficiary account 123456789012 ',
      'IFSC plain': 'HDFC0001234',
      'IFSC lower-case': 'ifsc code hdfc0001234',
      'IFSC legacy 4+7 form': 'SBIN0001234',
      'IFSC inside combined text':
          'Bank: HDFC, IFSC: HDFC0001234, Acct: 50100123456789',
      'PAN embedded with surrounding labels':
          'Name: RAJU, PAN ABCDE1234F, pay ₹500',
      'Account digits after rupee text':
          'Payment of ₹500 from account 50100123456789 for college fees',
    };
    blocked.forEach((name, value) {
      test(name, () {
        expect(SecureClipboard.containsSensitiveData(value), isTrue,
            reason: 'should block: $name');
      });
    });
  });

  group('containsSensitiveData — allowed (non-sensitive) patterns', () {
    const allowed = <String, String>{
      'empty': '',
      'plain text': ' Electricity bill paid ',
      'transaction id': 'TXN20261030153045',
      '12-digit UTR / bank reference': '123456789012',
      '8-digit RRN': '00674523',
      'UPI VPA': 'raju@okhdfcbank',
      'UPI VPA with bank suffix digits': 'raju@axisbank',
      'alphanumeric order id': 'ABCD0123456789',
      'referral link': 'https://erupaiya.app/refer?code=RAJU1234',
      'short digits': '12345678',
      'IFSC word alone': 'IFSC',
      'pan card product name': 'Pan Card Bill Payment',
    };
    allowed.forEach((name, value) {
      test(name, () {
        expect(SecureClipboard.containsSensitiveData(value), isFalse,
            reason: 'should allow: $name');
      });
    });
  });

  group('SecureClipboard.copy — clipboard write behaviour', () {
    test('blocked copy performs NO clipboard write and returns false',
        () async {
      final ok = await SecureClipboard.copy('ABCDE1234F');
      expect(ok, isFalse);
      expect(clipboardWrites, isEmpty);
    });

    test('allowed copy writes the exact text and returns true', () async {
      const ref = '123456789012';
      final ok = await SecureClipboard.copy(ref);
      expect(ok, isTrue);
      expect(clipboardWrites, [ref]);
    });

    test('referral link still copies through the guard', () async {
      const url = 'https://erupaiya.app/refer?code=RAJU1234';
      final ok = await SecureClipboard.copy(url);
      expect(ok, isTrue);
      expect(clipboardWrites, [url]);
    });

    test('blocked copy does not clear or modify existing clipboard content',
        () async {
      await SecureClipboard.copy('00674523'); // allowed RRN
      final ok = await SecureClipboard.copy('HDFC0001234'); // blocked IFSC
      expect(ok, isFalse);
      // Only the allowed write ever reached the platform — the guard never
      // writes an empty/replacement value over it.
      expect(clipboardWrites, ['00674523']);
    });
  });

  testWidgets(
      'blocked copy shows the security message snackbar', (tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        builder: (_, __) => MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: Center(child: Text('HOST'))),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final ok = await SecureClipboard.copy('ABCDE1234F');
    expect(ok, isFalse);
    await tester.pump();
    expect(find.text(SecureClipboard.blockedMessage), findsOneWidget);

    // Flush the auto-dismiss timer so teardown is clean.
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  });

  group('sensitive input fields — selection toolbar cannot copy', () {
    // The framework's own Copy/Cut buttons write straight to the clipboard;
    // sensitiveFieldContextMenu must strip them from the toolbar while
    // keeping the rest of the UX (Select all / Paste).
    // Deterministic harness: select all programmatically, then render the
    // exact toolbar our contextMenuBuilder produces for that state.
    Future<void> pumpGuardedToolbar(
        WidgetTester tester, bool blockCopy) async {
      // One controller instance shared across both pump phases so the
      // EditableTextState (and its selection) survives the toolbar re-render.
      final controller = TextEditingController();
      Widget harness({Widget? toolbar}) {
        return ScreenUtilInit(
          designSize: const Size(360, 690),
          builder: (_, __) => MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  GreyTextFormField(
                    controller: controller,
                    blockCopy: blockCopy,
                  ),
                  if (toolbar != null) toolbar else const SizedBox.shrink(),
                ],
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'ABCDE1234F note');
      await tester.pumpAndSettle();

      final state = tester.state<EditableTextState>(find.byType(EditableText));
      // Partial selection of the first word via the controller — with the
      // whole text selected the framework drops the 'Select all' button,
      // which is not what this guard test is about.
      controller.selection =
          const TextSelection(baseOffset: 0, extentOffset: 10);
      await tester.pump();

      // Framework default must offer Copy (otherwise the app silently has no
      // copy UX at all and this test proves nothing).
      expect(
        state.contextMenuButtonItems.map((item) => item.type),
        contains(ContextMenuButtonType.copy),
      );

      await tester.pumpWidget(harness(
        toolbar: Builder(builder: (context) =>
            SecureClipboard.sensitiveFieldContextMenu(context, state)),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('guarded toolbar strips Copy/Cut but keeps Select all',
        (tester) async {

      await pumpGuardedToolbar(tester, true);
      // 'Paste' is only offered by the framework when the platform clipboard
      // already holds content, so it is not asserted here.
      expect(find.text('Select all'), findsOneWidget);
      expect(find.text('Copy'), findsNothing);
      expect(find.text('Cut'), findsNothing);
      expect(clipboardWrites, isEmpty,
          reason: 'toolbar alone must never write the clipboard');
    });

    testWidgets('unguarded fields still expose Copy through the framework',
        (tester) async {
      // A plain TextField using the DEFAULT contextMenuBuilder must still
      // show Copy — the protection is field-scoped, not an app-wide UX loss.
      final controller = TextEditingController();
      Widget harness(Widget? toolbarBuilder) {
        return ScreenUtilInit(
          designSize: const Size(360, 690),
          builder: (_, __) => MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  TextField(controller: controller),
                  if (toolbarBuilder != null) toolbarBuilder,
                ],
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(harness(null));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'ABCDE1234F');
      await tester.pumpAndSettle();
      final state = tester.state<EditableTextState>(find.byType(EditableText));
      state.selectAll(SelectionChangedCause.longPress);
      await tester.pump();

      await tester.pumpWidget(harness(Builder(builder: (context) {
        // Exactly what the framework default builder produces for a plain
        // TextField (AdaptiveTextSelectionToolbar.buttonItems passthrough).
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: state.contextMenuAnchors,
          buttonItems: state.contextMenuButtonItems,
        );
      })));
      await tester.pumpAndSettle();
      expect(find.text('Copy'), findsOneWidget);
    });
  
    test('every sensitive entry screen wires the toolbar guard', () {
      const guarded = [
        'lib/widgets/pan_aadhaar_input_fields.dart',
        'lib/widgets/grey_text_form_field.dart',
        'lib/features/refer_and_earn/views/add_bank_account_view.dart',
        'lib/features/educationFees/views/education_fees_recipient_view.dart',
      ];
      for (final path in guarded) {
        expect(File(path).readAsStringSync(),
            contains('SecureClipboard.sensitiveFieldContextMenu'),
            reason: '$path must block selection-toolbar copy on sensitive fields');
      }
      // The identity-completion screen opts in through the shared widget.
      final tmp = File(
              'lib/features/auth/views/temporary_block_identity_completion_view.dart')
          .readAsStringSync();
      expect('blockCopy: true'.allMatches(tmp).length, 2,
          reason: 'PAN and Aadhaar fields both opt in');
    });
  });
  
  group('entry-point audit — centralized protection is enforced', () {
    test('Clipboard.setData exists only inside SecureClipboard', () {
      final offenders = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final content = entity.readAsStringSync();
        if (content.contains('Clipboard.setData') &&
            !entity.path.endsWith('secure_clipboard.dart')) {
          offenders.add(entity.path);
        }
      }
      expect(offenders, isEmpty,
          reason: 'raw clipboard writes bypass the security gate');
    });

    const guardedFiles = [
      'lib/features/profile/views/transaction_detail_screen.dart',
      'lib/features/services/views/credit_card_transaction_detail_screen.dart',
      'lib/widgets/payment_success_flow.dart',
      'lib/features/refer_and_earn/views/refer_and_earn_view.dart',
    ];
    for (final path in guardedFiles) {
      test('$path uses SecureClipboard', () {
        final content = File(path).readAsStringSync();
        expect(content, contains('SecureClipboard.copy'));
      });
    }

    test('no SelectableText selection-copy path exists in the app', () {
      // Selectable widgets would bypass the guard; the app must not add them
      // without extending this audit.
      final selectable = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.readAsStringSync().contains('SelectableText')) {
          selectable.add(entity.path);
        }
      }
      expect(selectable, isEmpty);
    });
  });
}
