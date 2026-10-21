// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:ui' as ui;

import 'package:e_rupaiya/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../components/refer_and_earn_app_bar.dart';
import '../components/referral_share_actions.dart';
import '../providers/referral_link_provider.dart';
import '../repositories/referral_repository.dart';
import '../services/referral_share_service.dart';

// Figma frame is 440×956; ScreenUtil design size is 360×690. Convert once,
// then let ScreenUtil scale once.
double _figmaW(double px) => (px * 360 / 440).w;
double _figmaH(double px) => (px * 690 / 956).h;
double _figmaR(double px) => (px * 360 / 440).r;
double _figmaSp(double px) => (px * 360 / 440).sp;

const String _kFont = 'Plus Jakarta Sans';

// ── How-It-Works step card spec (Figma px, converted by helpers) ─────────────
const double _kStepIconTile = 58; // icon tile 58×58
const double _kStepIconTileNarrow = 50; // phones narrower than 340dp
const double _kStepIconRadius = 14; // icon tile corner radius
const double _kStepIconInnerRatio = 0.62; // svg size inside tile
const double _kStepCardRadius = 16; // card corner radius
const double _kStepCardPadV = 13.5; // card top/bottom padding -> height 85
const double _kStepCardPadLeft = 14; // card left padding before icon tile
const double _kStepCardPadRight = 12;
const double _kStepIconTextGap = 13; // icon tile -> text
const double _kStepCardGap = 15; // vertical gap between cards
const double _kStepBadgeSize = 26;
const double _kStepBadgeCardGap = 16; // badge -> card

const Color _kOrange = Color(0xFFE5532D);
const Color _kPeachBg = Color(0xFFFDF3EF);
const Color _kHeroBlue = Color(0xFF084591);
const Color _kWalletBlue = Color(0xFF084591);

TextStyle _ts({
  required double size,
  FontWeight weight = FontWeight.w400,
  Color color = Colors.black,
  double? height,
  double letterSpacing = 0,
}) {
  return TextStyle(
    fontFamily: _kFont,
    fontSize: _figmaSp(size),
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing == 0 ? 0 : _figmaSp(letterSpacing),
  );
}

