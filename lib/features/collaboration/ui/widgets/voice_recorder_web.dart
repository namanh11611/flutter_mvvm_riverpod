// This implementation is selected only for Flutter web.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

class VoiceRecorder {
  html.MediaRecorder? _recorder;
  html.MediaStream? _stream;
  final List<html.Blob> _chunks = [];

  bool get isRecording => _recorder?.state == 'recording';
  String get fileExtension => 'webm';

  Future<void> start() async {
    if (isRecording) return;
    final stream = await html.window.navigator.mediaDevices!.getUserMedia({
      'audio': true,
    });
    _stream = stream;
    final recorder = html.MediaRecorder(stream);
    _chunks.clear();
    recorder.addEventListener('dataavailable', (event) {
      final data = (event as dynamic).data as html.Blob?;
      if (data != null && data.size > 0) _chunks.add(data);
    });
    recorder.start();
    _recorder = recorder;
  }

  Future<Uint8List?> stop() async {
    final recorder = _recorder;
    if (recorder == null || recorder.state != 'recording') return null;
    final completed = Completer<Uint8List?>();
    recorder.addEventListener('stop', (_) {
      final blob = html.Blob(_chunks, 'audio/webm');
      final reader = html.FileReader();
      reader.onLoadEnd.first.then((_) {
        final result = reader.result;
        // dart:html exposes an ArrayBuffer result as Uint8List on current
        // Flutter web builds. Older runtimes can still expose ByteBuffer.
        final bytes = switch (result) {
          Uint8List value => value,
          ByteBuffer value => value.asUint8List(),
          _ => null,
        };
        completed.complete(bytes?.isNotEmpty == true ? bytes : null);
        _stopStream();
      });
      reader.readAsArrayBuffer(blob);
    });
    recorder.stop();
    _recorder = null;
    return completed.future;
  }

  void dispose() {
    if (isRecording) _recorder?.stop();
    _stopStream();
  }

  void _stopStream() {
    for (final track in _stream?.getTracks() ?? <html.MediaStreamTrack>[]) {
      track.stop();
    }
    _stream = null;
  }
}
