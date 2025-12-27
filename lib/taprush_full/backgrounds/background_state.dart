class BackgroundState {
  // Free built-ins: user may pick up to 6
  static const maxBuiltInSelected = 6;
  final List<String> selectedBuiltIns = [];

  // Paid: custom backgrounds up to 6
  static const maxCustom = 6;
  final List<String> customUris = []; // placeholders like "file://..."

  bool selectBuiltIn(String id) {
    if (selectedBuiltIns.contains(id)) return true;
    if (selectedBuiltIns.length >= maxBuiltInSelected) return false;
    selectedBuiltIns.add(id);
    return true;
  }

  void unselectBuiltIn(String id) {
    selectedBuiltIns.remove(id);
  }

  bool addCustomUri(String uri) {
    if (customUris.length >= maxCustom) return false;
    customUris.add(uri);
    return true;
  }

  void removeCustomAt(int index) {
    if (index < 0 || index >= customUris.length) return;
    customUris.removeAt(index);
  }
}

class BuiltInBackgrounds {
  static const ids = <String>[
    'bg_01', 'bg_02', 'bg_03', 'bg_04', 'bg_05',
    'bg_06', 'bg_07', 'bg_08', 'bg_09', 'bg_10',
  ];
}
