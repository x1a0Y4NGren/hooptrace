class BackupManifest {
  const BackupManifest({
    required this.appName,
    required this.appVersion,
    required this.schemaVersion,
    required this.exportedAt,
    required this.recordCounts,
    required this.checksum,
  });

  final String appName;
  final String appVersion;
  final int schemaVersion;
  final DateTime exportedAt;
  final Map<String, int> recordCounts;
  final String checksum;

  Map<String, dynamic> toJson() => {
        ...checksumSourceJson(),
        'checksum': checksum,
      };

  Map<String, dynamic> checksumSourceJson() => {
        'appName': appName,
        'appVersion': appVersion,
        'schemaVersion': schemaVersion,
        'exportedAt': exportedAt.toUtc().toIso8601String(),
        'recordCounts': recordCounts,
      };

  factory BackupManifest.fromJson(Map<String, dynamic> json) {
    return BackupManifest(
      appName: json['appName'] as String,
      appVersion: json['appVersion'] as String,
      schemaVersion: json['schemaVersion'] as int,
      exportedAt: DateTime.parse(json['exportedAt'] as String).toUtc(),
      recordCounts: (json['recordCounts'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, value as int)),
      checksum: json['checksum'] as String,
    );
  }
}