const String _cardArrowSvg = '''
<svg width="57" height="57" viewBox="0 0 57 57" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M27.2322 17.0934L41.6464 21.4612L37.2786 35.8754" stroke="white" stroke-width="1.5" stroke-miterlimit="10" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M15.3454 35.5309L41.3834 21.6034" stroke="white" stroke-width="1.5" stroke-miterlimit="10" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

class ReferAndEarnView extends HookConsumerWidget {
  const ReferAndEarnView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = MediaQuery.of(context);
    final topInset = media.padding.top;
    final screenWidth = media.size.width;
    // Figma 440 frame: hero body ~268 + 28 overlap under the white panel.
    final heroOverlap = _figmaH(28);
    final heroHeight = topInset + _figmaH(268) + heroOverlap;
    // Narrow phones (e.g. 320) need a slightly smaller QR to keep side gutters.
    final qrSize = screenWidth < 340 ? _figmaW(156) : _figmaW(180);

    final linkAsync = ref.watch(referralLinkProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const ReferralShareFooter(),
      body: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ReferAndEarnAppBar(
                title: '',
                height: heroHeight,
                bottomReserve: heroOverlap,
                backgroundColor: _kHeroBlue,
                hideBottomStrip: true,
                body: Column(
                  children: [
                    SizedBox(height: _figmaH(6)),
                    Text(
                      'One Refer = 100 eCoins',
                      key: const ValueKey('refer-earn-hero-title'),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: _ts(
                        size: 22,
                        weight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.0,
                        // Figma letter-spacing: -2% of font size.
                        letterSpacing: -0.44,
                      ),
                    ),
                    SizedBox(height: _figmaH(28)),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: _figmaW(317)),
                          child: AspectRatio(
                            aspectRatio: 317 / 164,
                            child: SvgPicture.asset(
                              key: const ValueKey('refer-earn-hero'),
                              FileConstants.referEarnHeroSvg,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: heroHeight - heroOverlap),
                child: Column(
                  children: [
                    Container(
                      key: const ValueKey('refer-earn-panel'),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(_figmaR(26)),
                        ),
                      ),
                      // Figma: ~27 top before wallet ring, ~42 below QR card.
                      padding: EdgeInsets.fromLTRB(
                        0,
                        _figmaH(27),
                        0,
                        _figmaH(42),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding:
                            EdgeInsets.symmetric(horizontal: _figmaW(22)),
                            child: const _WalletPillButton(),
                          ),
                          SizedBox(height: _figmaH(21)),
                          Padding(
                            padding:
                            EdgeInsets.symmetric(horizontal: _figmaW(25)),
                            child: const _HowItWorksSection(),
                          ),
                          SizedBox(height: _figmaH(38)),
                          Padding(
                            padding:
                            EdgeInsets.symmetric(horizontal: _figmaW(57)),
                            child: _ReferralQrCard(
                              linkAsync: linkAsync,
                              qrSize: qrSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const _CoinValueSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Wallet pill (with white ring) ─────────────────────

class _WalletPillButton extends StatelessWidget {
  const _WalletPillButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RouteConstants.referAndEarnWallet),
      child: Container(
        key: const ValueKey('refer-earn-wallet-ring'),
        width: double.infinity,
        padding: EdgeInsets.all(_figmaW(11)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_figmaR(44)),
          border: Border.all(color: const Color(0xFFF1F1F1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: _figmaR(16),
              offset: Offset(0, _figmaH(4)),
            ),
          ],
        ),
        child: Container(
          key: const ValueKey('refer-earn-wallet-pill'),
          width: double.infinity,
          height: _figmaH(54),
          padding: EdgeInsets.symmetric(horizontal: _figmaW(20)),
          decoration: BoxDecoration(
            color: _kWalletBlue,
            borderRadius: BorderRadius.circular(_figmaR(40)),
          ),
          child: Row(
            children: [
              Image.asset(
                FileConstants.coin_3d,
                width: _figmaW(22),
                height: _figmaW(22),
              ),
              SizedBox(width: _figmaW(10)),
              Expanded(
                child: Text(
                  'My Wallet & Referals',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _ts(
                    size: 15,
                    weight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              SvgPicture.string(
                _cardArrowSvg,
                width: _figmaW(28),
                height: _figmaW(28),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────── How it works ──────────────────────────────────

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  // Getter (not static final) so hot reload picks up spec changes.
  static List<_StepSpec> get _steps => <_StepSpec>[
    _StepSpec(
      number: '1',
      title: 'Invite Your Friends',
      subtitle: 'Share your referral link with friends.',
      titleColor: const Color(0xFF5B3FF0),
      badgeColor: const Color(0xFFEDEAFB),
      cardColor: const Color(0xFFF8F6FD),
      iconTileColor: const Color(0xFFEEEBFC),
      iconAsset: FileConstants.referStepInvitePng,
    ),
    _StepSpec(
      number: '2',
      title: 'They join eRupaiya',
      subtitle: 'Your friends sign up successfully.',
      titleColor: const Color(0xFF5BA67C),
      badgeColor: const Color(0xFFE4F3EA),
      cardColor: const Color(0xFFF4F9F6),
      iconTileColor: const Color(0xFFE9F4EE),
      iconAsset: FileConstants.referStepJoinPng,
    ),
    _StepSpec(
      number: '3',
      title: 'First Eligible Payment',
      subtitle: 'They complete a qualifying payment.',
      titleColor: const Color(0xFF5B9BEA),
      badgeColor: const Color(0xFFE3F0FD),
      cardColor: const Color(0xFFF4F8FC),
      iconTileColor: const Color(0xFFE3F1FE),
      iconAsset: FileConstants.referStepPaymentPng,
    ),
    _StepSpec(
      number: '4',
      title: 'You get the matching reward',
      subtitle: 'Check your rewards from invited friends.',
      titleColor: const Color(0xFFD39B4A),
      badgeColor: const Color(0xFFFBEBD3),
      cardColor: const Color(0xFFFCF8F1),
      iconTileColor: const Color(0xFFFBF1E0),
      iconAsset: FileConstants.referStepRewardPng,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('refer-earn-how-it-works'),
      width: double.infinity,
      padding: EdgeInsets.only(top: _figmaH(20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_figmaR(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: _figmaR(14),
            offset: Offset(0, _figmaH(2)),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'How It Works',
            textAlign: TextAlign.center,
            style: _ts(
              size: 20,
              weight: FontWeight.w500,
            ),
          ),
          SizedBox(height: _figmaH(8)),
          // Width limited so the copy wraps in 3 lines like the design.
          Padding(
            padding: EdgeInsets.symmetric(horizontal: _figmaW(26)),
            child: Text.rich(
              TextSpan(
                style: _ts(
                  size: 14,
                  color: Colors.black.withOpacity(0.55),
                  height: 1.55,
                  letterSpacing: -0.2,
                ),
                children: [
                  const TextSpan(text: 'Refer once and '),
                  TextSpan(
                    text: 'earn coins every time',
                    style: _ts(
                      size: 14,
                      weight: FontWeight.w500,
                      color: Colors.black,
                      height: 1.55,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const TextSpan(
                    text: ' your friend spends in the app. Use your coins '
                        'like real money for payments anytime.',
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: _figmaH(22)),
          _StepsTimeline(steps: _steps),
        ],
      ),
    );
  }
}

class _StepSpec {
  const _StepSpec({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.titleColor,
    required this.badgeColor,
    required this.cardColor,
    required this.iconTileColor,
    required this.iconAsset,
  });

  final String number;
  final String title;
  final String subtitle;
  final Color titleColor;
  final Color badgeColor;
  final Color cardColor;
  final Color iconTileColor;
  final String iconAsset;
}

class _StepsTimeline extends StatelessWidget {
  const _StepsTimeline({required this.steps});

  final List<_StepSpec> steps;

  @override
  Widget build(BuildContext context) {
    final badgeSize = _figmaW(_kStepBadgeSize);
    final mediaW = MediaQuery.sizeOf(context).width;
    final iconTile = mediaW < 340
        ? _figmaW(_kStepIconTileNarrow)
        : _figmaW(_kStepIconTile);
    final cardPadV = _figmaH(_kStepCardPadV);
    final stepGap = _figmaH(_kStepCardGap);
    final cardHeight = cardPadV * 2 + iconTile;
    // Badge is vertically centred on the card.
    final badgeTop = (cardHeight - badgeSize) / 2;

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _StepRow(
            spec: steps[i],
            badgeSize: badgeSize,
            iconTile: iconTile,
            cardPadV: cardPadV,
            cardHeight: cardHeight,
            badgeTop: badgeTop,
            connectorHeight: i == steps.length - 1 ? 0 : stepGap,
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.spec,
    required this.badgeSize,
    required this.iconTile,
    required this.cardPadV,
    required this.cardHeight,
    required this.badgeTop,
    required this.connectorHeight,
  });

  final _StepSpec spec;
  final double badgeSize;
  final double iconTile;
  final double cardPadV;
  final double cardHeight;
  final double badgeTop;
  final double connectorHeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: badgeSize,
          child: Padding(
            padding: EdgeInsets.only(top: badgeTop),
            child: _StepNumberBadge(
              number: spec.number,
              color: spec.titleColor,
              background: spec.badgeColor,
              size: badgeSize,
            ),
          ),
        ),
        SizedBox(width: _figmaW(_kStepBadgeCardGap)),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: connectorHeight),
            child: Container(
              height: cardHeight,
              padding: EdgeInsets.fromLTRB(
                _figmaW(_kStepCardPadLeft),
                cardPadV,
                _figmaW(_kStepCardPadRight),
                cardPadV,
              ),
              decoration: BoxDecoration(
                color: spec.cardColor,
                borderRadius: BorderRadius.circular(_figmaR(_kStepCardRadius)),
                border: Border.all(
                  color: spec.titleColor.withOpacity(0.07),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  _HowItWorksStepIcon(
                    key: ValueKey('refer-earn-step-tile-${spec.number}'),
                    asset: spec.iconAsset,
                    size: iconTile,
                    tileColor: spec.iconTileColor,
                  ),
                  SizedBox(width: _figmaW(_kStepIconTextGap)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          spec.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: _ts(
                            size: 15,
                            weight: FontWeight.w600,
                            color: spec.titleColor,
                            height: 1.25,
                          ),
                        ),
                        SizedBox(height: _figmaH(3)),
                        Text(
                          spec.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: _ts(
                            size: 12,
                            color: Colors.black.withOpacity(0.6),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Step icon tile: exactly [size] × [size], rounded, with the PNG icon
/// centred inside it (see _kStepIconInnerRatio).
class _HowItWorksStepIcon extends StatelessWidget {
  const _HowItWorksStepIcon({
    super.key,
    required this.asset,
    required this.size,
    required this.tileColor,
  });

  final String asset;
  final double size;
  final Color tileColor;

  @override
  Widget build(BuildContext context) {
    final inner = size * _kStepIconInnerRatio;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(_figmaR(_kStepIconRadius)),
      ),
      child: Image.asset(
        asset,
        width: inner,
        height: inner,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class _StepNumberBadge extends StatelessWidget {
  const _StepNumberBadge({
    required this.number,
    required this.color,
    required this.background,
    required this.size,
  });

  final String number;
  final Color color;
  final Color background;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
      ),
      child: Text(
        number,
        style: _ts(
          size: 14,
          weight: FontWeight.w700,
          color: color,
          height: 1,
        ),
      ),
    );
  }
}

// ───────────────────────────── Referral QR card ──────────────────────────────

class _ReferralQrCard extends HookConsumerWidget {
  const _ReferralQrCard({
    required this.linkAsync,
    required this.qrSize,
  });

  final AsyncValue<ReferralLinkResponse> linkAsync;
  final double qrSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qrKey = useMemoized(GlobalKey.new);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        _figmaW(16),
        _figmaH(30),
        _figmaW(16),
        _figmaH(28),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_figmaR(22)),
        border: Border.all(color: const Color(0xFFE9E9E9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: _figmaR(12),
            offset: Offset(0, _figmaH(3)),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'My Referral QR',
            textAlign: TextAlign.center,
            style: _ts(
              size: 20,
              weight: FontWeight.w500,
            ),
          ),
          SizedBox(height: _figmaH(8)),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: _figmaW(215)),
            child: Text(
              'share this qr with your friends to invite them to eRupaiya',
              textAlign: TextAlign.center,
              style: _ts(
                size: 13,
                color: Colors.black.withOpacity(0.55),
                height: 1.5,
                letterSpacing: -0.1,
              ),
            ),
          ),
          SizedBox(height: _figmaH(10)),
          linkAsync.when(
            loading: () => SizedBox(
              height: qrSize,
              child: const Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => _QrError(
              onRetry: () => ref.invalidate(referralLinkProvider),
              height: qrSize,
            ),
            data: (data) {
              final link = data.referralLink.trim();
              if (!data.status || link.isEmpty) {
                return _QrError(
                  onRetry: () => ref.invalidate(referralLinkProvider),
                  height: qrSize,
                );
              }
              return Column(
                children: [
                  RepaintBoundary(
                    key: qrKey,
                    child: Container(
                      key: const ValueKey('refer-earn-qr'),
                      color: Colors.white,
                      padding: EdgeInsets.all(_figmaW(8)),
                      child: QrImageView(
                        data: link,
                        version: QrVersions.auto,
                        size: qrSize,
                        gapless: true,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Colors.black,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: _figmaH(12)),
                  _ReferralUrlRow(url: link),
                  SizedBox(height: _figmaH(18)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _OutlineActionButton(
                        iconAsset: FileConstants.referQrDownloadSvg,
                        label: 'Download',
                        width: _figmaW(104),
                        onTap: () => _downloadQr(context, qrKey),
                      ),
                      SizedBox(width: _figmaW(16)),
                      _OutlineActionButton(
                        iconAsset: FileConstants.referQrShareSvg,
                        label: 'share',
                        width: _figmaW(79),
                        onTap: () => ReferralShareService.shareAny(context),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _downloadQr(BuildContext context, GlobalKey qrKey) async {
    try {
      final boundary =
      qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        AppSnackbar.show('Unable to capture QR code.');
        return;
      }
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        AppSnackbar.show('Unable to capture QR code.');
        return;
      }
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/erupaiya_referral_qr_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes.buffer.asUint8List());
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png', name: 'referral_qr.png')],
        text: 'My eRupaiya referral QR',
      );
    } catch (_) {
      AppSnackbar.show('Failed to download QR code.');
    }
  }
}

class _QrError extends StatelessWidget {
  const _QrError({
    required this.onRetry,
    required this.height,
  });

  final VoidCallback onRetry;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Failed to load referral link.',
            textAlign: TextAlign.center,
            style: _ts(size: 13, color: Colors.black.withOpacity(0.6)),
          ),
          SizedBox(height: _figmaH(10)),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _ReferralUrlRow extends StatelessWidget {
  const _ReferralUrlRow({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: url));
        AppSnackbar.show('Referral link copied');
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.copy_rounded, size: _figmaR(15), color: Colors.black87),
          SizedBox(width: _figmaW(8)),
          Flexible(
            child: Text(
              url,
              key: const ValueKey('refer-earn-url'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _ts(
                size: 14,
                weight: FontWeight.w500,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  const _OutlineActionButton({
    required this.iconAsset,
    required this.label,
    required this.onTap,
    required this.width,
  });

  final String iconAsset;
  final String label;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final iconSize = _figmaW(15);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: _figmaH(32),
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: _figmaW(6)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_figmaR(20)),
          border: Border.all(color: _kOrange, width: 1),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                iconAsset,
                width: iconSize,
                height: iconSize,
              ),
              SizedBox(width: _figmaW(5)),
              Text(
                label,
                maxLines: 1,
                style: _ts(
                  size: 14,
                  weight: FontWeight.w500,
                  color: _kOrange,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────── Coin value section ────────────────────────────

class _CoinValueSection extends StatelessWidget {
  const _CoinValueSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _kPeachBg,
      padding: EdgeInsets.fromLTRB(
        _figmaW(24),
        _figmaH(30),
        _figmaW(24),
        _figmaH(24),
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth.clamp(0.0, _figmaW(190));
              return SizedBox(
                width: width,
                child: AspectRatio(
                  aspectRatio: 747 / 303,
                  child: Image.asset(
                    key: const ValueKey('refer-earn-coin-equals'),
                    FileConstants.referCoinEqualsPng,
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: _figmaH(14)),
          Text.rich(
            TextSpan(
              style: _ts(
                size: 18,
                weight: FontWeight.w400,
                height: 1.3,
              ),
              children: const [
                TextSpan(text: 'Your Coins. '),
                TextSpan(
                  text: 'Real Value.',
                  style: TextStyle(color: _kOrange),
                ),
                TextSpan(text: ' Real Benefits.'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: _figmaH(6)),
          Text(
            'Every eRupaiya Coin is worth ₹1. Use your coins for eligible bill '
                'payments, mobile recharges and more. Turn your coin balance into '
                'real value for your everyday needs.',
            textAlign: TextAlign.center,
            style: _ts(
              size: 12.5,
              color: Colors.black.withOpacity(0.8),
              height: 1.75,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}