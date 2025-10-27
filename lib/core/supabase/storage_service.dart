import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

/// Storage Service
/// Handles all file storage operations
class StorageService {
  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // Quick access to storage client
  SupabaseStorageClient get storage => supabase.storage;

  // Bucket names
  static const String issuePhotosBucket = 'issue-photos';

  /// Upload file to storage
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required dynamic file,
    FileOptions fileOptions = const FileOptions(),
  }) async {
    await supabase.storage
        .from(bucket)
        .upload(path, file, fileOptions: fileOptions);
    return getPublicUrl(bucket: bucket, path: path);
  }

  /// Update existing file in storage
  Future<String> updateFile({
    required String bucket,
    required String path,
    required dynamic file,
    FileOptions fileOptions = const FileOptions(),
  }) async {
    await supabase.storage
        .from(bucket)
        .update(path, file, fileOptions: fileOptions);
    return getPublicUrl(bucket: bucket, path: path);
  }

  /// Download file from storage
  Future<Uint8List> downloadFile({
    required String bucket,
    required String path,
  }) async {
    return await supabase.storage.from(bucket).download(path);
  }

  /// Get public URL for a storage file
  String getPublicUrl({required String bucket, required String path}) {
    return supabase.storage.from(bucket).getPublicUrl(path);
  }

  /// Create signed URL (temporary access)
  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    required int expiresIn, // seconds
  }) async {
    return await supabase.storage.from(bucket).createSignedUrl(path, expiresIn);
  }

  /// List files in a bucket
  Future<List<FileObject>> listFiles({
    required String bucket,
    String? path,
    SearchOptions searchOptions = const SearchOptions(),
  }) async {
    return await supabase.storage
        .from(bucket)
        .list(path: path, searchOptions: searchOptions);
  }

  /// Delete files from storage
  Future<List<FileObject>> deleteFiles({
    required String bucket,
    required List<String> paths,
  }) async {
    return await supabase.storage.from(bucket).remove(paths);
  }

  /// Move/rename a file
  Future<String> moveFile({
    required String bucket,
    required String fromPath,
    required String toPath,
  }) async {
    await supabase.storage.from(bucket).move(fromPath, toPath);
    return getPublicUrl(bucket: bucket, path: toPath);
  }

  /// Copy a file
  Future<String> copyFile({
    required String bucket,
    required String fromPath,
    required String toPath,
  }) async {
    await supabase.storage.from(bucket).copy(fromPath, toPath);
    return getPublicUrl(bucket: bucket, path: toPath);
  }

  /// Create a new bucket
  Future<String> createBucket({required String id, bool public = false}) async {
    return await supabase.storage.createBucket(
      id,
      BucketOptions(public: public),
    );
  }

  /// Delete a bucket
  Future<String> deleteBucket(String id) async {
    return await supabase.storage.deleteBucket(id);
  }

  /// Get bucket details
  Future<Bucket> getBucket(String id) async {
    return await supabase.storage.getBucket(id);
  }

  /// List all buckets
  Future<List<Bucket>> listBuckets() async {
    return await supabase.storage.listBuckets();
  }

  // ========== Issue Photos Specific Methods ==========

  /// Ensure the issue_photos bucket exists
  /// Creates it if it doesn't exist
  Future<void> ensureIssuePhotosBucketExists() async {
    try {
      await getBucket(issuePhotosBucket);
    } catch (e) {
      // Bucket doesn't exist, create it
      try {
        await createBucket(id: issuePhotosBucket, public: true);
      } catch (createError) {
        // Ignore if bucket already exists (race condition)
        if (!createError.toString().contains('already exists')) {
          rethrow;
        }
      }
    }
  }

  /// Upload issue photo to storage
  /// Returns the public URL of the uploaded photo
  Future<String> uploadIssuePhoto({
    required String issueId,
    required String fileName,
    required Uint8List fileBytes,
    String? mimeType,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$issueId/${timestamp}_$fileName';

    await storage
        .from(issuePhotosBucket)
        .uploadBinary(
          storagePath,
          fileBytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: false),
        );

    return getPublicUrl(bucket: issuePhotosBucket, path: storagePath);
  }

  /// Delete issue photo from storage
  Future<void> deleteIssuePhoto(String photoUrl) async {
    try {
      // Extract path from URL
      // URL format: https://xxx.supabase.co/storage/v1/object/public/issue_photos/path
      final uri = Uri.parse(photoUrl);
      final pathSegments = uri.pathSegments;

      // Find 'issue_photos' in path and get everything after it
      final bucketIndex = pathSegments.indexOf(issuePhotosBucket);
      if (bucketIndex == -1 || bucketIndex >= pathSegments.length - 1) {
        throw Exception('Invalid photo URL format');
      }

      final path = pathSegments.sublist(bucketIndex + 1).join('/');
      await storage.from(issuePhotosBucket).remove([path]);
    } catch (e) {
      throw Exception('Failed to delete photo from storage: $e');
    }
  }

  /// Delete all photos for an issue
  Future<void> deleteIssuePhotos(String issueId) async {
    try {
      final files = await storage.from(issuePhotosBucket).list(path: issueId);
      if (files.isEmpty) return;

      final paths = files.map((f) => '$issueId/${f.name}').toList();
      await storage.from(issuePhotosBucket).remove(paths);
    } catch (e) {
      throw Exception('Failed to delete issue photos: $e');
    }
  }
}
