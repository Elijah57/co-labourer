import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../data/audio_storage.dart';

class PhotoService {
  final _picker = ImagePicker();

  Future<String?> pickAndSave(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 512,
      imageQuality: 80,
    );
    if (picked == null) return null;

    final dir = await photoDirectory();
    final ext = p.extension(picked.path);
    final fileName = '${const Uuid().v4()}${ext.isEmpty ? '.jpg' : ext}';
    final file = File(p.join(dir.path, fileName));
    await file.writeAsBytes(await picked.readAsBytes(), flush: true);
    return fileName;
  }

  Future<void> delete(String? fileName) async {
    if (fileName == null) return;
    final dir = await photoDirectory();
    final file = File(p.join(dir.path, fileName));
    if (await file.exists()) await file.delete();
  }
}
