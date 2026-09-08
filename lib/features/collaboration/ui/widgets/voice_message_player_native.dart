import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'voice_message_controls.dart';

class VoiceMessagePlayer extends StatefulWidget {
  const VoiceMessagePlayer({
    required this.url,
    this.isMine = false,
    this.isRead = false,
    super.key,
  });

  final String url;
  final bool isMine;
  final bool isRead;

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  static _VoiceMessagePlayerState? _activePlayer;
  static const _speeds = <double>[1, 1.5, 2];

  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _completionSubscription;
  double _speed = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _completionSubscription = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        unawaited(_resetAfterCompletion());
      }
    });
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      await _player.setUrl(widget.url);
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _error = 'Voice message unavailable');
    }
  }

  @override
  void dispose() {
    if (_activePlayer == this) _activePlayer = null;
    unawaited(_completionSubscription?.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 20),
          const SizedBox(width: 8),
          Text(_error!),
        ],
      );
    }

    return StreamBuilder<PlayerState>(
      stream: _player.playerStateStream,
      builder: (context, stateSnapshot) {
        final state = stateSnapshot.data;
        final isLoading =
            state == null ||
            state.processingState == ProcessingState.loading ||
            state.processingState == ProcessingState.buffering;
        final isPlaying = state?.playing ?? false;
        final isComplete = state?.processingState == ProcessingState.completed;
        return StreamBuilder<Duration>(
          stream: _player.positionStream,
          initialData: Duration.zero,
          builder: (context, positionSnapshot) {
            final duration = _player.duration ?? Duration.zero;
            final position = positionSnapshot.data ?? Duration.zero;
            return VoiceMessageControls(
              isMine: widget.isMine,
              isRead: widget.isRead,
              isPlaying: isPlaying,
              isLoading: isLoading,
              position: position,
              duration: duration,
              speed: _speed,
              onPlayPause: isLoading
                  ? null
                  : () => _togglePlayback(isPlaying, isComplete),
              onSeek: (fraction) => _player.seek(
                Duration(
                  milliseconds: (duration.inMilliseconds * fraction).round(),
                ),
              ),
              onChangeSpeed: _changeSpeed,
            );
          },
        );
      },
    );
  }

  Future<void> _togglePlayback(bool isPlaying, bool isComplete) async {
    if (isPlaying) {
      await _player.pause();
      if (_activePlayer == this) _activePlayer = null;
      return;
    }
    if (_activePlayer != this) await _activePlayer?._player.pause();
    _activePlayer = this;
    if (isComplete) await _player.seek(Duration.zero);
    unawaited(_player.play());
  }

  Future<void> _resetAfterCompletion() async {
    await _player.pause();
    await _player.seek(Duration.zero);
    if (_activePlayer == this) _activePlayer = null;
  }

  void _changeSpeed() {
    final next = (_speeds.indexOf(_speed) + 1) % _speeds.length;
    setState(() => _speed = _speeds[next]);
    unawaited(_player.setSpeed(_speed));
  }
}
