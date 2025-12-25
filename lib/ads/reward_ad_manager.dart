class RewardAdManager {
  void preload() {}
  Future<bool> show({required void Function() onEarned}) async {
    onEarned();
    return true;
  }
}
