import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

/// Service for compressing images to meet size requirements for AI detection API
class ImageCompressionService {
  /// Maximum target size in bytes (150KB)
  static const int maxSizeBytes = 150 * 1024;

  /// Default JPEG quality (0-100)
  static const int defaultQuality = 85;

  /// Minimum quality threshold to prevent over-compression
  static const int minQuality = 30;

  /// Quality reduction step for adaptive compression
  static const int qualityStep = 10;

  /// Compresses an image to meet the target size requirement
  /// 
  /// Uses adaptive quality reduction to ensure the compressed image
  /// is smaller than [maxSize] bytes while maintaining acceptable quality.
  /// 
  /// Parameters:
  /// - [imageFile]: The image file to compress (from camera or picker)
  /// - [maxSize]: Maximum size in bytes (defaults to 150KB)
  /// - [quality]: Initial JPEG quality (defaults to 85)
  /// 
  /// Returns: Compressed image as [Uint8List]
  /// 
  /// Throws: [Exception] if compression fails or image cannot be decoded
  Future<Uint8List> compressImage({
    required XFile imageFile,
    int maxSize = maxSizeBytes,
    int quality = defaultQuality,
  }) async {
    try {
      // Read the image file as bytes
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Run compression in isolate to avoid blocking UI thread
      final compressedBytes = await compute(
        _compressImageInIsolate,
        _CompressionParams(
          imageBytes: imageBytes,
          maxSize: maxSize,
          quality: quality,
        ),
      );

      return compressedBytes;
    } catch (e) {
      throw Exception('Image compression failed: $e');
    }
  }

  /// Static method to run in isolate
  static Uint8List _compressImageInIsolate(_CompressionParams params) {
    // Decode the image
    img.Image? image = img.decodeImage(params.imageBytes);
    
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Start with the specified quality
    int currentQuality = params.quality;
    Uint8List? compressedBytes;

    // Adaptive quality reduction loop
    while (currentQuality >= minQuality) {
      // Encode as JPEG with current quality
      compressedBytes = Uint8List.fromList(
        img.encodeJpg(image, quality: currentQuality),
      );

      // Check if size meets requirement
      if (compressedBytes.length <= params.maxSize) {
        return compressedBytes;
      }

      // Reduce quality for next iteration
      currentQuality -= qualityStep;
    }

    // If still too large after minimum quality, resize the image
    if (compressedBytes != null && compressedBytes.length > params.maxSize) {
      // Calculate resize ratio to reduce file size
      final double sizeRatio = params.maxSize / compressedBytes.length;
      final double scaleFactor = sizeRatio * 0.8; // Use 80% to ensure we're under limit
      
      final int newWidth = (image.width * scaleFactor).round();
      final int newHeight = (image.height * scaleFactor).round();

      // Resize image
      final img.Image resizedImage = img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );

      // Encode resized image with minimum quality
      compressedBytes = Uint8List.fromList(
        img.encodeJpg(resizedImage, quality: minQuality),
      );

      // Final check
      if (compressedBytes.length > params.maxSize) {
        throw Exception(
          'Unable to compress image below ${params.maxSize} bytes. '
          'Final size: ${compressedBytes.length} bytes',
        );
      }
    }

    return compressedBytes!;
  }

  /// Converts image bytes to Base64 encoded string
  /// 
  /// Parameters:
  /// - [bytes]: Image bytes to convert
  /// 
  /// Returns: Base64 encoded string
  String convertToBase64(Uint8List bytes) {
    return base64Encode(bytes);
  }

  /// Convenience method to compress and convert to Base64 in one call
  /// 
  /// Parameters:
  /// - [imageFile]: The image file to compress and encode
  /// - [maxSize]: Maximum size in bytes (defaults to 150KB)
  /// - [quality]: Initial JPEG quality (defaults to 85)
  /// 
  /// Returns: Base64 encoded string of compressed image
  Future<String> compressAndEncode({
    required XFile imageFile,
    int maxSize = maxSizeBytes,
    int quality = defaultQuality,
  }) async {
    final Uint8List compressedBytes = await compressImage(
      imageFile: imageFile,
      maxSize: maxSize,
      quality: quality,
    );
    return convertToBase64(compressedBytes);
  }

  /// Gets the size of an image file in bytes
  /// 
  /// Useful for logging and debugging
  Future<int> getImageSize(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    return bytes.length;
  }
}

/// Parameters for image compression in isolate
class _CompressionParams {
  final Uint8List imageBytes;
  final int maxSize;
  final int quality;

  _CompressionParams({
    required this.imageBytes,
    required this.maxSize,
    required this.quality,
  });
}
