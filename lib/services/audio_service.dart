import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

class AudioService {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();

  Future<Directory> _audioDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'audio'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<String?> startRecording() async {
    if (!await _recorder.hasPermission()) return null;
    final dir = await _audioDir();
    final fileName = '${const Uuid().v4()}.m4a';
    await _recorder.start(
      const RecordConfig(),
      path: p.join(dir.path, fileName),
    );
    return fileName;
  }

  Future<void> stopRecording() => _recorder.stop();

  Future<void> cancelRecording() => _recorder.cancel();

  Future<void> play(String fileName) async {
    final dir = await _audioDir();
    await _player.play(DeviceFileSource(p.join(dir.path, fileName)));
  }

  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}
