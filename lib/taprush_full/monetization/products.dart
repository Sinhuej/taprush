enum ProductId {
  removeAds_422,
  streakInsurance_051,

  shame_panicked_111,
  shame_oneMore_111,
  shame_dontScreenshot_222,

  pack_animals_1001,
  pack_planets_1001,
  pack_exotics_1001,
  pack_foods_2000,

  background_upload_100,
}

class Product {
  final ProductId id;
  final String title;
  final String desc;
  final int priceCents;

  const Product(this.id, this.title, this.desc, this.priceCents);

  String get price {
    final d = priceCents ~/ 100;
    final c = priceCents % 100;
    return '\$${d}.${c.toString().padLeft(2, '0')}';
  }
}

class Products {
  static const removeAds = Product(
    ProductId.removeAds_422,
    'You Earned Silence',
    'Removes banner + interstitial ads.\nRewarded ads stay optional.',
    422,
  );

  static const streakInsurance = Product(
    ProductId.streakInsurance_051,
    'This One Actually Mattered',
    'Save your streak once.\nBecause losing this one would sting.',
    51,
  );

  static const panicked = Product(
    ProductId.shame_panicked_111,
    'I Panicked Pack',
    'Rewind ×1\nMercy ×1\n“We all saw that.”',
    111,
  );

  static const oneMore = Product(
    ProductId.shame_oneMore_111,
    'Fine. One More Try.',
    'Rewind ×1\n“No judgment. Okay, some judgment.”',
    111,
  );

  static const dontScreenshot = Product(
    ProductId.shame_dontScreenshot_222,
    'Don’t Screenshot This',
    'Rewind ×2\nMercy ×1\nFlarе\n“Please don’t post this.”',
    222,
  );

  static const animals = Product(
    ProductId.pack_animals_1001,
    'Animal Skin Pack (10)',
    'Unlocks after Reverse mode.',
    1001,
  );

  static const planets = Product(
    ProductId.pack_planets_1001,
    'Planet Pack (10)',
    'Unlocks after Dual mode.',
    1001,
  );

  static const exotics = Product(
    ProductId.pack_exotics_1001,
    'Exotic Animal Pack (10)',
    'Unlocks after Sideways mode.',
    1001,
  );

  static const foods = Product(
    ProductId.pack_foods_2000,
    'Food Pack (50)',
    'Unlocks after Chaos mode.',
    2000,
  );

  static const backgroundUpload = Product(
    ProductId.background_upload_100,
    'Custom Backgrounds (6)',
    'Upload up to 6 images.\nLocal-only.\nNo advantage.',
    100,
  );

  static const all = <Product>[
    removeAds,
    streakInsurance,
    panicked,
    oneMore,
    dontScreenshot,
    animals,
    planets,
    exotics,
    foods,
    backgroundUpload,
  ];
}
