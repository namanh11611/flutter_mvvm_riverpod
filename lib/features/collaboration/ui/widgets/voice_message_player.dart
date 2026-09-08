export 'voice_message_player_stub.dart'
    if (dart.library.io) 'voice_message_player_native.dart'
    if (dart.library.html) 'voice_message_player_web.dart';
