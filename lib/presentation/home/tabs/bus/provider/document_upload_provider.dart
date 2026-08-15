import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final imagePickerProvider = Provider<ImagePicker>((ref) {
  return ImagePicker();
});

final documentImageProvider = StateNotifierProvider.family<
    DocumentImageNotifier,
    XFile?,
    ({String busId, String documentType})
>(
      (ref, params) {
    return DocumentImageNotifier(
      ref.read(imagePickerProvider),
    );
  },
);

class DocumentImageNotifier extends StateNotifier<XFile?> {
  final ImagePicker _picker;

  DocumentImageNotifier(this._picker) : super(null);

  Future<void> pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (image == null) return;

    state = image;
  }

  void clearImage() {
    state = null;
  }
}