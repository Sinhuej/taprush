import 'package:flutter/material.dart';
import '../economy/coin_manager.dart';
import '../skins/skin_manager.dart';
import '../ads/reward_ad_manager.dart';

class SkinShopScreen extends StatelessWidget {
  final CoinManager coins;
  final SkinManager skins;
  final RewardAdManager rewards;

  const SkinShopScreen({
    super.key,
    required this.coins,
    required this.skins,
    required this.rewards,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Skins")),
      body: const Center(
        child: Text("Skin shop coming soon"),
      ),
    );
  }
}
