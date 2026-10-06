import 'dart:async';
import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime expiresAt;
  final TextStyle? style;
  final VoidCallback? onExpired;

  const CountdownTimer({
    super.key,
    required this.expiresAt,
    this.style,
    this.onExpired,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  late Duration _timeLeft;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _timeLeft = widget.expiresAt.isAfter(now)
        ? widget.expiresAt.difference(now)
        : Duration.zero;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateTimeLeft();
    });
    if (_timeLeft == Duration.zero) {
      _timer.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onExpired?.call());
    }
  }

  void _calculateTimeLeft() {
    if (!mounted) return;
    final now = DateTime.now();
    if (widget.expiresAt.isAfter(now)) {
      setState(() {
        _timeLeft = widget.expiresAt.difference(now);
      });
    } else {
      _timer.cancel();
      if (mounted) {
        setState(() {
          _timeLeft = Duration.zero;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onExpired?.call();
        });
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timeLeft == Duration.zero) {
      return Text(AppLocalizations.of(context)!.expired, style: widget.style?.copyWith(color: Colors.red));
    }

    final minutes = _timeLeft.inMinutes.toString().padLeft(2, '0');
    final seconds = (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');

    return Text(
      '$minutes:$seconds',
      style: widget.style,
    );
  }
}
