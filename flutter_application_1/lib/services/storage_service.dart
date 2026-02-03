import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:extended_image/extended_image.dart';
// image_cropper removed temporarily because it caused Android embedding/compile issues.
// When re-adding the dependency, restore the import above and the cropping logic below.
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
// import 'dart:typed_data';
// Duplicate imports removed above

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();

  // 🆕 Pick and crop profile picture
  static Future<File?> pickAndCropProfilePicture(BuildContext context) async {
    try {
      // Pick image
      debugPrint('📸 Opening image picker...');
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        debugPrint('❌ User cancelled image selection from gallery');
        return null;
      }

      debugPrint('✅ Image picked: ${pickedFile.path}');

      // Show cropping UI
      debugPrint('✂️ Opening crop dialog...');
      final cropped = await _showCropper(context, File(pickedFile.path));

      if (cropped != null) {
        debugPrint('✅ Image cropped successfully: ${cropped.path}');
      } else {
        debugPrint('❌ User cancelled cropping dialog');
      }

      return cropped;
    } catch (e) {
      debugPrint('❌ Error picking/cropping image: $e');
      return null;
    }
  }

  // 🆕 Pick and crop company logo (same as profile, but different UI text)
  static Future<File?> pickAndCropCompanyLogo(BuildContext context) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      // Show cropping UI
      final cropped = await _showCropper(context, File(pickedFile.path));
      return cropped;
    } catch (e) {
      debugPrint('Error picking/cropping logo: $e');
      return null;
    }
  }

  // Helper: show cropping dialog and return cropped file
  static Future<File?> _showCropper(
      BuildContext context, File imageFile) async {
    File? result;
    await showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal
      builder: (ctx) {
        GlobalKey<ExtendedImageEditorState> editorKey =
            GlobalKey<ExtendedImageEditorState>();
        return AlertDialog(
          title: const Text(
            'Crop Your Photo',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pinch to zoom, drag to move the image',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 300,
                height: 300,
                child: ExtendedImage.file(
                  imageFile,
                  fit: BoxFit.contain,
                  mode: ExtendedImageMode.editor,
                  extendedImageEditorKey: editorKey,
                  cacheRawData: true, // Required for accessing rawImageData
                  initEditorConfigHandler: (state) => EditorConfig(
                    maxScale: 8.0,
                    cropRectPadding: const EdgeInsets.all(20.0),
                    hitTestSize: 20.0,
                    cropAspectRatio: 1.0, // Square crop for profile picture
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                debugPrint('❌ User tapped Cancel in crop dialog');
                Navigator.of(ctx).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                debugPrint('✂️ User tapped Crop button, processing...');
                final editor = editorKey.currentState;
                if (editor != null) {
                  final cropRect = editor.getCropRect();
                  final rawImage = editor.rawImageData;
                  debugPrint('📐 Crop rect: $cropRect');
                  debugPrint(
                      '📦 Raw image data size: ${rawImage.length} bytes');

                  // If the raw image data is empty, fall back to the original file
                  if (rawImage.isEmpty) {
                    debugPrint('⚠️ Raw image empty, using original file');
                    result = imageFile;
                    Navigator.of(ctx).pop();
                    return;
                  }

                  try {
                    // Decode the raw image bytes and crop using dart:ui
                    final codec = await ui.instantiateImageCodec(rawImage);
                    final frame = await codec.getNextFrame();
                    final originalImage = frame.image;
                    debugPrint(
                        '🖼️ Original image size: ${originalImage.width}x${originalImage.height}');

                    // Use the full image bounds if cropRect is null
                    final Rect effectiveCropRect = cropRect ??
                        Rect.fromLTWH(0, 0, originalImage.width.toDouble(),
                            originalImage.height.toDouble());
                    final srcRect = Rect.fromLTWH(
                        effectiveCropRect.left,
                        effectiveCropRect.top,
                        effectiveCropRect.width,
                        effectiveCropRect.height);
                    final recorder = ui.PictureRecorder();
                    final canvas = Canvas(recorder);
                    final paint = Paint();
                    final dstRect = Rect.fromLTWH(0, 0, effectiveCropRect.width,
                        effectiveCropRect.height);
                    canvas.drawImageRect(
                        originalImage, srcRect, dstRect, paint);
                    final picture = recorder.endRecording();
                    final croppedImage = await picture.toImage(
                        effectiveCropRect.width.toInt(),
                        effectiveCropRect.height.toInt());
                    final byteData = await croppedImage.toByteData(
                        format: ui.ImageByteFormat.png);
                    final cropData = byteData!.buffer.asUint8List();
                    final tempPath = imageFile.parent.path;
                    final croppedFile = File(
                        '$tempPath/cropped_${DateTime.now().millisecondsSinceEpoch}.png');
                    await croppedFile.writeAsBytes(cropData);
                    debugPrint('✅ Cropped file saved: ${croppedFile.path}');
                    debugPrint(
                        '✅ Cropped file size: ${await croppedFile.length()} bytes');
                    result = croppedFile;
                  } catch (e) {
                    debugPrint('❌ Error during crop processing: $e');
                    // Fall back to original if crop fails
                    result = imageFile;
                  }
                }
                Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('✓ Crop & Use'),
            ),
          ],
        );
      },
    );
    return result;
  }

  // Upload profile picture
  static Future<String?> uploadProfilePicture(String userId, File file) async {
    try {
      final ref = _storage
          .ref()
          .child('profile_pictures')
          .child(userId)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      return null;
    }
  }

  static Future<String?> uploadCompanyLogo(String employerId, File file) async {
    try {
      final ref = _storage
          .ref()
          .child('company_logos')
          .child(employerId)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading company logo: $e');
      return null;
    }
  }

  static Future<String?> uploadDocument(
    String userId,
    File file,
    String fileName,
  ) async {
    try {
      final ref = _storage
          .ref()
          .child('documents')
          .child(userId)
          .child('${DateTime.now().millisecondsSinceEpoch}_$fileName');

      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading document: $e');
      return null;
    }
  }

  static Future<bool> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }
}
