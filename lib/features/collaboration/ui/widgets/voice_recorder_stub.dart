import 'dart:typed_data';

class VoiceRecorder {
  bool get isRecording => false;
  String get fileExtension => 'm4a';

  Future<void> start() => throw UnsupportedError(
    'Voice recording is not supported on this device.',
  );

  Future<Uint8List?> stop() async => null;

  void dispose() {}
}
