import 'supabase_service.dart';

/// Service for handling permission checks
///
/// Centralizes all permission logic for notification operations
class PermissionService {
  final SupabaseService _supabase = SupabaseService.instance;

  /// Check if user has permission to create notifications
  ///
  /// Only developers and authorities can create notifications
  Future<bool> canCreateNotification(String userId) async {
    try {
      final users = await _supabase.select(
        'profiles',
        filters: {'id': userId},
      );

      if (users.isEmpty) {
        return false;
      }

      final user = users.first;
      final role = user['role'] as String?;

      return role == 'developer' || role == 'authority';
    } catch (e) {
      return false;
    }
  }

  /// Check if user has permission to update a notification
  ///
  /// Only the creator can update their own draft notifications
  Future<bool> canUpdateNotification(
    String userId,
    String notificationId,
  ) async {
    try {
      final notifications = await _supabase.select(
        'notifications',
        filters: {'id': notificationId},
      );

      if (notifications.isEmpty) {
        return false;
      }

      final notification = notifications.first;
      final createdBy = notification['created_by'] as String?;
      final status = notification['status'] as String;

      // Only creator can update, and only draft notifications
      return createdBy == userId && status == 'draft';
    } catch (e) {
      return false;
    }
  }

  /// Check if user has permission to delete a notification
  ///
  /// Only the creator can delete their own draft/scheduled notifications
  Future<bool> canDeleteNotification(
    String userId,
    String notificationId,
  ) async {
    try {
      final notifications = await _supabase.select(
        'notifications',
        filters: {'id': notificationId},
      );

      if (notifications.isEmpty) {
        return false;
      }

      final notification = notifications.first;
      final createdBy = notification['created_by'] as String?;
      final status = notification['status'] as String;

      // Only creator can delete, and only draft/scheduled notifications
      return createdBy == userId && (status == 'draft' || status == 'scheduled');
    } catch (e) {
      return false;
    }
  }

  /// Check if user has permission to hard delete a notification
  ///
  /// Only admins and developers can hard delete notifications
  Future<bool> canHardDeleteNotification(String userId) async {
    try {
      final users = await _supabase.select(
        'profiles',
        filters: {'id': userId},
      );

      if (users.isEmpty) {
        return false;
      }

      final user = users.first;
      final role = user['role'] as String?;

      return role == 'admin' || role == 'developer';
    } catch (e) {
      return false;
    }
  }

  /// Check if user has permission to delete their own user_notification
  ///
  /// Users can only delete their own user_notification records
  Future<bool> canDeleteUserNotification(
    String userId,
    String notificationId,
  ) async {
    try {
      final userNotifications = await _supabase.select(
        'user_notifications',
        filters: {
          'user_id': userId,
          'notification_id': notificationId,
        },
      );

      // User can delete if they have a user_notification record
      return userNotifications.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Check if user is an admin
  ///
  /// Admins have elevated permissions for system operations
  Future<bool> isAdmin(String userId) async {
    try {
      final users = await _supabase.select(
        'profiles',
        filters: {'id': userId},
      );

      if (users.isEmpty) {
        return false;
      }

      final user = users.first;
      final role = user['role'] as String?;

      return role == 'admin';
    } catch (e) {
      return false;
    }
  }

  /// Check if user is a developer
  ///
  /// Developers have elevated permissions for development operations
  Future<bool> isDeveloper(String userId) async {
    try {
      final users = await _supabase.select(
        'profiles',
        filters: {'id': userId},
      );

      if (users.isEmpty) {
        return false;
      }

      final user = users.first;
      final role = user['role'] as String?;

      return role == 'developer';
    } catch (e) {
      return false;
    }
  }

  /// Check if user has admin or developer role
  ///
  /// Used for operations that require elevated permissions
  Future<bool> hasElevatedPermissions(String userId) async {
    try {
      final users = await _supabase.select(
        'profiles',
        filters: {'id': userId},
      );

      if (users.isEmpty) {
        return false;
      }

      final user = users.first;
      final role = user['role'] as String?;

      return role == 'admin' || role == 'developer';
    } catch (e) {
      return false;
    }
  }

  /// Get user role
  ///
  /// Returns the user's role or null if not found
  Future<String?> getUserRole(String userId) async {
    try {
      final users = await _supabase.select(
        'profiles',
        filters: {'id': userId},
      );

      if (users.isEmpty) {
        return null;
      }

      final user = users.first;
      return user['role'] as String?;
    } catch (e) {
      return null;
    }
  }
}
