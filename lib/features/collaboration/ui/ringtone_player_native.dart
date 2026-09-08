// ignore_for_file: experimental_member_use

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class PlatformRingtonePlayer {
  final AudioPlayer _player = AudioPlayer();
  late final StreamAudioSource _source = _GeneratedRingtoneSource();
  bool _loaded = false;
  bool _disposed = false;

  Future<bool> startRinging() async {
    if (_disposed) return false;
    if (_player.playing) return true;
    if (!_loaded) {
      await _player.setAudioSource(_source);
      await _player.setLoopMode(LoopMode.one);
      await _player.setVolume(0.72);
      _loaded = true;
    }
    await _player.seek(Duration.zero);
    unawaited(
      _player.play().catchError((Object error) {
        debugPrint('[group_call] ringtone_play_failed error=$error');
      }),
    );
    debugPrint('[group_call] ringtone_started platform=native');
    return true;
  }

  Future<void> stopRinging() async {
    if (_disposed) return;
    await _player.pause();
    if (_loaded) await _player.seek(Duration.zero);
    debugPrint('[group_call] ringtone_stopped platform=native');
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _player.dispose();
  }
}

class _GeneratedRingtoneSource extends StreamAudioSource {
  _GeneratedRingtoneSource() : _bytes = _buildRingtoneWave();

  final Uint8List _bytes;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final first = (start ?? 0).clamp(0, _bytes.length).toInt();
    final last = (end ?? _bytes.length).clamp(first, _bytes.length).toInt();
    final chunk = Uint8List.sublistView(_bytes, first, last);
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: chunk.length,
      offset: first,
      stream: Stream.value(chunk),
      contentType: 'audio/wav',
    );
  }
}

Uint8List _buildRingtoneWave() {
  const sampleRate = 16000;
  const seconds = 2;
  const bytesPerSample = 2;
  const dataLength = sampleRate * seconds * bytesPerSample;
  final bytes = Uint8List(44 + dataLength);
  final data = ByteData.sublistView(bytes);

  void ascii(int offset, String value) {
    for (var index = 0; index < value.length; index++) {
      data.setUint8(offset + index, value.codeUnitAt(index));
    }
  }

  ascii(0, 'RIFF');
  data.setUint32(4, 36 + dataLength, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, sampleRate * bytesPerSample, Endian.little);
  data.setUint16(32, bytesPerSample, Endian.little);
  data.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  data.setUint32(40, dataLength, Endian.little);

  for (var sample = 0; sample < sampleRate * seconds; sample++) {
    final time = sample / sampleRate;
    final position = time % 1.0;
    final audible = position < 0.36 || (position >= 0.48 && position < 0.84);
    var value = 0.0;
    if (audible) {
      final segmentPosition = position < 0.36 ? position : position - 0.48;
      final edge = math.min(segmentPosition, 0.36 - segmentPosition);
      final envelope = (edge / 0.02).clamp(0.0, 1.0);
      value =
          (math.sin(2 * math.pi * 440 * time) +
              math.sin(2 * math.pi * 480 * time)) *
          0.16 *
          envelope;
    }
    data.setInt16(
      44 + sample * bytesPerSample,
      (value * 32767).round(),
      Endian.little,
    );
  }
  return bytes;
}
