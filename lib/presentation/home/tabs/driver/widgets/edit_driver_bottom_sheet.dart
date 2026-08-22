import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/services/driver_local_image_service.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_entity.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/components/inputs/custom_text_form.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/provider/driver_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class EditDriverBottomSheet extends ConsumerStatefulWidget {
  final DriverEntity driver;

  const EditDriverBottomSheet({
    super.key,
    required this.driver,
  });

  @override
  ConsumerState<EditDriverBottomSheet> createState() =>
      _EditDriverBottomSheetState();
}

class _EditDriverBottomSheetState extends ConsumerState<EditDriverBottomSheet> {
  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  late final TextEditingController revenueController;
  late final TextEditingController tripsController;

  final formKey = GlobalKey<FormState>();

  final _picker = ImagePicker();
  File? _newIdCardImage;
  File? _newLicenseImage;

  File? _existingLocalIdCardImage;
  File? _existingLocalLicenseImage;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.driver.name);
    phoneController = TextEditingController(text: widget.driver.phone);
    revenueController = TextEditingController(
      text: widget.driver.totalRevenue > 0
          ? (widget.driver.totalRevenue % 1 == 0
              ? widget.driver.totalRevenue.toInt().toString()
              : widget.driver.totalRevenue.toString())
          : '0',
    );
    tripsController = TextEditingController(
      text: widget.driver.tripsCount.toString(),
    );

    _loadExistingImages();
  }

  Future<void> _loadExistingImages() async {
    final idCard = await DriverLocalImageService.instance
        .getIdCardImage(widget.driver.id);
    final license = await DriverLocalImageService.instance
        .getLicenseImage(widget.driver.id);

    if (mounted) {
      setState(() {
        _existingLocalIdCardImage = idCard;
        _existingLocalLicenseImage = license;
      });
    }
  }

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
            _newIdCardImage = File(picked.path);
          } else {
            _newLicenseImage = File(picked.path);
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
                  child: Icon(Icons.camera_alt_outlined,
                      color: AppColors.primary),
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
                  child: Icon(Icons.photo_library_outlined,
                      color: AppColors.primary),
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

  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final double totalRevenue =
          double.tryParse(revenueController.text.trim()) ??
              widget.driver.totalRevenue;
      final int tripsCount = int.tryParse(tripsController.text.trim()) ??
          widget.driver.tripsCount;

      final success =
          await ref.read(driversProvider.notifier).updateDriver(
                id: widget.driver.id,
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                totalRevenue: totalRevenue,
                tripsCount: tripsCount,
                idCardImageUrl: widget.driver.idCardImageUrl,
                licenseImageUrl: widget.driver.licenseImageUrl,
              );

      if (!mounted) return;

      if (success) {
        if (_newIdCardImage != null) {
          await DriverLocalImageService.instance
              .saveIdCardImage(widget.driver.id, _newIdCardImage!);
        }
        if (_newLicenseImage != null) {
          await DriverLocalImageService.instance
              .saveLicenseImage(widget.driver.id, _newLicenseImage!);
        }

        ref.invalidate(driverLocalImagesProvider(widget.driver.id));

        if (!mounted) return;

        Navigator.pop(context, true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تعديل بيانات السائق بنجاح'),
            backgroundColor: AppColors.green,
          ),
        );
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء تعديل بيانات السائق'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: AppColors.red,
        ),
      );
    }
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
                  title: 'تعديل بيانات السائق',
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
                    child: _EditDocumentUploadBox(
                      title: 'صورة الرخصة',
                      newImage: _newLicenseImage,
                      existingLocalImage: _existingLocalLicenseImage,
                      existingImageUrl: widget.driver.licenseImageUrl,
                      icon: Icons.drive_eta_outlined,
                      onTap: () => _showImageSourcePicker(isIdCard: false),
                      onRemoveNew: () {
                        setState(() {
                          _newLicenseImage = null;
                        });
                      },
                    ),
                  ),

                  SizedBox(width: 12.w),

                  // ID Card Image Upload Box
                  Expanded(
                    child: _EditDocumentUploadBox(
                      title: 'صورة البطاقة',
                      newImage: _newIdCardImage,
                      existingLocalImage: _existingLocalIdCardImage,
                      existingImageUrl: widget.driver.idCardImageUrl,
                      icon: Icons.badge_outlined,
                      onTap: () => _showImageSourcePicker(isIdCard: true),
                      onRemoveNew: () {
                        setState(() {
                          _newIdCardImage = null;
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
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24.w,
                          height: 24.w,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : CustomText(
                          title: 'حفظ التعديلات',
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

class _EditDocumentUploadBox extends StatelessWidget {
  final String title;
  final File? newImage;
  final File? existingLocalImage;
  final String? existingImageUrl;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onRemoveNew;

  const _EditDocumentUploadBox({
    required this.title,
    required this.newImage,
    required this.existingLocalImage,
    required this.existingImageUrl,
    required this.icon,
    required this.onTap,
    required this.onRemoveNew,
  });

  @override
  Widget build(BuildContext context) {
    if (newImage != null) {
      return Stack(
        children: [
          Container(
            height: 120.h,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.primary, width: 1.5),
              image: DecorationImage(
                image: FileImage(newImage!),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 6.h,
            left: 6.w,
            child: InkWell(
              onTap: onRemoveNew,
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
                title: '$title (جديدة)',
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

    if (existingLocalImage != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Stack(
          children: [
            Container(
              height: 120.h,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                image: DecorationImage(
                  image: FileImage(existingLocalImage!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 6.h,
              left: 6.w,
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
        ),
      );
    }

    if (existingImageUrl != null && existingImageUrl!.isNotEmpty) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Stack(
          children: [
            Container(
              height: 120.h,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11.r),
                child: CachedNetworkImage(
                  imageUrl: existingImageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (_, _, _) => const Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 6.h,
              left: 6.w,
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
        ),
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
