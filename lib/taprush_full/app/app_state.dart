import '../game/modes/mode_id.dart';
import '../monetization/products.dart';
import '../backgrounds/background_state.dart';

class AppState {
  // Unlocks
  final Set<ModeId> unlockedModes = {ModeId.normal};

  // Owned products (simulated — hook real IAP later)
  final Set<ProductId> owned = {};

  // Cosmetics selections (ids)
  String? selectedSkinId;

  // Backgrounds
  final BackgroundState backgrounds = BackgroundState();

  // Scoring
  int best = 0;

  bool has(ProductId id) => owned.contains(id);

  void unlockMode(ModeId id) => unlockedModes.add(id);

  void grant(ProductId id) => owned.add(id);
}
