import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aanda/src/core/network/cubit/network_status_cubit.dart';
import 'package:aanda/src/core/network/cubit/network_status_state.dart';
import 'package:aanda/src/core/network/presentation/offline_overlay.dart';
import 'package:aanda/src/core/network/presentation/offline_screen.dart';

class NetworkAwareRoot extends StatelessWidget {
  const NetworkAwareRoot({super.key, required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NetworkStatusCubit, NetworkStatusState>(
      builder: (context, state) {
        // 1. If user opened the app while offline and hasn't connected yet:
        // Show the dedicated OfflineScreen.
        if (state.isInitialOffline) {
          return const OfflineScreen();
        }

        // 2. If user is inside the app, keep screen visible and show overlay if offline
        return Stack(
          fit: StackFit.expand,
          children: [
            if (child != null) child!,
            const OfflineOverlay(),
          ],
        );
      },
    );
  }
}
