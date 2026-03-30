import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:handwerker_app/core/theme/app_theme.dart';

/// Action types that can be queued offline
enum OfflineActionType {
  markOnTheWay,
  confirmArrival,
  startJob,
  completeOrder,
  updateLocation,
  sendMessage,
}

/// A queued action to retry when connectivity restores
class QueuedAction {
  final OfflineActionType type;
  final Map<String, dynamic> payload;
  final DateTime timestamp;

  QueuedAction({
    required this.type,
    required this.payload,
  }) : timestamp = DateTime.now();
}

/// Manages offline action queue with local timestamps
/// Critical actions (payments, disputes) are NOT queued — they require
/// active connectivity as per the workflow spec.
class OfflineQueueManager {
  static final OfflineQueueManager _instance = OfflineQueueManager._();
  factory OfflineQueueManager() => _instance;
  OfflineQueueManager._();

  final Queue<QueuedAction> _queue = Queue();
  bool _isProcessing = false;

  /// Queue an action for later execution
  void enqueue(OfflineActionType type, Map<String, dynamic> payload) {
    // Critical actions cannot be queued
    if (_isCritical(type)) return;

    _queue.add(QueuedAction(type: type, payload: payload));
  }

  /// Process all queued actions when back online
  Future<void> processQueue(
      Future<void> Function(QueuedAction action) executor) async {
    if (_isProcessing || _queue.isEmpty) return;
    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final action = _queue.first;
      try {
        await executor(action);
        _queue.removeFirst();
      } catch (e) {
        // If sync fails after 10 minutes, stop and alert user
        if (DateTime.now().difference(action.timestamp).inMinutes > 10) {
          break;
        }
        // Wait before retrying
        await Future.delayed(const Duration(seconds: 5));
      }
    }

    _isProcessing = false;
  }

  int get pendingCount => _queue.length;
  bool get hasPending => _queue.isNotEmpty;

  void clear() => _queue.clear();

  bool _isCritical(OfflineActionType type) {
    // Payment capture and dispute opening require active connection
    return false; // None of the queued types are critical
  }
}

/// Connectivity-aware banner widget
class ConnectivityBanner extends StatelessWidget {
  final bool isOffline;

  const ConnectivityBanner({super.key, required this.isOffline});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isOffline ? 36 : 0,
      color: isOffline ? AppTheme.error : AppTheme.success,
      child: isOffline
          ? const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_rounded,
                      size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Keine Verbindung — Daten werden verzögert',
                    style: TextStyle(
                      fontFamily: 'GeneralSans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

/// Retry dialog when sync fails
class SyncRetryDialog extends StatelessWidget {
  final int pendingActions;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  const SyncRetryDialog({
    super.key,
    required this.pendingActions,
    required this.onRetry,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
      title: const Row(
        children: [
          Icon(Icons.sync_problem_rounded,
              color: AppTheme.warning, size: 24),
          SizedBox(width: 12),
          Text('Synchronisation fehlgeschlagen'),
        ],
      ),
      content: Text(
        '$pendingActions Aktion${pendingActions == 1 ? '' : 'en'} '
        'konnte${pendingActions == 1 ? '' : 'n'} nicht synchronisiert werden.',
      ),
      actions: [
        TextButton(onPressed: onDismiss, child: const Text('Später')),
        TextButton(
          onPressed: onRetry,
          child: const Text('Erneut versuchen',
              style: TextStyle(color: AppTheme.amber)),
        ),
      ],
    );
  }
}
