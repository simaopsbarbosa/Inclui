import 'package:flutter_test/flutter_test.dart';
import 'package:inclui/profile_page.dart';

void main() {
  group('maskEmail', () {
    test('correctly masks normal email', () {
      expect(maskEmail('johndoe@example.com'), equals('jo*****@example.com'));
    });

    test('correctly masks 3-letter local part', () {
      expect(maskEmail('abc@example.com'), equals('ab*@example.com'));
    });

    test('correctly masks 2-letter local part', () {
      expect(maskEmail('cd@example.com'), equals('cd@example.com'));
    });

    test('correctly masks 1-letter local part', () {
      expect(maskEmail('e@example.com'), equals('Invalid email'));
    });

    test('handles empty string', () {
      expect(maskEmail(''), equals('Invalid email'));
    });

    test('handles invalid email', () {
      expect(maskEmail('invalidemail'), equals('Invalid email'));
    });
  });

  group('formatDate', () {
    test('formats valid ISO date to DD/MM/YYYY', () {
      expect(formatDate('2024-04-10T12:34:56Z'), 'Joined 10/04/2024');
    });

    test('formats another valid ISO date correctly', () {
      expect(formatDate('2000-01-01T00:00:00Z'), 'Joined 01/01/2000');
    });

    test('returns empty string for invalid input', () {
      expect(formatDate('not-a-date'), '');
    });

    test('returns empty string for empty input', () {
      expect(formatDate(''), '');
    });
  });
}
