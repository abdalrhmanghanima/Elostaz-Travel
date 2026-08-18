import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

class BusLocalImageService {
  BusLocalImageService._internal();

  static final BusLocalImageService instance =
  BusLocalImageService._internal();

  Future<String> _getAppDir() async {
    final dir = await getApplicationDocumentsDirectory();

    final imagesDir = Directory(
      '${dir.path}/bus_local_images',
    );

    if (!await imagesDir.exists()) {
      await imagesDir.create(
        recursive: true,
      );
    }

    return imagesDir.path;
  }

  // ============================================================
  // GET BUS IMAGE
  // ============================================================

  Future<File?> getBusImage(String busId) async {
    if (busId.trim().isEmpty) return null;

    try {
      final dir = await _getAppDir();

      final file = File(
        '$dir/bus_$busId.jpg',
      );

      if (await file.exists()) {
        return file;
      }
    } catch (e, st) {
      developer.log(
        'Error getting local bus image: $e',
        error: e,
        stackTrace: st,
        name: 'BusLocalImageService',
      );
    }

    return null;
  }

  // ============================================================
  // GET LICENSE IMAGE
  // ============================================================

  Future<File?> getLicenseImage(String busId) async {
    if (busId.trim().isEmpty) return null;

    try {
      final dir = await _getAppDir();

      final file = File(
        '$dir/license_$busId.jpg',
      );

      if (await file.exists()) {
        return file;
      }
    } catch (e, st) {
      developer.log(
        'Error getting local license image: $e',
        error: e,
        stackTrace: st,
        name: 'BusLocalImageService',
      );
    }

    return null;
  }

  // ============================================================
  // SAVE BUS IMAGE
  // ============================================================

  Future<File?> saveBusImage(
      String busId,
      File sourceFile,
      ) async {
    if (busId.trim().isEmpty) {
      return null;
    }

    try {
      // تأكد إن الملف المصدر لسه موجود
      if (!await sourceFile.exists()) {
        developer.log(
          'Source bus image does not exist: ${sourceFile.path}',
          name: 'BusLocalImageService',
        );

        return null;
      }

      final dir = await _getAppDir();

      final targetFile = File(
        '$dir/bus_$busId.jpg',
      );

      // احذف الصورة القديمة
      if (await targetFile.exists()) {
        await targetFile.delete();
      }

      // انسخ الصورة الجديدة
      await sourceFile.copy(
        targetFile.path,
      );

      // تأكد إن النسخة اتعملت فعلًا
      if (!await targetFile.exists()) {
        developer.log(
          'Bus image copy failed',
          name: 'BusLocalImageService',
        );

        return null;
      }

      developer.log(
        'Saved local bus image for $busId to ${targetFile.path}',
        name: 'BusLocalImageService',
      );

      return targetFile;
    } catch (e, st) {
      developer.log(
        'Error saving local bus image: $e',
        error: e,
        stackTrace: st,
        name: 'BusLocalImageService',
      );

      return null;
    }
  }

  // ============================================================
  // SAVE LICENSE IMAGE
  // ============================================================

  Future<File?> saveLicenseImage(
      String busId,
      File sourceFile,
      ) async {
    if (busId.trim().isEmpty) {
      return null;
    }

    try {
      // تأكد إن الملف المصدر لسه موجود
      if (!await sourceFile.exists()) {
        developer.log(
          'Source license image does not exist: ${sourceFile.path}',
          name: 'BusLocalImageService',
        );

        return null;
      }

      final dir = await _getAppDir();

      final targetFile = File(
        '$dir/license_$busId.jpg',
      );

      // احذف الصورة القديمة
      if (await targetFile.exists()) {
        await targetFile.delete();
      }

      // انسخ الصورة الجديدة
      await sourceFile.copy(
        targetFile.path,
      );

      // تأكد إن النسخة اتعملت
      if (!await targetFile.exists()) {
        developer.log(
          'License image copy failed',
          name: 'BusLocalImageService',
        );

        return null;
      }

      developer.log(
        'Saved local license image for $busId to ${targetFile.path}',
        name: 'BusLocalImageService',
      );

      return targetFile;
    } catch (e, st) {
      developer.log(
        'Error saving local license image: $e',
        error: e,
        stackTrace: st,
        name: 'BusLocalImageService',
      );

      return null;
    }
  }

  // ============================================================
  // DELETE ALL BUS IMAGES
  // ============================================================

  Future<void> deleteBusImages(String busId) async {
    if (busId.trim().isEmpty) return;

    try {
      final dir = await _getAppDir();

      final busFile = File(
        '$dir/bus_$busId.jpg',
      );

      final licenseFile = File(
        '$dir/license_$busId.jpg',
      );

      if (await busFile.exists()) {
        await busFile.delete();

        developer.log(
          'Deleted local bus image for $busId',
          name: 'BusLocalImageService',
        );
      }

      if (await licenseFile.exists()) {
        await licenseFile.delete();

        developer.log(
          'Deleted local license image for $busId',
          name: 'BusLocalImageService',
        );
      }
    } catch (e, st) {
      developer.log(
        'Error deleting local bus images for $busId: $e',
        error: e,
        stackTrace: st,
        name: 'BusLocalImageService',
      );
    }
  }
}

// ============================================================
// PROVIDER
// ============================================================

final busLocalImagesProvider =
FutureProvider.family<
    ({File? busImage, File? licenseImage}),
    String
>(
      (ref, busId) async {
    final busImage =
    await BusLocalImageService.instance.getBusImage(
      busId,
    );

    final licenseImage =
    await BusLocalImageService.instance.getLicenseImage(
      busId,
    );

    return (
    busImage: busImage,
    licenseImage: licenseImage,
    );
  },
);