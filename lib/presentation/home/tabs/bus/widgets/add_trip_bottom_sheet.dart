import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_date_picker.dart';
import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_entity.dart';
import 'package:elostaz_travel/domain/factory/entity/factory_entity.dart';
import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/presentation/components/custom_button/custom_button.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/components/inputs/custom_text_form.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/provider/bus_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/provider/driver_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/factory/provider/factory_provider.dart';
import 'package:elostaz_travel/presentation/trip/provider/trip_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddTripBottomSheet extends ConsumerStatefulWidget {
  const AddTripBottomSheet({
    super.key,
    required this.drivers,
    required this.bus,
  });

  final List<DriverEntity> drivers;
  final BusEntity bus;

  @override
  ConsumerState<AddTripBottomSheet> createState() => _AddTripBottomSheetState();
}

class _AddTripBottomSheetState extends ConsumerState<AddTripBottomSheet> {
  final formKey = GlobalKey<FormState>();

  // Normal trip controllers
  final detailsController = TextEditingController();
  final revenueController = TextEditingController();
  final expensesController = TextEditingController();
  final expenseDetailsController = TextEditingController();

  DriverEntity? selectedDriver;
  FactoryEntity? selectedFactory;
  DateTime? selectedDate = DateTime.now();

  // Sahra (Night Shift) fields
  bool isNightShift = false;
  final sahraDetailsController = TextEditingController();
  final sahraRevenueController = TextEditingController();
  final sahraExpensesController = TextEditingController();
  final sahraExpenseDetailsController = TextEditingController();
  DriverEntity? sahraDriver;

  double? parseArabicNumber(String value) {
    final normalized = value
        .replaceAll('٠', '0')
        .replaceAll('١', '1')
        .replaceAll('٢', '2')
        .replaceAll('٣', '3')
        .replaceAll('٤', '4')
        .replaceAll('٥', '5')
        .replaceAll('٦', '6')
        .replaceAll('٧', '7')
        .replaceAll('٨', '8')
        .replaceAll('٩', '9')
        .replaceAll('٫', '.')
        .trim();

    return double.tryParse(normalized);
  }

