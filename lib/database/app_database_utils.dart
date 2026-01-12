part of 'app_database.dart';

mixin AppDatabaseUtils on AppDatabaseBase {
  // =================
  // Utility Methods
  // =================

  /// Get count of entries for today (for streak calculation)
  Future<Map<ProtocolType, int>> getTodayCounts() async {
    final entries = await getTodayProtocolEntries();
    final counts = <ProtocolType, int>{};

    for (final type in ProtocolType.values) {
      counts[type] = entries.where((e) => e.type == type).length;
    }

    return counts;
  }
}
