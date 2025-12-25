import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../bg/background_manager.dart';

class BackgroundSettingsScreen extends StatefulWidget {
  final BackgroundManager bg;

  const BackgroundSettingsScreen({super.key, required this.bg});

  @override
  State<BackgroundSettingsScreen> createState() => _BackgroundSettingsScreenState();
}

class _BackgroundSettingsScreenState extends State<BackgroundSettingsScreen> {
  final picker = ImagePicker();

  Future<void> _addImage() async {
    final x = await picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;
    await widget.bg.addPath(x.path);
  }

  @override
  Widget build(BuildContext context) {
    final paths = widget.bg.paths;

    return Scaffold(
      appBar: AppBar(title: const Text('Backgrounds')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pick up to 6 images. TapRush will rotate them as speed/stage increases.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: paths.length,
                itemBuilder: (context, i) {
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.image),
                      title: Text(paths[i], maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await widget.bg.removeAt(i);
                          if (mounted) setState(() {});
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: paths.length >= 6 ? null : () async {
                      await _addImage();
                      if (mounted) setState(() {});
                    },
                    icon: const Icon(Icons.add),
                    label: Text(paths.length >= 6 ? 'Limit reached (6)' : 'Add image'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
