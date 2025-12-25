import 'skin.dart';
import 'skin_state_store.dart';

class SkinManager {
  final SkinStateStore store;

  SkinManager(this.store);

  Skin selected = const Skin(
    colorA: 0xFF6A11CB,
    colorB: 0xFF2575FC,
    glow: true,
  );

  Future<void> init() async {}
}
