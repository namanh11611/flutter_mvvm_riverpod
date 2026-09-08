// This implementation is selected only for Flutter web.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/material.dart';

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

  late final html.AudioElement _audio;
  final List<StreamSubscription<html.Event>> _subscriptions = [];
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isLoading = true;
  double _speed = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _audio = html.AudioElement()
      ..src = widget.url
      ..controls = false
      ..preload = 'metadata';
    _subscriptions
      ..add(_audio.onLoadedMetadata.listen((_) => _syncMetadata()))
      ..add(_audio.onDurationChange.listen((_) => _syncMetadata()))
      ..add(_audio.onTimeUpdate.listen((_) => _syncPosition()))
      ..add(_audio.onWaiting.listen((_) => _setLoading(true)))
      ..add(_audio.onCanPlay.listen((_) => _setLoading(false)))
      ..add(_audio.onPlay.listen((_) => _setPlaying(true)))
      ..add(_audio.onPause.listen((_) => _setPlaying(false)))
      ..add(_audio.onEnded.listen((_) => _handleEnded()))
      ..add(
        _audio.onError.listen((_) {
          if (mounted) {
            setState(() {
              _error = 'Voice message unavailable';
              _isLoading = false;
            });
          }
        }),
      );
    _audio.load();
  }

  void _syncMetadata() {
    final seconds = _audio.duration;
    if (!seconds.isFinite || seconds <= 0 || !mounted) return;
    setState(() {
      _duration = _secondsToDuration(seconds);
      _isLoading = false;
    });
  }

  void _syncPosition() {
    if (!mounted) return;
    setState(() => _position = _secondsToDuration(_audio.currentTime));
  }

  void _setLoading(bool value) {
    if (mounted && _isLoading != value) setState(() => _isLoading = value);
  }

  void _setPlaying(bool value) {
    if (mounted && _isPlaying != value) setState(() => _isPlaying = value);
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      _pause();
      return;
    }
    if (_duration > Duration.zero && _position >= _duration) {
      _audio.currentTime = 0;
    }
    if (_activePlayer != this) _activePlayer?._pause();
    _activePlayer = this;
    try {
      await _audio.play();
    } catch (_) {
      if (mounted) setState(() => _error = 'Voice message unavailable');
    }
  }

  void _pause() {
    _audio.pause();
    if (_activePlayer == this) _activePlayer = null;
  }

  void _handleEnded() {
    _audio
      ..pause()
      ..currentTime = 0;
    if (_activePlayer == this) _activePlayer = null;
    if (mounted) {
      setState(() {
        _position = Duration.zero;
        _isPlaying = false;
      });
    }
  }

  void _seek(double fraction) {
    if (_duration <= Duration.zero) return;
    _audio.currentTime = _duration.inMilliseconds * fraction / 1000;
    _syncPosition();
  }

  void _changeSpeed() {
    final next = (_speeds.indexOf(_speed) + 1) % _speeds.length;
    setState(() => _speed = _speeds[next]);
    _audio.playbackRate = _speed;
  }

  Duration _secondsToDuration(num seconds) =>
      Duration(milliseconds: (seconds * 1000).round());

  @override
  void dispose() {
    if (_activePlayer == this) _activePlayer = null;
    _audio
      ..pause()
      ..removeAttribute('src')
      ..load();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
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
    return VoiceMessageControls(
      isMine: widget.isMine,
      isRead: widget.isRead,
      isPlaying: _isPlaying,
      isLoading: _isLoading,
      position: _position,
      duration: _duration,
      speed: _speed,
      onPlayPause: _togglePlayback,
      onSeek: _seek,
      onChangeSpeed: _changeSpeed,
    );
  }
}
