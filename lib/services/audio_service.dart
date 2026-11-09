import 'package:audioplayers/audioplayers.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import '../data/audio_storage.dart';

class AudioService {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();

  Stream<double> get recordingLevels => _recorder
      .onAmplitudeChanged(const Duration(milliseconds: 100))
      .map((amplitude) {
        final current = amplitude.current.isFinite ? amplitude.current : -60.0;
        return ((current + 60) / 60).clamp(0.0, 1.0).toDouble();
      });

  Stream<void> get onComplete => _player.onPlayerComplete;

  Future<String?> startRecording() async {
    if (!await _recorder.hasPermission()) return null;
    final dir = await audioDirectory();
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
    final dir = await audioDirectory();
    await _player.stop();
    await _player.play(DeviceFileSource(p.join(dir.path, fileName)));
  }

  Future<void> stop() => _player.stop();

  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}
