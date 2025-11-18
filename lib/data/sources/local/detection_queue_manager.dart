import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/queued_detection.dart';
import '../../models/detection_exception.dart';

/// Detection Queue Manager
/// Manages offline detection queue with persistence using shared_preferences
class DetectionQueueManager {
  static const int maxQueueSize = 100;
  static const String _queueKey = 'detection_queue';

  final SharedPreferences _prefs;
  final StreamController<int> _queueSizeController = StreamController<int>.broadcast();

  DetectionQueueManager(this._prefs);

  /// Stream of queue size updates for reactive UI
  Stream<int> get queueSizeStream => _queueSizeController.stream;

  /// Get current queue size
  Future<int> get queueSize async {
    final queue = await getQueue();
    return queue.length;
  }

  /// Enqueue a detection for later processing
  /// Throws DetectionException.queueFull if queue is at max capacity
  Future<void> enqueue(QueuedDetection detection) async {
    try {
      final queue = await getQueue();

      // Check if queue is full
      if (queue.length >= maxQueueSize) {
        // Remove oldest detection (FIFO)
        queue.removeAt(0);
        throw DetectionException.queueFull(
          'Detection queue full. Oldest detection discarded.',
        );
      }

      // Add new detection to queue
      queue.add(detection);

      // Persist queue
      await _saveQueue(queue);

      // Notify listeners
      _queueSizeController.add(queue.length);
    } catch (e) {
      if (e is DetectionException) {
        rethrow;
      }
      throw DetectionException.unknown(
        'Failed to enqueue detection: ${e.toString()}',
        e,
      );
    }
  }

  /// Get all queued detections
  Future<List<QueuedDetection>> getQueue() async {
    try {
      final queueJson = _prefs.getString(_queueKey);
      if (queueJson == null || queueJson.isEmpty) {
        return [];
      }

      final List<dynamic> queueList = jsonDecode(queueJson);
      return queueList
          .map((json) => QueuedDetection.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If there's an error reading the queue, return empty list
      // and clear corrupted data
      await _prefs.remove(_queueKey);
      return [];
    }
  }

  /// Remove a detection from the queue by ID
  Future<void> dequeue(String id) async {
    try {
      final queue = await getQueue();
      queue.removeWhere((detection) => detection.id == id);

      await _saveQueue(queue);

      // Notify listeners
      _queueSizeController.add(queue.length);
    } catch (e) {
      throw DetectionException.unknown(
        'Failed to dequeue detection: ${e.toString()}',
        e,
      );
    }
  }

  /// Process all queued detections with retry logic
  /// Returns a list of successfully processed detection IDs
  Future<List<String>> processQueue({
    required Future<void> Function(QueuedDetection) processFunction,
    int maxRetries = 3,
  }) async {
    final queue = await getQueue();
    final successfulIds = <String>[];

    for (final detection in queue) {
      try {
        // Skip if already exceeded max retries
        if (detection.retryCount >= maxRetries) {
          await dequeue(detection.id);
          continue;
        }

        // Attempt to process
        await processFunction(detection);

        // Success - remove from queue
        await dequeue(detection.id);
        successfulIds.add(detection.id);
      } catch (e) {
        // Increment retry count
        final updatedDetection = detection.incrementRetry();
        await _updateDetection(updatedDetection);

        // If max retries reached, remove from queue
        if (updatedDetection.retryCount >= maxRetries) {
          await dequeue(detection.id);
        }
      }
    }

    return successfulIds;
  }

  /// Clear all queued detections
  Future<void> clearQueue() async {
    await _prefs.remove(_queueKey);
    _queueSizeController.add(0);
  }

  /// Get the oldest queued detection
  Future<QueuedDetection?> getOldest() async {
    final queue = await getQueue();
    if (queue.isEmpty) return null;
    return queue.first;
  }

  /// Get the newest queued detection
  Future<QueuedDetection?> getNewest() async {
    final queue = await getQueue();
    if (queue.isEmpty) return null;
    return queue.last;
  }

  /// Check if queue is empty
  Future<bool> get isEmpty async {
    final queue = await getQueue();
    return queue.isEmpty;
  }

  /// Check if queue is full
  Future<bool> get isFull async {
    final queue = await getQueue();
    return queue.length >= maxQueueSize;
  }

  /// Save queue to shared preferences
  Future<void> _saveQueue(List<QueuedDetection> queue) async {
    final queueJson = jsonEncode(queue.map((d) => d.toJson()).toList());
    await _prefs.setString(_queueKey, queueJson);
  }

  /// Update a specific detection in the queue
  Future<void> _updateDetection(QueuedDetection updatedDetection) async {
    final queue = await getQueue();
    final index = queue.indexWhere((d) => d.id == updatedDetection.id);

    if (index != -1) {
      queue[index] = updatedDetection;
      await _saveQueue(queue);
    }
  }

  /// Dispose resources
  void dispose() {
    _queueSizeController.close();
  }
}
