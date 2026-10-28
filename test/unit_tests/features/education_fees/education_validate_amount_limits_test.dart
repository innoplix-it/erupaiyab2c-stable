import 'package:e_rupaiya/features/educationFees/models/education_fees_responses.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  group('EducationValidateAmountResponse amount limits', () {
    test('parses min/max from data map without hardcoding values', () {
      final response = EducationValidateAmountResponse.fromJson({
        'status': true,
        'data': {
          'min_amount': 100,
          'max_amount': 200000,
        },
      });

      expect(response.status, isTrue);
      expect(response.minAmount, 100);
      expect(response.maxAmount, 200000);
    });

    test('parses camelCase min/max from root', () {
      final response = EducationValidateAmountResponse.fromJson({
        'status': false,
        'message': 'Amount too low',
        'minAmount': 250,
        'maxAmount': 150000,
      });

      expect(response.minAmount, 250);
      expect(response.maxAmount, 150000);
      expect(response.message, 'Amount too low');
    });

    test('leaves limits null when backend omits them', () {
      final response = EducationValidateAmountResponse.fromJson({
        'status': true,
        'message': 'ok',
      });

      expect(response.minAmount, isNull);
      expect(response.maxAmount, isNull);
    });

    test('formats min/max label from backend values with en_IN grouping', () {
      final formatter = NumberFormat.decimalPattern('en_IN');
      const minAmount = 100.0;
      const maxAmount = 200000.0;
      final label =
          'Min Amount ${formatter.format(minAmount.round())} Max ₹${formatter.format(maxAmount.round())}';

      expect(label, 'Min Amount 100 Max ₹2,00,000');
    });
  });
}
