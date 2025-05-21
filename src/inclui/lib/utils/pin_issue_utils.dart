Map<String, dynamic> chooseIssueForPin(
  Map<String, int> counts,
  List<String> preferences,
) {
  String chosenType;
  bool usedPreferences = false;

  final preferredCounts = {
    for (final entry in counts.entries)
      if (preferences.contains(entry.key)) entry.key: entry.value,
  };

  if (preferredCounts.isNotEmpty) {
    final maxPreferred = preferredCounts.values.reduce((a, b) => a > b ? a : b);
    final topPreferred = preferredCounts.entries
        .where((entry) => entry.value == maxPreferred)
        .map((entry) => entry.key)
        .toList()
      ..sort();
    chosenType = topPreferred.first;
    usedPreferences = true;
  } else if (counts.isNotEmpty) {
    final maxGeneral = counts.values.reduce((a, b) => a > b ? a : b);
    final topGeneral = counts.entries
        .where((entry) => entry.value == maxGeneral)
        .map((entry) => entry.key)
        .toList()
      ..sort();
    chosenType = topGeneral.first;
  } else {
    chosenType = '';
    usedPreferences = false;
  }

  return {
    'issue': chosenType,
    'highlight': usedPreferences,
  };
}