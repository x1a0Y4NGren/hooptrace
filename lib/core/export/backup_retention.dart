/// Optional file operations used by automatic-backup retention.
///
/// Implementations may omit this capability (for example, older test fakes
/// or an Android provider that has not added directory listing yet). The
/// automatic-backup service treats the capability as best effort.
abstract interface class BackupRetentionStorage {
  Future<List<String>> listFiles({required String directory});

  Future<void> deleteFile({
    required String directory,
    required String fileName,
  });
}
