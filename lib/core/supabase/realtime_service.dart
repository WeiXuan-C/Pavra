import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

/// Realtime Service
/// Handles all realtime subscriptions and presence
class RealtimeService {
  // Singleton pattern
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  // Quick access to realtime client
  RealtimeClient get realtime => supabase.realtime;

  // Track active channels
  final Map<String, RealtimeChannel> _channels = {};

  /// Subscribe to realtime changes on a table
  RealtimeChannel subscribeToTable({
    required String table,
    required void Function(PostgresChangePayload) callback,
    PostgresChangeEvent event = PostgresChangeEvent.all,
    String schema = 'public',
    PostgresChangeFilter? filter,
  }) {
    final channelName = 'table:$table';

    // Remove existing channel if any
    if (_channels.containsKey(channelName)) {
      unsubscribe(channelName);
    }

    final channel = supabase.channel(channelName);

    channel
        .onPostgresChanges(
          event: event,
          schema: schema,
          table: table,
          filter: filter,
          callback: callback,
        )
        .subscribe();

    _channels[channelName] = channel;
    return channel;
  }

  /// Subscribe to INSERT events only
  RealtimeChannel subscribeToInserts({
    required String table,
    required void Function(PostgresChangePayload) callback,
    PostgresChangeFilter? filter,
  }) {
    return subscribeToTable(
      table: table,
      callback: callback,
      event: PostgresChangeEvent.insert,
      filter: filter,
    );
  }

  /// Subscribe to UPDATE events only
  RealtimeChannel subscribeToUpdates({
    required String table,
    required void Function(PostgresChangePayload) callback,
    PostgresChangeFilter? filter,
  }) {
    return subscribeToTable(
      table: table,
      callback: callback,
      event: PostgresChangeEvent.update,
      filter: filter,
    );
  }

  /// Subscribe to DELETE events only
  RealtimeChannel subscribeToDeletes({
    required String table,
    required void Function(PostgresChangePayload) callback,
    PostgresChangeFilter? filter,
  }) {
    return subscribeToTable(
      table: table,
      callback: callback,
      event: PostgresChangeEvent.delete,
      filter: filter,
    );
  }

  /// Subscribe to presence (online users)
  RealtimeChannel subscribeToPresence({
    required String channelName,
    required void Function(RealtimePresenceJoinPayload) onJoin,
    required void Function(RealtimePresenceLeavePayload) onLeave,
    required void Function(RealtimePresenceSyncPayload) onSync,
    Map<String, dynamic>? initialPresence,
  }) {
    // Remove existing channel if any
    if (_channels.containsKey(channelName)) {
      unsubscribe(channelName);
    }

    final channel = supabase.channel(channelName);

    channel
        .onPresenceSync(onSync)
        .onPresenceJoin(onJoin)
        .onPresenceLeave(onLeave)
        .subscribe((status, error) async {
          if (status == RealtimeSubscribeStatus.subscribed &&
              initialPresence != null) {
            await channel.track(initialPresence);
          }
        });

    _channels[channelName] = channel;
    return channel;
  }

  /// Subscribe to broadcast messages
  RealtimeChannel subscribeToBroadcast({
    required String channelName,
    required String event,
    required void Function(Map<String, dynamic>) callback,
  }) {
    // Remove existing channel if any
    if (_channels.containsKey(channelName)) {
      unsubscribe(channelName);
    }

    final channel = supabase.channel(channelName);

    channel
        .onBroadcast(event: event, callback: (payload) => callback(payload))
        .subscribe();

    _channels[channelName] = channel;
    return channel;
  }

  /// Send a broadcast message
  Future<void> sendBroadcast({
    required String channelName,
    required String event,
    required Map<String, dynamic> payload,
  }) async {
    if (_channels.containsKey(channelName)) {
      await _channels[channelName]!.sendBroadcastMessage(
        event: event,
        payload: payload,
      );
    }
  }

  /// Track presence state
  Future<void> trackPresence({
    required String channelName,
    required Map<String, dynamic> state,
  }) async {
    if (_channels.containsKey(channelName)) {
      await _channels[channelName]!.track(state);
    }
  }

  /// Untrack presence state
  Future<void> untrackPresence(String channelName) async {
    if (_channels.containsKey(channelName)) {
      await _channels[channelName]!.untrack();
    }
  }

  /// Unsubscribe from a specific channel by name
  Future<void> unsubscribe(String channelName) async {
    if (_channels.containsKey(channelName)) {
      await supabase.removeChannel(_channels[channelName]!);
      _channels.remove(channelName);
    }
  }

  /// Unsubscribe from all channels
  Future<void> unsubscribeAll() async {
    for (final channel in _channels.values) {
      await supabase.removeChannel(channel);
    }
    _channels.clear();
  }

  /// Get all active channel names
  List<String> getActiveChannels() {
    return _channels.keys.toList();
  }

  /// Check if a channel is active
  bool isChannelActive(String channelName) {
    return _channels.containsKey(channelName);
  }
}
