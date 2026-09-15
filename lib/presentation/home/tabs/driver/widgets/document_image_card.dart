import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:flutter/material.dart';

class DocumentImageCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final File? imageFile;
  final String? imageUrl;
  final VoidCallback onTapUpload;

  const DocumentImageCard({
    super.key,
    required this.label,
    required this.icon,
    this.imageFile,
    this.imageUrl,
    required this.onTapUpload,
  });

  bool get _hasImage =>
      imageFile != null || (imageUrl != null && imageUrl!.isNotEmpty);

  void _showImageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.all(16.w),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: imageFile != null
                    ? Image.file(
                  imageFile!,
                  fit: BoxFit.contain,
                )
                    : CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.contain,
                  placeholder: (_, _) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (_, _, _) => const Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8.h,
              left: 8.w,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _hasImage ? () => _showImageDialog(context) : onTapUpload,
      child: Container(
        height: 130.h,
        decoration: BoxDecoration(
          color: AppColors.backgroundGray,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: _hasImage
                ? AppColors.primary.withValues(alpha: 0.25)
                : const Color(0xFFE0E0E0),
          ),
        ),
        child: _hasImage
            ? ClipRRect(
          borderRadius: BorderRadius.circular(13.r),
          child: Stack(
            fit: StackFit.expand,
            children: [
              imageFile != null
                  ? Image.file(
                imageFile!,
                fit: BoxFit.cover,
              )
                  : CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, _) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (_, _, _) => const Icon(
                  Icons.broken_image,
                  color: Colors.grey,
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 6.h,
                    horizontal: 8.w,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.65),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomText(
                        title: label,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        fontColor: Colors.white,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 6.h,
                left: 6.w,
                child: GestureDetector(
                  onTap: onTapUpload,
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 14.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 34.sp,
              color: const Color(0xFFBFC3CB),
            ),
            SizedBox(height: 8.h),
            CustomText(
              title: label,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              fontColor: const Color(0xFF777B85),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            CustomText(
              title: 'اضغط للرفع',
              fontSize: 11.sp,
              fontColor: AppColors.primary,
              fontWeight: FontWeight.w600,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
