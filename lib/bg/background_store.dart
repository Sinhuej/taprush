class BackgroundStore {
  List<String> _cache = const [];

  /// Load persisted background paths
  Future<List<String>> load() async {
    return List<String>.from(_cache);
  }

  /// Save background paths
  Future<void> save(List<String> paths) async {
    _cache = List<String>.from(paths);
  }
}
