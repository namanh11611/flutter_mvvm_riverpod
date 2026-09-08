import 'package:flutter/material.dart';

class VoiceMessagePlayer extends StatelessWidget {
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
  Widget build(BuildContext context) => const Text('Voice message attached');
}
