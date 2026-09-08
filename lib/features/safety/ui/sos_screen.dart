import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../common/ui/widgets/common_header.dart';
import '../model/emergency_service.dart';
import 'state/sos_state.dart';
import 'view_model/sos_view_model.dart';

class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _holdController;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          ref.read(sosViewModelProvider.notifier).triggerEmergency();
        }
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(sosViewModelProvider.notifier).activate();
    });
  }

  @override
  void dispose() {
    _holdController.dispose();
    super.dispose();
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

    return Scaffold(
      body: Column(
        children: [
          const CommonHeader(header: 'Emergency / SOS'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              children: [
                Center(
                  child: _HoldButton(
                    controller: _holdController,
                    isLoading: state.isTriggering || state.isLocating,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Hold for 3 seconds to trigger emergency SOS',
                  textAlign: TextAlign.center,
                  style: AppTheme.subtitle16,
                ),
                const SizedBox(height: 6),
                Text(
                  'Your location is used to find local emergency numbers.',
                  textAlign: TextAlign.center,
                  style: AppTheme.body12.copyWith(color: AppColors.mono60),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.call,
                        label: 'Call local\nemergency',
                        color: AppColors.error,
                        onTap: state.numbers?.preferredService == null
                            ? null
                            : viewModel.callPreferred,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.location_on_outlined,
                        label: 'Broadcast GPS\nnow',
                        color: AppColors.brandSurface,
                        onTap: state.isLocating
                            ? null
                            : viewModel.alertContacts,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'LOCAL EMERGENCY NUMBERS',
                        style: AppTheme.title14.copyWith(
                          color: AppColors.brandTextMuted,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    if (state.countryCode != null)
                      IconButton(
                        tooltip: 'Refresh emergency numbers',
                        onPressed: state.isRefreshing ? null : viewModel.refresh,
                        icon: state.isRefreshing
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh),
                      ),
                  ],
                ),
                if (state.locationLabel != null)
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(state.locationLabel!, style: AppTheme.body14),
                      ),
                      if (state.usingCache)
                        const Chip(label: Text('Saved data')),
                    ],
                  ),
                const SizedBox(height: 12),
                _EmergencyContent(state: state, viewModel: viewModel),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: viewModel.alertContacts,
                  icon: const Icon(Icons.sms_outlined),
                  label: const Text('Alert my emergency contacts'),
                ),
                const SizedBox(height: 14),
                Text(
                  'After the 3-second hold, GoBuddy prepares a location alert for your emergency contacts and opens the emergency number in your phone app. Your phone requires confirmation before sending or calling.',
                  textAlign: TextAlign.center,
                  style: AppTheme.body12.copyWith(color: AppColors.mono60),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyContent extends StatelessWidget {
  const _EmergencyContent({required this.state, required this.viewModel});
  final SosState state;
  final SosViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if ((state.isLocating || state.isRefreshing) && state.numbers == null) {
      return const Card(
        elevation: 0,
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Expanded(child: Text('Finding local emergency numbers…')),
            ],
          ),
        ),
      );
    }
    final numbers = state.numbers;
    if (numbers == null) {
      return Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.public, size: 38),
              const SizedBox(height: 10),
              const Text(
                'Finding the emergency numbers for your current location.',
                textAlign: TextAlign.center,
              ),
              if (state.countryCode != null) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: viewModel.refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      );
    }
    if (numbers.localOnly && numbers.services.isEmpty) {
      return const Card(
        color: AppColors.cempedak10,
        elevation: 0,
        child: ListTile(
          leading: Icon(Icons.warning_amber_rounded),
          title: Text('Local numbers only'),
          subtitle: Text('Ask nearby staff for the emergency number in this area.'),
        ),
      );
    }
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < numbers.services.length; index++) ...[
            _ServiceRow(service: numbers.services[index], viewModel: viewModel),
            if (index < numbers.services.length - 1)
              const Divider(height: 1, indent: 64),
          ],
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.service, required this.viewModel});
  final EmergencyService service;
  final SosViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final icon = switch (service.type) {
      EmergencyServiceType.dispatch => Icons.emergency_outlined,
      EmergencyServiceType.police => Icons.local_police_outlined,
      EmergencyServiceType.ambulance => Icons.medical_services_outlined,
      EmergencyServiceType.fire => Icons.local_fire_department_outlined,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.rambutan10,
            foregroundColor: AppColors.error,
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.label, style: AppTheme.title16),
                Wrap(
                  spacing: 10,
                  children: service.numbers
                      .map((number) => Text(number, style: AppTheme.body14))
                      .toList(),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Call ${service.label}',
            onSelected: viewModel.call,
            itemBuilder: (context) => service.numbers
                .map((number) => PopupMenuItem(
                      value: number,
                      child: Text('Call $number'),
                    ))
                .toList(),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.call, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: onTap == null ? AppColors.mono40 : color),
                const SizedBox(width: 10),
                Expanded(child: Text(label, style: AppTheme.title14)),
              ],
            ),
          ),
        ),
      );
}

class _HoldButton extends StatelessWidget {
  const _HoldButton({required this.controller, required this.isLoading});
  final AnimationController controller;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: isLoading ? null : (_) => controller.forward(from: 0),
        onTapUp: isLoading
            ? null
            : (_) {
                if (!controller.isCompleted) controller.reverse();
              },
        onTapCancel: isLoading
            ? null
            : () {
                if (!controller.isCompleted) controller.reverse();
              },
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) => SizedBox.square(
            dimension: 190,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: isLoading ? null : controller.value,
                  strokeWidth: 9,
                  color: AppColors.error,
                  backgroundColor: AppColors.rambutan20,
                ),
                Center(
                  child: Container(
                    width: 158,
                    height: 158,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sos, size: 54, color: Colors.white),
                              Text(
                                'HOLD',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
