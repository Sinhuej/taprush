import 'package:flutter/material.dart';
import '../app/app_state.dart';
import '../game/modes/mode_id.dart';
import '../monetization/products.dart';
import '../backgrounds/background_state.dart';
import '../cosmetics/skins.dart';

class StoreScreen extends StatelessWidget {
  final AppState state;
  final VoidCallback onBack;
  final VoidCallback onStateChanged;

  const StoreScreen({
    super.key,
    required this.state,
    required this.onBack,
    required this.onStateChanged,
  });

  bool _visible(ProductId id) {
    // Mode-based pack release plan (LOCKED)
    switch (id) {
      case ProductId.pack_animals_1001:
        return state.unlockedModes.contains(ModeId.reverse);
      case ProductId.pack_planets_1001:
        return state.unlockedModes.contains(ModeId.dual);
      case ProductId.pack_exotics_1001:
        return state.unlockedModes.contains(ModeId.sideways);
      case ProductId.pack_foods_2000:
        return state.unlockedModes.contains(ModeId.chaos);
      default:
        return true;
    }
  }

  void _buy(ProductId id) {
    // Simulated purchases (TODO: wire real IAP).
    state.grant(id);
    onStateChanged();
  }

  @override
  Widget build(BuildContext context) {
    final items = Products.all.where((p) => _visible(p.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Core', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final p in items.where((p) =>
              p.id == ProductId.removeAds_422 ||
              p.id == ProductId.streakInsurance_051 ||
              p.id == ProductId.shame_panicked_111 ||
              p.id == ProductId.shame_oneMore_111 ||
              p.id == ProductId.shame_dontScreenshot_222 ||
              p.id == ProductId.background_upload_100))
            _Item(
              title: p.title,
              price: p.price,
              desc: p.desc,
              owned: state.has(p.id),
              onBuy: () => _buy(p.id),
            ),

          const SizedBox(height: 18),
          const Text('Mode-Unlocked Packs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final p in items.where((p) =>
              p.id == ProductId.pack_animals_1001 ||
              p.id == ProductId.pack_planets_1001 ||
              p.id == ProductId.pack_exotics_1001 ||
              p.id == ProductId.pack_foods_2000))
            _Item(
              title: p.title,
              price: p.price,
              desc: p.desc,
              owned: state.has(p.id),
              onBuy: () => _buy(p.id),
            ),

          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 10),

          const Text('Backgrounds', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _BackgroundPanel(state: state, onStateChanged: onStateChanged),

          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 10),

          const Text('Skins (Preview Lists)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _SkinPanel(state: state, onStateChanged: onStateChanged),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final String title;
  final String price;
  final String desc;
  final bool owned;
  final VoidCallback onBuy;

  const _Item({
    required this.title,
    required this.price,
    required this.desc,
    required this.owned,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(desc),
        trailing: owned
            ? const Text('OWNED', style: TextStyle(fontWeight: FontWeight.w900))
            : TextButton(
                onPressed: onBuy,
                child: Text(price, style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
      ),
    );
  }
}

class _BackgroundPanel extends StatelessWidget {
  final AppState state;
  final VoidCallback onStateChanged;

  const _BackgroundPanel({required this.state, required this.onStateChanged});

  @override
  Widget build(BuildContext context) {
    final bg = state.backgrounds;
    final canUpload = state.has(ProductId.background_upload_100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Built-ins selected: ${bg.selectedBuiltIns.length}/${BackgroundState.maxBuiltInSelected}'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final id in BuiltInBackgrounds.ids)
              FilterChip(
                label: Text(id),
                selected: bg.selectedBuiltIns.contains(id),
                onSelected: (v) {
                  if (v) {
                    final ok = bg.selectBuiltIn(id);
                    if (!ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Max 6 built-in backgrounds selected.')),
                      );
                    }
                  } else {
                    bg.unselectBuiltIn(id);
                  }
                  onStateChanged();
                },
              )
          ],
        ),
        const SizedBox(height: 12),
        Text('Custom backgrounds: ${bg.customUris.length}/${BackgroundState.maxCustom}'),
        const SizedBox(height: 6),
        Text(
          canUpload
              ? 'Upload enabled (simulated). Add placeholder URIs.'
              : 'Buy "Custom Backgrounds (6)" to add your own images.',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: canUpload
                    ? () {
                        final ok = bg.addCustomUri('file://custom_${bg.customUris.length + 1}.jpg');
                        if (!ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Max 6 custom backgrounds.')),
                          );
                        }
                        onStateChanged();
                      }
                    : null,
                child: const Text('Add Custom (Sim)'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: canUpload && bg.customUris.isNotEmpty
                    ? () {
                        bg.removeCustomAt(bg.customUris.length - 1);
                        onStateChanged();
                      }
                    : null,
                child: const Text('Remove Last'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SkinPanel extends StatelessWidget {
  final AppState state;
  final VoidCallback onStateChanged;

  const _SkinPanel({required this.state, required this.onStateChanged});

  bool get _animalsOwned => state.has(ProductId.pack_animals_1001);
  bool get _planetsOwned => state.has(ProductId.pack_planets_1001);
  bool get _exoticsOwned => state.has(ProductId.pack_exotics_1001);
  bool get _foodsOwned => state.has(ProductId.pack_foods_2000);

  @override
  Widget build(BuildContext context) {
    final list = <Skin>[
      if (_animalsOwned) ...AnimalSkins.all,
      if (_planetsOwned) ...PlanetSkins.all,
      if (_exoticsOwned) ...ExoticSkins.all,
      if (_foodsOwned) ...FoodSkins.all,
    ];

    if (list.isEmpty) {
      return const Text('Buy a pack to see skins here.');
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final s in list)
          ChoiceChip(
            label: Text(s.name),
            selected: state.selectedSkinId == s.id,
            onSelected: (_) {
              state.selectedSkinId = s.id;
              onStateChanged();
            },
          ),
      ],
    );
  }
}
