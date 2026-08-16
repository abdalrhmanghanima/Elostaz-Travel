import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/navigator/navigator.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_entity.dart';
import 'package:elostaz_travel/presentation/components/custom_button/custom_button.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/components/inputs/custom_text_form.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/provider/driver_provider.dart';
import 'package:elostaz_travel/presentation/trip/provider/trip_provider.dart';
import 'package:flutter/material.dart';

import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
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
  ConsumerState<AddTripBottomSheet> createState() =>
      _AddTripBottomSheetState();
}

class _AddTripBottomSheetState
    extends ConsumerState<AddTripBottomSheet> {
  final formKey = GlobalKey<FormState>();

  final detailsController = TextEditingController();
  final revenueController = TextEditingController(text: '0');
  final expensesController = TextEditingController(text: '0');

  DriverEntity? selectedDriver;
  DateTime? selectedDate;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
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
                        title: 'إضافة رحلة',
                        fontSize: 21.sp,
                        fontWeight: FontWeight.w700,
                        fontColor: AppColors.primary,
                      ),

                      const Spacer(),

                      SizedBox(width: 25.w),
                    ],
                  ),

                  SizedBox(height: 22.h),

                  CustomText(
                    title: 'اختر السائق',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    fontColor: const Color(0xFF555555),
                  ),

                  SizedBox(height: 6.h),

                  FormField<DriverEntity>(
                    validator: (value) {
                      if (selectedDriver == null) {
                        return 'من فضلك اختر السائق';
                      }

                      return null;
                    },
                    builder: (field) {
                      return Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 64.h,
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius:
                              BorderRadius.circular(12.r),
                              border: Border.all(
                                color: field.hasError
                                    ? Colors.red
                                    : const Color(0xFFC9CBD1),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<DriverEntity>(
                                value: selectedDriver,
                                isExpanded: true,
                                icon: Icon(
                                  Icons
                                      .keyboard_arrow_down_rounded,
                                  color:
                                  const Color(0xFF777B85),
                                  size: 25.sp,
                                ),
                                hint: CustomText(
                                  title: 'اختر السائق',
                                  fontSize: 14.sp,
                                  fontColor:
                                  const Color(0xFF888C95),
                                ),
                                items: widget.drivers.map((driver) {
                                  return DropdownMenuItem<
                                      DriverEntity>(
                                    value: driver,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 42.w,
                                          height: 42.w,
                                          decoration:
                                          const BoxDecoration(
                                            color:
                                            Color(0xFFF0F2F6),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.person_rounded,
                                            size: 23.sp,
                                            color:
                                            AppColors.primary,
                                          ),
                                        ),

                                        SizedBox(width: 10.w),

                                        CustomText(
                                          title: driver.name,
                                          fontSize: 14.sp,
                                          fontWeight:
                                          FontWeight.w700,
                                          fontColor:
                                          AppColors.primary,
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (driver) {
                                  setState(() {
                                    selectedDriver = driver;
                                  });

                                  field.didChange(driver);
                                },
                              ),
                            ),
                          ),

                          if (field.hasError)
                            Padding(
                              padding: EdgeInsets.only(
                                top: 5.h,
                                right: 8.w,
                              ),
                              child: Text(
                                field.errorText!,
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

                  SizedBox(height: 12.h),

                  CustomText(
                    title: 'تفاصيل الرحلة',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    fontColor: const Color(0xFF555555),
                  ),

                  SizedBox(height: 6.h),

                  CustomTextFormField(
                    controller: detailsController,
                    hint: 'تفاصيل الرحلة',
                    onChange: (_) {
                      formKey.currentState?.validate();
                    },
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'من فضلك أدخل تفاصيل الرحلة';
                      }

                      return null;
                    },
                  ),

                  SizedBox(height: 12.h),

                  CustomText(
                    title: 'إيراد الرحلة',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    fontColor: const Color(0xFF555555),
                  ),

                  SizedBox(height: 6.h),

                  CustomTextFormField(
                    controller: revenueController,
                    textInputType:
                    const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    hint: '0',
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'من فضلك أدخل إيراد الرحلة';
                      }

                      final revenue =
                      parseArabicNumber(value);

                      if (revenue == null) {
                        return 'من فضلك أدخل مبلغ صحيح';
                      }

                      if (revenue < 0) {
                        return 'الإيراد لا يمكن أن يكون أقل من صفر';
                      }

                      return null;
                    },
                    suffix: Padding(
                      padding: EdgeInsets.all(14.w),
                      child: CustomText(
                        title: 'ج.م',
                        fontSize: 13.sp,
                        fontColor:
                        const Color(0xFF777B85),
                      ),
                    ),
                  ),

                  SizedBox(height: 12.h),

                  CustomText(
                    title: 'مصروفات الرحلة',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    fontColor: const Color(0xFF555555),
                  ),

                  SizedBox(height: 6.h),

                  CustomTextFormField(
                    controller: expensesController,
                    textInputType:
                    const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    hint: '0',
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return null;
                      }

                      final expenses =
                      parseArabicNumber(value);

                      if (expenses == null) {
                        return 'من فضلك أدخل مبلغ صحيح';
                      }

                      if (expenses < 0) {
                        return 'المصروفات لا يمكن أن تكون أقل من صفر';
                      }

                      return null;
                    },
                    suffix: Padding(
                      padding: EdgeInsets.all(14.w),
                      child: CustomText(
                        title: 'ج.م',
                        fontSize: 13.sp,
                        fontColor:
                        const Color(0xFF777B85),
                      ),
                    ),
                  ),

                  SizedBox(height: 12.h),

                  CustomText(
                    title: 'تاريخ الرحلة',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    fontColor: const Color(0xFF555555),
                  ),

                  SizedBox(height: 6.h),

                  FormField<DateTime>(
                    validator: (value) {
                      if (selectedDate == null) {
                        return 'من فضلك اختر تاريخ الرحلة';
                      }

                      return null;
                    },
                    builder: (field) {
                      return Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final date =
                              await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );

                              if (date != null) {
                                setState(() {
                                  selectedDate = date;
                                });

                                field.didChange(date);
                              }
                            },
                            child: Container(
                              height: 64.h,
                              width: double.infinity,
                              padding:
                              EdgeInsets.symmetric(
                                horizontal: 14.w,
                              ),
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius:
                                BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: field.hasError
                                      ? Colors.red
                                      : const Color(0xFFC9CBD1),
                                ),
                              ),
                              child: CustomText(
                                title: selectedDate == null
                                    ? 'سنة/شهر/يوم'
                                    : '${selectedDate!.day.toString().padLeft(2, '0')}/'
                                    '${selectedDate!.month.toString().padLeft(2, '0')}/'
                                    '${selectedDate!.year}',
                                fontSize: 16.sp,
                                fontColor: selectedDate == null
                                    ? const Color(0xFF777B85)
                                    : AppColors.primary,
                              ),
                            ),
                          ),

                          if (field.hasError)
                            Padding(
                              padding: EdgeInsets.only(
                                top: 5.h,
                                right: 8.w,
                              ),
                              child: Text(
                                field.errorText!,
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

                  SizedBox(height: 22.h),

                  CustomButton(
                    title: 'حفظ الرحلة',
                    width: double.infinity,
                    height: 58.h,
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
                          parseArabicNumber(
                            revenueController.text,
                          ) ??
                              0;

                      final expenses =
                          parseArabicNumber(
                            expensesController.text,
                          ) ??
                              0;

                      final trip = TripEntity(
                        id: '',
                        driverId: selectedDriver!.id,
                        driverName: selectedDriver!.name,
                        busId: widget.bus.id!,
                        busName: widget.bus.busName,
                        plateNumber: widget.bus.plateNumber,
                        details:
                        detailsController.text.trim(),
                        revenue: revenue,
                        expenses: expenses,
                        createdAt: selectedDate!,
                      );

                      final success = await ref
                          .read(tripProvider.notifier)
                          .addTrip(trip);

                      if (!mounted) return;

                      if (success) {
                        ref.invalidate(
                          busTripsProvider(widget.bus.id!),
                        );

                        ref.invalidate(
                          driverTripsProvider(
                            selectedDriver!.id,
                          ),
                        );

                        ref.invalidate(
                          driversProvider,
                        );

                        NavigatorHandler.pop();
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
