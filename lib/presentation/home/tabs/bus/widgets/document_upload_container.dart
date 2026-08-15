import 'package:dotted_border/dotted_border.dart';
import 'package:elostaz_travel/presentation/components/custom_svg/custom_svg_icon.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/provider/document_upload_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
class DocumentUploadContainer extends ConsumerWidget {
  final String icon;
  final String title;
  final String busId;
  final String documentType;

  const DocumentUploadContainer({
    super.key,
    required this.icon,
    required this.title,
    required this.documentType, required this.busId,
  });

  Future<void> _showImageSourceSheet(
      BuildContext context,
      WidgetRef ref,
      ) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'اختر طريقة رفع الصورة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF172B4D),
                  ),
                ),

                const SizedBox(height: 20),

                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF172B4D),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                    ),
                  ),
                  title: const Text('الكاميرا'),
                  onTap: () {
                    Navigator.pop(context);

                    ref
                        .read(
                      documentImageProvider(
                        (
                        busId: busId,
                        documentType: documentType,
                        ),
                      ).notifier,
                    )
                        .pickImage(ImageSource.camera);
                  },
                ),

                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF172B4D),
                    child: Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white,
                    ),
                  ),
                  title: const Text('المعرض'),
                  onTap: () {
                    Navigator.pop(context);

                    ref
                        .read(
                      documentImageProvider(
                        (
                        busId: busId,
                        documentType: documentType,
                        ),
                      ).notifier,
                    )
                        .pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedImage = ref.watch(
      documentImageProvider(
        (
        busId: busId,
        documentType: documentType,
        ),
      ),
    );

    return GestureDetector(
      onTap: () => _showImageSourceSheet(context, ref),
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          color: const Color(0xFFC7C8CE),
          strokeWidth: 2,
          dashPattern: const [7, 5],
          radius: const Radius.circular(18),
          padding: EdgeInsets.zero,
        ),
        child: Container(
          width: double.infinity,
          height: 225,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F7F9),
            borderRadius: BorderRadius.circular(18),
          ),
          child: selectedImage != null
              ? Image.file(
            File(selectedImage.path),
            fit: BoxFit.cover,
          )
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFF172B4D),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: CustomSvgIcon(
                    assetName: icon,
                    width: 32,
                    height: 32,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF172B4D),
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'اضغط للرفع أو اسحب الملف هنا',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF55555A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}