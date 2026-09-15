import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_date_picker.dart';
import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_entity.dart';
import 'package:elostaz_travel/domain/factory/entity/factory_entity.dart';
import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/domain/trip/validation/trip_date_rule.dart';
import 'package:elostaz_travel/presentation/components/custom_button/custom_button.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/components/inputs/custom_text_form.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/provider/bus_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/provider/driver_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/factory/provider/factory_provider.dart';
import 'package:elostaz_travel/presentation/trip/provider/trip_provider.dart';
import 'package:elostaz_travel/presentation/trip/provider/paginated_trips_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddTripBottomSheet extends ConsumerStatefulWidget {
  const AddTripBottomSheet({
    super.key,
    required this.drivers,
    required this.bus,
    this.tripToEdit,
  });

  final List<DriverEntity> drivers;
  final BusEntity bus;
  final TripEntity? tripToEdit;

  @override
  ConsumerState<AddTripBottomSheet> createState() => _AddTripBottomSheetState();
}

class _AddTripBottomSheetState extends ConsumerState<AddTripBottomSheet> {
  final formKey = GlobalKey<FormState>();

  final detailsController = TextEditingController();
  final revenueController = TextEditingController();
  final expensesController = TextEditingController();
  final driverWageController = TextEditingController();
  final expenseDetailsController = TextEditingController();

  DriverEntity? selectedDriver;
  FactoryEntity? selectedFactory;
  DateTime? selectedDate = DateTime.now();
  TimeOfDay? departureTime;

