import 'package:cached_network_image/cached_network_image.dart';
import 'package:e_rupaiya/widgets/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Loads [url] for the QR avatar. True only when the image is ready to paint.
typedef ReferralQrPhotoLoader = Future<bool> Function(
  String url,
  BuildContext context,
);

/// Referral QR with optional centered profile photo (overlay, not embedded).
///
/// The QR renders immediately with the original payload. Error correction stays
/// at level L (qr_flutter default) until the photo is actually shown, then
/// switches to H so the center overlay can be recovered. The avatar is about
/// 22% of the QR edge (~6% of its area) and sits inside the quiet zone.
class ReferralQrCode extends HookWidget {
  const ReferralQrCode({
    super.key,
    required this.data,
    required this.qrSize,
    this.profilePhotoUrl,
    this.photoLoader,
    this.avatarPreview,
  });

  final String data;
  final double qrSize;

  /// Logged-in user photo from [ProfileModel.profilePhotoUrl].
  final String? profilePhotoUrl;

  /// Test seam. Production uses [precacheImage].
  final ReferralQrPhotoLoader? photoLoader;

  /// Replaces the network photo in tests so layout can be measured offline.
  final Widget? avatarPreview;

  static const ValueKey qrKey = ValueKey('refer-earn-qr');
  static const ValueKey avatarOverlayKey = ValueKey('refer-earn-qr-avatar');

  @override
  Widget build(BuildContext context) {
    final url = profilePhotoUrl?.trim() ?? '';
    final showAvatar = useState(false);

    useEffect(() {
      if (url.isEmpty) {
        showAvatar.value = false;
        return null;
      }
      var cancelled = false;
      final loader = photoLoader ?? _precacheProfilePhoto;
      loader(url, context).then((ready) {
        if (!cancelled) showAvatar.value = ready;
      });
      return () => cancelled = true;
    }, [url, photoLoader]);

    final avatarDiameter = qrSize * 0.22;
    final ringPadding = qrSize * 0.03;
    final useHighEc = showAvatar.value;

    return Stack(
      alignment: Alignment.center,
      children: [
        QrImageView(
          key: qrKey,
          data: data,
          version: QrVersions.auto,
          size: qrSize,
          gapless: true,
          // L matches the previous QR (no logo). H (~30% recovery) only while
          // the avatar is painted. Overlay diameter is 0.28 of [qrSize].
          padding: const EdgeInsets.all(10),
          errorCorrectionLevel:
              useHighEc ? QrErrorCorrectLevel.H : QrErrorCorrectLevel.L,
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: Colors.black,
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: Colors.black,
          ),
        ),
        if (showAvatar.value)
          Container(
            key: avatarOverlayKey,
            width: avatarDiameter + ringPadding * 2,
            height: avatarDiameter + ringPadding * 2,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            padding: EdgeInsets.all(ringPadding),
            child: ClipOval(
              child: avatarPreview ??
                  AppNetworkImage(
                    url: url,
                    width: avatarDiameter,
                    height: avatarDiameter,
                    fit: BoxFit.cover,
                    showShimmer: false,
                    errorWidget: const SizedBox.shrink(),
                  ),
            ),
          ),
      ],
    );
  }
}

Future<bool> _precacheProfilePhoto(String url, BuildContext context) async {
  try {
    await precacheImage(CachedNetworkImageProvider(url), context);
    return true;
  } catch (_) {
    return false;
  }
}
