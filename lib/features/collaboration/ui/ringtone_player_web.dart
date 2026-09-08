import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Web Audio implementation with no external audio file or asset dependency.
class PlatformRingtonePlayer {
  web.AudioContext? _context;
  Timer? _repeatTimer;
  final Set<Timer> _burstTimers = {};
  final Set<web.OscillatorNode> _oscillators = {};
  bool _disposed = false;
  bool _ringing = false;

  Future<bool> startRinging() async {
    if (_disposed) return false;
    if (_ringing && _context?.state == 'running') return true;

    final context = _context ??= web.AudioContext();
    try {
      if (context.state != 'running') {
        await context.resume().toDart.timeout(const Duration(seconds: 2));
      }
    } catch (error) {
      debugPrint('[group_call] ringtone_autoplay_blocked error=$error');
      return false;
    }
    if (context.state != 'running') {
      debugPrint(
        '[group_call] ringtone_autoplay_blocked state=${context.state}',
      );
      return false;
    }

    _ringing = true;
    _repeatTimer?.cancel();
    _playBurst();
    _repeatTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _playBurst(),
    );
    debugPrint('[group_call] ringtone_started platform=web_audio');
    return true;
  }

  void _playBurst() {
    final context = _context;
    if (!_ringing || context == null || context.state != 'running') return;

    final gain = context.createGain();
    gain.gain.value = 0.075;
    gain.connect(context.destination);
    final burstOscillators = <web.OscillatorNode>[];
    for (final frequency in const [440.0, 480.0]) {
      final oscillator = context.createOscillator();
      oscillator.type = 'sine';
      oscillator.frequency.value = frequency;
      oscillator.connect(gain);
      oscillator.start();
      _oscillators.add(oscillator);
      burstOscillators.add(oscillator);
    }

    late final Timer stopTimer;
    stopTimer = Timer(const Duration(milliseconds: 720), () {
      _burstTimers.remove(stopTimer);
      for (final oscillator in burstOscillators) {
        _stopOscillator(oscillator);
      }
      try {
        gain.disconnect();
      } catch (_) {
        // The audio graph may already be disconnected during teardown.
      }
    });
    _burstTimers.add(stopTimer);
  }

  void _stopOscillator(web.OscillatorNode oscillator) {
    _oscillators.remove(oscillator);
    try {
      oscillator.stop();
    } catch (_) {
      // Stopping an already-finished oscillator is harmless.
    }
    try {
      oscillator.disconnect();
    } catch (_) {
      // The node may already have been disconnected during teardown.
    }
  }

  Future<void> stopRinging() async {
    _ringing = false;
    _repeatTimer?.cancel();
    _repeatTimer = null;
    for (final timer in _burstTimers.toList()) {
      timer.cancel();
    }
    _burstTimers.clear();
    for (final oscillator in _oscillators.toList()) {
      _stopOscillator(oscillator);
    }
    final context = _context;
    _context = null;
    if (context != null && context.state != 'closed') {
      try {
        await context.close().toDart;
      } catch (_) {
        // Closing is best-effort when the browser is tearing down the page.
      }
    }
    debugPrint('[group_call] ringtone_stopped platform=web_audio');
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await stopRinging();
  }
}
