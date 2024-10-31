abstract class AppDb {
  Future<void> save({required String key, required String value});
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> clear();
}
