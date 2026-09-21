import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aanda/src/core/network/cubit/network_status_cubit.dart';
import 'package:aanda/src/core/network/cubit/network_status_state.dart';

class OfflineOverlay extends StatelessWidget {
  const OfflineOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NetworkStatusCubit, NetworkStatusState>(
      builder: (context, state) {
        final showOffline = state.isMidSessionOffline;
        final showRestored = state.wasOffline;
        final isVisible = showOffline || showRestored;

        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              offset: isVisible ? const Offset(0, 0) : const Offset(0, -1.2),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: isVisible ? 1.0 : 0.0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Material(
                    elevation: 6,
                    shadowColor: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: showRestored
                            ? const Color(0xFF1E3A2B)
                            : const Color(0xFF22262B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: showRestored
                              ? const Color(0xFF34D399)
                              : const Color(0xFFF59E0B).withValues(alpha: 0.8),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Status Icon
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: showRestored
                                  ? const Color(0xFF065F46)
                                  : const Color(0xFF374151),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              showRestored
                                  ? Icons.check_circle_rounded
                                  : Icons.wifi_off_rounded,
                              size: 18,
                              color: showRestored
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFFFBBF24),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Text Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  showRestored
                                      ? 'Back online!'
                                      : 'You are offline!',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  showRestored
                                      ? 'Connection restored'
                                      : 'Changes will sync when reconnected',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Retry Button (only when offline)
                          if (showOffline)
                            InkWell(
                              onTap: state.isChecking
                                  ? null
                                  : () => context
                                      .read<NetworkStatusCubit>()
                                      .retry(),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: state.isChecking
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.refresh_rounded,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Retry',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
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
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
