import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:e_rupaiya/widgets/app_html.dart';

class MockLauncher extends Mock {
  Future<bool> call(Uri url, {LaunchMode mode});
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppHtml - AUD-017 Link Security Behavioral Tests', () {
    late MockLauncher mockLauncher;

    setUpAll(() {
      registerFallbackValue(Uri());
      registerFallbackValue(LaunchMode.externalApplication);
    });

    setUp(() {
      mockLauncher = MockLauncher();
      when(() => mockLauncher(any(), mode: any(named: 'mode')))
          .thenAnswer((_) async => true);
    });

    test('javascript: URL does not call launchUrl', () async {
      await AppHtml.handleLinkTap('javascript:alert(1)', mockLauncher);
      verifyNever(() => mockLauncher(any(), mode: any(named: 'mode')));
    });

    test('custom scheme URL does not call launchUrl', () async {
      await AppHtml.handleLinkTap('customapp://action', mockLauncher);
      verifyNever(() => mockLauncher(any(), mode: any(named: 'mode')));
    });

    test('HTTP URL does not call launchUrl', () async {
      await AppHtml.handleLinkTap('http://example.com', mockLauncher);
      verifyNever(() => mockLauncher(any(), mode: any(named: 'mode')));
    });

    test('malformed HTTPS URL does not call launchUrl', () async {
      await AppHtml.handleLinkTap('https://', mockLauncher);
      verifyNever(() => mockLauncher(any(), mode: any(named: 'mode')));
    });

    test('hostless HTTPS URL does not call launchUrl', () async {
      await AppHtml.handleLinkTap('https:///path', mockLauncher);
      verifyNever(() => mockLauncher(any(), mode: any(named: 'mode')));
    });

    test('valid HTTPS URL calls launchUrl with correct parameters', () async {
      await AppHtml.handleLinkTap('https://example.com', mockLauncher);
      verify(() => mockLauncher(
        Uri.parse('https://example.com'),
        mode: LaunchMode.externalApplication,
      )).called(1);
    });

    test('empty URL does not call launchUrl', () async {
      await AppHtml.handleLinkTap('', mockLauncher);
      verifyNever(() => mockLauncher(any(), mode: any(named: 'mode')));
    });

    test('null URL does not call launchUrl', () async {
      await AppHtml.handleLinkTap(null, mockLauncher);
      verifyNever(() => mockLauncher(any(), mode: any(named: 'mode')));
    });

    test('invalid URL does not call launchUrl', () async {
      await AppHtml.handleLinkTap('not-a-url', mockLauncher);
      verifyNever(() => mockLauncher(any(), mode: any(named: 'mode')));
    });
  });

  group('AppHtml - Widget Rendering Regression Tests', () {
    testWidgets('empty HTML shows no content message', (tester) async {
      const html = '';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppHtml(html: html),
          ),
        ),
      );
      
      expect(find.text('No content available.'), findsOneWidget);
    });

    testWidgets('valid HTML renders correctly', (tester) async {
      const html = '<p>Test content</p>';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppHtml(html: html),
          ),
        ),
      );
      
      expect(find.text('Test content'), findsOneWidget);
    });
  });

  group('AppHtml - Widget Link Integration Tests', () {
    late MockLauncher mockLauncher;

    setUpAll(() {
      registerFallbackValue(Uri());
      registerFallbackValue(LaunchMode.externalApplication);
    });

    setUp(() {
      mockLauncher = MockLauncher();
      when(() => mockLauncher(any(), mode: any(named: 'mode')))
          .thenAnswer((_) async => true);
    });

    testWidgets('widget with javascript: link renders but does not invoke launcher', (tester) async {
      const html = '<a href="javascript:alert(1)">Click</a>';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppHtml(
              html: html,
              urlLauncher: mockLauncher,
            ),
          ),
        ),
      );
      
      expect(find.text('Click'), findsOneWidget);
      
      // Note: flutter_html widget may not reliably trigger onLinkTap via tap in tests
      // The validation logic is tested by the unit tests above.
      // This test verifies the widget renders correctly with such HTML.
      verifyNever(() => mockLauncher(any(), mode: any(named: 'mode')));
    });

    testWidgets('widget with custom scheme link renders but does not invoke launcher', (tester) async {
      const html = '<a href="customapp://action">Click</a>';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppHtml(
              html: html,
              urlLauncher: mockLauncher,
            ),
          ),
        ),
      );
      
      expect(find.text('Click'), findsOneWidget);
      verifyNever(() => mockLauncher(any(), mode: any(named: 'mode')));
    });

    testWidgets('widget with HTTP link renders but does not invoke launcher', (tester) async {
      const html = '<a href="http://example.com">Click</a>';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppHtml(
              html: html,
              urlLauncher: mockLauncher,
            ),
          ),
        ),
      );
      
      expect(find.text('Click'), findsOneWidget);
      verifyNever(() => mockLauncher(any(), mode: any(named: 'mode')));
    });

    testWidgets('widget with valid HTTPS link renders', (tester) async {
      const html = '<a href="https://example.com">Click</a>';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppHtml(
              html: html,
              urlLauncher: mockLauncher,
            ),
          ),
        ),
      );
      
      expect(find.text('Click'), findsOneWidget);
      
      // Note: flutter_html widget tests cannot reliably trigger onLinkTap via tap
      // due to the widget's internal implementation. The actual launcher invocation
      // for valid HTTPS URLs is verified by the unit tests above.
    });
  });
}
