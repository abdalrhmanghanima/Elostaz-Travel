import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/core/dimens/dimens.dart';
import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/navigator/navigator.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_icons.dart';
import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/presentation/components/custom_app_bar/custom_app_bar.dart';
import 'package:elostaz_travel/presentation/components/custom_button/custom_button.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/components/inputs/custom_text_form.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/provider/bus_insurance_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/provider/bus_provider.dart';
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
  final modelYearController = TextEditingController();

  final chassisNumberController = TextEditingController();
  final engineNumberController = TextEditingController();
  final passengerCountController = TextEditingController();
  final licenseExpiryDateController = TextEditingController();
  final carTypeController = TextEditingController();
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
    modelYearController.dispose();

    chassisNumberController.dispose();
    engineNumberController.dispose();
    passengerCountController.dispose();
    licenseExpiryDateController.dispose();
    carTypeController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insuranceType = ref.watch(insuranceTypeProvider);
    final specialRequirement = ref.watch(specialRequirementsProvider);
    final busState = ref.watch(busProvider);
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        title: "إضافة أتوبيس",
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
              bottom: 20.h,
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
                          hint: "ادخل اسم الاتوبيس",
                          textInputType: TextInputType.text,
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
                          hint: "أ ب ج 1 2 3",
                          textInputType: TextInputType.text,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "رقم اللوحة مطلوب";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),
                        CustomText(title: "الماركة"),
                        SizedBox(height: 4.h),
                        CustomTextFormField(
                          controller: brandController,
                          hint: "شيفرولية",
                          textInputType: TextInputType.text,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "الماركة مطلوبة";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),
                        CustomText(title: "الموديل"),
                        SizedBox(height: 4.h),
                        CustomTextFormField(
                          controller: modelYearController,
                          hint: "ادخل سنة الصنع",
                          textInputType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "سنة الصنع مطلوبة";
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
                          textInputType: TextInputType.number,
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
                          textInputType: TextInputType.number,
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
                          hint: "مثال: 50",
                          textInputType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "عدد الركاب مطلوب";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.h),
                        CustomText(title: "تاريخ انتهاء الرخصة"),
                        SizedBox(height: 4.h),
                        CustomTextFormField(
                          controller: licenseExpiryDateController,
                          hint: "dd/mm/yy",
                          readOnly: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "تاريخ انتهاء الرخصة مطلوب";
                            }
                            return null;
                          },
                          onTap: () async {
                            final DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );

                            if (pickedDate != null) {
                              licenseExpiryDateController.text =
                              '${pickedDate.day.toString().padLeft(2, '0')}/'
                                  '${pickedDate.month.toString().padLeft(2, '0')}/'
                                  '${(pickedDate.year % 100).toString().padLeft(2, '0')}';
                            }
                          },
                        ),
                        SizedBox(height: 16.h),
                        CustomText(title: "نوع السيارة"),
                        SizedBox(height: 4.h),
                        CustomTextFormField(
                          controller: carTypeController,
                          hint: "مثال: ميني باص",
                          textInputType: TextInputType.text,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "نوع السيارة مطلوب";
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
                        CustomText(
                          title: "الشؤون القانونية والتأمين",
                          fontSize: 16.sp,
                        ),
                        SizedBox(height: 10.h),
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
                                    'محظورة من البيع';
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: specialRequirement == 'محظورة من البيع'
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(13),
                                      boxShadow: specialRequirement == 'محظورة من البيع'
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
                                      'محظورة من البيع',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: specialRequirement == 'محظورة من البيع'
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

                    final licenseExpiryDate = DateTime(
                      2000 + int.parse(dateParts[2]),
                      int.parse(dateParts[1]),
                      int.parse(dateParts[0]),
                    );

                    final bus = BusEntity(
                      id: busId,

                      busName: busNameController.text.trim(),

                      plateNumber: plateNumberController.text.trim(),

                      brand: brandController.text.trim(),

                      modelYear: int.parse(
                        modelYearController.text.trim(),
                      ),

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

                      insuranceType: ref.read(insuranceTypeProvider),
                    );

                    await ref.read(busProvider.notifier).addBus(
                      bus: bus,
                    );

                    if (mounted) {
                      NavigatorHandler.pop();
                    }
                  },
                  bg: AppColors.primary,)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
