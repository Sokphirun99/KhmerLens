import 'dart:io';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // TODO: Implement storage operations
  Future<String> saveImage(File imageFile) async {
    // TODO: Implement save image to local storage
    return '';
  }

  Future<void> deleteImage(String imagePath) async {
    // TODO: Implement delete image
  }

  Future<File?> getImageFile(String imagePath) async {
    // TODO: Implement get image file
    return null;
  }

  Future<List<String>> getAllImagePaths() async {
    // TODO: Implement get all image paths
    return [];
  }

  Future<void> clearAllImages() async {
    // TODO: Implement clear all images
  }
}
