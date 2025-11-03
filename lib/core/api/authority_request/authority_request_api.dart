import 'dart:developer' as developer;
import '../../supabase/database_service.dart';

/// Authority Request API
/// Handles authority request operations with the database
class AuthorityRequestApi {
  final _db = DatabaseService();

  static const String _tableName = 'requests';

  // ========== CREATE ==========

  /// Create a new authority request
  Future<Map<String, dynamic>> createRequest({
    required String userId,
    required String idNumber,
    required String organization,
    required String location,
    String? referrerCode,
    String? remarks,
  }) async {
    try {
      final data = {
        'user_id': userId,
        'id_number': idNumber,
        'organization': organization,
        'location': location,
        if (referrerCode != null && referrerCode.isNotEmpty)
          'referrer_code': referrerCode,
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
        'status': 'pending',
      };

      return await _db.insert<Map<String, dynamic>>(
        table: _tableName,
        data: data,
      );
    } catch (e) {
      developer.log(
        'Error creating authority request: $e',
        name: 'AuthorityRequestApi',
        error: e,
      );
      rethrow;
    }
  }

  // ========== READ ==========

  /// Get request by ID
  Future<Map<String, dynamic>?> getRequestById(String requestId) async {
    try {
      return await _db.selectSingle(
        table: _tableName,
        columns: '*',
        filterColumn: 'id',
        filterValue: requestId,
      );
    } catch (e) {
      developer.log(
        'Error getting request by ID: $e',
        name: 'AuthorityRequestApi',
        error: e,
      );
      rethrow;
    }
  }

  /// Get all requests by user ID
  Future<List<Map<String, dynamic>>> getRequestsByUserId(
    String userId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      return await _db
          .selectWithPagination(
            table: _tableName,
            columns: '*',
            page: page,
            pageSize: pageSize,
            orderBy: 'created_at',
            ascending: false,
          )
          .then((results) {
            return results
                .where(
                  (r) => r['user_id'] == userId && r['is_deleted'] == false,
                )
                .toList();
          });
    } catch (e) {
      developer.log(
        'Error getting requests by user ID: $e',
        name: 'AuthorityRequestApi',
        error: e,
      );
      rethrow;
    }
  }

  /// Get all pending requests (for admin/authority review)
  Future<List<Map<String, dynamic>>> getPendingRequests({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      return await _db
          .selectWithPagination(
            table: _tableName,
            columns: '*',
            page: page,
            pageSize: pageSize,
            orderBy: 'created_at',
            ascending: false,
          )
          .then((results) {
            return results
                .where(
                  (r) => r['status'] == 'pending' && r['is_deleted'] == false,
                )
                .toList();
          });
    } catch (e) {
      developer.log(
        'Error getting pending requests: $e',
        name: 'AuthorityRequestApi',
        error: e,
      );
      rethrow;
    }
  }

  /// Get all requests with optional status filter (for developer review)
  Future<List<Map<String, dynamic>>> getAllRequests({
    String? status,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      return await _db
          .selectWithPagination(
            table: _tableName,
            columns: '*',
            page: page,
            pageSize: pageSize,
            orderBy: 'created_at',
            ascending: false,
          )
          .then((results) {
            return results.where((r) {
              if (r['is_deleted'] == true) return false;
              if (status != null && r['status'] != status) return false;
              return true;
            }).toList();
          });
    } catch (e) {
      developer.log(
        'Error getting all requests: $e',
        name: 'AuthorityRequestApi',
        error: e,
      );
      rethrow;
    }
  }

  /// Check if user has pending request
  Future<bool> hasPendingRequest(String userId) async {
    try {
      final result = await _db
          .from(_tableName)
          .select('id')
          .eq('user_id', userId)
          .eq('status', 'pending')
          .eq('is_deleted', false);

      return result.isNotEmpty;
    } catch (e) {
      developer.log(
        'Error checking pending request: $e',
        name: 'AuthorityRequestApi',
        error: e,
      );
      rethrow;
    }
  }

  // ========== UPDATE ==========

  /// Update request status (approve/reject)
  Future<List<Map<String, dynamic>>> updateRequestStatus({
    required String requestId,
    required String status,
    required String reviewedBy,
    String? reviewedComment,
  }) async {
    try {
      developer.log(
        'Updating request status: requestId=$requestId, status=$status',
        name: 'AuthorityRequestApi',
      );

      final data = {
        'status': status,
        'reviewed_by': reviewedBy,
        'reviewed_at': DateTime.now().toIso8601String(),
        if (reviewedComment != null && reviewedComment.isNotEmpty)
          'reviewed_comment': reviewedComment,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final result = await _db.update<Map<String, dynamic>>(
        table: _tableName,
        data: data,
        matchColumn: 'id',
        matchValue: requestId,
      );

      developer.log(
        'Update result: ${result.length} records updated',
        name: 'AuthorityRequestApi',
      );

      return result;
    } catch (e) {
      developer.log(
        'Error updating request status: $e',
        name: 'AuthorityRequestApi',
        error: e,
      );
      rethrow;
    }
  }

  // ========== DELETE ==========

  /// Soft delete request
  Future<void> deleteRequest(String requestId) async {
    try {
      await _db.update(
        table: _tableName,
        data: {
          'is_deleted': true,
          'deleted_at': DateTime.now().toIso8601String(),
        },
        matchColumn: 'id',
        matchValue: requestId,
      );
    } catch (e) {
      developer.log(
        'Error deleting request: $e',
        name: 'AuthorityRequestApi',
        error: e,
      );
      rethrow;
    }
  }
}
