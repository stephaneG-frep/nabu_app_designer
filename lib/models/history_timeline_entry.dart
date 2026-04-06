class HistoryTimelineEntry {
  const HistoryTimelineEntry({
    required this.index,
    required this.label,
    required this.createdAt,
    required this.isCurrent,
  });

  final int index;
  final String label;
  final DateTime createdAt;
  final bool isCurrent;
}
