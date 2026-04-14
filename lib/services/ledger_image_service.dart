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
  static const int minFileSizeBytes = 100;
  static const int maxFileSizeBytes = 50 * 1024 * 1024;

  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  final Set<String> _pendingOrphans = {};
  bool _cleanupScheduled = false;

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
      if (!_validateInputSize(bytes)) {
        throw Exception('Image size exceeds ${maxInputSizeMB}MB limit');
      }

      final result = await _resizeImage(bytes);
      if (result == null) {
        throw Exception('Failed to process image');
      }

      final savedPath =
          await _saveToStorage(result.bytes, isWebp: result.isWebp);
      if (savedPath == null) {
        throw Exception('Failed to save image');
      }

      if (!await validateImage(savedPath)) {
        await deleteImage(savedPath);
        throw Exception('Image validation failed');
      }

      return savedPath;
    } catch (e) {
      debugPrint('Image processing error: $e');
      rethrow;
    }
  }

  bool _validateInputSize(Uint8List bytes) {
    final sizeMB = bytes.length / (1024 * 1024);
    return sizeMB <= maxInputSizeMB;
  }

  Future<({Uint8List bytes, bool isWebp})?> _resizeImage(
      Uint8List bytes) async {
    try {
      final decodedImage = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: maxWidth,
        minHeight: maxWidth,
        quality: 100,
        format: CompressFormat.webp,
      );
      return (bytes: Uint8List.fromList(decodedImage), isWebp: true);
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
        return (bytes: Uint8List.fromList(pngResult), isWebp: false);
      } catch (pngError) {
        debugPrint('PNG fallback also failed: $pngError');
        return null;
      }
    }
  }

  Future<String?> _saveToStorage(Uint8List bytes,
      {required bool isWebp}) async {
    try {
      final directory = await _getStorageDirectory();
      if (directory == null) return null;

      final extension = isWebp ? 'webp' : 'png';
      final filename = '${_uuid.v4()}.$extension';
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

  Future<bool> validateImage(String imagePath) async {
    try {
      final file = File(imagePath);

      if (!file.existsSync()) return false;

      final storageDir = await _getStorageDirectory();
      if (storageDir == null) return false;

      final normalizedPath = file.resolveSymbolicLinksSync();
      if (!normalizedPath.startsWith(storageDir.path)) return false;

      final stat = await file.stat();
      if (stat.size < minFileSizeBytes) return false;
      if (stat.size > maxFileSizeBytes) return false;

      final headerBytes = Uint8List.fromList(await file.openRead(0, 12).first);
      if (!_isValidImageHeader(headerBytes)) return false;

      return true;
    } catch (e) {
      debugPrint('Image validation failed: $e');
      return false;
    }
  }

  bool _isValidImageHeader(Uint8List bytes) {
    if (bytes.length < 4) return false;

    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return true;

    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) return true;

    if (bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46) return true;

    return false;
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

  Future<void> markOrphan(String orphanPath) async {
    _pendingOrphans.add(orphanPath);
    _scheduleCleanup();
  }

  void _scheduleCleanup() {
    if (_cleanupScheduled) return;
    _cleanupScheduled = true;

    Future.delayed(const Duration(seconds: 5), () {
      _processOrphans();
      _cleanupScheduled = false;

      if (_pendingOrphans.isNotEmpty) {
        _scheduleCleanup();
      }
    });
  }

  Future<void> _processOrphans() async {
    final toClean = List<String>.from(_pendingOrphans);
    _pendingOrphans.clear();

    for (final orphanPath in toClean) {
      try {
        final file = File(orphanPath);
        if (await file.exists()) {
          await file.delete();
          debugPrint('Cleaned orphan: $orphanPath');
        }
      } catch (e) {
        debugPrint('Failed to clean orphan: $orphanPath - $e');
        _pendingOrphans.add(orphanPath);
      }
    }
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
