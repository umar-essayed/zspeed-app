import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';

class TransportBookTab extends StatelessWidget {
  const TransportBookTab({
    super.key,
    required this.rides,
    required this.selectedRideId,
    required this.onBookRide,
    required this.onShowRideDetails,
    required this.onLocationSelected,
  });

  final List<Map<String, dynamic>> rides;
  final String? selectedRideId;
  final ValueChanged<Map<String, dynamic>> onBookRide;
  final ValueChanged<Map<String, dynamic>> onShowRideDetails;
  final ValueChanged<String> onLocationSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade100,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsetsDirectional.only(bottom: 24),
              child: Column(
                children: [
                  _buildLocationInput(
                    icon: Icons.location_on,
                    iconColor: Colors.orange.shade600,
                    hintText: AppLocalizations.of(context)!.pickupLocation,
                    value: '12 Street, NAC',
                    readOnly: true,
                  ),
                  const SizedBox(height: 16),
                  _buildLocationInput(
                    icon: Icons.location_on,
                    iconColor: Colors.orange.shade600,
                    hintText: AppLocalizations.of(context)!.dropoffLocation,
                    placeholder: AppLocalizations.of(context)!.whereToQuestion,
                    readOnly: false,
                    onTap: () => _showLocationPicker(context),
                  ),
                ],
              ),
            ),
            Text(
              AppLocalizations.of(context)!.availableRides,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children:
                  rides.map((ride) => _buildRideCard(context, ride)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInput({
    required IconData icon,
    required Color iconColor,
    required String hintText,
    String? value,
    String? placeholder,
    required bool readOnly,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: readOnly ? Colors.grey.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: Text(
                value ?? placeholder ?? hintText,
                style: TextStyle(
                  fontSize: 16,
                  color: value != null ? Colors.black : Colors.grey.shade600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadiusDirectional.only(
            topStart: Radius.circular(20),
            topEnd: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.popularLocations,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...[
              'Cairo Tech Hub, NAC',
              'Green River, NAC',
              'Downtown NAC',
              'Monorail Station',
              'Airport'
            ].map(
              (location) => ListTile(
                leading: const Icon(Icons.location_on, color: Colors.orange),
                title: Text(location),
                onTap: () {
                  onLocationSelected(location);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideCard(BuildContext context, Map<String, dynamic> ride) {
    final bool isSelected = selectedRideId == ride['id'];
    return GestureDetector(
      onTap: () => onShowRideDetails(ride),
      child: Container(
        margin: const EdgeInsetsDirectional.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.orange.shade600 : Colors.grey.shade200,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade100, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  ride['image'],
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: Colors.orange.shade50,
                      child: Icon(Icons.person, color: Colors.orange.shade400),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${ride['type']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${ride['price']} EGP',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.driverLabel('${ride['driver']}'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStatItem(
                        icon: Icons.star,
                        iconColor: Colors.orange.shade600,
                        value: '${ride['rating']}',
                      ),
                      _buildStatItem(
                        icon: Icons.people,
                        iconColor: Colors.orange.shade600,
                        value: '${ride['trips']} trips',
                      ),
                      _buildStatItem(
                        icon: Icons.access_time,
                        iconColor: Colors.orange.shade600,
                        value: '${ride['eta']} min',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${ride['car']} • ${ride['plate']}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => onBookRide(ride),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade100, width: 1),
                ),
                child: Icon(
                  Icons.arrow_forward,
                  color: Colors.orange.shade600,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
