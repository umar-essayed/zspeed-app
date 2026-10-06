import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';

class TransportCallScreen extends StatelessWidget {
  const TransportCallScreen({
    super.key,
    required this.activeRide,
    required this.onEndCall,
    required this.onMute,
  });

  final Map<String, dynamic> activeRide;
  final VoidCallback onEndCall;
  final VoidCallback onMute;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: NetworkImage(activeRide['driverImage']),
          ),
          const SizedBox(height: 24),
          Text(
            activeRide['driver'],
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.calling,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            activeRide['phone'],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: IconButton(
                  onPressed: onEndCall,
                  icon:
                      const Icon(Icons.call_end, color: Colors.white, size: 32),
                  iconSize: 32,
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(width: 32),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: IconButton(
                  onPressed: onMute,
                  icon: Icon(Icons.mic_off,
                      color: Colors.grey.shade800, size: 24),
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
