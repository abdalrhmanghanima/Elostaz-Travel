import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

class DriverLocalImageService {
  DriverLocalImageService._internal();

  static final DriverLocalImageService instance =
      DriverLocalImageService._internal();

  Future<String> _getAppDir() async {
    final dir = await getApplicationDocumentsDirectory();

    final imagesDir = Directory(
      '${dir.path}/driver_local_images',
    );

    if (!await imagesDir.exists()) {
      await imagesDir.create(
        recursive: true,
      );
    }

    return imagesDir.path;
  }

  // ============================================================
  // GET ID CARD IMAGE
  // ============================================================
  Future<File?> getIdCardImage(String driverId) async {
    if (driverId.trim().isEmpty) return null;

    try {
      final dir = await _getAppDir();
      final file = File('$dir/id_card_$driverId.jpg');

      if (await file.exists()) {
        return file;
      }
    } catch (e, st) {
      developer.log(
        'Error getting local driver id card image: $e',
        error: e,
        stackTrace: st,
        name: 'DriverLocalImageService',
      );
    }

    return null;
  }

  // ============================================================
  // GET LICENSE IMAGE
  // ============================================================
  Future<File?> getLicenseImage(String driverId) async {
    if (driverId.trim().isEmpty) return null;

    try {
      final dir = await _getAppDir();
      final file = File('$dir/license_$driverId.jpg');

      if (await file.exists()) {
        return file;
      }
    } catch (e, st) {
      developer.log(
        'Error getting local driver license image: $e',
        error: e,
        stackTrace: st,
        name: 'DriverLocalImageService',
      );
    }

    return null;
  }

  // ============================================================
  // SAVE ID CARD IMAGE
  // ============================================================
  Future<File?> saveIdCardImage(
    String driverId,
    File sourceFile,
  ) async {
    if (driverId.trim().isEmpty) return null;

    try {
      if (!await sourceFile.exists()) {
        developer.log(
          'Source id card image does not exist: ${sourceFile.path}',
          name: 'DriverLocalImageService',
        );
        return null;
      }

      final dir = await _getAppDir();
      final targetFile = File('$dir/id_card_$driverId.jpg');

      if (await targetFile.exists()) {
        await targetFile.delete();
      }

      await sourceFile.copy(targetFile.path);

      if (!await targetFile.exists()) {
        developer.log(
          'Driver ID card image copy failed',
          name: 'DriverLocalImageService',
        );
        return null;
      }

      developer.log(
        'Saved local driver id card image for $driverId to ${targetFile.path}',
        name: 'DriverLocalImageService',
      );

      return targetFile;
    } catch (e, st) {
      developer.log(
        'Error saving local driver id card image: $e',
        error: e,
        stackTrace: st,
        name: 'DriverLocalImageService',
      );
      return null;
    }
  }

  // ============================================================
  // SAVE LICENSE IMAGE
  // ============================================================
  Future<File?> saveLicenseImage(
    String driverId,
    File sourceFile,
  ) async {
    if (driverId.trim().isEmpty) return null;

    try {
      if (!await sourceFile.exists()) {
        developer.log(
          'Source driver license image does not exist: ${sourceFile.path}',
          name: 'DriverLocalImageService',
        );
        return null;
      }

      final dir = await _getAppDir();
      final targetFile = File('$dir/license_$driverId.jpg');

      if (await targetFile.exists()) {
        await targetFile.delete();
      }

      await sourceFile.copy(targetFile.path);

      if (!await targetFile.exists()) {
        developer.log(
          'Driver license image copy failed',
          name: 'DriverLocalImageService',
        );
        return null;
      }

      developer.log(
        'Saved local driver license image for $driverId to ${targetFile.path}',
        name: 'DriverLocalImageService',
      );

      return targetFile;
    } catch (e, st) {
      developer.log(
        'Error saving local driver license image: $e',
        error: e,
        stackTrace: st,
        name: 'DriverLocalImageService',
      );
      return null;
    }
  }

  // ============================================================
  // DELETE ALL DRIVER IMAGES
  // ============================================================
  Future<void> deleteDriverImages(String driverId) async {
    if (driverId.trim().isEmpty) return;

    try {
      final dir = await _getAppDir();
      final idCardFile = File('$dir/id_card_$driverId.jpg');
      final licenseFile = File('$dir/license_$driverId.jpg');

      if (await idCardFile.exists()) {
        await idCardFile.delete();
      }
      if (await licenseFile.exists()) {
        await licenseFile.delete();
      }
    } catch (e, st) {
      developer.log(
        'Error deleting local driver images for $driverId: $e',
        error: e,
        stackTrace: st,
        name: 'DriverLocalImageService',
      );
    }
  }
}

// ============================================================
// PROVIDER
// ============================================================
final driverLocalImagesProvider = FutureProvider.family<
    ({File? idCardImage, File? licenseImage}),
    String>(
  (ref, driverId) async {
    final idCardImage =
        await DriverLocalImageService.instance.getIdCardImage(driverId);
    final licenseImage =
        await DriverLocalImageService.instance.getLicenseImage(driverId);

    return (
      idCardImage: idCardImage,
      licenseImage: licenseImage,
    );
  },
);