  @override
  void dispose() {
    detailsController.dispose();
    revenueController.dispose();
    expensesController.dispose();
    expenseDetailsController.dispose();
    sahraDetailsController.dispose();
    sahraRevenueController.dispose();
    sahraExpensesController.dispose();
    sahraExpenseDetailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripProvider);
    final factoriesState = ref.watch(factoriesProvider);
    final factories = factoriesState.valueOrNull ?? [];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          padding: EdgeInsets.fromLTRB(
            20.w,
            12.h,
            20.w,
            20.h,
          ),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28.r),
            ),
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 45.w,
                      height: 5.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9D9D9),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),

                  SizedBox(height: 18.h),

                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.close_rounded,
                          size: 25.sp,
                          color: AppColors.primary,
                        ),
                      ),

                      const Spacer(),

                      CustomText(
                        title: 'إضافة رحلة جديدة',
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        fontColor: AppColors.primary,
                      ),

                      const Spacer(),

                      SizedBox(width: 25.w),
                    ],
                  ),

                  SizedBox(height: 18.h),

                  // =================== FACTORY SELECTION (OPTIONAL) ===================
                  CustomText(
                    title: 'المصنع (اختياري - للورديات)',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    fontColor: const Color(0xFF555555),
                  ),

                  SizedBox(height: 6.h),

                  Container(
                    height: 60.h,
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: const Color(0xFFDCDCDC)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<FactoryEntity>(
                        isExpanded: true,
                        hint: Row(
                          children: [
                            Icon(
                              Icons.factory_outlined,
                              color: AppColors.primary,
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            CustomText(
                              title: 'بدون مصنع (رحلة عامة)',
                              fontSize: 14.sp,
                              fontColor: const Color(0xFF888888),
                            ),
                          ],
                        ),
                        value: selectedFactory,
                        items: [
                          DropdownMenuItem<FactoryEntity>(
                            value: null,
                            child: CustomText(
                              title: 'بدون مصنع (رحلة عامة)',
                              fontSize: 14.sp,
                              fontColor: const Color(0xFF888888),
                            ),
                          ),
                          ...factories.map((factory) {
                            return DropdownMenuItem<FactoryEntity>(
                              value: factory,
                              child: CustomText(
                                title: factory.name,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setState(() {
                            selectedFactory = val;
                          });
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: 14.h),

                  // =================== DRIVER SELECTION ===================
                  CustomText(
                    title: 'اختر السواق *',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    fontColor: const Color(0xFF555555),
                  ),

                  SizedBox(height: 6.h),

                  FormField<DriverEntity>(
                    validator: (_) {
                      if (selectedDriver == null) {
                        return 'من فضلك اختر السواق';
                      }
                      return null;
                    },
                    builder: (field) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 64.h,
                            padding: EdgeInsets.symmetric(horizontal: 14.w),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: field.hasError
                                    ? Colors.red
                                    : const Color(0xFFDCDCDC),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<DriverEntity>(
                                isExpanded: true,
                                hint: Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline_rounded,
                                      color: AppColors.primary,
                                      size: 20.sp,
                                    ),
                                    SizedBox(width: 8.w),
                                    CustomText(
                                      title: 'اختر السواق',
                                      fontSize: 14.sp,
                                      fontColor: const Color(0xFF888888),
                                    ),
                                  ],
                                ),
                                value: selectedDriver,
                                items: widget.drivers.map((driver) {
                                  return DropdownMenuItem<DriverEntity>(
                                    value: driver,
                                    child: CustomText(
                                      title: driver.name,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    selectedDriver = val;
                                  });
                                  field.didChange(val);
                                },
                              ),
                            ),
                          ),
                          if (field.hasError)
                            Padding(
                              padding: EdgeInsets.only(top: 4.h, right: 8.w),
                              child: Text(
                                field.errorText ?? '',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  SizedBox(height: 14.h),

                  // =================== DETAILS ===================
                  CustomText(
                    title: 'تفاصيل الرحلة *',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    fontColor: const Color(0xFF555555),
                  ),

                  SizedBox(height: 6.h),

                  CustomTextFormField(
                    controller: detailsController,
                    hint: 'مثال: رحلة الإسكندرية / وردية المصنع...',
                    prefix: Icon(
                      Icons.description_outlined,
                      size: 22.sp,
                      color: const Color(0xFF777B85),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'من فضلك أدخل تفاصيل الرحلة';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 14.h),

                  // =================== DATE PICKER ===================
                  CustomText(
                    title: 'تاريخ الرحلة',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    fontColor: const Color(0xFF555555),
                  ),

                  SizedBox(height: 6.h),

                  InkWell(
                    onTap: () async {
                      final picked = await AppDatePicker.show(
                        context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        helpText: 'اختر تاريخ الرحلة',
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      height: 52.h,
                      padding: EdgeInsets.symmetric(horizontal: 14.w),
                      decoration: BoxDecoration(
                        color: AppColors.inputBg,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 18.sp,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 8.w),
                          CustomText(
                            title: selectedDate != null
                                ? AppDateFormatter.format(selectedDate!)
                                : 'اختر التاريخ',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 14.h),

                  // =================== REVENUE ===================
                  CustomText(
                    title: 'إيراد الرحلة (ج.م) *',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    fontColor: const Color(0xFF555555),
                  ),

                  SizedBox(height: 6.h),

                  CustomTextFormField(
                    controller: revenueController,
                    hint: '0',
                    textInputType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    prefix: Icon(
                      Icons.attach_money_rounded,
                      size: 22.sp,
                      color: const Color(0xFF777B85),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'من فضلك أدخل الإيراد';
                      }
                      if (parseArabicNumber(value) == null) {
                        return 'أدخل رقم صحيح';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 14.h),

                  // =================== NORMAL EXPENSES ===================
                  CustomText(
                    title: 'مصروف الرحلة (ج.م)',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    fontColor: const Color(0xFF555555),
                  ),

                  SizedBox(height: 6.h),

                  CustomTextFormField(
                    controller: expensesController,
                    hint: '0',
                    textInputType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    prefix: Icon(
                      Icons.money_off_rounded,
                      size: 22.sp,
                      color: const Color(0xFF777B85),
                    ),
                  ),

                  SizedBox(height: 10.h),

                  CustomText(
                    title: 'تفاصيل المصروف (اختياري)',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    fontColor: const Color(0xFF555555),
                  ),

                  SizedBox(height: 6.h),

                  CustomTextFormField(
                    controller: expenseDetailsController,
                    hint: 'مثال: سولار، كارتة، صيانة، أكل...',
                    prefix: Icon(
                      Icons.notes_rounded,
                      size: 22.sp,
                      color: const Color(0xFF777B85),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // =================== SAHRA TOGGLE ===================
                  Material(
                    color: isNightShift
                        ? AppColors.lightGreen
                        : AppColors.backgroundGray,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      side: BorderSide(
                        color: isNightShift
                            ? AppColors.green
                            : const Color(0xFFE0E0E0),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 6.h,
                      ),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Row(
                          children: [
                            Icon(
                              Icons.nightlight_round,
                              size: 20.sp,
                              color: isNightShift
                                  ? AppColors.green
                                  : const Color(0xFF777777),
                            ),
                            SizedBox(width: 8.w),
                            CustomText(
                              title: 'سهرة (وردية إضافية)',
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              fontColor: isNightShift
                                  ? AppColors.green
                                  : AppColors.primary,
                            ),
                          ],
                        ),
                        subtitle: Text(
                          'تفعيل هذا الخيار في حالة قيام الأتوبيس بسهرة أو وردية ليلية إضافية',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: const Color(0xFF888888),
                          ),
                        ),
                        activeThumbColor: AppColors.green,
                        activeTrackColor: AppColors.lightGreen,
                        value: isNightShift,
                        onChanged: (val) {
                          setState(() {
                            isNightShift = val;
                          });
                        },
                      ),
                    ),
                  ),

                  // =================== SAHRA SECTION ===================
                  if (isNightShift) ...[
                    SizedBox(height: 14.h),
                    Container(
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: AppColors.green.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.stars_rounded,
                                color: AppColors.green,
                                size: 20.sp,
                              ),
                              SizedBox(width: 6.w),
                              CustomText(
                                title: 'بيانات السهرة (اختياري بالكامل)',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                fontColor: AppColors.green,
                              ),
                            ],
                          ),

                          SizedBox(height: 12.h),

                          // 1. تفاصيل السهرة
                          CustomText(
                            title: 'تفاصيل السهرة',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            fontColor: const Color(0xFF555555),
                          ),
                          SizedBox(height: 4.h),
                          CustomTextFormField(
                            controller: sahraDetailsController,
                            hint: 'مثال: سهرة من المصنع لأكتوبر من 8 م لـ 4 ص...',
                            prefix: Icon(
                              Icons.description_outlined,
                              size: 20.sp,
                              color: const Color(0xFF777B85),
                            ),
                          ),

                          SizedBox(height: 12.h),

                          // 2. سائق السهرة
                          CustomText(
                            title: 'سائق السهرة',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            fontColor: const Color(0xFF555555),
                          ),
                          SizedBox(height: 4.h),
                          Container(
                            height: 60.h,
                            padding: EdgeInsets.symmetric(horizontal: 14.w),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: const Color(0xFFDCDCDC)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<DriverEntity>(
                                isExpanded: true,
                                hint: Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline_rounded,
                                      color: const Color(0xFF777B85),
                                      size: 18.sp,
                                    ),
                                    SizedBox(width: 8.w),
                                    CustomText(
                                      title: 'اختر سائق السهرة (اختياري)',
                                      fontSize: 13.sp,
                                      fontColor: const Color(0xFF888888),
                                    ),
                                  ],
                                ),
                                value: sahraDriver,
                                items: widget.drivers.map((driver) {
                                  return DropdownMenuItem<DriverEntity>(
                                    value: driver,
                                    child: CustomText(
                                      title: driver.name,
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    sahraDriver = val;
                                  });
                                },
                              ),
                            ),
                          ),

                          SizedBox(height: 12.h),

                          // 3. إيراد السهرة
                          CustomText(
                            title: 'إيراد السهرة (ج.م)',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            fontColor: const Color(0xFF555555),
                          ),
                          SizedBox(height: 4.h),
                          CustomTextFormField(
                            controller: sahraRevenueController,
                            hint: '0',
                            textInputType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            prefix: Icon(
                              Icons.attach_money_rounded,
                              size: 20.sp,
                              color: const Color(0xFF777B85),
                            ),
                          ),

                          SizedBox(height: 12.h),

                          // 4. مصروف السهرة
                          CustomText(
                            title: 'مصروف السهرة (ج.م)',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            fontColor: const Color(0xFF555555),
                          ),
                          SizedBox(height: 4.h),
                          CustomTextFormField(
                            controller: sahraExpensesController,
                            hint: '0',
                            textInputType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            prefix: Icon(
                              Icons.money_off_rounded,
                              size: 20.sp,
                              color: const Color(0xFF777B85),
                            ),
                          ),

                          SizedBox(height: 12.h),

                          // 5. تفاصيل مصروف السهرة
                          CustomText(
                            title: 'تفاصيل مصروف السهرة',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            fontColor: const Color(0xFF555555),
                          ),
                          SizedBox(height: 4.h),
                          CustomTextFormField(
                            controller: sahraExpenseDetailsController,
                            hint: 'مثال: سولار إضافي وطريق...',
                            prefix: Icon(
                              Icons.notes_rounded,
                              size: 20.sp,
                              color: const Color(0xFF777B85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: 24.h),

                  // =================== SUBMIT BUTTON ===================
                  CustomButton(
                    title: 'حفظ الرحلة',
                    width: double.infinity,
                    height: 56.h,
                    bg: AppColors.primary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    fontColor: AppColors.white,
                    radius: 12.r,
                    elevation: 0,
                    isLoading: tripState.isLoading,
                    onTap: () async {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }

                      final revenue =
                          parseArabicNumber(revenueController.text) ?? 0.0;
                      final expenses =
                          parseArabicNumber(expensesController.text) ?? 0.0;

                      final sahraRev = isNightShift
                          ? parseArabicNumber(sahraRevenueController.text)
                          : null;
                      final sahraExp = isNightShift
                          ? parseArabicNumber(sahraExpensesController.text)
                          : null;

                      final trip = TripEntity(
                        id: '',
                        driverId: selectedDriver!.id,
                        driverName: selectedDriver!.name,
                        busId: widget.bus.id ?? '',
                        busName: widget.bus.busName,
                        plateNumber: widget.bus.plateNumber,
                        details: detailsController.text.trim(),
                        revenue: revenue,
                        expenses: expenses,
                        expenseDetails:
                            expenseDetailsController.text.trim().isNotEmpty
                                ? expenseDetailsController.text.trim()
                                : null,
                        factoryId: selectedFactory?.id,
                        factoryName: selectedFactory?.name,
                        isNightShift: isNightShift,
                        sahraDetails: isNightShift &&
                                sahraDetailsController.text.trim().isNotEmpty
                            ? sahraDetailsController.text.trim()
                            : null,
                        sahraDriverId: isNightShift ? sahraDriver?.id : null,
                        sahraDriverName: isNightShift ? sahraDriver?.name : null,
                        sahraRevenue: sahraRev,
                        sahraExpense: sahraExp,
                        sahraExpenseDetails: isNightShift &&
                                sahraExpenseDetailsController.text
                                    .trim()
                                    .isNotEmpty
                            ? sahraExpenseDetailsController.text.trim()
                            : null,
                        createdAt: selectedDate ?? DateTime.now(),
                      );

                      final success =
                          await ref.read(tripProvider.notifier).addTrip(trip);

                      if (!context.mounted) return;

                      if (success) {
                        ref.invalidate(busTripsProvider(widget.bus.id ?? ''));
                        ref.invalidate(driverTripsProvider(selectedDriver!.id));
                        if (selectedFactory != null) {
                          ref.invalidate(
                              factoryTripsProvider(selectedFactory!.id));
                          ref.invalidate(factoriesProvider);
                        }
                        ref.invalidate(driversProvider);
                        ref.invalidate(busProvider);

                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('حدث خطأ أثناء حفظ الرحلة'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
