import 'package:flutter_test/flutter_test.dart';
import 'package:inclui/services/pin_issue_utils.dart';

void main() {
  group('chooseIssueForPin', () {
    test('highlights preferred issue if present', () {
      final counts = {'wheelchair': 3, 'elevator': 2, 'braille': 1};
      final preferences = ['elevator', 'braille'];
      final result = chooseIssueForPin(counts, preferences);
      expect(result['issue'], 'elevator');
      expect(result['highlight'], true);
    });

    test('selects most reported issue if no preference', () {
      final counts = {'wheelchair': 3, 'elevator': 2, 'braille': 1};
      final preferences = <String>[]; 
      final result = chooseIssueForPin(counts, preferences);
      expect(result['issue'], 'wheelchair');
      expect(result['highlight'], false);
    });

    test('breaks tie alphabetically when no preference', () {
      final counts = {'wheelchair': 2, 'elevator': 2};
      final preferences = <String>[];
      final result = chooseIssueForPin(counts, preferences);
      expect(result['issue'], 'elevator'); 
      expect(result['highlight'], false);
    });

    test('breaks tie alphabetically among preferred issues', () {
      final counts = {'wheelchair': 2, 'elevator': 2};
      final preferences = ['elevator', 'wheelchair'];
      final result = chooseIssueForPin(counts, preferences);
      expect(result['issue'], 'elevator');
      expect(result['highlight'], true);
    });

    test('returns empty if there are no reports', () {
      final counts = <String, int>{};
      final preferences = <String>['elevator']; 
      final result = chooseIssueForPin(counts, preferences);
      expect(result['issue'], '');
      expect(result['highlight'], false);
    });

    test('ignores preferences not present in reports', () {
      final counts = {'wheelchair': 2, 'elevator': 1};
      final preferences = ['braille'];
      final result = chooseIssueForPin(counts, preferences);
      expect(result['issue'], 'wheelchair');
      expect(result['highlight'], false);
    });
  });
}