import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

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
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _stateSubscription;
  File? _temporaryFile;
  bool _isPlaying = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _stateSubscription = _player.playerStateStream.listen((state) {
      final playing = state.playing;
      if (state.processingState == ProcessingState.completed) {
        unawaited(_reset());
      } else if (mounted && playing != _isPlaying) {
        setState(() => _isPlaying = playing);
      }
    });
    unawaited(_load());
  }

  Future<void> _load() async {
    final directory = await getTemporaryDirectory();
    final file = File(
      path.join(
        directory.path,
        'gobuddy_preview_${DateTime.now().microsecondsSinceEpoch}.${widget.fileExtension}',
      ),
    );
    await file.writeAsBytes(widget.bytes, flush: true);
    _temporaryFile = file;
    await _player.setFilePath(file.path);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _toggle() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      unawaited(_player.play());
    }
  }

  Future<void> _reset() async {
    await _player.pause();
    await _player.seek(Duration.zero);
    if (mounted) setState(() => _isPlaying = false);
  }

  @override
  void dispose() {
    unawaited(_disposeResources());
    super.dispose();
  }

  Future<void> _disposeResources() async {
    await _stateSubscription?.cancel();
    await _player.dispose();
    final file = _temporaryFile;
    if (file != null && await file.exists()) await file.delete();
  }

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    onPressed: _isLoading ? null : _toggle,
    tooltip: _isPlaying ? 'Pause preview' : 'Play preview',
    icon: _isLoading
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
  );
}
