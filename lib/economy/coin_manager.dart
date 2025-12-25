import 'coin_store.dart';

class CoinManager {
  final CoinStore store;
  int coins = 0;

  CoinManager(this.store);

  Future<void> init() async {
    coins = await store.load();
  }

  void add(int v) {
    coins += v;
    store.save(coins);
  }

  Future<bool> spend(int v) async {
    if (coins < v) return false;
    coins -= v;
    await store.save(coins);
    return true;
  }
}
