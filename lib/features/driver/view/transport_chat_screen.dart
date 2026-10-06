import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';

class TransportChatScreen extends StatelessWidget {
  const TransportChatScreen({
    super.key,
    required this.activeRide,
    required this.onMessageSent,
  });

  final Map<String, dynamic> activeRide;
  final VoidCallback onMessageSent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: BorderDirectional(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(activeRide['driverImage']),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activeRide['driver'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.onlineStatus,
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsetsDirectional.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello! I\'m on my way. ETA 5 minutes.',
                        style: TextStyle(color: Colors.grey.shade800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '2:30 PM',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsetsDirectional.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade100, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Great! I\'ll be waiting at the pickup location.',
                        style: TextStyle(color: Colors.grey.shade800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '2:31 PM',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: BorderDirectional(
              top: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.typeYourMessage,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.orange.shade600,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: IconButton(
                  onPressed: onMessageSent,
                  icon: const Icon(Icons.send, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
