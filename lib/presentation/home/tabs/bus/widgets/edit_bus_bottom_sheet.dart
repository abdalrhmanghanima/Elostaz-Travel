import 'dart:io';

import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/presentation/components/custom_button/custom_button.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/components/inputs/custom_text_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class EditBusBottomSheet extends ConsumerStatefulWidget {
  const EditBusBottomSheet({
    super.key,
    required this.bus,
    required this.onSave,
  });

  final BusEntity bus;

  final Future<bool> Function({
  required String busName,
  required DateTime licenseExpiryDate,
  File? busImage,
  File? licenseImage,
  }) onSave;

  @override
  ConsumerState<EditBusBottomSheet> createState() =>
      _EditBusBottomSheetState();
}

class _EditBusBottomSheetState
    extends ConsumerState<EditBusBottomSheet> {
  late final TextEditingController busNameController;

  late DateTime selectedLicenseExpiryDate;

  File? selectedBusImage;
  File? selectedLicenseImage;

  final ImagePicker imagePicker = ImagePicker();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    busNameController = TextEditingController(
      text: widget.bus.busName,
    );

    selectedLicenseExpiryDate =
        widget.bus.licenseExpiryDate;
  }

  @override
  void dispose() {
    busNameController.dispose();
    super.dispose();
  }

  Future<void> _pickBusImage() async {
    final image = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() {
      selectedBusImage = File(image.path);
    });
  }

  Future<void> _pickLicenseImage() async {
    final image = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() {
      selectedLicenseImage = File(image.path);
    });
  }

  Future<void> _pickLicenseExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedLicenseExpiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null) return;

    setState(() {
      selectedLicenseExpiryDate = date;
    });
  }

  Future<void> _save() async {
    final busName = busNameController.text.trim();

    if (busName.isEmpty) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final success = await widget.onSave(
        busName: busName,
        licenseExpiryDate: selectedLicenseExpiryDate,
        busImage: selectedBusImage,
        licenseImage: selectedLicenseImage,
      );

      if (!mounted) return;

      if (success) {
        Navigator.pop(context);
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 12.h,
          bottom:
          MediaQuery.of(context).viewInsets.bottom + 20.h,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 45.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius:
                    BorderRadius.circular(10.r),
                  ),
                ),
              ),

              SizedBox(height: 20.h),

              CustomText(
                title: 'تعديل بيانات الأتوبيس',
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                fontColor: AppColors.primary,
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 24.h),

              CustomText(
                title: 'اسم الأتوبيس',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),

              SizedBox(height: 7.h),

              CustomTextFormField(
                controller: busNameController,
                hint: 'اسم الأتوبيس',
              ),

              SizedBox(height: 16.h),

              CustomText(
                title: 'تاريخ انتهاء الرخصة',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),

              SizedBox(height: 7.h),

              InkWell(
                onTap: isLoading
                    ? null
                    : _pickLicenseExpiryDate,
                borderRadius: BorderRadius.circular(16.r),
                child: Container(
                  height: 56.h,
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.inputBg,
                    borderRadius:
                    BorderRadius.circular(16.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        color: AppColors.primary,
                        size: 22.sp,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: CustomText(
                          title:
                          '${selectedLicenseExpiryDate.day}/'
                              '${selectedLicenseExpiryDate.month}/'
                              '${selectedLicenseExpiryDate.year}',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey,
                        size: 22.sp,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20.h),

              CustomText(
                title: 'صورة الأتوبيس',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),

              SizedBox(height: 8.h),

              _ImagePickerContainer(
                selectedImage: selectedBusImage,
                existingImageUrl: widget.bus.busImageUrl,
                icon: Icons.directions_bus_outlined,
                title: 'تغيير صورة الأتوبيس',
                onTap: isLoading
                    ? null
                    : _pickBusImage,
              ),

              SizedBox(height: 18.h),

              CustomText(
                title: 'صورة رخصة الأتوبيس',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),

              SizedBox(height: 8.h),

              _ImagePickerContainer(
                selectedImage: selectedLicenseImage,
                existingImageUrl:
                widget.bus.licenseImageUrl,
                icon: Icons.description_outlined,
                title: 'تغيير صورة الرخصة',
                onTap: isLoading
                    ? null
                    : _pickLicenseImage,
              ),

              SizedBox(height: 24.h),

              CustomButton(
                title: 'حفظ التعديلات',
                width: double.infinity,
                height: 56.h,
                bg: AppColors.primary,
                fontColor: AppColors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                radius: 12.r,
                isLoading: isLoading,
                onTap: _save,
              ),

              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePickerContainer extends StatelessWidget {
  const _ImagePickerContainer({
    required this.selectedImage,
    required this.existingImageUrl,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final File? selectedImage;
  final String? existingImageUrl;
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasSelectedImage = selectedImage != null;

    final hasExistingImage =
        existingImageUrl != null &&
            existingImageUrl!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        width: double.infinity,
        height: 150.h,
        decoration: BoxDecoration(
          color: AppColors.inputBg,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasSelectedImage
            ? Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              selectedImage!,
              fit: BoxFit.cover,
            ),
            _ImageOverlay(title: title),
          ],
        )
            : hasExistingImage
            ? Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              existingImageUrl!,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) {
                return _EmptyImageState(
                  icon: icon,
                  title: title,
                );
              },
            ),
            _ImageOverlay(title: title),
          ],
        )
            : _EmptyImageState(
          icon: icon,
          title: title,
        ),
      ),
    );
  }
}

class _EmptyImageState extends StatelessWidget {
  const _EmptyImageState({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 36.sp,
          color: AppColors.primary,
        ),
        SizedBox(height: 8.h),
        CustomText(
          title: title,
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          fontColor: AppColors.primary,
        ),
      ],
    );
  }
}

class _ImageOverlay extends StatelessWidget {
  const _ImageOverlay({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: 8.h,
          horizontal: 12.w,
        ),
        color: Colors.black.withOpacity(.55),
        child: CustomText(
          title: title,
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          fontColor: AppColors.white,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}