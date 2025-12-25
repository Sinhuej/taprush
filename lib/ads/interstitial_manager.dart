class InterstitialManager {
  void preload() {}
  Future<void> showIfReady({required void Function() onClosed}) async {
    onClosed();
  }
}
