class CosmeticUnlocks {
  static const int multiColorCost = 100000;

  bool multiColorUnlocked = false;

  bool canUnlock(int coins) => coins >= multiColorCost;

  void unlockMultiColor() {
    multiColorUnlocked = true;
  }
}
