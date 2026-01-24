import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as img;
import '../utils/constants.dart';
import '../utils/exceptions.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _imageFolder = 'documents';
  static const String _thumbnailFolder = 'thumbnails';
  static const int _thumbnailSize = 200;

  Directory? _appDocDir;
  Directory? _imageDir;
  Directory? _thumbnailDir;

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

  /// Saves an image to local storage with compression and generates a thumbnail.
  /// Returns the saved image path.
  Future<String> saveImage(File imageFile) async {
    try {
      await _ensureDirectories();

      final String fileName = '${const Uuid().v4()}.jpg';
      final String savedPath = path.join(_imageDir!.path, fileName);

      // Read and process image
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        // If decoding fails, just copy the file as-is
        await imageFile.copy(savedPath);
        return savedPath;
      }

      // Resize if larger than max dimensions
      if (image.width > AppConstants.maxImageWidth ||
          image.height > AppConstants.maxImageHeight) {
        image = img.copyResize(
          image,
          width: image.width > image.height ? AppConstants.maxImageWidth : null,
          height:
              image.height >= image.width ? AppConstants.maxImageHeight : null,
        );
      }

      // Save compressed image
      final compressedBytes = img.encodeJpg(
        image,
        quality: AppConstants.jpegQuality,
      );
      await File(savedPath).writeAsBytes(compressedBytes);

      // Generate thumbnail
      await _generateThumbnail(image, fileName);

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

  /// Generates a thumbnail for the given image.
  Future<void> _generateThumbnail(img.Image image, String fileName) async {
    try {
      await _ensureDirectories();

      final thumbnail = img.copyResize(
        image,
        width: _thumbnailSize,
        height: _thumbnailSize,
      );

      final thumbnailPath = path.join(_thumbnailDir!.path, fileName);
      final thumbnailBytes = img.encodeJpg(thumbnail, quality: 70);
      await File(thumbnailPath).writeAsBytes(thumbnailBytes);
    } catch (e, stackTrace) {
      if (e is StorageException) rethrow;
      throw StorageException(
        'Failed to generate thumbnail',
        code: 'STORAGE_THUMBNAIL_FAILED',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Deletes an image and its thumbnail from storage.
  Future<void> deleteImage(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }

      // Also delete thumbnail
      final fileName = path.basename(imagePath);
      final thumbnailPath = await getThumbnailPath(fileName);
      if (thumbnailPath != null) {
        final thumbnailFile = File(thumbnailPath);
        if (await thumbnailFile.exists()) {
          await thumbnailFile.delete();
        }
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
  Future<int> getStorageSize() async {
    try {
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
  Future<void> regenerateThumbnails() async {
    try {
      await _ensureDirectories();

      final imagePaths = await getAllImagePaths();
      for (final imagePath in imagePaths) {
        final fileName = path.basename(imagePath);
        final thumbnailPath = path.join(_thumbnailDir!.path, fileName);

        if (!await File(thumbnailPath).exists()) {
          final bytes = await File(imagePath).readAsBytes();
          final image = img.decodeImage(bytes);
          if (image != null) {
            await _generateThumbnail(image, fileName);
          }
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
}
