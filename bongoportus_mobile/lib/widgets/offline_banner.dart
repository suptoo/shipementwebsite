import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

/// Animated banner that slides down when the device is offline.
/// Shows "You're offline — showing cached data" with a smooth animation.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityService.instance.isOnline,
      builder: (context, online, _) {
        return AnimatedSlide(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          offset: online ? const Offset(0, -1) : Offset.zero,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: online ? 0.0 : 1.0,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.shade700,
                    Colors.deepOrange.shade600,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      color: Colors.white.withAlpha(220),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'You\'re offline — showing cached data',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
