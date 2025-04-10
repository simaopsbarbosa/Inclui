import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SearchPage Filters', () {
    test('Should filter reports by max distance', () {
      final reports = [
        {'name': 'Place A', 'distance': 5.0, 'issue': 'wheelchair'},
        {'name': 'Place B', 'distance': 15.0, 'issue': 'elevator'},
        {'name': 'Place C', 'distance': 25.0, 'issue': 'braille'},
      ];

      final maxDistance = 10.0;

      final filteredReports = reports.where((report) {
        final distance = report['distance'] is num ? report['distance'] as num : 0.0;
        return distance <= maxDistance;
      }).toList();

      expect(filteredReports.length, 1);
      expect(filteredReports[0]['name'], 'Place A');
    });

    test('Should filter reports by issue type', () {
      final reports = [
        {'name': 'Place A', 'distance': 5.0, 'issue': 'wheelchair'},
        {'name': 'Place B', 'distance': 15.0, 'issue': 'elevator'},
        {'name': 'Place C', 'distance': 25.0, 'issue': 'braille'},
      ];

      final selectedIssueType = 'elevator';

      final filteredReports = reports.where((report) {
        return report['issue'] == selectedIssueType;
      }).toList();

      expect(filteredReports.length, 1);
      expect(filteredReports[0]['name'], 'Place B');
    });

    test('Should filter reports by both max distance and issue type', () {
      final reports = [
        {'name': 'Place A', 'distance': 5.0, 'issue': 'wheelchair'},
        {'name': 'Place B', 'distance': 15.0, 'issue': 'elevator'},
        {'name': 'Place C', 'distance': 25.0, 'issue': 'braille'},
      ];

      final maxDistance = 20.0;
      final selectedIssueType = 'elevator';

      final filteredReports = reports.where((report) {
        final distance = report['distance'] is num ? report['distance'] as num : 0.0;
        return distance <= maxDistance && report['issue'] == selectedIssueType;
      }).toList();

      expect(filteredReports.length, 1);
      expect(filteredReports[0]['name'], 'Place B');
    });
  });
}