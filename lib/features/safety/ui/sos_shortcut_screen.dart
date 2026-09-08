import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import 'view_model/sos_view_model.dart';

/// A fast, deliberate confirmation surface opened by platform SOS shortcuts.
class SosShortcutScreen extends ConsumerStatefulWidget {
  const SosShortcutScreen({super.key});

  @override
  ConsumerState<SosShortcutScreen> createState() => _SosShortcutScreenState();
}

class _SosShortcutScreenState extends ConsumerState<SosShortcutScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(sosViewModelProvider.notifier).activate();
    });
  }

  Future<void> _trigger() async {
    await ref.read(sosViewModelProvider.notifier).triggerEmergency();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sosViewModelProvider);
    final viewModel = ref.read(sosViewModelProvider.notifier);
    ref.listen(sosViewModelProvider.select((value) => value.message),
        (previous, next) {
      if (next == null || next == previous) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next)));
      viewModel.clearMessage();
    });

    final busy = state.isTriggering;
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        backgroundColor: const Color(0xFF8F1018),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton.filledTonal(
                    tooltip: 'Cancel SOS',
                    onPressed: busy
                        ? null
                        : () => context.canPop()
                            ? context.pop()
                            : context.go(Routes.main),
                    icon: const Icon(Icons.close),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.sos_rounded, color: Colors.white, size: 92),
                const SizedBox(height: 20),
                Text(
                  busy ? 'Preparing emergency help...' : 'Emergency SOS',
                  textAlign: TextAlign.center,
                  style: AppTheme.title32.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  state.isLocating
                      ? 'Getting your location while you confirm'
                      : 'Slide below to alert your contacts and open the local emergency number.',
                  textAlign: TextAlign.center,
                  style: AppTheme.body16.copyWith(color: Colors.white70),
                ),
                const Spacer(),
                if (busy)
                  const Padding(
                    padding: EdgeInsets.all(28),
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                else
                  _SlideToConfirm(onConfirmed: _trigger),
                const SizedBox(height: 18),
                TextButton(
                  onPressed: busy ? null : () => context.go(Routes.sos),
                  child: const Text(
                    'Open full emergency options',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideToConfirm extends StatefulWidget {
  const _SlideToConfirm({required this.onConfirmed});

  final Future<void> Function() onConfirmed;

  @override
  State<_SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<_SlideToConfirm> {
  double _offset = 0;
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Slide to activate emergency SOS',
        hint: 'Swipe the handle all the way to the right',
        child: LayoutBuilder(
          builder: (context, constraints) {
            const height = 72.0;
            const padding = 6.0;
            const handleSize = height - padding * 2;
            final maxOffset = constraints.maxWidth - handleSize - padding * 2;
            final progress = maxOffset <= 0 ? 0.0 : (_offset / maxOffset);
            return Container(
              height: height,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(height / 2),
                border: Border.all(color: Colors.white38),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: (1 - progress).clamp(0.25, 1).toDouble(),
                    child: const Padding(
                      padding: EdgeInsets.only(left: 58),
                      child: Text(
                        'SLIDE TO ACTIVATE SOS  >>',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .5,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: padding + _offset.clamp(0, maxOffset).toDouble(),
                    child: GestureDetector(
                      onHorizontalDragUpdate: _confirmed
                          ? null
                          : (details) => setState(() {
                                _offset = (_offset + details.delta.dx)
                                    .clamp(0, maxOffset)
                                    .toDouble();
                              }),
                      onHorizontalDragEnd: _confirmed
                          ? null
                          : (_) async {
                              if (_offset >= maxOffset * .88) {
                                setState(() {
                                  _offset = maxOffset;
                                  _confirmed = true;
                                });
                                await widget.onConfirmed();
                                if (mounted) {
                                  setState(() {
                                    _offset = 0;
                                    _confirmed = false;
                                  });
                                }
                              } else {
                                setState(() => _offset = 0);
                              }
                            },
                      child: const CircleAvatar(
                        radius: handleSize / 2,
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.error,
                        child: Icon(Icons.chevron_right_rounded, size: 42),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
}
