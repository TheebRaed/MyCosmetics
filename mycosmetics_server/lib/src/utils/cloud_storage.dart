/// Production Cloud Storage Integration for Serverpod.
///
/// Serverpod provides built-in cloud storage via the
/// serverpod_cloud_storage_s3 package (AWS S3) and
/// serverpod_cloud_storage_gcp package (Google Cloud Storage).
///
/// Configuration in config/production.yaml:
///
/// storage:
///   public:
///     type: s3
///     bucketName: mycosmetics-assets-prod
///     region: me-south-1
///     keyId: \${CLOUD_STORAGE_KEY_ID}
///     keySecret: \${CLOUD_STORAGE_SECRET}
///     publicHost: assets.mycosmetics.app
///
/// Usage in endpoints (Serverpod built-in):
///   final url = await session.storage.storeFile(
///     storeName: 'public',
///     byteData: imageBytes,
///     path: 'saved_looks/\${userId}/\${filename}',
///     verified: true,
///   );
///
/// The Flutter client uploads via the standard Serverpod upload URL flow:
///   1. POST /serverpod_cloud_storage/upload_description
///      → Returns signed upload URL
///   2. Client PUTs directly to S3/GCS using signed URL
///   3. POST /serverpod_cloud_storage/verify
///      → Server verifies and returns public CDN URL
///
/// This file documents the integration — actual upload logic is handled
/// by Serverpod's built-in cloud storage module.

class CloudStorageConfig {
  /// S3 path prefix for saved look images
  static const savedLooksPrefix  = 'saved_looks';

  /// S3 path prefix for product images
  static const productImagesPrefix = 'products';

  /// S3 path prefix for user avatars
  static const avatarsPrefix = 'avatars';

  /// Maximum file size: 5 MB for images
  static const maxImageBytes = 5 * 1024 * 1024;

  /// Allowed MIME types for upload
  static const allowedMimeTypes = ['image/jpeg', 'image/png', 'image/webp'];

  /// CDN base URL (CloudFront or Cloud CDN in front of S3/GCS)
  static const cdnBase = 'https://assets.mycosmetics.app';

  /// Validates MIME type before accepting upload
  static bool isAllowedMimeType(String mimeType) =>
      allowedMimeTypes.contains(mimeType.toLowerCase());

  /// Builds the public CDN URL from an S3 path
  static String cdnUrl(String s3Path) => '$cdnBase/$s3Path';

  /// Generates a storage path for a saved look
  static String savedLookPath(int userId) =>
      '$savedLooksPrefix/$userId/look_${DateTime.now().millisecondsSinceEpoch}.png';

  /// Generates a storage path for an avatar
  static String avatarPath(int userId) =>
      '$avatarsPrefix/$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
}
