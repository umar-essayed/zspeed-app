import 'package:flutter/material.dart';

/// Editable info field row for vendor settings.
class VendorInfoField extends StatelessWidget {
  const VendorInfoField({
    super.key,
    required this.label,
    required this.value,
    required this.onEdit,
  });

  final String label;
  final String value;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Expanded(
                    child: Text(value, style: const TextStyle(fontSize: 16))),
                IconButton(
                  icon: const Icon(Icons.edit,
                      size: 16, color: Color(0xFFF35535)),
                  onPressed: onEdit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Operating-hour row with edit button.
class VendorOperatingHourRow extends StatelessWidget {
  const VendorOperatingHourRow({
    super.key,
    required this.day,
    required this.hours,
    required this.onEdit,
  });

  final String day;
  final String hours;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Row(
            children: [
              Text(hours,
                  style: const TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(width: 8),
              IconButton(
                icon:
                    const Icon(Icons.edit, size: 16, color: Color(0xFFF35535)),
                onPressed: onEdit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Notification toggle row.
class VendorNotificationToggle extends StatelessWidget {
  const VendorNotificationToggle({
    super.key,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500)),
                Text(description,
                    style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          ),
          Switch(
              value: value, // ignore: deprecated_member_use
              onChanged: onChanged,
              activeThumbColor: const Color(0xFFF35535)),
        ],
      ),
    );
  }
}

/// Navigation list tile for vendor settings.
class VendorNavigationTile extends StatelessWidget {
  const VendorNavigationTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.color = const Color(0xFFF35535),
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title,
          style: TextStyle(color: color == Colors.red ? Colors.red : null)),
      trailing: color == Colors.red ? null : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
