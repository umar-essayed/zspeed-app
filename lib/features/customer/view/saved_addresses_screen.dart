import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/features/customer/model/saved_address.dart';
import 'package:uuid/uuid.dart';

class SavedAddressesScreen extends StatelessWidget {
  const SavedAddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color brandOrange = Color(0xFFF35535);
    const Color brandYellow = Color(0xFFFF9800);

    // In a real implementation, we would extract this into a ViewModel,
    // but we can wire it directly to AuthCubit for MVP
    final authCubit = context.watch<AuthCubit>();
    final user = authCubit.state.user;

    if (user == null) {
      return Scaffold(
          body: Center(child: Text(AppLocalizations.of(context)!.pleaseLogin)));
    }

    final addresses = user.savedAddresses;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.savedAddresses,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [brandOrange, brandYellow],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: addresses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.noAddressesSavedYet,
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final addr = addresses[index];
                return Card(
                  margin: const EdgeInsetsDirectional.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          const Color(0xFFF35535).withValues(alpha: 0.1),
                      child: const Icon(Icons.location_on,
                          color: Color(0xFFF35535)),
                    ),
                    title: Text(addr.label,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(addr.address),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          authCubit.removeSavedAddress(addr.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(AppLocalizations.of(context)!
                                    .addressRemoved(addr.label))),
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(AppLocalizations.of(context)!.delete,
                              style: const TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAddressDialog(context, authCubit),
        backgroundColor: const Color(0xFFF35535),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(AppLocalizations.of(context)!.addNew,
            style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showAddAddressDialog(BuildContext context, AuthCubit authCubit) {
    final labelCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final buildingCtrl = TextEditingController();
    final floorCtrl = TextEditingController();
    final instCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.addSavedAddress),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelCtrl,
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.addressLabel),
              ),
              TextField(
                controller: addressCtrl,
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.fullAddress),
              ),
              TextField(
                controller: buildingCtrl,
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.buildingOptional),
              ),
              TextField(
                controller: floorCtrl,
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.floorAptOptional),
              ),
              TextField(
                controller: instCtrl,
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!
                        .deliveryInstructionsOptional),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel,
                style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (labelCtrl.text.trim().isEmpty ||
                  addressCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          AppLocalizations.of(context)!.labelAndAddressAre)),
                );
                return;
              }

              final newAddress = SavedAddress(
                id: const Uuid().v4(),
                label: labelCtrl.text.trim(),
                address: addressCtrl.text.trim(),
                latitude: 0.0, // Defaults for MVP
                longitude: 0.0,
                building: buildingCtrl.text.trim().isEmpty
                    ? null
                    : buildingCtrl.text.trim(),
                floor: floorCtrl.text.trim().isEmpty
                    ? null
                    : floorCtrl.text.trim(),
                instructions:
                    instCtrl.text.trim().isEmpty ? null : instCtrl.text.trim(),
              );

              authCubit.addSavedAddress(newAddress);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(AppLocalizations.of(context)!
                        .addressAdded(newAddress.label))),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF35535),
                foregroundColor: Colors.white),
            child: Text(AppLocalizations.of(context)!.save,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
