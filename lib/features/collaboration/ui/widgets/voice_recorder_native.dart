import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Records a compact, speech-optimised M4A voice note on Android and iOS.
class VoiceRecorder {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;

  bool get isRecording => _isRecording;
  String get fileExtension => 'm4a';

  Future<void> start() async {
    if (_isRecording) return;
    if (!await _recorder.hasPermission()) {
      throw StateError(
        'Microphone permission is required. Enable it in your phone settings.',
      );
    }

    final temporaryDirectory = await getTemporaryDirectory();
    final outputPath = path.join(
      temporaryDirectory.path,
      'gobuddy_voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
    );
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000,
        sampleRate: 44100,
        numChannels: 1,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
      ),
      path: outputPath,
    );
    _isRecording = true;
  }

  Future<Uint8List?> stop() async {
    if (!_isRecording) return null;
    final outputPath = await _recorder.stop();
    _isRecording = false;
    if (outputPath == null) return null;

    final file = File(outputPath);
    if (!await file.exists()) return null;
    try {
      final bytes = await file.readAsBytes();
      return bytes.isEmpty ? null : bytes;
    } finally {
      if (await file.exists()) await file.delete();
    }
  }

  void dispose() {
    unawaited(_dispose());
  }

  Future<void> _dispose() async {
    if (_isRecording) {
      await _recorder.cancel();
      _isRecording = false;
    }
    await _recorder.dispose();
  }
}
