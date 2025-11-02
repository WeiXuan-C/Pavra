import '../../core/api/authority_request/authority_request_api.dart';
import '../models/authority_request_model.dart';

/// Authority Request Repository
/// Bridge between API and UI layer
class AuthorityRequestRepository {
  final _api = AuthorityRequestApi();

  // ========== CREATE ==========

  /// Create a new authority request
  Future<AuthorityRequestModel> createRequest({
    required String userId,
    required String idNumber,
    required String organization,
    required String location,
    String? referrerCode,
    String? remarks,
  }) async {
    final json = await _api.createRequest(
      userId: userId,
      idNumber: idNumber,
      organization: organization,
      location: location,
      referrerCode: referrerCode,
      remarks: remarks,
    );

    return AuthorityRequestModel.fromJson(json);
  }

  // ========== READ ==========

  /// Get request by ID
  Future<AuthorityRequestModel?> getRequestById(String requestId) async {
    final json = await _api.getRequestById(requestId);
    if (json == null) return null;

    return AuthorityRequestModel.fromJson(json);
  }

  /// Get all requests by user ID
  Future<List<AuthorityRequestModel>> getRequestsByUserId(
    String userId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final jsonList = await _api.getRequestsByUserId(
      userId,
      page: page,
      pageSize: pageSize,
    );

    return jsonList
        .map((json) => AuthorityRequestModel.fromJson(json))
        .toList();
  }

  /// Get all pending requests
  Future<List<AuthorityRequestModel>> getPendingRequests({
    int page = 1,
    int pageSize = 20,
  }) async {
    final jsonList = await _api.getPendingRequests(
      page: page,
      pageSize: pageSize,
    );

    return jsonList
        .map((json) => AuthorityRequestModel.fromJson(json))
        .toList();
  }

  /// Check if user has pending request
  Future<bool> hasPendingRequest(String userId) async {
    return await _api.hasPendingRequest(userId);
  }

  // ========== UPDATE ==========

  /// Update request status
  Future<AuthorityRequestModel> updateRequestStatus({
    required String requestId,
    required String status,
    required String reviewedBy,
    String? reviewedComment,
  }) async {
    final jsonList = await _api.updateRequestStatus(
      requestId: requestId,
      status: status,
      reviewedBy: reviewedBy,
      reviewedComment: reviewedComment,
    );

    return AuthorityRequestModel.fromJson(jsonList.first);
  }

  // ========== DELETE ==========

  /// Delete request
  Future<void> deleteRequest(String requestId) async {
    await _api.deleteRequest(requestId);
  }
}
