import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_colors.dart';

class AppHtml extends StatelessWidget {
  const AppHtml({
    super.key,
    required this.html,
    this.urlLauncher,
  });

  final String html;
  final Future<bool> Function(Uri url, {LaunchMode mode})? urlLauncher;

  static Future<void> handleLinkTap(
    String? url,
    Future<bool> Function(Uri url, {LaunchMode mode}) launcher,
  ) async {
    final raw = url?.trim();
    if (raw == null || raw.isEmpty) return;
    final uri = Uri.tryParse(raw);
    if (uri == null) return;
    
    // Allow only HTTPS URLs with a valid host
    if (uri.scheme != 'https') {
      return;
    }
    if (uri.host.isEmpty) {
      return;
    }
    
    await launcher(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final normalized = html.trim();
    if (normalized.isEmpty) {
      return Text(
        'No content available.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary.withOpacity(0.75),
              height: 1.5,
            ),
      );
    }

    final baseStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textPrimary.withOpacity(0.75),
          height: 1.5,
        );

    return Html(
      data: normalized,
      style: {
        'body': Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          color: baseStyle?.color,
          fontSize: baseStyle?.fontSize != null
              ? FontSize(baseStyle!.fontSize!)
              : FontSize.medium,
          fontWeight: baseStyle?.fontWeight,
          lineHeight: LineHeight(baseStyle?.height ?? 1.5),
        ),
        'p': Style(
          margin: Margins.only(bottom: 10),
        ),
        'a': Style(
          color: AppColors.primary,
          textDecoration: TextDecoration.underline,
        ),
        'ul': Style(margin: Margins.only(bottom: 10, left: 18)),
        'ol': Style(margin: Margins.only(bottom: 10, left: 18)),
        'li': Style(margin: Margins.only(bottom: 6)),
        'h1': Style(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
        'h2': Style(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
        'h3': Style(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
      },
      onLinkTap: (url, _, __) async {
        final launcher = urlLauncher ?? launchUrl;
        await handleLinkTap(url, launcher);
      },
    );
  }
}
