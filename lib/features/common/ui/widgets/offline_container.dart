import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';

class OfflineContainer extends ConsumerWidget {
  final Widget? child;

  const OfflineContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = false;
    // final isOffline = useState(false);

    // useOnStreamChange(Connectivity().onConnectivityChanged, onData: (data) {
    //   if (Platform.isIOS) return;
    //   isOffline.value = data.contains(ConnectivityResult.none);
    //   debugPrint(
    //       'HENZY [OfflineContainer.build] $data => ${isOffline.value ? 'offline' : 'online'}');
    // });

    return Scaffold(
      body: Stack(
        children: [
          Container(
            padding: EdgeInsets.only(top: isOffline ? 20 : 0),
            child: child,
          ),
          if (isOffline)
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
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Your device is offline',
                      style: AppTheme.bodyMedium14.copyWith(
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
