import 'dart:io';

import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/services/bus_local_image_service.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_date_picker.dart';
import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/presentation/components/custom_button/custom_button.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/components/inputs/custom_text_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';



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
    String? model,
    int? manufacturingYear,
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
  late final TextEditingController modelController;
  late final TextEditingController manufacturingYearController;

  late DateTime selectedLicenseExpiryDate;

  File? selectedBusImage;
  File? selectedLicenseImage;

  File? existingLocalBusImage;
  File? existingLocalLicenseImage;

  final ImagePicker imagePicker = ImagePicker();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    busNameController = TextEditingController(
      text: widget.bus.busName,
    );

    modelController = TextEditingController(
      text: widget.bus.model.isNotEmpty
          ? widget.bus.model
          : widget.bus.brand,
    );

    manufacturingYearController = TextEditingController(
      text: widget.bus.manufacturingYear != null &&
              widget.bus.manufacturingYear! > 0
          ? widget.bus.manufacturingYear.toString()
          : (widget.bus.modelYear > 0 ? widget.bus.modelYear.toString() : ''),
    );

    selectedLicenseExpiryDate =
        widget.bus.licenseExpiryDate;

    _loadExistingLocalImages();
  }

  Future<void> _loadExistingLocalImages() async {
    final busId = widget.bus.id;

    if (busId == null) return;

    final busImage =
    await BusLocalImageService.instance.getBusImage(busId);

    final licenseImage =
    await BusLocalImageService.instance.getLicenseImage(busId);

    if (!mounted) return;

    setState(() {
      existingLocalBusImage = busImage;
      existingLocalLicenseImage = licenseImage;
    });
  }

  @override
  void dispose() {
    busNameController.dispose();
    modelController.dispose();
    manufacturingYearController.dispose();
    super.dispose();
  }

  // ============================================================
  // IMAGE SOURCE PICKER (CAMERA / GALLERY)
  // ============================================================

  Future<ImageSource?> _showImageSourcePicker() async {
    return await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24.r),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 20.w,
              vertical: 20.h,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 45.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                SizedBox(height: 16.h),
                CustomText(
                  title: 'اختر طريقة رفع الصورة',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  fontColor: AppColors.primary,
                ),
                SizedBox(height: 20.h),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 22.sp,
                    ),
                  ),
                  title: CustomText(
                    title: 'الكاميرا',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white,
                      size: 22.sp,
                    ),
                  ),
                  title: CustomText(
                    title: 'المعرض',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext, ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // BUS IMAGE
  // ============================================================

  Future<void> _pickBusImage() async {
    if (isLoading) return;

    final source = await _showImageSourcePicker();
    if (source == null) return;

    final image = await imagePicker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (image == null) return;

    try {
      final sourceFile = File(image.path);

      if (!await sourceFile.exists()) {
        return;
      }

      final tempDir =
      await getApplicationDocumentsDirectory();

      final imagesDir = Directory(
        '${tempDir.path}/bus_edit_temp',
      );

      if (!await imagesDir.exists()) {
        await imagesDir.create(
          recursive: true,
        );
      }

      final savedFile = File(
        '${imagesDir.path}/selected_bus_image_${widget.bus.id}.jpg',
      );

      // امسح النسخة السابقة لو موجودة
      if (await savedFile.exists()) {
        await savedFile.delete();
      }

      // انسخ الصورة من cache لمكان دائم
      await sourceFile.copy(
        savedFile.path,
      );

      if (!mounted) return;

      setState(() {
        selectedBusImage = savedFile;
      });

      debugPrint(
        'Temporary permanent bus image saved: ${savedFile.path}',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'Error selecting bus image: $e',
      );
      debugPrint(
        '$stackTrace',
      );
    }
  }
  Future<void> _pickLicenseImage() async {
    if (isLoading) return;

    final source = await _showImageSourcePicker();
    if (source == null) return;

    final image = await imagePicker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (image == null) return;

    try {
      final sourceFile = File(image.path);

      if (!await sourceFile.exists()) {
        return;
      }

      final tempDir =
      await getApplicationDocumentsDirectory();

      final imagesDir = Directory(
        '${tempDir.path}/bus_edit_temp',
      );

      if (!await imagesDir.exists()) {
        await imagesDir.create(
          recursive: true,
        );
      }

      final savedFile = File(
        '${imagesDir.path}/selected_license_image_${widget.bus.id}.jpg',
      );

      if (await savedFile.exists()) {
        await savedFile.delete();
      }

      await sourceFile.copy(
        savedFile.path,
      );

      if (!mounted) return;

      setState(() {
        selectedLicenseImage = savedFile;
      });

      debugPrint(
        'Temporary permanent license image saved: ${savedFile.path}',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'Error selecting license image: $e',
      );
      debugPrint(
        '$stackTrace',
      );
    }
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _pickLicenseExpiryDate() async {
    if (isLoading) return;

    final now = DateTime.now();

    // نخلي firstDate من بداية اليوم الحالي
    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    // لو التاريخ الحالي للرخصة قديم، نسمح للـDatePicker
    // إنه يبدأ من التاريخ القديم حتى يقدر يعرضه.
    final firstDate = selectedLicenseExpiryDate.isBefore(today)
        ? DateTime(
      selectedLicenseExpiryDate.year,
      selectedLicenseExpiryDate.month,
      selectedLicenseExpiryDate.day,
    )
        : today;

    final selectedDate = await AppDatePicker.show(
      context,
      initialDate: selectedLicenseExpiryDate,
      firstDate: firstDate,
      lastDate: DateTime(2100),
      helpText: 'اختر تاريخ انتهاء الرخصة',
    );

    if (selectedDate == null) return;

    if (!mounted) return;

    setState(() {
      selectedLicenseExpiryDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
    });
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _save() async {
    final busName = busNameController.text.trim();
    final modelText = modelController.text.trim();
    final mfgYearText = manufacturingYearController.text.trim();
    final mfgYear = int.tryParse(mfgYearText);

    if (busName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('من فضلك أدخل اسم الأتوبيس'),
        ),
      );
      return;
    }

    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      debugPrint(
        '================ EDIT BUS SAVE ================',
      );

      debugPrint('Bus ID: ${widget.bus.id}');
      debugPrint('Bus Name: $busName');
      debugPrint('Model: $modelText');
      debugPrint('Manufacturing Year: $mfgYear');
      debugPrint(
        'License Expiry: $selectedLicenseExpiryDate',
      );
      debugPrint(
        'New Bus Image: ${selectedBusImage?.path}',
      );
      debugPrint(
        'New License Image: ${selectedLicenseImage?.path}',
      );

      final success = await widget.onSave(
        busName: busName,
        licenseExpiryDate: selectedLicenseExpiryDate,
        model: modelText.isNotEmpty ? modelText : null,
        manufacturingYear: mfgYear,
        busImage: selectedBusImage,
        licenseImage: selectedLicenseImage,
      );

      debugPrint('UPDATE RESULT: $success');

      if (!mounted) return;

      if (success) {
        // مهم جدًا:
        // الصور اتحفظت Local بالفعل داخل onSave،
        // فنطلب من Provider إعادة قراءة الصور.
        if (widget.bus.id != null) {
          ref.invalidate(
            busLocalImagesProvider(widget.bus.id!),
          );
        }

        // نقفل Edit Bottom Sheet بعد تحديث الـProvider
        Navigator.of(context).pop();

        return;
      }

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'فشل تعديل بيانات الأتوبيس',
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint(
        '================ EDIT BUS ERROR ================',
      );

      debugPrint('ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ أثناء تعديل الأتوبيس: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

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
            crossAxisAlignment:
            CrossAxisAlignment.stretch,
            children: [
              // Handle
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

              // Title
              CustomText(
                title: 'تعديل بيانات الأتوبيس',
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                fontColor: AppColors.primary,
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 24.h),

              // ==================================================
              // BUS NAME
              // ==================================================

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

              // ==================================================
              // MODEL
              // ==================================================

              CustomText(
                title: 'الموديل',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),

              SizedBox(height: 7.h),

              CustomTextFormField(
                controller: modelController,
                hint: 'مثال: Mercedes Tourismo',
                textInputType: TextInputType.text,
              ),

              SizedBox(height: 16.h),

              // ==================================================
              // MANUFACTURING YEAR
              // ==================================================

              CustomText(
                title: 'سنة الصنع',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),

              SizedBox(height: 7.h),

              CustomTextFormField(
                controller: manufacturingYearController,
                hint: 'مثال: 2020',
                textInputType: TextInputType.number,
              ),

              SizedBox(height: 16.h),

              // ==================================================
              // LICENSE EXPIRY DATE
              // ==================================================

              CustomText(
                title: 'تاريخ انتهاء الرخصة',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),

              SizedBox(height: 7.h),

              InkWell(
                onTap: _pickLicenseExpiryDate,
                borderRadius:
                BorderRadius.circular(16.r),
                child: Container(
                  height: 56.h,
                  padding:
                  EdgeInsets.symmetric(
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
                          title: AppDateFormatter.format(selectedLicenseExpiryDate),
                          fontSize: 15.sp,
                          fontWeight:
                          FontWeight.w500,
                        ),
                      ),

                      Icon(
                        Icons
                            .keyboard_arrow_down_rounded,
                        color: Colors.grey,
                        size: 22.sp,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20.h),

              // ==================================================
              // BUS IMAGE
              // ==================================================

              CustomText(
                title: 'صورة الأتوبيس',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),

              SizedBox(height: 8.h),

              _ImagePickerContainer(
                selectedImage: selectedBusImage,
                existingLocalImage:
                existingLocalBusImage,
                existingImageUrl:
                widget.bus.busImageUrl,
                icon:
                Icons.directions_bus_outlined,
                title: 'تغيير صورة الأتوبيس',
                onTap: isLoading
                    ? null
                    : _pickBusImage,
              ),

              SizedBox(height: 18.h),

              // ==================================================
              // LICENSE IMAGE
              // ==================================================

              CustomText(
                title: 'صورة رخصة الأتوبيس',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),

              SizedBox(height: 8.h),

              _ImagePickerContainer(
                selectedImage:
                selectedLicenseImage,
                existingLocalImage:
                existingLocalLicenseImage,
                existingImageUrl:
                widget.bus.licenseImageUrl,
                icon:
                Icons.description_outlined,
                title: 'تغيير صورة الرخصة',
                onTap: isLoading
                    ? null
                    : _pickLicenseImage,
              ),

              SizedBox(height: 24.h),

              // ==================================================
              // SAVE
              // ==================================================

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

// ================================================================
// IMAGE PICKER CONTAINER
// ================================================================

class _ImagePickerContainer
    extends StatelessWidget {
  const _ImagePickerContainer({
    required this.selectedImage,
    this.existingLocalImage,
    required this.existingImageUrl,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final File? selectedImage;
  final File? existingLocalImage;
  final String? existingImageUrl;

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasSelectedImage =
        selectedImage != null;

    final hasExistingLocalImage =
        existingLocalImage != null;

    final hasExistingImage =
        existingImageUrl != null &&
            existingImageUrl!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius:
      BorderRadius.circular(16.r),
      child: Container(
        width: double.infinity,
        height: 150.h,
        decoration: BoxDecoration(
          color: AppColors.inputBg,
          borderRadius:
          BorderRadius.circular(16.r),
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
            _ImageOverlay(
              title: title,
            ),
          ],
        )
            : hasExistingLocalImage
            ? Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              existingLocalImage!,
              fit: BoxFit.cover,
            ),
            _ImageOverlay(
              title: title,
            ),
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
            _ImageOverlay(
              title: title,
            ),
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

// ================================================================
// EMPTY IMAGE
// ================================================================

class _EmptyImageState
    extends StatelessWidget {
  const _EmptyImageState({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment:
      MainAxisAlignment.center,
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

// ================================================================
// IMAGE OVERLAY
// ================================================================

class _ImageOverlay
    extends StatelessWidget {
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