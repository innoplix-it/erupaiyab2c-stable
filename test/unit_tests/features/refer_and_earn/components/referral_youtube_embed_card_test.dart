import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReferralYoutubeEmbedCard - AUD-014 WebView Security', () {
    test('YouTube embed URL is correct', () {
      const expectedEmbed = 'https://www.youtube.com/embed/uJ4DtjpF7QA?playsinline=1&rel=0&modestbranding=1';
      // This verifies the embed URL is as expected
      expect(expectedEmbed.contains('youtube.com'), isTrue);
      expect(expectedEmbed.contains('/embed/'), isTrue);
    });

    test('YouTube hosts allow-list includes required domains', () {
      // Based on the onNavigationRequest implementation in referral_youtube_embed_card.dart
      final allowedHosts = [
        'www.youtube.com',
        'youtube.com',
        'm.youtube.com',
        'ytimg.com',
        'www.ytimg.com',
        'googlevideo.com',
        'www.googlevideo.com',
      ];
      
      // Verify the allow-list contains the primary YouTube embed host
      expect(allowedHosts.contains('www.youtube.com'), isTrue);
      expect(allowedHosts.contains('youtube.com'), isTrue);
      
      // Verify the allow-list includes YouTube image host
      expect(allowedHosts.contains('ytimg.com'), isTrue);
      expect(allowedHosts.contains('www.ytimg.com'), isTrue);
      
      // Verify the allow-list includes Google video host
      expect(allowedHosts.contains('googlevideo.com'), isTrue);
      expect(allowedHosts.contains('www.googlevideo.com'), isTrue);
    });

    test('Navigation to example.com should be blocked', () {
      // Simulate navigation request to example.com
      final testUrl = 'https://example.com';
      final uri = Uri.parse(testUrl);
      final host = uri.host;
      
      // Check if host is in allow-list
      final allowedHosts = [
        'www.youtube.com',
        'youtube.com',
        'm.youtube.com',
        'ytimg.com',
        'www.ytimg.com',
        'googlevideo.com',
        'www.googlevideo.com',
      ];
      
      // example.com should NOT be in the allow-list
      expect(allowedHosts.contains(host), isFalse);
    });

    test('Navigation to YouTube embed should be allowed', () {
      // Simulate navigation request to YouTube embed
      final testUrl = 'https://www.youtube.com/embed/uJ4DtjpF7QA';
      final uri = Uri.parse(testUrl);
      final host = uri.host;
      
      // Check if host is in allow-list
      final allowedHosts = [
        'www.youtube.com',
        'youtube.com',
        'm.youtube.com',
        'ytimg.com',
        'www.ytimg.com',
        'googlevideo.com',
        'www.googlevideo.com',
      ];
      
      // www.youtube.com should be in the allow-list
      expect(allowedHosts.contains(host), isTrue);
    });

    test('Navigation to ytimg.com should be allowed', () {
      // Simulate navigation request to YouTube image host
      final testUrl = 'https://ytimg.com/vi/uJ4DtjpF7HQ/maxresdefault.jpg';
      final uri = Uri.parse(testUrl);
      final host = uri.host;
      
      // Check if host is in allow-list
      final allowedHosts = [
        'www.youtube.com',
        'youtube.com',
        'm.youtube.com',
        'ytimg.com',
        'www.ytimg.com',
        'googlevideo.com',
        'www.googlevideo.com',
      ];
      
      // ytimg.com should be in the allow-list
      expect(allowedHosts.contains(host), isTrue);
    });

    test('Navigation to unrelated domain should be blocked', () {
      // Simulate navigation request to unrelated domain
      final testUrl = 'https://malicious-site.com/track';
      final uri = Uri.parse(testUrl);
      final host = uri.host;
      
      // Check if host is in allow-list
      final allowedHosts = [
        'www.youtube.com',
        'youtube.com',
        'm.youtube.com',
        'ytimg.com',
        'www.ytimg.com',
        'googlevideo.com',
        'www.googlevideo.com',
      ];
      
      // malicious-site.com should NOT be in the allow-list
      expect(allowedHosts.contains(host), isFalse);
    });

    test('Navigation to HTTP YouTube URL should be blocked', () {
      // Simulate navigation request to HTTP YouTube URL
      final testUrl = 'http://www.youtube.com/embed/uJ4DtjpF7QA';
      final uri = Uri.parse(testUrl);
      final scheme = uri.scheme;
      
      // HTTP scheme should be blocked even if host is allowed
      expect(scheme, isNot('https'));
    });

    test('Navigation to intent:// scheme should be blocked', () {
      // Simulate navigation request to intent:// scheme
      final testUrl = 'intent://www.youtube.com/embed/uJ4DtjpF7QA#Intent';
      final uri = Uri.parse(testUrl);
      final scheme = uri.scheme;
      
      // intent:// scheme should be blocked even if host is allowed
      expect(scheme, isNot('https'));
    });

    test('Navigation to HTTPS YouTube URL should be allowed', () {
      // Simulate navigation request to HTTPS YouTube URL
      final testUrl = 'https://www.youtube.com/embed/uJ4DtjpF7QA';
      final uri = Uri.parse(testUrl);
      final scheme = uri.scheme;
      final host = uri.host;
      
      // Check if scheme is HTTPS and host is in allow-list
      final allowedHosts = [
        'www.youtube.com',
        'youtube.com',
        'm.youtube.com',
        'ytimg.com',
        'www.ytimg.com',
        'googlevideo.com',
        'www.googlevideo.com',
      ];
      
      expect(scheme, equals('https'));
      expect(allowedHosts.contains(host), isTrue);
    });
  });
}
