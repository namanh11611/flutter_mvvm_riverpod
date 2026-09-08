import 'package:flutter/material.dart';

class VoiceMessageControls extends StatelessWidget {
  const VoiceMessageControls({
    required this.isMine,
    required this.isRead,
    required this.isPlaying,
    required this.isLoading,
    required this.position,
    required this.duration,
    required this.speed,
    required this.onPlayPause,
    required this.onSeek,
    required this.onChangeSpeed,
    super.key,
  });

  final bool isMine;
  final bool isRead;
  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration duration;
  final double speed;
  final VoidCallback? onPlayPause;
  final ValueChanged<double> onSeek;
  final VoidCallback onChangeSpeed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = isMine
        ? colors.onPrimaryContainer
        : colors.onSurfaceVariant;
    final accent = isMine ? colors.primary : colors.secondary;
    final progress = duration.inMilliseconds <= 0
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);

    return Container(
      width: 292,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          IconButton.filled(
            visualDensity: VisualDensity.compact,
            tooltip: isPlaying ? 'Pause voice message' : 'Play voice message',
            onPressed: isLoading ? null : onPlayPause,
            style: IconButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: colors.onPrimary,
              disabledBackgroundColor: accent.withValues(alpha: 0.35),
            ),
            icon: isLoading
                ? SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.onPrimary,
                    ),
                  )
                : Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                VoiceWaveformProgress(
                  progress: progress,
                  activeColor: accent,
                  inactiveColor: foreground.withValues(alpha: 0.3),
                  enabled: duration > Duration.zero,
                  onSeek: onSeek,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Row(
                    children: [
                      Text(
                        _format(position),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: foreground.withValues(alpha: 0.75),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _format(duration),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: foreground.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          TextButton(
            onPressed: onChangeSpeed,
            style: TextButton.styleFrom(
              foregroundColor: foreground,
              minimumSize: const Size(38, 32),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            child: Text(_speedLabel(speed)),
          ),
          const SizedBox(width: 3),
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: accent.withValues(alpha: 0.18),
                foregroundColor: accent,
                child: const Icon(Icons.mic_rounded, size: 19),
              ),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: isRead
                        ? const Color(0xFF38BDF8)
                        : const Color(0xFF22C55E),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isMine
                          ? colors.primaryContainer
                          : colors.surfaceContainerHighest,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _format(Duration value) {
    final minutes = value.inMinutes;
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  static String _speedLabel(double value) =>
      value == value.roundToDouble() ? '${value.toInt()}x' : '${value}x';
}

class VoiceWaveformProgress extends StatelessWidget {
  const VoiceWaveformProgress({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    required this.enabled,
    required this.onSeek,
    super.key,
  });

  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final bool enabled;
  final ValueChanged<double> onSeek;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      void seek(double dx) {
        if (!enabled || constraints.maxWidth <= 0) return;
        onSeek((dx / constraints.maxWidth).clamp(0.0, 1.0));
      }

      return Semantics(
        label: 'Voice message playback position',
        value: '${(progress * 100).round()} percent',
        slider: true,
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => seek(details.localPosition.dx),
            onHorizontalDragUpdate: (details) => seek(details.localPosition.dx),
            child: SizedBox(
              height: 31,
              width: double.infinity,
              child: CustomPaint(
                painter: _WaveformPainter(
                  progress: progress,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  static const _heights = <double>[
    .25,
    .45,
    .72,
    .38,
    .9,
    .55,
    .3,
    .68,
    .85,
    .42,
    .62,
    .95,
    .48,
    .33,
    .78,
    .52,
    .88,
    .36,
    .66,
    .44,
    .82,
    .58,
    .3,
    .7,
    .92,
    .5,
    .76,
    .4,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 2.3;
    final barWidth =
        (size.width - gap * (_heights.length - 1)) / _heights.length;
    final playedX = size.width * progress;
    for (var index = 0; index < _heights.length; index++) {
      final left = index * (barWidth + gap);
      final height = 5 + (size.height - 8) * _heights[index];
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, (size.height - height) / 2, barWidth, height),
        Radius.circular(barWidth),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..color = left + barWidth / 2 <= playedX
              ? activeColor
              : inactiveColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.activeColor != activeColor ||
      oldDelegate.inactiveColor != inactiveColor;
}
