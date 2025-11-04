import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/constants/constants.dart';
import '/generated/locale_keys.g.dart';
import '/theme/app_colors.dart';
import '/theme/app_theme.dart';

class OfflineContainer extends ConsumerStatefulWidget {
  final Widget? child;

  const OfflineContainer({super.key, required this.child});

  @override
  ConsumerState<OfflineContainer> createState() => _OfflineContainerState();
}

class _OfflineContainerState extends ConsumerState<OfflineContainer> {
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription =
        Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    if (Platform.isIOS) return;

    setState(() {
      _isOffline = result.contains(ConnectivityResult.none);
    });
    debugPrint(
        '${Constants.tag} [_OfflineContainerState._updateConnectionStatus] $result => ${_isOffline ? 'offline' : 'online'}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            padding: EdgeInsets.only(top: _isOffline ? 20 : 0),
            child: widget.child,
          ),
          if (_isOffline)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top + 2,
                  bottom: 2,
                ),
                color: AppColors.mono60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.signal_wifi_connected_no_internet_4,
                      size: 16,
                      color: AppColors.mono0,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      LocaleKeys.offline.tr(),
                      style: AppTheme.body14.copyWith(
                        color: AppColors.mono0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
