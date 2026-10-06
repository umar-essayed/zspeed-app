import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';

class TransportHistoryTab extends StatelessWidget {
  const TransportHistoryTab({
    super.key,
    required this.rideHistory,
    required this.onShowRideDetails,
  });

  final List<Map<String, dynamic>> rideHistory;
  final ValueChanged<Map<String, dynamic>> onShowRideDetails;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.rideHistory,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            if (rideHistory.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.history,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppLocalizations.of(context)!.noRideHistory,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children:
                    rideHistory.map((ride) => _buildHistoryCard(ride)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> ride) {
    return GestureDetector(
      onTap: () => onShowRideDetails(ride),
      child: Container(
        margin: const EdgeInsetsDirectional.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride['date'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ride['driver'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${ride['price']} EGP',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          Icons.star,
                          size: 14,
                          color: index < ride['rating']
                              ? Colors.orange.shade600
                              : Colors.grey.shade300,
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on,
                      size: 16, color: Colors.orange.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ride['from'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward,
                      size: 16, color: Colors.orange.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ride['to'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
