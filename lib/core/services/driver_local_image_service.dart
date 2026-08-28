import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/core/utils/image_compression_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  DocumentReference<Map<String, dynamic>>? _getImageDocRef(
    String driverId,
    String imageDocName,
  ) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || driverId.trim().isEmpty) return null;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('drivers')
        .doc(driverId)
        .collection('images')
        .doc(imageDocName);
  }

  Future<int?> _getLocalMetaTimestamp(String metaFilePath) async {
    try {
      final metaFile = File(metaFilePath);
      if (await metaFile.exists()) {
        final content = await metaFile.readAsString();
        return int.tryParse(content.trim());
      }
    } catch (_) {}
    return null;
  }

  Future<void> _setLocalMetaTimestamp(String metaFilePath, int timestamp) async {
    try {
      final metaFile = File(metaFilePath);
      await metaFile.writeAsString(timestamp.toString());
    } catch (_) {}
  }

  // ============================================================
  // GET ID CARD IMAGE
  // ============================================================

  Future<File?> getIdCardImage(String driverId) async {
    if (driverId.trim().isEmpty) return null;

    final dir = await _getAppDir();
    final localFile = File('$dir/id_card_$driverId.jpg');
    final metaFilePath = '$dir/id_card_$driverId.meta';

    try {
      final docRef = _getImageDocRef(driverId, 'idPhoto');
      if (docRef == null) {
        developer.log('getIdCardImage: user not authenticated for $driverId', name: 'DriverLocalImageService');
        return await localFile.exists() ? localFile : null;
      }

      developer.log('getIdCardImage: querying Firestore path ${docRef.path}', name: 'DriverLocalImageService');
      final snapshot = await docRef.get();

      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        final base64Str = data['base64'] as String?;
        final rawUpdatedAt = data['updatedAt'];
        final int firestoreTimestamp = rawUpdatedAt is Timestamp
            ? rawUpdatedAt.millisecondsSinceEpoch
            : (rawUpdatedAt is int ? rawUpdatedAt : 0);

        developer.log('getIdCardImage: Firestore doc exists, base64 length=${base64Str?.length ?? 0}, firestoreTs=$firestoreTimestamp', name: 'DriverLocalImageService');

        final localTimestamp = await _getLocalMetaTimestamp(metaFilePath);
        final localExists = await localFile.exists();

        // Use local cache only if it exists AND is at least as fresh as Firestore
        if (localExists &&
            localTimestamp != null &&
            localTimestamp >= firestoreTimestamp &&
            firestoreTimestamp > 0) {
          developer.log('getIdCardImage: using local cache for $driverId', name: 'DriverLocalImageService');
          return localFile;
        }

        // Download from Firestore into local cache
        if (base64Str != null && base64Str.isNotEmpty) {
          developer.log('getIdCardImage: downloading from Firestore to local cache for $driverId', name: 'DriverLocalImageService');
          final bytes = base64Decode(base64Str);
          await localFile.writeAsBytes(bytes, flush: true);
          await _setLocalMetaTimestamp(metaFilePath, firestoreTimestamp > 0 ? firestoreTimestamp : DateTime.now().millisecondsSinceEpoch);
          return localFile;
        }

        developer.log('getIdCardImage: Firestore doc exists but base64 is empty for $driverId', name: 'DriverLocalImageService');
      } else {
        developer.log('getIdCardImage: Firestore doc does NOT exist for $driverId — checking local for migration', name: 'DriverLocalImageService');
        if (await localFile.exists()) {
          final base64Str = await ImageCompressionHelper.compressAndEncodeBase64(localFile, initialMaxDimension: 1600);
          if (base64Str != null) {
            final now = DateTime.now().millisecondsSinceEpoch;
            await docRef.set({
              'base64': base64Str,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            await _setLocalMetaTimestamp(metaFilePath, now);
            developer.log('getIdCardImage: migrated local ID photo to Firestore for $driverId', name: 'DriverLocalImageService');
          }
          return localFile;
        }
        return null;
      }
    } catch (e, st) {
      developer.log(
        'getIdCardImage: ERROR for $driverId: $e',
        error: e,
        stackTrace: st,
        name: 'DriverLocalImageService',
      );
    }

    // Fallback to existing local file if network fails
    if (await localFile.exists()) {
      return localFile;
    }

    return null;
  }

  // ============================================================
  // GET LICENSE IMAGE
  // ============================================================

  Future<File?> getLicenseImage(String driverId) async {
    if (driverId.trim().isEmpty) return null;

    final dir = await _getAppDir();
    final localFile = File('$dir/license_$driverId.jpg');
    final metaFilePath = '$dir/license_$driverId.meta';

    try {
      final docRef = _getImageDocRef(driverId, 'licensePhoto');
      if (docRef == null) {
        developer.log('getLicenseImage: user not authenticated for $driverId', name: 'DriverLocalImageService');
        return await localFile.exists() ? localFile : null;
      }

      developer.log('getLicenseImage: querying Firestore path ${docRef.path}', name: 'DriverLocalImageService');
      final snapshot = await docRef.get();

      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        final base64Str = data['base64'] as String?;
        final rawUpdatedAt = data['updatedAt'];
        final int firestoreTimestamp = rawUpdatedAt is Timestamp
            ? rawUpdatedAt.millisecondsSinceEpoch
            : (rawUpdatedAt is int ? rawUpdatedAt : 0);

        developer.log('getLicenseImage: Firestore doc exists, base64 length=${base64Str?.length ?? 0}, firestoreTs=$firestoreTimestamp', name: 'DriverLocalImageService');

        final localTimestamp = await _getLocalMetaTimestamp(metaFilePath);
        final localExists = await localFile.exists();

        // Use local cache only if it exists AND is at least as fresh as Firestore
        if (localExists &&
            localTimestamp != null &&
            localTimestamp >= firestoreTimestamp &&
            firestoreTimestamp > 0) {
          developer.log('getLicenseImage: using local cache for $driverId', name: 'DriverLocalImageService');
          return localFile;
        }

        // Download from Firestore into local cache
        if (base64Str != null && base64Str.isNotEmpty) {
          developer.log('getLicenseImage: downloading from Firestore to local cache for $driverId', name: 'DriverLocalImageService');
          final bytes = base64Decode(base64Str);
          await localFile.writeAsBytes(bytes, flush: true);
          await _setLocalMetaTimestamp(metaFilePath, firestoreTimestamp > 0 ? firestoreTimestamp : DateTime.now().millisecondsSinceEpoch);
          return localFile;
        }

        developer.log('getLicenseImage: Firestore doc exists but base64 is empty for $driverId', name: 'DriverLocalImageService');
      } else {
        developer.log('getLicenseImage: Firestore doc does NOT exist for $driverId — checking local for migration', name: 'DriverLocalImageService');
        if (await localFile.exists()) {
          final base64Str = await ImageCompressionHelper.compressAndEncodeBase64(localFile, initialMaxDimension: 1600);
          if (base64Str != null) {
            final now = DateTime.now().millisecondsSinceEpoch;
            await docRef.set({
              'base64': base64Str,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            await _setLocalMetaTimestamp(metaFilePath, now);
            developer.log('getLicenseImage: migrated local license photo to Firestore for $driverId', name: 'DriverLocalImageService');
          }
          return localFile;
        }
        return null;
      }
    } catch (e, st) {
      developer.log(
        'getLicenseImage: ERROR for $driverId: $e',
        error: e,
        stackTrace: st,
        name: 'DriverLocalImageService',
      );
    }

    // Fallback to existing local file if network fails
    if (await localFile.exists()) {
      return localFile;
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
          'saveIdCardImage: Source file does not exist: ${sourceFile.path}',
          name: 'DriverLocalImageService',
        );
        return null;
      }

      final dir = await _getAppDir();
      final targetFile = File('$dir/id_card_$driverId.jpg');
      final metaFilePath = '$dir/id_card_$driverId.meta';

      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await sourceFile.copy(targetFile.path);

      // Compress and upload to Firestore
      developer.log('saveIdCardImage: compressing image for $driverId', name: 'DriverLocalImageService');
      final base64Str = await ImageCompressionHelper.compressAndEncodeBase64(
        targetFile,
        initialMaxDimension: 1600,
      );

      if (base64Str != null) {
        final docRef = _getImageDocRef(driverId, 'idPhoto');
        if (docRef != null) {
          developer.log('saveIdCardImage: uploading to Firestore path ${docRef.path} (base64 length=${base64Str.length})', name: 'DriverLocalImageService');
          await docRef.set({
            'base64': base64Str,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          developer.log('saveIdCardImage: upload SUCCESS for $driverId', name: 'DriverLocalImageService');
        } else {
          developer.log('saveIdCardImage: docRef is null (user not auth?) for $driverId', name: 'DriverLocalImageService');
        }
      } else {
        developer.log('saveIdCardImage: compression returned null for $driverId', name: 'DriverLocalImageService');
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      await _setLocalMetaTimestamp(metaFilePath, now);

      return targetFile;
    } catch (e, st) {
      developer.log(
        'saveIdCardImage: ERROR for $driverId: $e',
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
          'saveLicenseImage: Source file does not exist: ${sourceFile.path}',
          name: 'DriverLocalImageService',
        );
        return null;
      }

      final dir = await _getAppDir();
      final targetFile = File('$dir/license_$driverId.jpg');
      final metaFilePath = '$dir/license_$driverId.meta';

      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await sourceFile.copy(targetFile.path);

      // Compress and upload to Firestore
      developer.log('saveLicenseImage: compressing image for $driverId', name: 'DriverLocalImageService');
      final base64Str = await ImageCompressionHelper.compressAndEncodeBase64(
        targetFile,
        initialMaxDimension: 1600,
      );

      if (base64Str != null) {
        final docRef = _getImageDocRef(driverId, 'licensePhoto');
        if (docRef != null) {
          developer.log('saveLicenseImage: uploading to Firestore path ${docRef.path} (base64 length=${base64Str.length})', name: 'DriverLocalImageService');
          await docRef.set({
            'base64': base64Str,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          developer.log('saveLicenseImage: upload SUCCESS for $driverId', name: 'DriverLocalImageService');
        } else {
          developer.log('saveLicenseImage: docRef is null (user not auth?) for $driverId', name: 'DriverLocalImageService');
        }
      } else {
        developer.log('saveLicenseImage: compression returned null for $driverId', name: 'DriverLocalImageService');
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      await _setLocalMetaTimestamp(metaFilePath, now);

      return targetFile;
    } catch (e, st) {
      developer.log(
        'saveLicenseImage: ERROR for $driverId: $e',
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
      final idCardMetaFile = File('$dir/id_card_$driverId.meta');
      final licenseMetaFile = File('$dir/license_$driverId.meta');

      if (await idCardFile.exists()) await idCardFile.delete();
      if (await licenseFile.exists()) await licenseFile.delete();
      if (await idCardMetaFile.exists()) await idCardMetaFile.delete();
      if (await licenseMetaFile.exists()) await licenseMetaFile.delete();

      // Delete from Firestore
      final idPhotoRef = _getImageDocRef(driverId, 'idPhoto');
      final licensePhotoRef = _getImageDocRef(driverId, 'licensePhoto');

      if (idPhotoRef != null) await idPhotoRef.delete();
      if (licensePhotoRef != null) await licensePhotoRef.delete();

      developer.log('deleteDriverImages: deleted all images for $driverId', name: 'DriverLocalImageService');
    } catch (e, st) {
      developer.log(
        'deleteDriverImages: ERROR for $driverId: $e',
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
    String
>((ref, driverId) async {
  final idCardImage = await DriverLocalImageService.instance.getIdCardImage(driverId);
  final licenseImage = await DriverLocalImageService.instance.getLicenseImage(driverId);

  return (
    idCardImage: idCardImage,
    licenseImage: licenseImage,
  );
});
