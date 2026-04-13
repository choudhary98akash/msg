import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class LedgerImageService {
  static const int maxWidth = 1200;
  static const int maxProofImages = 4;
  static const int maxInputSizeMB = 10;
  static const String folderName = 'ledger_proofs';

  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  Future<String?> pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 4096,
        maxHeight: 4096,
        imageQuality: 100,
      );
      if (image == null) return null;
      return await _processAndSave(await image.readAsBytes());
    } catch (e) {
      debugPrint('Camera pick error: $e');
      return null;
    }
  }

  Future<String?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 4096,
        maxHeight: 4096,
        imageQuality: 100,
      );
      if (image == null) return null;
      return await _processAndSave(await image.readAsBytes());
    } catch (e) {
      debugPrint('Gallery pick error: $e');
      return null;
    }
  }

  Future<String?> _processAndSave(Uint8List bytes) async {
    try {
      if (!_validateSize(bytes)) {
        throw Exception('Image size exceeds ${maxInputSizeMB}MB limit');
      }

      final processedBytes = await _resizeImage(bytes);
      if (processedBytes == null) {
        throw Exception('Failed to process image');
      }

      final savedPath = await _saveToStorage(processedBytes);
      if (savedPath == null) {
        throw Exception('Failed to save image');
      }

      return savedPath;
    } catch (e) {
      debugPrint('Image processing error: $e');
      rethrow;
    }
  }

  bool _validateSize(Uint8List bytes) {
    final sizeMB = bytes.length / (1024 * 1024);
    return sizeMB <= maxInputSizeMB;
  }

  Future<Uint8List?> _resizeImage(Uint8List bytes) async {
    try {
      final decodedImage = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: maxWidth,
        minHeight: maxWidth,
        quality: 100,
        format: CompressFormat.webp,
      );
      return Uint8List.fromList(decodedImage);
    } catch (e) {
      debugPrint('WebP conversion failed, trying PNG fallback: $e');
      try {
        final pngResult = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: maxWidth,
          minHeight: maxWidth,
          quality: 100,
          format: CompressFormat.png,
        );
        return Uint8List.fromList(pngResult);
      } catch (pngError) {
        debugPrint('PNG fallback also failed: $pngError');
        return null;
      }
    }
  }

  Future<String?> _saveToStorage(Uint8List bytes) async {
    try {
      final directory = await _getStorageDirectory();
      if (directory == null) return null;

      final filename = '${_uuid.v4()}.webp';
      final filePath = path.join(directory.path, filename);
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      return filePath;
    } catch (e) {
      debugPrint('Save to storage error: $e');
      return null;
    }
  }

  Future<Directory?> _getStorageDirectory() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final storageDir = Directory(path.join(appDir.path, folderName));

      if (!await storageDir.exists()) {
        await storageDir.create(recursive: true);
      }

      return storageDir;
    } catch (e) {
      debugPrint('Get storage directory error: $e');
      return null;
    }
  }

  Future<bool> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Delete image error: $e');
      return false;
    }
  }

  Future<int> deleteImages(List<String> imagePaths) async {
    int deletedCount = 0;
    for (final path in imagePaths) {
      if (await deleteImage(path)) {
        deletedCount++;
      }
    }
    return deletedCount;
  }

  Future<void> cleanupOrphanedImages(List<String> validPaths) async {
    try {
      final directory = await _getStorageDirectory();
      if (directory == null || !await directory.exists()) return;

      final files = directory.listSync();
      for (final file in files) {
        if (file is File) {
          if (!validPaths.contains(file.path)) {
            try {
              await file.delete();
              debugPrint('Cleaned up orphaned image: ${file.path}');
            } catch (e) {
              debugPrint('Failed to delete orphaned file: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Cleanup orphaned images error: $e');
    }
  }

  String sanitizeFilename(String input) {
    return input
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-.]'), '_')
        .toLowerCase()
        .substring(0, input.length > 50 ? 50 : input.length);
  }

  bool fileExists(String imagePath) {
    return File(imagePath).existsSync();
  }
}
