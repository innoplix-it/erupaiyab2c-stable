import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../constants/app_colors.dart';

class ReferralYoutubeEmbedCard extends StatefulWidget {
  const ReferralYoutubeEmbedCard({super.key, this.height = 160});

  final double height;

  @override
  State<ReferralYoutubeEmbedCard> createState() =>
      _ReferralYoutubeEmbedCardState();
}

class _ReferralYoutubeEmbedCardState extends State<ReferralYoutubeEmbedCard> {
  static const _youtubeEmbed =
      'https://www.youtube.com/embed/uJ4DtjpF7QA?playsinline=1&rel=0&modestbranding=1';
  static const _youtubeEmbedHtml = '''
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
    <style>
      html, body {
        margin: 0;
        padding: 0;
        background: #000;
        overflow: hidden;
        height: 100.h%;
        width: 100.w%;
      }
      iframe {
        border: 0;
        width: 100.w%;
        height: 100.h%;
      }
    </style>
  </head>
  <body>
    <iframe
      src="$_youtubeEmbed"
      title="Referral video"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
      allowfullscreen>
    </iframe>
  </body>
</html>
''';

  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
        ),
      )
      ..loadHtmlString(_youtubeEmbedHtml);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: SizedBox(
        width: double.infinity,
        height: widget.height.h,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black,
                child: WebViewWidget(controller: _controller),
              ),
            ),
            if (_isLoading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
