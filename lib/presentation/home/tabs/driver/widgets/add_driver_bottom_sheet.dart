import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/components/inputs/custom_text_form.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddDriverBottomSheet extends StatefulWidget {
  const AddDriverBottomSheet({super.key});

  @override
  State<AddDriverBottomSheet> createState() => _AddDriverBottomSheetState();
}

class _AddDriverBottomSheetState extends State<AddDriverBottomSheet> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final revenueController = TextEditingController();
  final tripsController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  final _picker = ImagePicker();
  File? _idCardImage;
  File? _licenseImage;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    revenueController.dispose();
    tripsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({
    required bool isIdCard,
    required ImageSource source,
  }) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (picked != null) {
        setState(() {
          if (isIdCard) {
            _idCardImage = File(picked.path);
          } else {
            _licenseImage = File(picked.path);
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showImageSourcePicker({required bool isIdCard}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                title: isIdCard ? 'اختر صورة البطاقة' : 'اختر صورة الرخصة',
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                fontColor: AppColors.primary,
              ),
              SizedBox(height: 16.h),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                ),
                title: const Text('الكاميرا'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(isIdCard: isIdCard, source: ImageSource.camera);
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.photo_library_outlined, color: AppColors.primary),
                ),
                title: const Text('المعرض'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(isIdCard: isIdCard, source: ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void submit() {
    if (!formKey.currentState!.validate()) return;

    final double totalRevenue =
        double.tryParse(revenueController.text.trim()) ?? 0;

    final int tripsCount = int.tryParse(tripsController.text.trim()) ?? 0;

    Navigator.pop(context, {
      'name': nameController.text.trim(),
      'phone': phoneController.text.trim(),
      'totalRevenue': totalRevenue,
      'tripsCount': tripsCount,
      'idCardImage': _idCardImage,
      'licenseImage': _licenseImage,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.fromLTRB(
        20.w,
        12.h,
        20.w,
        MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Center(
                child: Container(
                  width: 45.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Center(
                child: CustomText(
                  title: 'إضافة سواق جديد',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  fontColor: AppColors.primary,
                ),
              ),
              SizedBox(height: 18.h),
              CustomTextFormField(
                controller: nameController,
                hint: 'اسم السواق *',
                prefix: Icon(
                  Icons.person_outline,
                  size: 22.sp,
                  color: const Color(0xFF777B85),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'من فضلك أدخل اسم السواق';
                  }
                  return null;
                },
              ),

              SizedBox(height: 12.h),
              CustomTextFormField(
                controller: phoneController,
                hint: 'رقم التليفون *',
                textInputType: TextInputType.phone,
                prefix: Icon(
                  Icons.phone_outlined,
                  size: 22.sp,
                  color: const Color(0xFF777B85),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'من فضلك أدخل رقم التليفون';
                  }
                  return null;
                },
              ),

              SizedBox(height: 12.h),

              CustomTextFormField(
                controller: revenueController,
                hint: 'إجمالي الإيراد',
                textInputType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                prefix: Icon(
                  Icons.attach_money,
                  size: 22.sp,
                  color: const Color(0xFF777B85),
                ),
              ),

              SizedBox(height: 12.h),

              CustomTextFormField(
                controller: tripsController,
                hint: 'عدد الرحلات',
                textInputType: TextInputType.number,
                prefix: Icon(
                  Icons.directions_bus_outlined,
                  size: 22.sp,
                  color: const Color(0xFF777B85),
                ),
              ),

              SizedBox(height: 20.h),

              // =================== DOCUMENTS SECTION ===================
              CustomText(
                title: 'المستندات الرسمية (اختياري)',
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                fontColor: AppColors.primary,
              ),

              SizedBox(height: 10.h),

              Row(
                children: [
                  // License Image Upload Box
                  Expanded(
                    child: _DocumentUploadBox(
                      title: 'صورة الرخصة',
                      image: _licenseImage,
                      icon: Icons.drive_eta_outlined,
                      onTap: () => _showImageSourcePicker(isIdCard: false),
                      onRemove: () {
                        setState(() {
                          _licenseImage = null;
                        });
                      },
                    ),
                  ),

                  SizedBox(width: 12.w),

                  // ID Card Image Upload Box
                  Expanded(
                    child: _DocumentUploadBox(
                      title: 'صورة البطاقة',
                      image: _idCardImage,
                      icon: Icons.badge_outlined,
                      onTap: () => _showImageSourcePicker(isIdCard: true),
                      onRemove: () {
                        setState(() {
                          _idCardImage = null;
                        });
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: CustomText(
                    title: 'إضافة السواق',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    fontColor: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentUploadBox extends StatelessWidget {
  final String title;
  final File? image;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _DocumentUploadBox({
    required this.title,
    required this.image,
    required this.icon,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (image != null) {
      return Stack(
        children: [
          Container(
            height: 120.h,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.primary, width: 1.5),
              image: DecorationImage(
                image: FileImage(image!),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 6.h,
            left: 6.w,
            child: InkWell(
              onTap: onRemove,
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 14.sp,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 6.h,
            right: 6.w,
            left: 6.w,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: CustomText(
                title: title,
                fontSize: 11.sp,
                fontColor: Colors.white,
                fontWeight: FontWeight.w600,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          color: const Color(0xFFC7C8CE),
          strokeWidth: 1.5,
          dashPattern: const [6, 4],
          radius: Radius.circular(12.r),
          padding: EdgeInsets.zero,
        ),
        child: Container(
          height: 120.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24.sp,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 6.h),
              CustomText(
                title: title,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                fontColor: AppColors.primary,
              ),
              SizedBox(height: 2.h),
              CustomText(
                title: 'اضغط للرفع',
                fontSize: 11.sp,
                fontColor: const Color(0xFF888B94),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
