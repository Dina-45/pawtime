import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

enum MediaIssue { denied, permanentlyDenied, unknown }

class MediaException implements Exception {
  final MediaIssue issue;
  final String message;
  const MediaException(this.issue, this.message);

  @override
  String toString() => message;
}

class MediaService {
  static final _picker = ImagePicker();

  /// Returns the picked photo, or null if the user cancelled.
  static Future<File?> pickPhoto(ImageSource source) async {
    // Runtime camera permission on Android via permission_handler.
    // On iOS the system dialog is shown by image_picker itself, using the
    // NSCameraUsageDescription text from Info.plist.
    if (source == ImageSource.camera && Platform.isAndroid) {
      final status = await Permission.camera.request();
      if (status.isPermanentlyDenied) {
        throw const MediaException(
          MediaIssue.permanentlyDenied,
          'Camera access is blocked ("Don\'t ask again"). Allow it in the app settings.',
        );
      }
      if (!status.isGranted) {
        throw const MediaException(
          MediaIssue.denied,
          'Camera permission denied.',
        );
      }
    }

    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 80, // JPEG compression
        maxWidth: 1080, // resize big photos
      );
      return file == null ? null : File(file.path);
    } on PlatformException catch (e) {
      if (e.code.contains('access_denied')) {
        throw const MediaException(
          MediaIssue.permanentlyDenied,
          'Access is denied. Allow camera / photos in the app settings.',
        );
      }
      throw MediaException(
        MediaIssue.unknown,
        e.message ?? 'Could not open the camera.',
      );
    }
  }

  static Future<bool> openSettings() => openAppSettings();
}
