import 'ringtone_player_native.dart'
    if (dart.library.js_interop) 'ringtone_player_web.dart'
    as platform;

/// Cross-platform incoming-call ringtone with an explicit autoplay result.
class RingtonePlayer {
  final platform.PlatformRingtonePlayer _delegate =
      platform.PlatformRingtonePlayer();

  /// Returns false when the browser requires a user gesture before audio can
  /// start. Calling this again from a button tap unlocks and starts the tone.
  Future<bool> startRinging() => _delegate.startRinging();

  Future<void> stopRinging() => _delegate.stopRinging();

  Future<void> dispose() => _delegate.dispose();
}
