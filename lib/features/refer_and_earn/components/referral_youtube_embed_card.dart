import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../constants/app_colors.dart';

class ReferralYoutubeEmbedCard extends StatefulWidget {
  const ReferralYoutubeEmbedCard({super.key});

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
        height: 100%;
        width: 100%;
      }
      iframe {
        border: 0;
        width: 100%;
        height: 100%;
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
          onNavigationRequest: (NavigationRequest request) {
            // Allow only HTTPS URLs to approved YouTube hosts
            final uri = Uri.parse(request.url);
            final scheme = uri.scheme;
            final host = uri.host;
            
            // Require HTTPS scheme
            if (scheme != 'https') {
              return NavigationDecision.prevent;
            }
            
            // Allow only approved YouTube hosts
            if (host == 'www.youtube.com' ||
                host == 'youtube.com' ||
                host == 'm.youtube.com' ||
                host == 'ytimg.com' ||
                host == 'www.ytimg.com' ||
                host == 'googlevideo.com' ||
                host == 'www.googlevideo.com') {
              return NavigationDecision.navigate;
            }
            
            // Block all other navigation
            return NavigationDecision.prevent;
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
        child: AspectRatio(
          aspectRatio: 16 / 9,
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
      ),
    );
  }
}
