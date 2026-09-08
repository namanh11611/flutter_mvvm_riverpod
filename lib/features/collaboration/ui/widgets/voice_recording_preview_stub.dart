import 'dart:typed_data';

import 'package:flutter/material.dart';

class VoiceRecordingPreviewButton extends StatelessWidget {
  const VoiceRecordingPreviewButton({
    required this.bytes,
    required this.fileExtension,
    super.key,
  });

  final Uint8List bytes;
  final String fileExtension;

  @override
  Widget build(BuildContext context) => const IconButton(
    onPressed: null,
    tooltip: 'Preview unavailable',
    icon: Icon(Icons.play_arrow_rounded),
  );
}
