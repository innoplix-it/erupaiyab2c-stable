import 'package:e_rupaiya/features/refer_and_earn/components/referral_qr_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

const _link = 'https://erupaiya.com/user/ERU123';

Future<void> _pump(
  WidgetTester tester, {
  String? profilePhotoUrl,
  ReferralQrPhotoLoader? photoLoader,
  Widget? avatarPreview,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Center(
        child: ReferralQrCode(
          data: _link,
          qrSize: 180,
          profilePhotoUrl: profilePhotoUrl,
          photoLoader: photoLoader,
          avatarPreview: avatarPreview,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('preserves the referral URL and level L without a photo',
      (tester) async {
    await _pump(tester);
    final qr = tester.widget<QrImageView>(find.byType(QrImageView));
    expect(
      find.byWidgetPredicate(
        (w) => w is ReferralQrCode && w.data == _link,
      ),
      findsOneWidget,
    );
    expect(qr.errorCorrectionLevel, QrErrorCorrectLevel.L);
    expect(find.byKey(ReferralQrCode.avatarOverlayKey), findsNothing);
  });

  testWidgets('empty profile URL keeps the original QR', (tester) async {
    await _pump(tester, profilePhotoUrl: '   ');
    final qr = tester.widget<QrImageView>(find.byType(QrImageView));
    expect(qr.errorCorrectionLevel, QrErrorCorrectLevel.L);
    expect(find.byKey(ReferralQrCode.avatarOverlayKey), findsNothing);
  });

  testWidgets('failed photo load does not cover the QR', (tester) async {
    await _pump(
      tester,
      profilePhotoUrl: 'https://example.invalid/photo.png',
      photoLoader: (_, __) async => false,
    );
    await tester.pump();
    final qr = tester.widget<QrImageView>(find.byType(QrImageView));
    expect(qr.errorCorrectionLevel, QrErrorCorrectLevel.L);
    expect(find.byKey(ReferralQrCode.avatarOverlayKey), findsNothing);
  });

  testWidgets('loaded photo uses level H and stays inside the quiet zone',
      (tester) async {
    await _pump(
      tester,
      profilePhotoUrl: 'https://example.invalid/photo.png',
      photoLoader: (_, __) async => true,
      avatarPreview: const ColoredBox(color: Color(0xFFDD5428)),
    );
    await tester.pump();

    final code = tester.widget<ReferralQrCode>(find.byType(ReferralQrCode));
    expect(code.data, _link);
    final qr = tester.widget<QrImageView>(find.byType(QrImageView));
    expect(qr.errorCorrectionLevel, QrErrorCorrectLevel.H);

    final overlay = find.byKey(ReferralQrCode.avatarOverlayKey);
    expect(overlay, findsOneWidget);
    final qrRect = tester.getRect(find.byType(QrImageView));
    final avatarRect = tester.getRect(overlay);
    expect(avatarRect.left, greaterThan(qrRect.left + 10));
    expect(avatarRect.top, greaterThan(qrRect.top + 10));
    expect(avatarRect.right, lessThan(qrRect.right - 10));
    expect(avatarRect.bottom, lessThan(qrRect.bottom - 10));
    expect(avatarRect.width / qrRect.width, lessThan(0.35));
  });
}
