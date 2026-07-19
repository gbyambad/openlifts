/// The backup file format version. Bump when the JSON shape changes in a way
/// older apps can't read; a backup with a higher value is rejected on import.
const backupExportVersion = 1;

/// App version stamped into the backup header (informational / diagnostics).
const backupAppVersion = '0.1.0';

/// Thrown when a backup can't be applied because it comes from a newer app or
/// schema than this build understands. Import makes no changes.
class IncompatibleBackupException implements Exception {
  const IncompatibleBackupException(this.message);
  final String message;
  @override
  String toString() => 'IncompatibleBackupException: $message';
}

/// Thrown when a backup file is malformed (not JSON, missing header, or a row
/// fails to decode). Import makes no changes.
class CorruptBackupException implements Exception {
  const CorruptBackupException(this.message);
  final String message;
  @override
  String toString() => 'CorruptBackupException: $message';
}

/// Serializes user-owned data to a portable JSON backup and restores it.
///
/// Backups carry only user-owned data (logs, bodyweight, settings, progression,
/// and custom/edited programs and exercises); built-ins are re-seeded on
/// restore. Restore is a destructive replace, run in a single transaction.
abstract interface class BackupRepository {
  /// Serializes all user-owned data to a JSON string.
  Future<String> exportToJson();

  /// Validates a backup's header without touching any data. Throws
  /// [CorruptBackupException] or [IncompatibleBackupException] on failure.
  void validate(String json);

  /// Replaces all data with the backup's contents in one transaction: clears
  /// everything, re-seeds built-ins from the given seed JSON, then imports the
  /// backup. Any failure aborts, leaving existing data untouched.
  Future<void> restoreFromJson(
    String json, {
    required String exercisesSeed,
    required String programsSeed,
  });
}
