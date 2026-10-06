import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';

class TransportHeader extends StatelessWidget {
  const TransportHeader({
    super.key,
    required this.currentScreen,
    required this.onGoBack,
    required this.onExit,
    required this.onMenuPressed,
  });

  final String currentScreen;
  final VoidCallback onGoBack;
  final VoidCallback onExit;
  final VoidCallback onMenuPressed;

  @override
  Widget build(BuildContext context) {
    if (currentScreen != 'main') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: BorderDirectional(
            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: onGoBack,
              icon: const Icon(Icons.arrow_back),
              color: Colors.orange.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              currentScreen == 'chat' ? AppLocalizations.of(context)!.chatWithDriver : AppLocalizations.of(context)!.callingDriverTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade600, Colors.orange.shade800],
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onExit,
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.speedRides,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.speedRidesSubtitle,
                  style: TextStyle(
                    color: Colors.orange.shade100,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onMenuPressed,
            icon: const Icon(Icons.menu, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class TransportTabNavigation extends StatelessWidget {
  const TransportTabNavigation({
    super.key,
    required this.currentScreen,
    required this.selectedTab,
    required this.onTabSelected,
  });

  final String currentScreen;
  final String selectedTab;
  final ValueChanged<String> onTabSelected;

  @override
  Widget build(BuildContext context) {
    if (currentScreen != 'main') {
      return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _TransportTabButton(
            tabId: 'book',
            label: AppLocalizations.of(context)!.bookRide,
            isSelected: selectedTab == 'book',
            onPressed: () => onTabSelected('book'),
          ),
          _TransportTabButton(
            tabId: 'active',
            label: AppLocalizations.of(context)!.activeRide,
            isSelected: selectedTab == 'active',
            onPressed: () => onTabSelected('active'),
          ),
          _TransportTabButton(
            tabId: 'history',
            label: AppLocalizations.of(context)!.history,
            isSelected: selectedTab == 'history',
            onPressed: () => onTabSelected('history'),
          ),
        ],
      ),
    );
  }
}

class _TransportTabButton extends StatelessWidget {
  const _TransportTabButton({
    required this.tabId,
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  final String tabId;
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.orange.shade600 : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.grey.shade800,
        side: BorderSide(
          color: isSelected ? Colors.orange.shade600 : Colors.grey.shade300,
          width: 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        elevation: isSelected ? 4 : 0,
        shadowColor: isSelected ? Colors.orange.shade200 : Colors.transparent,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: isSelected ? Colors.white : Colors.grey.shade800,
        ),
      ),
    );
  }
}
