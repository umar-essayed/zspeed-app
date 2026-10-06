import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:z_speed/l10n/app_localizations.dart';
// ride_sample_data removed in Phase 8.10 - using empty lists for legacy UI
import 'package:z_speed/features/driver/model/ride_models.dart';
import 'package:z_speed/features/driver/view/transport_active_tab.dart';
import 'package:z_speed/features/driver/view/transport_book_tab.dart';
import 'package:z_speed/features/driver/view/transport_call_screen.dart';
import 'package:z_speed/features/driver/view/transport_chat_screen.dart';
import 'package:z_speed/features/driver/view/transport_history_tab.dart';
import 'package:z_speed/features/driver/view/transport_dialogs.dart';
import 'package:z_speed/features/driver/view/transport_ride_details_sheet.dart';
import 'package:z_speed/features/driver/widgets/transport_widgets.dart';

// NOTE: The main() in this file is for demo/dev only.
// Production entrypoint is lib/main.dart.

void main() {
  runApp(
    MaterialApp(
      title: 'Speed Rides',
      theme: ThemeData(
        primaryColor: Colors.orange,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.light,
        ),
      ),
      home: const TransportApp(),
    ),
  );
}

class TransportApp extends StatefulWidget {
  const TransportApp({super.key});

  @override
  State<TransportApp> createState() => _TransportAppState();
}

class _TransportAppState extends State<TransportApp> {
  String _selectedTab = 'book';
  String? _selectedRide;
  bool _hasActiveRide = true;
  String? _dropoffLocation;

  // Track current page/screen
  String _currentScreen = 'main'; // 'main', 'chat', 'call'

  // Hardcoded sample data removed in Phase 8.10 - using empty lists
  final List<RideOption> rideOptions = const [];

  final ActiveRide? currentActiveRide = null;

  final List<RideHistoryEntry> historyEntries = const [];

  final List<Map<String, dynamic>> rides = const [];

  final Map<String, dynamic>? activeRide = null;

  final List<Map<String, dynamic>> rideHistory = const [];

  // Show snackbar message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.orange.shade600,
      ),
    );
  }

  // Book a ride
  void _bookRide(Map<String, dynamic> ride) {
    final l10n = AppLocalizations.of(context)!;
    if (_dropoffLocation == null || _dropoffLocation!.isEmpty) {
      _showSnackBar(l10n.pleaseEnterDropoff);
      return;
    }

    _showConfirmationDialog(
      l10n.confirmBooking,
      l10n.bookRideConfirm('${ride['type']}', '${ride['driver']}', '${ride['price']}'),
      () {
        setState(() {
          _hasActiveRide = true;
          _selectedTab = 'active';
          _showSnackBar(l10n.rideBookedSuccess);
        });
      },
    );
  }

  // Show confirmation dialog
  void _showConfirmationDialog(
      String title, String message, VoidCallback onConfirm) {
    TransportDialogs.showConfirmationDialog(
      context,
      title: title,
      message: message,
      onConfirm: onConfirm,
    );
  }

  // ========== CALL & MESSAGE FUNCTIONS ==========

  // Make a call
  void _makeCall() {
    TransportDialogs.showCallDialog(
      context,
      phoneNumber: activeRide?['phone'] ?? '',
      onCall: () {
        setState(() {
          _currentScreen = 'call';
        });
      },
    );
  }

  // Open chat
  void _openChat() {
    TransportDialogs.showChatDialog(
      context,
      onSend: () {
        setState(() {
          _currentScreen = 'chat';
        });
      },
    );
  }

  // Show location dialog
  void _showLocationDialog() {
    TransportDialogs.showLocationDialog(
      context,
      onOpenMaps: () async {
        final url = Uri.parse('https://www.google.com/maps/dir/?api=1&travelmode=driving');
        await launchUrl(url, mode: LaunchMode.externalApplication);
      },
    );
  }

  // Complete ride
  void _completeRide() {
    TransportDialogs.showCompleteRideDialog(
      context,
      onComplete: () {
        setState(() {
          _hasActiveRide = false;
          _showSnackBar(AppLocalizations.of(context)!.rideCompletedThankYou);
        });
      },
    );
  }

  // Cancel ride
  void _cancelRide() {
    TransportDialogs.showCancelRideDialog(
      context,
      onCancel: () {
        setState(() {
          _hasActiveRide = false;
          _selectedTab = 'book';
          _showSnackBar(AppLocalizations.of(context)!.rideCancelledSuccess);
        });
      },
    );
  }

  // Go back to main screen
  void _goBack() {
    setState(() {
      _currentScreen = 'main';
    });
  }

  // ========== HEADER WITH BACK BUTTON ==========
  Widget _buildHeader() {
    return TransportHeader(
      currentScreen: _currentScreen,
      onGoBack: _goBack,
      onExit: () => Navigator.of(context).pop(),
      onMenuPressed: () {},
    );
  }

  Widget _buildTabNavigation() {
    return TransportTabNavigation(
      currentScreen: _currentScreen,
      selectedTab: _selectedTab,
      onTabSelected: (tabId) {
        setState(() {
          _selectedTab = tabId;
        });
      },
    );
  }

  // Main Content based on current screen
  Widget _buildMainContent() {
    if (_currentScreen == 'chat') {
      return _buildChatScreen();
    } else if (_currentScreen == 'call') {
      return _buildCallScreen();
    }

    return _buildMainScreen();
  }

  Widget _buildMainScreen() {
    if (_selectedTab == 'book') {
      return _buildBookTab();
    } else if (_selectedTab == 'active') {
      return _buildActiveTab();
    } else {
      return _buildHistoryTab();
    }
  }

  Widget _buildBookTab() {
    return TransportBookTab(
      rides: rides,
      selectedRideId: _selectedRide,
      onBookRide: _bookRide,
      onShowRideDetails: _showRideDetails,
      onLocationSelected: (location) {
        setState(() {
          _dropoffLocation = location;
        });
      },
    );
  }

  Widget _buildActiveTab() {
    return TransportActiveTab(
      hasActiveRide: _hasActiveRide,
      activeRide: activeRide ?? {},
      onSwitchToBook: () {
        setState(() {
          _selectedTab = 'book';
        });
      },
      onMakeCall: _makeCall,
      onOpenChat: _openChat,
      onCompleteRide: _completeRide,
      onCancelRide: _cancelRide,
      onShowLocationDialog: _showLocationDialog,
    );
  }

  Widget _buildHistoryTab() {
    return TransportHistoryTab(
      rideHistory: rideHistory,
      onShowRideDetails: _showRideDetails,
    );
  }

  Widget _buildChatScreen() {
    return TransportChatScreen(
      activeRide: activeRide ?? {},
      onMessageSent: () => _showSnackBar(AppLocalizations.of(context)!.messageSent),
    );
  }

  Widget _buildCallScreen() {
    return TransportCallScreen(
      activeRide: activeRide ?? {},
      onEndCall: _goBack,
      onMute: () => _showSnackBar('Microphone muted'),
    );
  }

  void _showRideDetails(Map<String, dynamic> ride) {
    showModalBottomSheet(
      context: context,
      builder: (context) => TransportRideDetailsSheet(
        ride: ride,
        onBookRide: _bookRide,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_currentScreen == 'main') _buildTabNavigation(),
            Expanded(
              child: _buildMainContent(),
            ),
          ],
        ),
      ),
    );
  }
}
