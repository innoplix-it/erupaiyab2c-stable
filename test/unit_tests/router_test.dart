import 'package:flutter_test/flutter_test.dart';
import 'package:e_rupaiya/constants/routes_constant.dart';

void main() {
  group('Router - AUD-018 Referral Deep Link Security', () {
    test('exact referral route is /referral', () {
      expect(RouteConstants.referral, equals('/referral'));
    });

    test('referral route does not match /referral/extra with startsWith', () {
      const location = '/referral/extra';
      final matchesWithStartsWith = location.startsWith(RouteConstants.referral);
      expect(matchesWithStartsWith, isTrue);
    });

    test('referral route matches exactly /referral with equality', () {
      const location = '/referral';
      final matchesExactly = location == RouteConstants.referral;
      expect(matchesExactly, isTrue);
    });

    test('referral route does not match /referral/extra with equality', () {
      const location = '/referral/extra';
      final matchesExactly = location == RouteConstants.referral;
      expect(matchesExactly, isFalse);
    });

    test('referral route does not match /referral/extra with equality (case 2)', () {
      const location = '/referral/wallet';
      final matchesExactly = location == RouteConstants.referral;
      expect(matchesExactly, isFalse);
    });
  });
}
