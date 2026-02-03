import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../utils/exceptions.dart';

/// Data class for passing image processing parameters to isolate
class _ImageProcessParams {
  final String sourcePath;
  final String destPath;
  final String thumbnailPath;
  final int maxWidth;
  final int maxHeight;
  final int jpegQuality;
  final int thumbnailSize;

  const _ImageProcessParams({
    required this.sourcePath,
    required this.destPath,
    required this.thumbnailPath,
    required this.maxWidth,
    required this.maxHeight,
    required this.jpegQuality,
    required this.thumbnailSize,
  });
}

/// Result from image processing isolate
class _ImageProcessResult {
  final bool success;
  final String? error;
  final int? imageSize;
  final int? thumbnailSize;

  const _ImageProcessResult({
    required this.success,
    this.error,
    this.imageSize,
    this.thumbnailSize,
  });
}

/// Top-level function for processing images in isolate
/// Must be top-level or static to work with compute()
_ImageProcessResult _processImageInIsolate(_ImageProcessParams params) {
  try {
    // Read source image
    final sourceFile = File(params.sourcePath);
    final bytes = sourceFile.readAsBytesSync();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) {
      // If decoding fails, just copy the file as-is
      sourceFile.copySync(params.destPath);
      return _ImageProcessResult(
        success: true,
        imageSize: bytes.length,
        thumbnailSize: 0,
      );
    }

    // Resize if larger than max dimensions
    if (image.width > params.maxWidth || image.height > params.maxHeight) {
      image = img.copyResize(
        image,
        width: image.width > image.height ? params.maxWidth : null,
        height: image.height >= image.width ? params.maxHeight : null,
      );
    }

    // Save compressed image
    final compressedBytes = img.encodeJpg(image, quality: params.jpegQuality);
    File(params.destPath).writeAsBytesSync(compressedBytes);

    // Generate thumbnail
    final thumbnail = img.copyResize(
      image,
      width: params.thumbnailSize,
      height: params.thumbnailSize,
    );
    final thumbnailBytes = img.encodeJpg(thumbnail, quality: 70);
    File(params.thumbnailPath).writeAsBytesSync(thumbnailBytes);

    return _ImageProcessResult(
      success: true,
      imageSize: compressedBytes.length,
      thumbnailSize: thumbnailBytes.length,
    );
  } catch (e) {
    return _ImageProcessResult(
      success: false,
      error: e.toString(),
    );
  }
}

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _imageFolder = 'documents';
  static const String _thumbnailFolder = 'thumbnails';
  static const int _thumbnailSize = 200;
  static const String _storageSizeKey = 'cached_storage_size';
  static const int _maxConcurrentProcessing = 3;

  Directory? _appDocDir;
  Directory? _imageDir;
  Directory? _thumbnailDir;

  // Cached storage size for performance
  int? _cachedStorageSize;

  Future<void> init() async {
    await _ensureDirectories();
  }

  Future<void> _ensureDirectories() async {
    try {
      _appDocDir ??= await getApplicationDocumentsDirectory();

      _imageDir = Directory(path.join(_appDocDir!.path, _imageFolder));
      if (!await _imageDir!.exists()) {
        await _imageDir!.create(recursive: true);
      }

      _thumbnailDir = Directory(path.join(_appDocDir!.path, _thumbnailFolder));
      if (!await _thumbnailDir!.exists()) {
        await _thumbnailDir!.create(recursive: true);
      }
    } catch (e, stackTrace) {
      throw StorageException(
        'Failed to initialize storage directories',
        code: 'STORAGE_INIT_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Synchronous version of getAbsolutePath. Requires init() to be called first.
  String getAbsolutePathSync(String inputPath) {
    if (_appDocDir == null || _imageDir == null) {
      throw StorageException(
        'StorageService not initialized. Call init() first.',
        code: 'STORAGE_NOT_INITIALIZED',
      );
    }

    if (inputPath.startsWith('/')) {
      return inputPath; // Already absolute
    }

    if (inputPath.contains(Platform.pathSeparator)) {
      return path.join(_appDocDir!.path, inputPath);
    } else {
      return path.join(_imageDir!.path, inputPath);
    }
  }

  /// Saves an image to local storage with compression and generates a thumbnail.
  /// Returns the saved image path.
  /// Processing is done in a background isolate for better performance.
  Future<String> saveImage(File imageFile) async {
    try {
      await _ensureDirectories();

      final String fileName = '${const Uuid().v4()}.jpg';
      final String savedPath = path.join(_imageDir!.path, fileName);
      final String thumbnailPath = path.join(_thumbnailDir!.path, fileName);

      // Process image in background isolate
      final params = _ImageProcessParams(
        sourcePath: imageFile.path,
        destPath: savedPath,
        thumbnailPath: thumbnailPath,
        maxWidth: AppConstants.maxImageWidth,
        maxHeight: AppConstants.maxImageHeight,
        jpegQuality: AppConstants.jpegQuality,
        thumbnailSize: _thumbnailSize,
      );

      final result = await compute(_processImageInIsolate, params);

      if (!result.success) {
        throw StorageException(
          result.error ?? 'Failed to process image',
          code: 'STORAGE_PROCESS_FAILED',
        );
      }

      // Update cached storage size
      if (result.imageSize != null && result.thumbnailSize != null) {
        await _updateCachedStorageSize(
            result.imageSize! + result.thumbnailSize!);
      }

      return savedPath;
    } catch (e, stackTrace) {
      if (e is StorageException) rethrow;
      throw StorageException(
        'Failed to save image',
        code: 'STORAGE_SAVE_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Saves multiple images to local storage with compression and generates thumbnails.
  /// Returns the list of saved image paths.
  /// Images are processed in parallel with a concurrency limit for better performance.
  Future<List<String>> saveImages(List<File> imageFiles) async {
    try {
      await _ensureDirectories();

      // Process images in parallel with concurrency limit
      final results = <String>[];
      final errors = <String>[];

      // Create batches based on concurrency limit
      for (var i = 0; i < imageFiles.length; i += _maxConcurrentProcessing) {
        final batch =
            imageFiles.skip(i).take(_maxConcurrentProcessing).toList();

        // Process batch in parallel
        final batchFutures = batch.map((imageFile) async {
          try {
            return await saveImage(imageFile);
          } catch (e) {
            errors.add('Failed to save ${imageFile.path}: $e');
            return null;
          }
        });

        final batchResults = await Future.wait(batchFutures);

        // Collect successful results
        for (final result in batchResults) {
          if (result != null) {
            results.add(result);
          }
        }
      }

      // If all images failed, throw an error
      if (results.isEmpty && imageFiles.isNotEmpty) {
        throw StorageException(
          'Failed to save any images',
          code: 'STORAGE_SAVE_FAILED',
        );
      }

      return results;
    } catch (e, stackTrace) {
      if (e is StorageException) rethrow;
      throw StorageException(
        'Failed to save images',
        code: 'STORAGE_SAVE_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Updates the cached storage size by adding a delta.
  Future<void> _updateCachedStorageSize(int delta) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentSize = prefs.getInt(_storageSizeKey) ?? 0;
      final newSize = currentSize + delta;
      await prefs.setInt(_storageSizeKey, newSize > 0 ? newSize : 0);
      _cachedStorageSize = newSize > 0 ? newSize : 0;
    } catch (e) {
      // Silently fail - cache is not critical
      debugPrint('Failed to update cached storage size: $e');
    }
  }

  /// Invalidates the storage size cache, forcing recalculation on next access.
  Future<void> invalidateStorageSizeCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageSizeKey);
      _cachedStorageSize = null;
    } catch (e) {
      debugPrint('Failed to invalidate storage size cache: $e');
    }
  }

  /// Gets the file size for updating cache when deleting.
  Future<int> _getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (e) {
      // Ignore errors
    }
    return 0;
  }

  /// Deletes an image and its thumbnail from storage.
  Future<void> deleteImage(String imagePath) async {
    try {
      int totalDeleted = 0;

      // Get image size before deleting for cache update
      final imageFile = File(imagePath);
      if (await imageFile.exists()) {
        totalDeleted += await _getFileSize(imagePath);

        // Invalidate Flutter's image cache for this file
        try {
          final fileImage = FileImage(imageFile);
          imageCache.evict(fileImage);
        } catch (e) {
          debugPrint('Failed to evict image from cache: $e');
        }

        await imageFile.delete();
      }

      // Also delete thumbnail
      final fileName = path.basename(imagePath);
      final thumbnailPath = await getThumbnailPath(fileName);
      if (thumbnailPath != null) {
        totalDeleted += await _getFileSize(thumbnailPath);
        final thumbnailFile = File(thumbnailPath);
        if (await thumbnailFile.exists()) {
          // Invalidate thumbnail cache too
          try {
            final thumbImage = FileImage(thumbnailFile);
            imageCache.evict(thumbImage);
          } catch (e) {
            debugPrint('Failed to evict thumbnail from cache: $e');
          }

          await thumbnailFile.delete();
        }
      }

      // Update cached storage size (subtract deleted size)
      if (totalDeleted > 0) {
        await _updateCachedStorageSize(-totalDeleted);
      }
    } catch (e, stackTrace) {
      if (e is StorageException) rethrow;
      throw StorageException(
        'Failed to delete image',
        code: 'STORAGE_DELETE_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Deletes multiple images and their thumbnails from storage.
  Future<void> deleteImages(List<String> imagePaths) async {
    try {
      for (final imagePath in imagePaths) {
        await deleteImage(imagePath);
      }
    } catch (e, stackTrace) {
      if (e is StorageException) rethrow;
      throw StorageException(
        'Failed to delete images',
        code: 'STORAGE_DELETE_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Returns the image file if it exists.
  Future<File?> getImageFile(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e, stackTrace) {
      throw StorageException(
        'Failed to get image file',
        code: 'STORAGE_LOAD_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Returns the thumbnail path for a given image file name.
  Future<String?> getThumbnailPath(String fileName) async {
    try {
      await _ensureDirectories();
      final thumbnailPath = path.join(_thumbnailDir!.path, fileName);
      final file = File(thumbnailPath);
      if (await file.exists()) {
        return thumbnailPath;
      }
      return null;
    } catch (e, stackTrace) {
      if (e is StorageException) rethrow;
      throw StorageException(
        'Failed to get thumbnail path',
        code: 'STORAGE_LOAD_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Returns the thumbnail file for a given image path.
  Future<File?> getThumbnailFile(String imagePath) async {
    try {
      final fileName = path.basename(imagePath);
      final thumbnailPath = await getThumbnailPath(fileName);
      if (thumbnailPath != null) {
        return File(thumbnailPath);
      }
      return null;
    } catch (e, stackTrace) {
      if (e is StorageException) rethrow;
      throw StorageException(
        'Failed to get thumbnail file',
        code: 'STORAGE_LOAD_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Returns all image paths in the documents folder.
  Future<List<String>> getAllImagePaths() async {
    try {
      await _ensureDirectories();

      final List<String> paths = [];
      final entities = await _imageDir!.list().toList();

      for (final entity in entities) {
        if (entity is File && _isImageFile(entity.path)) {
          paths.add(entity.path);
        }
      }

      return paths;
    } catch (e, stackTrace) {
      if (e is StorageException) rethrow;
      throw StorageException(
        'Failed to get image paths',
        code: 'STORAGE_LOAD_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Checks if a file is an image based on extension.
  bool _isImageFile(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext);
  }

  /// Clears all images and thumbnails from storage.
  Future<void> clearAllImages() async {
    try {
      await _ensureDirectories();

      // Clear images
      final imageEntities = await _imageDir!.list().toList();
      for (final entity in imageEntities) {
        if (entity is File) {
          await entity.delete();
        }
      }

      // Clear thumbnails
      final thumbnailEntities = await _thumbnailDir!.list().toList();
      for (final entity in thumbnailEntities) {
        if (entity is File) {
          await entity.delete();
        }
      }

      // Reset storage cache to 0
      _cachedStorageSize = 0;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_storageSizeKey, 0);
    } catch (e, stackTrace) {
      if (e is StorageException) rethrow;
      throw StorageException(
        'Failed to clear all images',
        code: 'STORAGE_DELETE_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Returns the total size of stored images in bytes.
  /// Uses cached value for performance, recalculates if cache is invalid.
  Future<int> getStorageSize({bool forceRecalculate = false}) async {
    try {
      // Return cached value if available and not forcing recalculation
      if (!forceRecalculate && _cachedStorageSize != null) {
        return _cachedStorageSize!;
      }

      // Try to get from SharedPreferences
      if (!forceRecalculate) {
        final prefs = await SharedPreferences.getInstance();
        final cachedSize = prefs.getInt(_storageSizeKey);
        if (cachedSize != null) {
          _cachedStorageSize = cachedSize;
          return cachedSize;
        }
      }

      // Calculate actual storage size
      await _ensureDirectories();

      int totalSize = 0;

      final imageEntities = await _imageDir!.list().toList();
      for (final entity in imageEntities) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      final thumbnailEntities = await _thumbnailDir!.list().toList();
      for (final entity in thumbnailEntities) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      // Cache the result
      _cachedStorageSize = totalSize;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_storageSizeKey, totalSize);

      return totalSize;
    } catch (e, stackTrace) {
      if (e is StorageException) rethrow;
      throw StorageException(
        'Failed to calculate storage size',
        code: 'STORAGE_LOAD_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Backwards-compatible alias used by repositories.
  Future<int> getTotalStorageUsed() async {
    return getStorageSize();
  }

  /// Returns the number of stored images.
  Future<int> getImageCount() async {
    try {
      await _ensureDirectories();

      final entities = await _imageDir!.list().toList();
      return entities.whereType<File>().length;
    } catch (e, stackTrace) {
      if (e is StorageException) rethrow;
      throw StorageException(
        'Failed to get image count',
        code: 'STORAGE_LOAD_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Copies an existing image to storage (useful for importing from gallery).
  Future<String> copyImageToStorage(String sourcePath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw StorageException(
          'Source file does not exist',
          code: 'STORAGE_FILE_NOT_FOUND',
        );
      }
      return await saveImage(sourceFile);
    } catch (e, stackTrace) {
      if (e is StorageException) rethrow;
      throw StorageException(
        'Failed to copy image to storage',
        code: 'STORAGE_SAVE_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Regenerates missing thumbnails for all stored images.
  /// Uses background isolate for processing.
  Future<void> regenerateThumbnails() async {
    try {
      await _ensureDirectories();

      final imagePaths = await getAllImagePaths();
      for (final imagePath in imagePaths) {
        final fileName = path.basename(imagePath);
        final thumbnailPath = path.join(_thumbnailDir!.path, fileName);

        if (!await File(thumbnailPath).exists()) {
          // Use isolate for thumbnail regeneration
          final params = _ImageProcessParams(
            sourcePath: imagePath,
            destPath: imagePath, // Not used for thumbnail-only regeneration
            thumbnailPath: thumbnailPath,
            maxWidth: AppConstants.maxImageWidth,
            maxHeight: AppConstants.maxImageHeight,
            jpegQuality: AppConstants.jpegQuality,
            thumbnailSize: _thumbnailSize,
          );

          // Process in background - we're only generating thumbnail
          await compute(_regenerateThumbnailInIsolate, params);
        }
      }
    } catch (e, stackTrace) {
      if (e is StorageException) rethrow;
      throw StorageException(
        'Failed to regenerate thumbnails',
        code: 'STORAGE_THUMBNAIL_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Converts a relative image path to an absolute path for display/loading.
  /// If the path is already absolute, it returns it as is (for backwards compatibility).
  Future<String> getAbsolutePath(String inputPath) async {
    await _ensureDirectories();
    if (inputPath.startsWith('/')) {
      return inputPath; // Already absolute
    }
    // Assume relative to appDocDir/documents by default if just filename,
    // or relative to appDocDir if it contains directory separator
    if (inputPath.contains(Platform.pathSeparator)) {
      return path.join(_appDocDir!.path, inputPath);
    } else {
      // Legacy fallback or just filename -> assume in image dir
      return path.join(_imageDir!.path, inputPath);
    }
  }

  /// Converts an absolute path to a path relative to the application documents directory.
  Future<String> getRelativePath(String absolutePath) async {
    await _ensureDirectories();
    final docDir = _appDocDir!.path;

    if (absolutePath.startsWith(docDir)) {
      // Remove the docDir prefix
      // Check if there is a separator after docDir
      if (absolutePath.length > docDir.length &&
          absolutePath[docDir.length] == Platform.pathSeparator) {
        return absolutePath.substring(docDir.length + 1);
      }
      return absolutePath.substring(docDir.length);
    }

    return absolutePath; // Could not convert, return original
  }
}

/// Top-level function to regenerate a single thumbnail in isolate
void _regenerateThumbnailInIsolate(_ImageProcessParams params) {
  try {
    final sourceFile = File(params.sourcePath);
    final bytes = sourceFile.readAsBytesSync();
    final image = img.decodeImage(bytes);

    if (image != null) {
      final thumbnail = img.copyResize(
        image,
        width: params.thumbnailSize,
        height: params.thumbnailSize,
      );
      final thumbnailBytes = img.encodeJpg(thumbnail, quality: 70);
      File(params.thumbnailPath).writeAsBytesSync(thumbnailBytes);
    }
  } catch (e) {
    // Silently fail for individual thumbnails
    debugPrint('Failed to regenerate thumbnail: $e');
  }
}
