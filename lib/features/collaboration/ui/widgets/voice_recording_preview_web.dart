// This implementation is selected only for Flutter web.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';

class VoiceRecordingPreviewButton extends StatefulWidget {
  const VoiceRecordingPreviewButton({
    required this.bytes,
    required this.fileExtension,
    super.key,
  });

  final Uint8List bytes;
  final String fileExtension;

  @override
  State<VoiceRecordingPreviewButton> createState() =>
      _VoiceRecordingPreviewButtonState();
}

class _VoiceRecordingPreviewButtonState
    extends State<VoiceRecordingPreviewButton> {
  late final String _objectUrl;
  late final html.AudioElement _audio;
  final List<StreamSubscription<html.Event>> _subscriptions = [];
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    final mimeType = widget.fileExtension.toLowerCase() == 'm4a'
        ? 'audio/mp4'
        : 'audio/webm';
    _objectUrl = html.Url.createObjectUrlFromBlob(
      html.Blob(<Object>[widget.bytes], mimeType),
    );
    _audio = html.AudioElement()
      ..src = _objectUrl
      ..controls = false
      ..preload = 'auto';
    _subscriptions
      ..add(_audio.onPlay.listen((_) => _setPlaying(true)))
      ..add(_audio.onPause.listen((_) => _setPlaying(false)))
      ..add(
        _audio.onEnded.listen((_) {
          _audio.currentTime = 0;
          _setPlaying(false);
        }),
      );
    _audio.load();
  }

  void _setPlaying(bool value) {
    if (mounted && _isPlaying != value) setState(() => _isPlaying = value);
  }

  Future<void> _toggle() async {
    if (_isPlaying) {
      _audio.pause();
    } else {
      await _audio.play();
    }
  }

  @override
  void dispose() {
    _audio
      ..pause()
      ..removeAttribute('src')
      ..load();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    html.Url.revokeObjectUrl(_objectUrl);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    onPressed: _toggle,
    tooltip: _isPlaying ? 'Pause preview' : 'Play preview',
    icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
  );
}
