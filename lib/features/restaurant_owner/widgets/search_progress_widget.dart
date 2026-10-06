import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/core/enums/driver_enums.dart';
import 'package:z_speed/features/driver/model/order_driver.dart';

class SearchProgressWidget extends StatefulWidget {
  final String orderId;
  final VoidCallback? onRetry;
  final VoidCallback? onManualAssign;
  final VoidCallback? onTimeout;
  final VoidCallback? onCancel;
  final bool isUnassignedState;

  const SearchProgressWidget({
    super.key,
    required this.orderId,
    this.onRetry,
    this.onManualAssign,
    this.onTimeout,
    this.onCancel,
    required this.isUnassignedState,
  });

  @override
  State<SearchProgressWidget> createState() => _SearchProgressWidgetState();
}

class _SearchProgressWidgetState extends State<SearchProgressWidget> {
  late final Stream<QuerySnapshot> _orderDriversStream;

  @override
  void initState() {
    super.initState();
    _orderDriversStream = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .collection('orderDrivers')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<QuerySnapshot>(
      stream: _orderDriversStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        
        OrderDriver? pendingDriver;
        Timestamp? pendingExpiresAt;
        final List<OrderDriver> failedAttempts = [];

        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final driver = OrderDriver.fromMap(data);
          if (driver.status == DriverAssignmentStatus.pending) {
            pendingDriver = driver;
            pendingExpiresAt = data['expiresAt'] as Timestamp?;
          } else if (driver.status == DriverAssignmentStatus.rejected ||
              driver.status == DriverAssignmentStatus.cancelled) {
            failedAttempts.add(driver);
          }
        }

        // Sort failed attempts by assignedAt (descending)
        failedAttempts.sort((a, b) => b.assignedAt.compareTo(a.assignedAt));

        if (widget.isUnassignedState) {
          return _buildUnassignedUI(context, l10n, failedAttempts);
        }

        return _buildSearchingUI(context, l10n, pendingDriver, pendingExpiresAt, failedAttempts);
      },
    );
  }

  Widget _buildSearchingUI(
    BuildContext context,
    AppLocalizations l10n,
    OrderDriver? pendingDriver,
    Timestamp? expiresAt,
    List<OrderDriver> failedAttempts,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  pendingDriver != null
                      ? 'Requesting driver: ${pendingDriver.driverName}'
                      : l10n.statusSearching,
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          if (pendingDriver != null && expiresAt != null) ...[
            const SizedBox(height: 12),
            DriverCountdownTimer(
              expiresAt: expiresAt,
              onTimeout: widget.onTimeout,
            ),
            if (pendingDriver.driverPhone.isNotEmpty ||
                pendingDriver.vehicleModel.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Vehicle: ${pendingDriver.vehicleModel} ${pendingDriver.licensePlate.isNotEmpty ? "(${pendingDriver.licensePlate})" : ""}',
                style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
              ),
            ],
          ] else ...[
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Selecting next driver...',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.orange.shade100,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ],
          if (failedAttempts.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => _showAttemptsHistoryDialog(context, failedAttempts),
                icon: const Icon(Icons.history, size: 18, color: Colors.orange),
                label: Text(
                  'View Attempts History (${failedAttempts.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ),
            ),
          ],
        if (widget.onCancel != null) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onCancel,
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('Cancel Search'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade800,
                side: BorderSide(color: Colors.red.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

  Widget _buildUnassignedUI(
    BuildContext context,
    AppLocalizations l10n,
    List<OrderDriver> failedAttempts,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.statusUnassigned,
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Dispatch was cancelled or all drivers declined.',
                style: TextStyle(color: Colors.red.shade800, fontSize: 13),
              ),
              if (failedAttempts.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => _showAttemptsHistoryDialog(context, failedAttempts),
                    icon: Icon(Icons.history, size: 18, color: Colors.red.shade700),
                    label: Text(
                      'View Attempts History (${failedAttempts.length})',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (widget.onRetry != null)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry Auto-Assign'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            if (widget.onRetry != null && widget.onManualAssign != null) const SizedBox(width: 8),
            if (widget.onManualAssign != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onManualAssign,
                  icon: const Icon(Icons.delivery_dining, size: 18),
                  label: Text(l10n.assignDriver),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.teal,
                    side: const BorderSide(color: Colors.teal),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _showAttemptsHistoryDialog(BuildContext context, List<OrderDriver> attempts) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.history, color: Colors.orange),
              const SizedBox(width: 10),
              Text(
                'Attempts History (${attempts.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: attempts.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final attempt = attempts[index];
                final isTimeout = attempt.rejectionReason?.contains('timed out') ?? false;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Icon(
                        isTimeout ? Icons.timer_off_outlined : Icons.cancel_outlined,
                        size: 18,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              attempt.driverName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (attempt.vehicleModel.isNotEmpty)
                              Text(
                                '${attempt.vehicleModel} ${attempt.licensePlate.isNotEmpty ? "(${attempt.licensePlate})" : ""}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isTimeout ? 'Timed out' : 'Declined',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade800,
                            ),
                          ),
                          if (attempt.rejectionReason != null && !isTimeout)
                            Text(
                              attempt.rejectionReason!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class DriverCountdownTimer extends StatefulWidget {
  final Timestamp expiresAt;
  final VoidCallback? onTimeout;

  const DriverCountdownTimer({
    super.key,
    required this.expiresAt,
    this.onTimeout,
  });

  @override
  State<DriverCountdownTimer> createState() => _DriverCountdownTimerState();
}

class _DriverCountdownTimerState extends State<DriverCountdownTimer> {
  Timer? _timer;
  int _secondsRemaining = 0;
  bool _hasTriggeredTimeout = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant DriverCountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt) {
      _hasTriggeredTimeout = false;
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    final expiry = widget.expiresAt.toDate();
    final now = DateTime.now();
    _secondsRemaining = expiry.difference(now).inSeconds;
    if (_secondsRemaining < 0) _secondsRemaining = 0;

    if (_secondsRemaining > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() {
            _secondsRemaining--;
          });
        } else {
          _timer?.cancel();
          _triggerTimeout();
        }
      });
    } else {
      _triggerTimeout();
    }
  }

  void _triggerTimeout() {
    if (!_hasTriggeredTimeout) {
      _hasTriggeredTimeout = true;
      widget.onTimeout?.call();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Awaiting response...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.orange.shade800,
              ),
            ),
            Text(
              '${_secondsRemaining}s remaining',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _secondsRemaining < 10 ? Colors.red : Colors.orange.shade900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _secondsRemaining > 0 ? _secondsRemaining / 60.0 : 0.0,
            backgroundColor: Colors.orange.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(
              _secondsRemaining < 10 ? Colors.red : Colors.orange,
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
