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

  /// Upload file to storage
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required dynamic file,
    FileOptions fileOptions = const FileOptions(),
  }) async {
    await supabase.storage.from(bucket).upload(
      path,
      file,
      fileOptions: fileOptions,
    );
    return getPublicUrl(bucket: bucket, path: path);
  }

  /// Update existing file in storage
  Future<String> updateFile({
    required String bucket,
    required String path,
    required dynamic file,
    FileOptions fileOptions = const FileOptions(),
  }) async {
    await supabase.storage.from(bucket).update(
      path,
      file,
      fileOptions: fileOptions,
    );
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
  String getPublicUrl({
    required String bucket,
    required String path,
  }) {
    return supabase.storage.from(bucket).getPublicUrl(path);
  }

  /// Create signed URL (temporary access)
  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    required int expiresIn, // seconds
  }) async {
    return await supabase.storage
        .from(bucket)
        .createSignedUrl(path, expiresIn);
  }

  /// List files in a bucket
  Future<List<FileObject>> listFiles({
    required String bucket,
    String? path,
    SearchOptions searchOptions = const SearchOptions(),
  }) async {
    return await supabase.storage.from(bucket).list(
      path: path,
      searchOptions: searchOptions,
    );
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
  Future<String> createBucket({
    required String id,
    bool public = false,
  }) async {
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
}
