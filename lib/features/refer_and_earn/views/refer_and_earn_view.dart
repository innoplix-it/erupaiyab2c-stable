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

const Color _kOrange = Color(0xFFDD5428);
const Color _kPeachBg = Color(0xFFFDF3EF);
const Color _kHeroBlue = Color(0xFF084591);
const Color _kWalletBlue = Color(0xFF084591);

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
                whiteHelpBadge: true,
                hideBottomStrip: true,
                body: Column(
                  children: [
                    SizedBox(height: _figmaH(6)),
                    Text(
                      'One Refer = 100 eCoins',
                      key: const ValueKey('refer-earn-hero-title'),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: _figmaSp(22),
                        height: 1.0,
                        // Figma letter-spacing: -2% of font size.
                        letterSpacing: _figmaSp(22) * -0.02,
                      ),
                    ),
                    SizedBox(height: _figmaH(10)),
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
                      child: Padding(
                        // Figma: ~32 side inset, ~38 top before wallet pill.
                        padding: EdgeInsets.fromLTRB(
                          _figmaW(32),
                          _figmaH(38),
                          _figmaW(32),
                          _figmaH(20),
                        ),
                        child: Column(
                          children: [
                            const _WalletPillButton(),
                            SizedBox(height: _figmaH(22)),
                            const _HowItWorksSection(),
                            SizedBox(height: _figmaH(22)),
                            _ReferralQrCard(
                              linkAsync: linkAsync,
                              qrSize: qrSize,
                            ),
                          ],
                        ),
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

class _WalletPillButton extends StatelessWidget {
  const _WalletPillButton();

  @override
  Widget build(BuildContext context) {
    // Figma wallet pill: height ~54, side inset handled by panel pad (32).
    return GestureDetector(
      onTap: () => context.push(RouteConstants.referAndEarnWallet),
      child: Container(
        key: const ValueKey('refer-earn-wallet-pill'),
        width: double.infinity,
        height: _figmaH(54),
        padding: EdgeInsets.symmetric(horizontal: _figmaW(16)),
        decoration: BoxDecoration(
          color: _kWalletBlue,
          borderRadius: BorderRadius.circular(_figmaR(40)),
          boxShadow: [
            BoxShadow(
              color: _kWalletBlue.withOpacity(0.22),
              blurRadius: _figmaR(12),
              offset: Offset(0, _figmaH(4)),
            ),
          ],
        ),
        child: Row(
          children: [
            Image.asset(
              FileConstants.coin_3d,
              width: _figmaW(26),
              height: _figmaW(26),
            ),
            SizedBox(width: _figmaW(10)),
            Expanded(
              child: Text(
                'My Wallet & Referals',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: _figmaSp(15.5),
                      letterSpacing: 0,
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
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  static final _steps = <_StepSpec>[
    _StepSpec(
      number: '1',
      title: 'Invite Your Friends',
      subtitle: 'Share your referral link with friends.',
      titleColor: const Color(0xFF5A3CF0),
      badgeColor: const Color(0xFFEDE7FF),
      cardColor: const Color(0xFFF6F2FF),
      // Figma 56×56 icon tile fill.
      iconTileColor: const Color(0xFFF0EDFD),
      iconAsset: FileConstants.referStepInvitePng,
    ),
    _StepSpec(
      number: '2',
      title: 'They join eRupaiya',
      subtitle: 'Your friends sign up successfully.',
      titleColor: const Color(0xFF1B8A4A),
      badgeColor: const Color(0xFFE3F7EC),
      cardColor: const Color(0xFFF1FBF5),
      iconTileColor: const Color(0xFFE8F8EF),
      iconAsset: FileConstants.referStepJoinPng,
    ),
    _StepSpec(
      number: '3',
      title: 'First Eligible Payment',
      subtitle: 'They complete a qualifying payment.',
      titleColor: const Color(0xFF1A6FBF),
      badgeColor: const Color(0xFFE3F1FB),
      cardColor: const Color(0xFFF0F7FD),
      iconTileColor: const Color(0xFFE8F3FC),
      iconAsset: FileConstants.referStepPaymentPng,
    ),
    _StepSpec(
      number: '4',
      title: 'You get the matching reward',
      subtitle: 'Check your rewards from invited friends.',
      titleColor: const Color(0xFFE85A2C),
      badgeColor: const Color(0xFFFFF0E8),
      cardColor: const Color(0xFFFFF6F0),
      iconTileColor: const Color(0xFFFFF0E8),
      iconAsset: FileConstants.referStepRewardPng,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'How It Works',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: _figmaSp(20),
                letterSpacing: 0,
              ),
        ),
        SizedBox(height: _figmaH(8)),
        Text.rich(
          TextSpan(
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black.withOpacity(0.55),
                  fontWeight: FontWeight.w400,
                  fontSize: _figmaSp(13),
                  height: 1.45,
                  letterSpacing: 0,
                ),
            children: const [
              TextSpan(text: 'Refer once and '),
              TextSpan(
                text: 'earn coins every time',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text:
                    ' your friend spends in the app. Use your coins like real money for payments anytime.',
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: _figmaH(18)),
        _StepsTimeline(steps: _steps),
      ],
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
    final badgeSize = _figmaW(28);
    final lineLeft = badgeSize / 2;

    return Stack(
      children: [
        Positioned(
          left: lineLeft - 0.75,
          top: badgeSize / 2,
          bottom: badgeSize / 2,
          width: 1.5,
          child: const CustomPaint(
            painter: _DashedLinePainter(color: Color(0xFFD0D5DD)),
            child: SizedBox.expand(),
          ),
        ),
        Column(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              _StepRow(spec: steps[i], badgeSize: badgeSize),
              if (i != steps.length - 1) SizedBox(height: _figmaH(12)),
            ],
          ],
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.spec, required this.badgeSize});

  final _StepSpec spec;
  final double badgeSize;

  @override
  Widget build(BuildContext context) {
    // Figma step icon tile: 56×56, rx=12.
    final iconTile = _figmaW(56);
    final iconInner = _figmaW(36);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: badgeSize,
          height: badgeSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: spec.badgeColor,
            shape: BoxShape.circle,
          ),
          child: Text(
            spec.number,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: spec.titleColor,
                  fontWeight: FontWeight.w700,
                  fontSize: _figmaSp(13),
                  height: 1,
                ),
          ),
        ),
        SizedBox(width: _figmaW(10)),
        Expanded(
          child: Container(
            padding: EdgeInsets.fromLTRB(
              _figmaW(12),
              _figmaH(12),
              _figmaW(12),
              _figmaH(12),
            ),
            decoration: BoxDecoration(
              color: spec.cardColor,
              borderRadius: BorderRadius.circular(_figmaR(16)),
            ),
            child: Row(
              children: [
                Container(
                  key: ValueKey('refer-earn-step-tile-${spec.number}'),
                  width: iconTile,
                  height: iconTile,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: spec.iconTileColor,
                    borderRadius: BorderRadius.circular(_figmaR(12)),
                  ),
                  child: Image.asset(
                    spec.iconAsset,
                    width: iconInner,
                    height: iconInner,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
                SizedBox(width: _figmaW(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spec.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: spec.titleColor,
                              fontWeight: FontWeight.w700,
                              fontSize: _figmaSp(14),
                              height: 1.25,
                              letterSpacing: 0,
                            ),
                      ),
                      SizedBox(height: _figmaH(4)),
                      Text(
                        spec.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.black.withOpacity(0.55),
                              fontWeight: FontWeight.w400,
                              fontSize: _figmaSp(12),
                              height: 1.35,
                              letterSpacing: 0,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dash = 4.0;
    const gap = 4.0;
    var y = 0.0;
    final x = size.width / 2;
    while (y < size.height) {
      canvas.drawLine(
          Offset(x, y), Offset(x, (y + dash).clamp(0, size.height)), paint);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

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
        _figmaH(18),
        _figmaW(16),
        _figmaH(16),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_figmaR(18)),
        border: Border.all(color: const Color(0xFFE6E6E6)),
      ),
      child: Column(
        children: [
          Text(
            'My Referral QR',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: _figmaSp(17),
                  letterSpacing: 0,
                ),
          ),
          SizedBox(height: _figmaH(6)),
          Text(
            'share this qr with your friends to invite them to eRupaiya',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black.withOpacity(0.5),
                  fontWeight: FontWeight.w400,
                  fontSize: _figmaSp(12),
                  height: 1.35,
                  letterSpacing: 0,
                ),
          ),
          SizedBox(height: _figmaH(16)),
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
                  SizedBox(height: _figmaH(14)),
                  _ReferralUrlRow(url: link),
                  SizedBox(height: _figmaH(14)),
                  Row(
                    children: [
                      Expanded(
                        child: _OutlineActionButton(
                          icon: Icons.download_rounded,
                          label: 'Download',
                          onTap: () => _downloadQr(context, qrKey),
                        ),
                      ),
                      SizedBox(width: _figmaW(12)),
                      Expanded(
                        child: _OutlineActionButton(
                          icon: Icons.share_outlined,
                          label: 'share',
                          onTap: () => ReferralShareService.shareAny(context),
                        ),
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black.withOpacity(0.6),
                  fontSize: _figmaSp(13),
                ),
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
          Icon(Icons.copy_rounded, size: _figmaR(16), color: Colors.black87),
          SizedBox(width: _figmaW(8)),
          Flexible(
            child: Text(
              url,
              key: const ValueKey('refer-earn-url'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: _figmaSp(13),
                    letterSpacing: 0,
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
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Figma outline CTA ~36 high (measured ~33–36 on 440 frame).
        height: _figmaH(36),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_figmaR(40)),
          border: Border.all(color: _kOrange, width: 1.4),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: _figmaW(8)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: _kOrange, size: _figmaR(18)),
              SizedBox(width: _figmaW(6)),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _kOrange,
                        fontWeight: FontWeight.w600,
                        fontSize: _figmaSp(14),
                        letterSpacing: 0,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoinValueSection extends StatelessWidget {
  const _CoinValueSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _kPeachBg,
      padding: EdgeInsets.fromLTRB(
        _figmaW(20),
        _figmaH(28),
        _figmaW(20),
        _figmaH(28),
      ),
      child: Column(
        children: [
          // Supplied Figma coin artwork (gold eCoin = 1 Rupee), extracted from
          // the reference and wrapped as SVG with embedded PNG for flutter_svg.
          // Image.asset fallback preserves artwork if SVG patterns fail.
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth.clamp(0.0, _figmaW(280));
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
          SizedBox(height: _figmaH(18)),
          Text.rich(
            TextSpan(
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: _figmaSp(18),
                    height: 1.3,
                    letterSpacing: 0,
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
          SizedBox(height: _figmaH(10)),
          Text(
            'Every eRupaiya Coin is worth ₹1. Use your coins for eligible bill '
            'payments, mobile recharges and more. Turn your coin balance into '
            'real value for your everyday needs.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black.withOpacity(0.55),
                  fontWeight: FontWeight.w400,
                  fontSize: _figmaSp(13),
                  height: 1.45,
                  letterSpacing: 0,
                ),
          ),
        ],
      ),
    );
  }
}
