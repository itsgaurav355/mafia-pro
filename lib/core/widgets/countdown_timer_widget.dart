import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

class CountdownTimerWidget extends StatefulWidget {
  final int initialSeconds;
  final VoidCallback? onTimerFinished;

  const CountdownTimerWidget({
    super.key,
    this.initialSeconds = 90,
    this.onTimerFinished,
  });

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  late int _remainingSeconds;
  late int _totalSeconds;
  Timer? _timer;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.initialSeconds;
    _remainingSeconds = widget.initialSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    HapticFeedback.selectionClick();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
        if (_remainingSeconds <= 5 && _remainingSeconds > 0) {
          HapticFeedback.lightImpact();
        }
      } else {
        _stopTimer();
        HapticFeedback.heavyImpact();
        widget.onTimerFinished?.call();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      _remainingSeconds = _totalSeconds;
    });
    HapticFeedback.selectionClick();
  }

  void _add30Seconds() {
    setState(() {
      _remainingSeconds += 30;
      _totalSeconds = (_remainingSeconds > _totalSeconds) ? _remainingSeconds : _totalSeconds;
    });
    HapticFeedback.selectionClick();
  }

  String get _formattedTime {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isCritical = _remainingSeconds <= 10 && _remainingSeconds > 0;
    final progress = _totalSeconds > 0 ? (_remainingSeconds / _totalSeconds) : 0.0;
    final ringColor = isCritical
        ? AppColors.error
        : (_isRunning ? AppColors.dayAccent : AppColors.textSecondary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCritical ? AppColors.error.withValues(alpha: 0.6) : AppColors.surfaceBorder,
          width: isCritical ? 1.5 : 1.0,
        ),
        boxShadow: isCritical
            ? [
                BoxShadow(
                  color: AppColors.error.withValues(alpha: 0.2),
                  blurRadius: 16,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Circular Clock Ring
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 58,
                height: 58,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: AppColors.surfaceBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                ),
              ),
              Text(
                _formattedTime,
                style: TextStyle(
                  color: isCritical ? AppColors.error : AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          // Label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'DISCUSSION TIMER',
                  style: TextStyle(
                    color: isCritical ? AppColors.error : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isRunning ? 'Town Debate Active' : 'Timer Paused',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Quick Controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // +30s
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
                color: AppColors.textSecondary,
                tooltip: '+30 Seconds',
                onPressed: _add30Seconds,
              ),

              // Play / Pause
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRunning ? AppColors.surfaceBorderLight : AppColors.dayAccent,
                ),
                child: IconButton(
                  icon: Icon(
                    _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: _isRunning ? Colors.white : Colors.black,
                    size: 24,
                  ),
                  onPressed: _isRunning ? _stopTimer : _startTimer,
                ),
              ),

              // Reset
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 22),
                color: AppColors.textMuted,
                tooltip: 'Reset',
                onPressed: _resetTimer,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