  @override
  void initState() {
    super.initState();
    if (widget.tripToEdit != null) {
      final trip = widget.tripToEdit!;
      detailsController.text = trip.details;
      if (trip.revenue > 0) {
        revenueController.text = trip.revenue % 1 == 0
            ? trip.revenue.toInt().toString()
            : trip.revenue.toString();
      }
      if (trip.expenses > 0) {
        expensesController.text = trip.expenses % 1 == 0
            ? trip.expenses.toInt().toString()
            : trip.expenses.toString();
      }
      if (trip.driverWage != null && trip.driverWage! > 0) {
        driverWageController.text = trip.driverWage! % 1 == 0
            ? trip.driverWage!.toInt().toString()
            : trip.driverWage!.toString();
      }
      expenseDetailsController.text = trip.expenseDetails ?? '';
      selectedDate = trip.tripDate ?? trip.createdAt;

      try {
        selectedDriver = widget.drivers.firstWhere(
          (d) => d.id == trip.driverId,
        );
      } catch (_) {}
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'ص' : 'م';
    return '$hour:$minute $period';
  }

  double? parseArabicNumber(String value) {
    if (value.trim().isEmpty) return null;
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
    driverWageController.dispose();
    expenseDetailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripProvider);
    final factoriesState = ref.watch(factoriesProvider);
    final factories = factoriesState.valueOrNull ?? [];

    if (widget.tripToEdit != null && selectedFactory == null && widget.tripToEdit!.factoryId != null) {
      try {
        selectedFactory = factories.firstWhere(
          (f) => f.id == widget.tripToEdit!.factoryId,
        );
      } catch (_) {}
    }

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

                  SizedBox(height: 10.h),

                  // Bus Info Badge (Automatically selected)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: const Color(0xFFD0DCFF)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.directions_bus_rounded,
                          color: AppColors.primary,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        CustomText(
                          title: 'الأتوبيس: ',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          fontColor: AppColors.primary,
                        ),
                        Expanded(
                          child: CustomText(
                            title: '${widget.bus.busName} (${widget.bus.plateNumber})',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            fontColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // =================== DRIVER SELECTION (REQUIRED) ===================
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

                  // =================== FACTORY SELECTION (OPTIONAL) ===================
                  CustomText(
                    title: 'المصنع (اختياري)',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    fontColor: const Color(0xFF555555),
                  ),

                  SizedBox(height: 6.h),

                  Container(
                    height: 64.h,
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: const Color(0xFFDCDCDC)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<FactoryEntity?>(
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
                          DropdownMenuItem<FactoryEntity?>(
                            value: null,
                            child: CustomText(
                              title: 'بدون مصنع (رحلة عامة)',
                              fontSize: 14.sp,
                              fontColor: const Color(0xFF888888),
                            ),
                          ),
                          ...factories.map((factory) {
                            return DropdownMenuItem<FactoryEntity?>(
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

                  // =================== DETAILS (OPTIONAL) ===================
                  CustomText(
                    title: 'تفاصيل الرحلة (اختياري)',
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
                  ),

                  SizedBox(height: 14.h),

                  // =================== DATE PICKER (OPTIONAL) ===================
                  CustomText(
                    title: 'تاريخ الرحلة (اختياري)',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    fontColor: const Color(0xFF555555),
                  ),

                  SizedBox(height: 6.h),

                  InkWell(
                    onTap: () async {
                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);
                      var initial = selectedDate ?? today;
                      if (initial.isAfter(today)) initial = today;
                      if (initial.isBefore(DateTime(2020))) {
                        initial = DateTime(2020);
                      }
                      final picked = await AppDatePicker.show(
                        context,
                        initialDate: initial,
                        firstDate: DateTime(2020),
                        lastDate: today,
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
                          Expanded(
                            child: CustomText(
                              title: selectedDate != null
                                  ? AppDateFormatter.format(selectedDate!)
                                  : 'التاريخ غير محدد (اضغط للاختيار)',
                              fontSize: 14.sp,
                              fontWeight: selectedDate != null
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              fontColor: selectedDate != null
                                  ? Colors.black87
                                  : const Color(0xFF888888),
                            ),
                          ),
                          if (selectedDate != null)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedDate = null;
                                });
                              },
                              child: Icon(
                                Icons.close_rounded,
                                size: 18.sp,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 14.h),

                  // =================== TIME (OPTIONAL) ===================
                  CustomText(
                    title: 'وقت الرحلة / الخروج (اختياري)',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    fontColor: const Color(0xFF555555),
                  ),

                  SizedBox(height: 6.h),

                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: departureTime ?? TimeOfDay.now(),
                        helpText: 'اختر وقت الرحلة',
                      );
                      if (picked != null) {
                        setState(() {
                          departureTime = picked;
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
                            Icons.access_time_rounded,
                            size: 20.sp,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: CustomText(
                              title: departureTime != null
                                  ? _formatTimeOfDay(departureTime!)
                                  : 'اختر وقت الرحلة (اختياري)',
                              fontSize: 14.sp,
                              fontWeight: departureTime != null
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              fontColor: departureTime != null
                                  ? AppColors.primary
                                  : const Color(0xFF888888),
                            ),
                          ),
                          if (departureTime != null)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  departureTime = null;
                                });
                              },
                              child: Icon(
                                Icons.close_rounded,
                                size: 20.sp,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 14.h),

                  // =================== REVENUE (OPTIONAL) ===================
                  CustomText(
                    title: 'إيراد الرحلة (ج.م) (اختياري)',
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
                      if (value != null &&
                          value.trim().isNotEmpty &&
                          parseArabicNumber(value) == null) {
                        return 'أدخل رقم صحيح';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 14.h),

                  // =================== DRIVER WAGE (OPTIONAL) ===================
                  CustomText(
                    title: 'أجر السائق (ج.م) (اختياري)',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    fontColor: const Color(0xFF555555),
                  ),

                  SizedBox(height: 6.h),

                  CustomTextFormField(
                    controller: driverWageController,
                    hint: '0',
                    textInputType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    prefix: Icon(
                      Icons.badge_outlined,
                      size: 22.sp,
                      color: const Color(0xFF777B85),
                    ),
                    validator: (value) {
                      if (value != null &&
                          value.trim().isNotEmpty &&
                          parseArabicNumber(value) == null) {
                        return 'أدخل رقم صحيح';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 14.h),

                  // =================== EXPENSES (OPTIONAL) ===================
                  CustomText(
                    title: 'مصروف الرحلة (ج.م) (اختياري)',
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
                    validator: (value) {
                      if (value != null &&
                          value.trim().isNotEmpty &&
                          parseArabicNumber(value) == null) {
                        return 'أدخل رقم صحيح';
                      }
                      return null;
                    },
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

                  SizedBox(height: 24.h),

                  // =================== SUBMIT BUTTON ===================
                  CustomButton(
                    title: widget.tripToEdit != null ? 'حفظ التعديلات' : 'حفظ الرحلة',
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

                      if (selectedDate != null) {
                        final dateError =
                            TripDateRule.errorFor(selectedDate!);
                        if (dateError != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(dateError)),
                          );
                          return;
                        }
                      }

                      final revenue =
                          parseArabicNumber(revenueController.text) ?? 0.0;
                      final expenses =
                          parseArabicNumber(expensesController.text) ?? 0.0;
                      final driverWage =
                          parseArabicNumber(driverWageController.text);

                      final trip = TripEntity(
                        id: widget.tripToEdit?.id ?? '',
                        driverId: selectedDriver!.id,
                        driverName: selectedDriver!.name,
                        busId: widget.bus.id ?? '',
                        busName: widget.bus.busName,
                        plateNumber: widget.bus.plateNumber,
                        details: detailsController.text.trim(),
                        revenue: revenue,
                        expenses: expenses,
                        driverWage: driverWage,
                        expenseDetails:
                            expenseDetailsController.text.trim().isNotEmpty
                                ? expenseDetailsController.text.trim()
                                : null,
                        factoryId: selectedFactory?.id,
                        factoryName: selectedFactory?.name,
                        departureTime: departureTime != null
                            ? _formatTimeOfDay(departureTime!)
                            : (widget.tripToEdit?.departureTime),
                        type: widget.tripToEdit?.type ?? TripType.trip,
                        tripDate: selectedDate,
                        createdAt: widget.tripToEdit?.createdAt ?? (selectedDate ?? DateTime.now()),
                      );

                      final bool success;
                      if (widget.tripToEdit != null) {
                        success = await ref.read(tripProvider.notifier).updateTrip(trip);
                      } else {
                        success = await ref.read(tripProvider.notifier).addTrip(trip);
                      }

                      if (!context.mounted) return;

                      if (success) {
                        ref.invalidate(busTripsProvider(widget.bus.id ?? ''));
                        ref.invalidate(busTripsLimitedProvider(widget.bus.id ?? ''));
                        ref.invalidate(busPaginatedTripsProvider(
                            PaginatedTripsRequest(entityId: widget.bus.id ?? '')));
                        ref.invalidate(driverTripsProvider(selectedDriver!.id));
                        ref.invalidate(driverTripsLimitedProvider(selectedDriver!.id));
                        ref.invalidate(driverPaginatedTripsProvider(
                            PaginatedTripsRequest(entityId: selectedDriver!.id)));
                        if (widget.tripToEdit != null && widget.tripToEdit!.driverId != selectedDriver!.id) {
                          ref.invalidate(driverTripsProvider(widget.tripToEdit!.driverId));
                          ref.invalidate(driverTripsLimitedProvider(widget.tripToEdit!.driverId));
                          ref.invalidate(driverPaginatedTripsProvider(
                              PaginatedTripsRequest(entityId: widget.tripToEdit!.driverId)));
                        }
                        if (selectedFactory != null) {
                          ref.invalidate(
                              factoryTripsProvider(selectedFactory!.id));
                          ref.invalidate(
                              factoryTripsLimitedProvider(selectedFactory!.id));
                          ref.invalidate(
                              factoryPaginatedTripsProvider(
                                  PaginatedTripsRequest(entityId: selectedFactory!.id)));
                          ref.invalidate(factoriesProvider);
                        }
                        if (widget.tripToEdit?.factoryId != null) {
                          ref.invalidate(
                              factoryTripsProvider(widget.tripToEdit!.factoryId!));
                          ref.invalidate(
                              factoryTripsLimitedProvider(widget.tripToEdit!.factoryId!));
                          ref.invalidate(
                              factoryPaginatedTripsProvider(
                                  PaginatedTripsRequest(entityId: widget.tripToEdit!.factoryId!)));
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

