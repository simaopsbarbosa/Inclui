import 'package:flutter_test/flutter_test.dart';
import 'package:inclui/screens/profile_page.dart';

void main() {
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

  group('maskEmail', () {
    test('masks email with more than 2 characters before @', () {
      final result = maskEmail('dinis@example.com');
      expect(result, 'di***@example.com');
    });

    test('masks email with exactly 2 characters before @', () {
      final result = maskEmail('ab@x.pt');
      expect(result, 'ab@x.pt');
    });
  });
}