import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/core/utils/image_compression_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  DocumentReference<Map<String, dynamic>>? _getImageDocRef(
    String busId,
    String imageDocName,
  ) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || busId.trim().isEmpty) return null;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('buses')
        .doc(busId)
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
  // GET BUS IMAGE
  // ============================================================

  Future<File?> getBusImage(String busId) async {
    if (busId.trim().isEmpty) return null;

    final dir = await _getAppDir();
    final localFile = File('$dir/bus_$busId.jpg');
    final metaFilePath = '$dir/bus_$busId.meta';

    try {
      final docRef = _getImageDocRef(busId, 'busPhoto');
      if (docRef == null) {
        developer.log('getBusImage: user not authenticated for $busId', name: 'BusLocalImageService');
        return await localFile.exists() ? localFile : null;
      }

      developer.log('getBusImage: querying Firestore path ${docRef.path}', name: 'BusLocalImageService');
      final snapshot = await docRef.get();

      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        final base64Str = data['base64'] as String?;
        final rawUpdatedAt = data['updatedAt'];
        final int firestoreTimestamp = rawUpdatedAt is Timestamp
            ? rawUpdatedAt.millisecondsSinceEpoch
            : (rawUpdatedAt is int ? rawUpdatedAt : 0);

        developer.log('getBusImage: Firestore doc exists, base64 length=${base64Str?.length ?? 0}, firestoreTs=$firestoreTimestamp', name: 'BusLocalImageService');

        final localTimestamp = await _getLocalMetaTimestamp(metaFilePath);
        final localExists = await localFile.exists();

        // Use local cache only if it exists AND is at least as fresh as Firestore
        if (localExists &&
            localTimestamp != null &&
            localTimestamp >= firestoreTimestamp &&
            firestoreTimestamp > 0) {
          developer.log('getBusImage: using local cache for $busId (localTs=$localTimestamp >= firestoreTs=$firestoreTimestamp)', name: 'BusLocalImageService');
          return localFile;
        }

        // Download from Firestore into local cache
        if (base64Str != null && base64Str.isNotEmpty) {
          developer.log('getBusImage: downloading from Firestore to local cache for $busId', name: 'BusLocalImageService');
          final bytes = base64Decode(base64Str);
          await localFile.writeAsBytes(bytes, flush: true);
          await _setLocalMetaTimestamp(metaFilePath, firestoreTimestamp > 0 ? firestoreTimestamp : DateTime.now().millisecondsSinceEpoch);
          return localFile;
        }

        developer.log('getBusImage: Firestore doc exists but base64 is empty for $busId', name: 'BusLocalImageService');
      } else {
        developer.log('getBusImage: Firestore doc does NOT exist for $busId — checking local for migration', name: 'BusLocalImageService');
        // If Firestore document does not exist but local file exists → migrate to Firestore
        if (await localFile.exists()) {
          final base64Str = await ImageCompressionHelper.compressAndEncodeBase64(localFile, initialMaxDimension: 1400);
          if (base64Str != null) {
            final now = DateTime.now().millisecondsSinceEpoch;
            await docRef.set({
              'base64': base64Str,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            await _setLocalMetaTimestamp(metaFilePath, now);
            developer.log('getBusImage: migrated local bus photo to Firestore for $busId', name: 'BusLocalImageService');
          }
          return localFile;
        }
        return null;
      }
    } catch (e, st) {
      developer.log(
        'getBusImage: ERROR for $busId: $e',
        error: e,
        stackTrace: st,
        name: 'BusLocalImageService',
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

  Future<File?> getLicenseImage(String busId) async {
    if (busId.trim().isEmpty) return null;

    final dir = await _getAppDir();
    final localFile = File('$dir/license_$busId.jpg');
    final metaFilePath = '$dir/license_$busId.meta';

    try {
      final docRef = _getImageDocRef(busId, 'licensePhoto');
      if (docRef == null) {
        developer.log('getLicenseImage: user not authenticated for $busId', name: 'BusLocalImageService');
        return await localFile.exists() ? localFile : null;
      }

      developer.log('getLicenseImage: querying Firestore path ${docRef.path}', name: 'BusLocalImageService');
      final snapshot = await docRef.get();

      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        final base64Str = data['base64'] as String?;
        final rawUpdatedAt = data['updatedAt'];
        final int firestoreTimestamp = rawUpdatedAt is Timestamp
            ? rawUpdatedAt.millisecondsSinceEpoch
            : (rawUpdatedAt is int ? rawUpdatedAt : 0);

        developer.log('getLicenseImage: Firestore doc exists, base64 length=${base64Str?.length ?? 0}, firestoreTs=$firestoreTimestamp', name: 'BusLocalImageService');

        final localTimestamp = await _getLocalMetaTimestamp(metaFilePath);
        final localExists = await localFile.exists();

        // Use local cache only if it exists AND is at least as fresh as Firestore
        if (localExists &&
            localTimestamp != null &&
            localTimestamp >= firestoreTimestamp &&
            firestoreTimestamp > 0) {
          developer.log('getLicenseImage: using local cache for $busId (localTs=$localTimestamp >= firestoreTs=$firestoreTimestamp)', name: 'BusLocalImageService');
          return localFile;
        }

        // Download from Firestore into local cache
        if (base64Str != null && base64Str.isNotEmpty) {
          developer.log('getLicenseImage: downloading from Firestore to local cache for $busId', name: 'BusLocalImageService');
          final bytes = base64Decode(base64Str);
          await localFile.writeAsBytes(bytes, flush: true);
          await _setLocalMetaTimestamp(metaFilePath, firestoreTimestamp > 0 ? firestoreTimestamp : DateTime.now().millisecondsSinceEpoch);
          return localFile;
        }

        developer.log('getLicenseImage: Firestore doc exists but base64 is empty for $busId', name: 'BusLocalImageService');
      } else {
        developer.log('getLicenseImage: Firestore doc does NOT exist for $busId — checking local for migration', name: 'BusLocalImageService');
        // If Firestore document does not exist but local file exists → migrate to Firestore
        if (await localFile.exists()) {
          final base64Str = await ImageCompressionHelper.compressAndEncodeBase64(localFile, initialMaxDimension: 1600);
          if (base64Str != null) {
            final now = DateTime.now().millisecondsSinceEpoch;
            await docRef.set({
              'base64': base64Str,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            await _setLocalMetaTimestamp(metaFilePath, now);
            developer.log('getLicenseImage: migrated local license photo to Firestore for $busId', name: 'BusLocalImageService');
          }
          return localFile;
        }
        return null;
      }
    } catch (e, st) {
      developer.log(
        'getLicenseImage: ERROR for $busId: $e',
        error: e,
        stackTrace: st,
        name: 'BusLocalImageService',
      );
    }

    // Fallback to existing local file if network fails
    if (await localFile.exists()) {
      return localFile;
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
    if (busId.trim().isEmpty) return null;

    try {
      if (!await sourceFile.exists()) {
        developer.log(
          'saveBusImage: Source file does not exist: ${sourceFile.path}',
          name: 'BusLocalImageService',
        );
        return null;
      }

      final dir = await _getAppDir();
      final targetFile = File('$dir/bus_$busId.jpg');
      final metaFilePath = '$dir/bus_$busId.meta';

      // Remove existing local file if present and copy new source
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await sourceFile.copy(targetFile.path);

      // Compress and upload to Firestore FIRST (before writing meta timestamp)
      developer.log('saveBusImage: compressing image for $busId', name: 'BusLocalImageService');
      final base64Str = await ImageCompressionHelper.compressAndEncodeBase64(
        targetFile,
        initialMaxDimension: 1400,
      );

      if (base64Str != null) {
        final docRef = _getImageDocRef(busId, 'busPhoto');
        if (docRef != null) {
          developer.log('saveBusImage: uploading to Firestore path ${docRef.path} (base64 length=${base64Str.length})', name: 'BusLocalImageService');
          await docRef.set({
            'base64': base64Str,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          developer.log('saveBusImage: upload SUCCESS for $busId', name: 'BusLocalImageService');
        } else {
          developer.log('saveBusImage: docRef is null (user not auth?) for $busId', name: 'BusLocalImageService');
        }
      } else {
        developer.log('saveBusImage: compression returned null (image too large?) for $busId', name: 'BusLocalImageService');
      }

      // Write meta timestamp after upload attempt
      final now = DateTime.now().millisecondsSinceEpoch;
      await _setLocalMetaTimestamp(metaFilePath, now);

      return targetFile;
    } catch (e, st) {
      developer.log(
        'saveBusImage: ERROR for $busId: $e',
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
    if (busId.trim().isEmpty) return null;

    try {
      if (!await sourceFile.exists()) {
        developer.log(
          'saveLicenseImage: Source file does not exist: ${sourceFile.path}',
          name: 'BusLocalImageService',
        );
        return null;
      }

      final dir = await _getAppDir();
      final targetFile = File('$dir/license_$busId.jpg');
      final metaFilePath = '$dir/license_$busId.meta';

      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await sourceFile.copy(targetFile.path);

      // Compress and upload to Firestore
      developer.log('saveLicenseImage: compressing image for $busId', name: 'BusLocalImageService');
      final base64Str = await ImageCompressionHelper.compressAndEncodeBase64(
        targetFile,
        initialMaxDimension: 1600,
      );

      if (base64Str != null) {
        final docRef = _getImageDocRef(busId, 'licensePhoto');
        if (docRef != null) {
          developer.log('saveLicenseImage: uploading to Firestore path ${docRef.path} (base64 length=${base64Str.length})', name: 'BusLocalImageService');
          await docRef.set({
            'base64': base64Str,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          developer.log('saveLicenseImage: upload SUCCESS for $busId', name: 'BusLocalImageService');
        } else {
          developer.log('saveLicenseImage: docRef is null (user not auth?) for $busId', name: 'BusLocalImageService');
        }
      } else {
        developer.log('saveLicenseImage: compression returned null (image too large?) for $busId', name: 'BusLocalImageService');
      }

      // Write meta timestamp after upload attempt
      final now = DateTime.now().millisecondsSinceEpoch;
      await _setLocalMetaTimestamp(metaFilePath, now);

      return targetFile;
    } catch (e, st) {
      developer.log(
        'saveLicenseImage: ERROR for $busId: $e',
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

      final busFile = File('$dir/bus_$busId.jpg');
      final licenseFile = File('$dir/license_$busId.jpg');
      final busMetaFile = File('$dir/bus_$busId.meta');
      final licenseMetaFile = File('$dir/license_$busId.meta');

      if (await busFile.exists()) await busFile.delete();
      if (await licenseFile.exists()) await licenseFile.delete();
      if (await busMetaFile.exists()) await busMetaFile.delete();
      if (await licenseMetaFile.exists()) await licenseMetaFile.delete();

      // Delete from Firestore
      final busPhotoRef = _getImageDocRef(busId, 'busPhoto');
      final licensePhotoRef = _getImageDocRef(busId, 'licensePhoto');

      if (busPhotoRef != null) await busPhotoRef.delete();
      if (licensePhotoRef != null) await licensePhotoRef.delete();

      developer.log('deleteBusImages: deleted all images for $busId', name: 'BusLocalImageService');
    } catch (e, st) {
      developer.log(
        'deleteBusImages: ERROR for $busId: $e',
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

final busLocalImagesProvider = FutureProvider.family<
    ({File? busImage, File? licenseImage}),
    String
>((ref, busId) async {
  final busImage = await BusLocalImageService.instance.getBusImage(busId);
  final licenseImage = await BusLocalImageService.instance.getLicenseImage(busId);

  return (
    busImage: busImage,
    licenseImage: licenseImage,
  );
});