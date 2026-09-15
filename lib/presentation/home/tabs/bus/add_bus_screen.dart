import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/core/dimens/dimens.dart';
import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/navigator/navigator.dart';
import 'package:elostaz_travel/core/services/bus_local_image_service.dart';
import 'package:elostaz_travel/core/services/license_notification_service.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_icons.dart';
import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/presentation/components/custom_app_bar/custom_app_bar.dart';
import 'package:elostaz_travel/presentation/components/custom_button/custom_button.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/components/inputs/custom_text_form.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/provider/bus_insurance_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/provider/bus_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/provider/document_upload_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/provider/special_requirements_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/widgets/document_upload_container.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddBusScreen extends ConsumerStatefulWidget {
  const AddBusScreen({super.key});

  @override
  ConsumerState<AddBusScreen> createState() => _AddBusScreenState();
}

class _AddBusScreenState extends ConsumerState<AddBusScreen> {
  final busNameController = TextEditingController();
  final plateNumberController = TextEditingController();
  final brandController = TextEditingController();
  final modelController = TextEditingController();
  final manufacturingYearController = TextEditingController();

  final chassisNumberController = TextEditingController();
  final engineNumberController = TextEditingController();
  final passengerCountController = TextEditingController();
  final licenseExpiryDateController = TextEditingController();
  final carTypeController = TextEditingController();
  final bankNameController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  late final String busId;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User is not authenticated');
    }

    busId = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('buses')
        .doc()
        .id;
  }
  @override
  void dispose() {
    busNameController.dispose();
    plateNumberController.dispose();
    brandController.dispose();
    modelController.dispose();
    manufacturingYearController.dispose();

    chassisNumberController.dispose();
    engineNumberController.dispose();
    passengerCountController.dispose();
    licenseExpiryDateController.dispose();
    carTypeController.dispose();
    bankNameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busState = ref.watch(busProvider);
    final specialRequirement = ref.watch(specialRequirementsProvider);
    final insuranceType = ref.watch(insuranceTypeProvider);
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        title: "إضافة عربية",
        fontColor: AppColors.white,
        onPressed: () => NavigatorHandler.pop(),
        centerTitle: true,
        showToolBar: true,
        iconPath: AppIcons.arrowLeft,
        bgColor: AppColors.primary,
      ),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16.w,
              right: 16.w,
              top: 20.h,
              bottom: 20.h + MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              children: [
                Container(
                  width: Dimens.width,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CustomText(title: "البيانات الأساسية", fontSize: 18.sp),
                        SizedBox(height: 16.h),
                        CustomText(title: "اسم الأتوبيس"),
                        SizedBox(height: 4.h),
                        CustomTextFormField(
                          controller: busNameController,
                          hint: "أدخل اسم الأتوبيس",
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "اسم الأتوبيس مطلوب";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),
                        CustomText(title: "رقم اللوحة"),
                        SizedBox(height: 4.h),
                        CustomTextFormField(
                          controller: plateNumberController,
                          hint: "أدخل رقم اللوحة",
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "رقم اللوحة مطلوب";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),
                        CustomText(title: "نوع العربية"),
                        SizedBox(height: 4.h),
                        CustomTextFormField(
                          controller: carTypeController,
                          hint: "مثال (ميكروباص - ميني باص - اتوبيس رحلات)",
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "نوع العربية مطلوب";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),
                        CustomText(title: "الماركة"),
                        SizedBox(height: 4.h),
                        CustomTextFormField(
                          controller: brandController,
                          hint: "مثال (تويوتا - مرسيدس - ميتسوبيشي)",
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "الماركة مطلوبة";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),
                        CustomText(title: "الموديل (اختياري)"),
                        SizedBox(height: 4.h),
                        CustomTextFormField(
                          controller: modelController,
                          hint: "مثال: Coaster, HiAce, Sprinter",
                        ),
                        SizedBox(height: 16.h),
                        CustomText(title: "سنة الصنع"),
                        SizedBox(height: 4.h),
                        CustomTextFormField(
                          controller: manufacturingYearController,
                          hint: "أدخل سنة الصنع (مثال: 2024)",
                          textInputType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "سنة الصنع مطلوبة";
                            }
                            final year = int.tryParse(value.trim());
                            if (year == null ||
                                year < 1900 ||
                                year > DateTime.now().year + 1) {
                              return "من فضلك أدخل سنة صنع صحيحة";
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                Container(
                  width: Dimens.width,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CustomText(title: "البيانات الفنية", fontSize: 18.sp),
                        SizedBox(height: 16.h),
                        CustomText(title: "رقم الشاسية"),
                        SizedBox(height: 4.h),
                        CustomTextFormField(
                          controller: chassisNumberController,
                          hint: "أدخل رقم الشاسية",
                          textInputType: TextInputType.text,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "رقم الشاسية مطلوب";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),
                        CustomText(title: "رقم الموتور"),
                        SizedBox(height: 4.h),
                        CustomTextFormField(
                          controller: engineNumberController,
                          hint: "أدخل رقم الموتور",
                          textInputType: TextInputType.text,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "رقم الموتور مطلوب";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),
                        CustomText(title: "عدد الركاب"),
                        SizedBox(height: 4.h),
                        CustomTextFormField(
                          controller: passengerCountController,
                          hint: "أدخل عدد الركاب",
                          textInputType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "عدد الركاب مطلوب";
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                Container(
                  width: Dimens.width,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CustomText(title: "الترخيص والتأمين", fontSize: 18.sp),
                        SizedBox(height: 16.h),
                        CustomText(title: "تاريخ انتهاء الترخيص"),
                        SizedBox(height: 4.h),
                        CustomTextFormField(
                          controller: licenseExpiryDateController,
                          hint: "DD/MM/YYYY",
                          textInputType: TextInputType.datetime,
                          onTap: () async {
                            final DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );

                            if (pickedDate != null) {
                              licenseExpiryDateController.text =
                              "${pickedDate.day.toString().padLeft(2, '0')}/"
                                  "${pickedDate.month.toString().padLeft(2, '0')}/"
                                  "${pickedDate.year}";
                            }
                          },
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "تاريخ انتهاء الترخيص مطلوب";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),
                        CustomText(title: "اشتراطات خاصة"),
                        SizedBox(height: 8.h),
                        Container(
                          height: 60,
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0EEF1),
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    ref.read(specialRequirementsProvider.notifier).state =
                                    'محظورة بيع';
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: specialRequirement == 'محظورة بيع'
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(13),
                                      boxShadow: specialRequirement == 'محظورة بيع'
                                          ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'محظورة بيع',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: specialRequirement == 'محظورة بيع'
                                            ? const Color(0xFF172B4D)
                                            : const Color(0xFF454545),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    ref.read(specialRequirementsProvider.notifier).state =
                                    'السيارة خالصة';
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: specialRequirement == 'السيارة خالصة'
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(13),
                                      boxShadow: specialRequirement == 'السيارة خالصة'
                                          ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'السيارة خالصة',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: specialRequirement == 'السيارة خالصة'
                                            ? const Color(0xFF172B4D)
                                            : const Color(0xFF454545),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (specialRequirement == 'محظورة بيع') ...[
                          SizedBox(height: 16.h),
                          CustomText(title: "اسم البنك المحظور البيع لصالحه *"),
                          SizedBox(height: 4.h),
                          CustomTextFormField(
                            controller: bankNameController,
                            hint: "أدخل اسم البنك المحظور البيع لصالحه",
                            textInputType: TextInputType.text,
                            validator: (value) {
                              if (ref.read(specialRequirementsProvider) == 'محظورة بيع') {
                                if (value == null || value.trim().isEmpty) {
                                  return "اسم البنك مطلوب عند اختيار محظورة بيع";
                                }
                              }
                              return null;
                            },
                          ),
                        ],
                        SizedBox(height: 16.h),
                        CustomText(title: "تأمين السيارة"),
                        SizedBox(height: 8.h),
                        Container(
                          height: 60,
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0EEF1),
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    ref.read(insuranceTypeProvider.notifier).state = 'غير مؤمنة';
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: insuranceType == 'غير مؤمنة'
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(13),
                                      boxShadow: insuranceType == 'غير مؤمنة'
                                          ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'غير مؤمنة',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: insuranceType == 'غير مؤمنة'
                                            ? const Color(0xFF172B4D)
                                            : const Color(0xFF454545),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    ref.read(insuranceTypeProvider.notifier).state = 'مؤمنة';
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: insuranceType == 'مؤمنة'
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(13),
                                      boxShadow: insuranceType == 'مؤمنة'
                                          ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'مؤمنة',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: insuranceType == 'مؤمنة'
                                            ? const Color(0xFF172B4D)
                                            : const Color(0xFF454545),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24.h,),
                Container(
                  width: Dimens.width,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding:  EdgeInsets.only(top:16.h,left: 20.w,right: 20.w,bottom: 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CustomText(title: "المرفقات",fontSize: 18.sp,),
                        SizedBox(height: 10.h,),
                        DocumentUploadContainer(
                          icon: AppIcons.file,
                          title: 'رخصة الأتوبيس',
                          busId: busId,
                          documentType: 'bus_license',
                        ),
                        SizedBox(height: 16.h,),
                        DocumentUploadContainer(
                          icon: AppIcons.busGray,
                          title: 'صورة الأتوبيس',
                          busId: busId,
                          documentType: 'bus_photo',
                        ),

                      ],
                    ),
                  ),
                ),
                SizedBox(height: 35.h,),
                CustomButton(
                  title: "حفظ بيانات الأتوبيس",
                  isLoading: busState.isLoading,
                  onTap: () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    final dateParts =
                    licenseExpiryDateController.text.split('/');

                    int year = int.parse(dateParts[2]);
                    if (year < 100) {
                      year += 2000;
                    }

                    final licenseExpiryDate = DateTime(
                      year,
                      int.parse(dateParts[1]),
                      int.parse(dateParts[0]),
                    );

                    final manufacturingYear = int.parse(
                      manufacturingYearController.text.trim(),
                    );

                    final bus = BusEntity(
                      id: busId,

                      busName: busNameController.text.trim(),

                      plateNumber: plateNumberController.text.trim(),

                      brand: brandController.text.trim(),

                      model: modelController.text.trim(),

                      manufacturingYear: manufacturingYear,

                      modelYear: manufacturingYear,

                      chassisNumber: chassisNumberController.text.trim(),

                      engineNumber: engineNumberController.text.trim(),

                      passengerCount: int.parse(
                        passengerCountController.text.trim(),
                      ),

                      vehicleType: carTypeController.text.trim(),

                      licenseExpiryDate: licenseExpiryDate,

                      licenseImageUrl: null,

                      busImageUrl: null,

                      specialConditions:
                          ref.read(specialRequirementsProvider),

                      prohibitedBankName: (ref.read(specialRequirementsProvider) ==
                                  'محظورة بيع' ||
                              ref.read(specialRequirementsProvider) ==
                                  'محظورة البيع')
                          ? bankNameController.text.trim()
                          : null,

                      insuranceType: ref.read(insuranceTypeProvider),
                    );

                    final messenger = ScaffoldMessenger.of(context);

                    await ref.read(busProvider.notifier).addBus(
                      bus: bus,
                    );

                    final state = ref.read(busProvider);
                    if (state.hasError) {
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'حدث خطأ أثناء حفظ البيانات. حاول مرة أخرى.',
                            ),
                          ),
                        );
                      }
                      return;
                    }

                    final busPhotoXFile = ref.read(
                      documentImageProvider(
                        (busId: busId, documentType: 'bus_photo'),
                      ),
                    );
                    final licenseXFile = ref.read(
                      documentImageProvider(
                        (busId: busId, documentType: 'bus_license'),
                      ),
                    );

                    if (busPhotoXFile != null) {
                      await BusLocalImageService.instance.saveBusImage(
                        busId,
                        File(busPhotoXFile.path),
                      );
                    }
                    if (licenseXFile != null) {
                      await BusLocalImageService.instance.saveLicenseImage(
                        busId,
                        File(licenseXFile.path),
                      );
                    }

                    await LicenseNotificationService.instance
                        .scheduleBusLicenseNotifications(bus);

                    if (mounted) {
                      NavigatorHandler.pop();
                    }
                  },
                  bg: AppColors.primary,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
