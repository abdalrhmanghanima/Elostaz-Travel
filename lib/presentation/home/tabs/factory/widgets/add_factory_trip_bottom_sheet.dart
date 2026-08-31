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

class AddFactoryTripBottomSheet extends ConsumerStatefulWidget {
  const AddFactoryTripBottomSheet({
    super.key,
    required this.factory,
    this.initialType = TripType.trip,
    this.tripToEdit,
  });

  final FactoryEntity factory;
  final String initialType;
  final TripEntity? tripToEdit;

  @override
  ConsumerState<AddFactoryTripBottomSheet> createState() =>
      _AddFactoryTripBottomSheetState();
}

class _AddFactoryTripBottomSheetState
    extends ConsumerState<AddFactoryTripBottomSheet> {
  final formKey = GlobalKey<FormState>();

  final detailsController = TextEditingController();
  final revenueController = TextEditingController();
  final expensesController = TextEditingController();
  final driverWageController = TextEditingController();
  final expenseDetailsController = TextEditingController();

  BusEntity? selectedBus;
  DriverEntity? selectedDriver;
  DateTime? selectedDate = DateTime.now();
  TimeOfDay? departureTime;

  bool get isNightOuting =>
      (widget.tripToEdit?.isNightOuting ?? widget.initialType == TripType.nightOuting);

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
    final busesState = ref.watch(busProvider);
    final driversState = ref.watch(driversProvider);

    final buses = busesState.valueOrNull ?? [];
    final drivers = driversState.valueOrNull ?? [];

    if (widget.tripToEdit != null) {
      if (selectedBus == null && widget.tripToEdit!.busId.isNotEmpty) {
        try {
          selectedBus = buses.firstWhere((b) => b.id == widget.tripToEdit!.busId);
        } catch (_) {}
      }
      if (selectedDriver == null && widget.tripToEdit!.driverId.isNotEmpty) {
        try {
          selectedDriver = drivers.firstWhere((d) => d.id == widget.tripToEdit!.driverId);
        } catch (_) {}
      }
    }

    final title = widget.tripToEdit != null
        ? (isNightOuting ? 'تعديل السهرة' : 'تعديل الرحلة')
        : (isNightOuting ? 'إضافة سهرة جديدة' : 'إضافة رحلة جديدة');
    final primaryColor = isNightOuting ? AppColors.green : AppColors.primary;
    final bgColor = isNightOuting ? const Color(0xFFF0FDF4) : const Color(0xFFF0F4FF);
    final borderColor = isNightOuting ? const Color(0xFFDCFCE7) : const Color(0xFFD0DCFF);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
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
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(Icons.close_rounded, size: 25.sp, color: primaryColor),
                      ),
                      const Spacer(),
                      CustomText(
                        title: title,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        fontColor: primaryColor,
                      ),
                      const Spacer(),
                      SizedBox(width: 25.w),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isNightOuting ? Icons.nightlight_round : Icons.directions_bus_rounded,
                              color: primaryColor,
                              size: 16.sp,
                            ),
                            SizedBox(width: 6.w),
                            CustomText(
                              title: isNightOuting ? 'سهرة' : 'رحلة',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              fontColor: primaryColor,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: CustomText(
                          title: 'المصنع: ${widget.factory.name}',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          fontColor: const Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  CustomText(
                    title: 'اختر الأتوبيس / العربية *',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    fontColor: const Color(0xFF555555),
                  ),
                  SizedBox(height: 6.h),
                  FormField<BusEntity>(
                    validator: (_) => selectedBus == null ? 'من فضلك اختر الأتوبيس' : null,
                    builder: (field) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 64.h,
                          padding: EdgeInsets.symmetric(horizontal: 14.w),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: field.hasError ? Colors.red : const Color(0xFFDCDCDC)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<BusEntity>(
                              isExpanded: true,
                              hint: Row(
                                children: [
                                  Icon(Icons.directions_bus_outlined, color: primaryColor, size: 20.sp),
                                  SizedBox(width: 8.w),
                                  CustomText(title: 'اختر الأتوبيس', fontSize: 14.sp, fontColor: const Color(0xFF888888)),
                                ],
                              ),
                              value: selectedBus,
                              items: buses.map((bus) => DropdownMenuItem<BusEntity>(
                                value: bus,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    CustomText(title: bus.busName, fontSize: 14.sp, fontWeight: FontWeight.w600),
                                    CustomText(title: bus.plateNumber, fontSize: 13.sp, fontColor: const Color(0xFF666666)),
                                  ],
                                ),
                              )).toList(),
                              onChanged: (val) {
                                setState(() => selectedBus = val);
                                field.didChange(val);
                              },
                            ),
                          ),
                        ),
                        if (field.hasError) Padding(padding: EdgeInsets.only(top: 4.h, right: 8.w), child: Text(field.errorText!, style: TextStyle(color: Colors.red, fontSize: 11.sp))),
                      ],
                    ),
                  ),
                  SizedBox(height: 14.h),
                  CustomText(
                    title: 'اختر السواق *',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    fontColor: const Color(0xFF555555),
                  ),
                  SizedBox(height: 6.h),
                  FormField<DriverEntity>(
                    validator: (_) => selectedDriver == null ? 'من فضلك اختر السواق' : null,
                    builder: (field) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 64.h,
                          padding: EdgeInsets.symmetric(horizontal: 14.w),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: field.hasError ? Colors.red : const Color(0xFFDCDCDC)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<DriverEntity>(
                              isExpanded: true,
                              hint: Row(
                                children: [
                                  Icon(Icons.person_outline_rounded, color: primaryColor, size: 20.sp),
                                  SizedBox(width: 8.w),
                                  CustomText(title: 'اختر السواق', fontSize: 14.sp, fontColor: const Color(0xFF888888)),
                                ],
                              ),
                              value: selectedDriver,
                              items: drivers.map((driver) => DropdownMenuItem<DriverEntity>(
                                value: driver,
                                child: CustomText(title: driver.name, fontSize: 14.sp, fontWeight: FontWeight.w600),
                              )).toList(),
                              onChanged: (val) {
                                setState(() => selectedDriver = val);
                                field.didChange(val);
                              },
                            ),
                          ),
                        ),
                        if (field.hasError) Padding(padding: EdgeInsets.only(top: 4.h, right: 8.w), child: Text(field.errorText!, style: TextStyle(color: Colors.red, fontSize: 11.sp))),
                      ],
                    ),
                  ),
                  SizedBox(height: 14.h),
                  CustomText(
                    title: isNightOuting ? 'تفاصيل السهرة (اختياري)' : 'تفاصيل الرحلة / الوردية (اختياري)',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    fontColor: const Color(0xFF555555),
                  ),
                  SizedBox(height: 6.h),
                  CustomTextFormField(
                    controller: detailsController,
                    hint: isNightOuting ? 'مثال: سهرة خط الهرم وردية ليلية...' : 'مثال: وردية صباحية من 7 ص إلى 3 م...',
                    prefix: Icon(Icons.description_outlined, size: 22.sp, color: const Color(0xFF777B85)),
                  ),
                  SizedBox(height: 14.h),
                  CustomText(
                    title: isNightOuting ? 'تاريخ السهرة (اختياري)' : 'تاريخ الرحلة (اختياري)',
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
                        helpText: isNightOuting ? 'اختر تاريخ السهرة' : 'اختر تاريخ الرحلة',
                      );
                      if (picked != null) setState(() => selectedDate = picked);
                    },
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      height: 52.h,
                      padding: EdgeInsets.symmetric(horizontal: 14.w),
                      decoration: BoxDecoration(color: AppColors.inputBg, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: const Color(0xFFE0E0E0))),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 18.sp, color: primaryColor),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: CustomText(
                              title: selectedDate != null ? AppDateFormatter.format(selectedDate!) : 'التاريخ غير محدد (اضغط للاختيار)',
                              fontSize: 14.sp,
                              fontWeight: selectedDate != null ? FontWeight.w600 : FontWeight.w400,
                              fontColor: selectedDate != null ? Colors.black87 : const Color(0xFF888888),
                            ),
                          ),
                          if (selectedDate != null) GestureDetector(onTap: () => setState(() => selectedDate = null), child: Icon(Icons.close_rounded, size: 18.sp, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  CustomText(
                    title: 'وقت الخروج من المصنع (اختياري)',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    fontColor: const Color(0xFF555555),
                  ),
                  SizedBox(height: 6.h),
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: departureTime ?? TimeOfDay.now(), helpText: 'اختر وقت الخروج من المصنع');
                      if (picked != null) setState(() => departureTime = picked);
                    },
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      height: 52.h,
                      padding: EdgeInsets.symmetric(horizontal: 14.w),
                      decoration: BoxDecoration(color: AppColors.inputBg, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: const Color(0xFFE0E0E0))),
                      child: Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 20.sp, color: primaryColor),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: CustomText(
                              title: departureTime != null ? _formatTimeOfDay(departureTime!) : 'اختر وقت الخروج (اختياري)',
                              fontSize: 14.sp,
                              fontWeight: departureTime != null ? FontWeight.w600 : FontWeight.w400,
                              fontColor: departureTime != null ? primaryColor : const Color(0xFF888888),
                            ),
                          ),
                          if (departureTime != null) GestureDetector(onTap: () => setState(() => departureTime = null), child: Icon(Icons.close_rounded, size: 20.sp, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  // =================== REVENUE ===================
                  CustomText(
                    title: isNightOuting ? 'إيراد السهرة (ج.م) (اختياري)' : 'إيراد الوردية / الرحلة (ج.م) (اختياري)',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    fontColor: const Color(0xFF555555),
                  ),
                  SizedBox(height: 6.h),
                  CustomTextFormField(
                    controller: revenueController,
                    hint: '0',
                    textInputType: const TextInputType.numberWithOptions(decimal: true),
                    prefix: Icon(Icons.attach_money_rounded, size: 22.sp, color: const Color(0xFF777B85)),
                    validator: (value) => (value != null && value.trim().isNotEmpty && parseArabicNumber(value) == null) ? 'أدخل رقم صحيح' : null,
                  ),
                  SizedBox(height: 14.h),

                  // =================== DRIVER WAGE ===================
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
                    textInputType: const TextInputType.numberWithOptions(decimal: true),
                    prefix: Icon(Icons.badge_outlined, size: 22.sp, color: const Color(0xFF777B85)),
                    validator: (value) => (value != null && value.trim().isNotEmpty && parseArabicNumber(value) == null) ? 'أدخل رقم صحيح' : null,
                  ),
                  SizedBox(height: 14.h),

                  // =================== EXPENSES ===================
                  CustomText(
                    title: isNightOuting ? 'مصروف السهرة (ج.م) (اختياري)' : 'مصروف الرحلة (ج.م) (اختياري)',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    fontColor: const Color(0xFF555555),
                  ),
                  SizedBox(height: 6.h),
                  CustomTextFormField(
                    controller: expensesController,
                    hint: '0',
                    textInputType: const TextInputType.numberWithOptions(decimal: true),
                    prefix: Icon(Icons.money_off_rounded, size: 22.sp, color: const Color(0xFF777B85)),
                    validator: (value) => (value != null && value.trim().isNotEmpty && parseArabicNumber(value) == null) ? 'أدخل رقم صحيح' : null,
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
                    prefix: Icon(Icons.notes_rounded, size: 22.sp, color: const Color(0xFF777B85)),
                  ),
                  SizedBox(height: 24.h),
                  CustomButton(
                    title: widget.tripToEdit != null
                        ? 'حفظ التعديلات'
                        : (isNightOuting ? 'حفظ السهرة' : 'حفظ الرحلة'),
                    width: double.infinity,
                    height: 56.h,
                    bg: primaryColor,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    fontColor: AppColors.white,
                    radius: 12.r,
                    elevation: 0,
                    isLoading: tripState.isLoading,
                    onTap: () async {
                      if (!formKey.currentState!.validate()) return;
                      final revenue = parseArabicNumber(revenueController.text) ?? 0.0;
                      final expenses = parseArabicNumber(expensesController.text) ?? 0.0;
                      final driverWage = parseArabicNumber(driverWageController.text);

                      final trip = TripEntity(
                        id: widget.tripToEdit?.id ?? '',
                        driverId: selectedDriver!.id,
                        driverName: selectedDriver!.name,
                        busId: selectedBus!.id ?? '',
                        busName: selectedBus!.busName,
                        plateNumber: selectedBus!.plateNumber,
                        details: detailsController.text.trim(),
                        revenue: revenue,
                        expenses: expenses,
                        driverWage: driverWage,
                        expenseDetails: expenseDetailsController.text.trim().isNotEmpty ? expenseDetailsController.text.trim() : null,
                        factoryId: widget.factory.id,
                        factoryName: widget.factory.name,
                        departureTime: departureTime != null
                            ? _formatTimeOfDay(departureTime!)
                            : (widget.tripToEdit?.departureTime),
                        type: isNightOuting ? TripType.nightOuting : TripType.trip,
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
                        ref.invalidate(factoryTripsProvider(widget.factory.id));
                        ref.invalidate(busTripsProvider(selectedBus!.id ?? ''));
                        ref.invalidate(driverTripsProvider(selectedDriver!.id));
                        if (widget.tripToEdit != null && widget.tripToEdit!.driverId != selectedDriver!.id) {
                          ref.invalidate(driverTripsProvider(widget.tripToEdit!.driverId));
                        }
                        if (widget.tripToEdit != null && widget.tripToEdit!.busId != selectedBus!.id) {
                          ref.invalidate(busTripsProvider(widget.tripToEdit!.busId));
                        }
                        ref.invalidate(factoriesProvider);
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
