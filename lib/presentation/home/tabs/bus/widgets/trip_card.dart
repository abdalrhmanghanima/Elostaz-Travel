import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_date_picker.dart';
import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/widgets/trip_actions_bottom_sheet.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/provider/driver_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/factory/provider/factory_provider.dart';
import 'package:elostaz_travel/presentation/trip/provider/trip_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TripCard extends ConsumerWidget {
  const TripCard({
    super.key,
    required this.trip,
    this.busId,
    this.showBus = false,
  });

  final TripEntity trip;
  final String? busId;
  final bool showBus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final netRevenue = trip.revenue - trip.expenses;
    final bool isNight = trip.isNightOuting;
    final bool hasFactory =
        trip.factoryName != null && trip.factoryName!.trim().isNotEmpty;
    final bool hasDepartureTime =
        trip.departureTime != null && trip.departureTime!.trim().isNotEmpty;

    // Date formatting: if year is <= 1970, treat as unspecified
    final effectiveDate = trip.effectiveDate;
    final bool isDateValid = effectiveDate.year > 1970;
    final String formattedDate = isDateValid
        ? AppDateFormatter.format(effectiveDate)
        : 'التاريخ غير محدد';

    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24.r),
            ),
          ),
          builder: (_) {
            return TripActionsBottomSheet(
              onDelete: () async {
                Navigator.pop(context);

                final success = await ref
                    .read(tripProvider.notifier)
                    .deleteTrip(trip.id);

                if (success) {
                  if (busId != null) {
                    ref.invalidate(
                      busTripsProvider(busId!),
                    );
                  } else if (trip.busId.isNotEmpty) {
                    ref.invalidate(
                      busTripsProvider(trip.busId),
                    );
                  }

                  ref.invalidate(
                    driverTripsProvider(trip.driverId),
                  );

                  ref.invalidate(
                    driversProvider,
                  );

                  if (trip.factoryId != null && trip.factoryId!.isNotEmpty) {
                    ref.invalidate(
                      factoryTripsProvider(trip.factoryId!),
                    );
                    ref.invalidate(
                      factoriesProvider,
                    );
                  }
                }
              },
            );
          },
        );
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 14.h),
        padding: EdgeInsets.symmetric(
          horizontal: 18.w,
          vertical: 16.h,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isNight
                ? AppColors.green.withValues(alpha: 0.3)
                : Colors.grey.shade200,
            width: isNight ? 1.2 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Row: Date & Badges (Type Badge + Date + Driver/Bus)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        title: 'التاريخ',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w400,
                        fontColor: const Color(0xFF777B85),
                      ),
                      SizedBox(height: 4.h),
                      CustomText(
                        title: formattedDate,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
                ),

                // Type Badge: رحلة vs سهرة
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: isNight
                        ? const Color(0xFFF0FDF4)
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: isNight
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isNight
                            ? Icons.nightlight_round
                            : Icons.directions_bus_rounded,
                        size: 14.sp,
                        color: isNight ? AppColors.green : AppColors.primary,
                      ),
                      SizedBox(width: 4.w),
                      CustomText(
                        title: trip.typeLabel,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        fontColor: isNight ? AppColors.green : AppColors.primary,
                      ),
                    ],
                  ),
                ),

                // Bus / Driver
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CustomText(
                        title: showBus ? 'الأتوبيس' : 'السائق',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w400,
                        fontColor: const Color(0xFF777B85),
                      ),
                      SizedBox(height: 4.h),
                      CustomText(
                        title: showBus ? trip.busName : trip.driverName,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (showBus && trip.driverName.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomText(
                    title: 'السائق: ${trip.driverName}',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    fontColor: const Color(0xFF555555),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.person_outline_rounded,
                    size: 15.sp,
                    color: const Color(0xFF777B85),
                  ),
                ],
              ),
            ],

            if (!showBus && busId == null && trip.busName.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomText(
                    title: 'الأتوبيس: ${trip.busName}',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    fontColor: const Color(0xFF555555),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.directions_bus_rounded,
                    size: 15.sp,
                    color: const Color(0xFF777B85),
                  ),
                ],
              ),
            ],

            // Factory / Departure Time badge if present
            if (hasFactory || hasDepartureTime) ...[
              SizedBox(height: 10.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 7.h,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: const Color(0xFFD0DCFF),
                  ),
                ),
                child: Row(
                  children: [
                    if (hasFactory) ...[
                      Icon(
                        Icons.factory_outlined,
                        size: 16.sp,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 6.w),
                      CustomText(
                        title: 'المصنع: ',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        fontColor: AppColors.primary,
                      ),
                      Expanded(
                        child: CustomText(
                          title: trip.factoryName!,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          fontColor: AppColors.primary,
                          maxLines: 1,
                        ),
                      ),
                    ],
                    if (hasDepartureTime) ...[
                      if (hasFactory) SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(
                            color: const Color(0xFFD0DCFF),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 13.sp,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 4.w),
                            CustomText(
                              title: trip.departureTime!,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              fontColor: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            SizedBox(height: 12.h),

            Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey.shade300,
            ),

            SizedBox(height: 12.h),

            // Financial Summary
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        title: 'الإيراد',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w400,
                        fontColor: const Color(0xFF777B85),
                      ),
                      SizedBox(height: 4.h),
                      CustomText(
                        title: '${trip.revenue.toStringAsFixed(0)} ج.م',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 8.w),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CustomText(
                        title: 'المصروفات',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w400,
                        fontColor: const Color(0xFF777B85),
                      ),
                      SizedBox(height: 4.h),
                      CustomText(
                        title: '${trip.expenses.toStringAsFixed(0)} ج.م',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 8.w),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CustomText(
                        title: 'الصافي',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        fontColor: const Color(0xFF777B85),
                      ),
                      SizedBox(height: 4.h),
                      CustomText(
                        title: '${netRevenue.toStringAsFixed(0)} ج.م',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        fontColor: netRevenue >= 0
                            ? (isNight ? AppColors.green : AppColors.primary)
                            : AppColors.red,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Normal Expense Details if present
            if (trip.expenseDetails != null &&
                trip.expenseDetails!.trim().isNotEmpty) ...[
              SizedBox(height: 10.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 15.sp,
                      color: const Color(0xFF6B7280),
                    ),
                    SizedBox(width: 6.w),
                    CustomText(
                      title: 'تفاصيل المصروف: ',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      fontColor: const Color(0xFF6B7280),
                    ),
                    Expanded(
                      child: CustomText(
                        title: trip.expenseDetails!,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        fontColor: const Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Legacy Categorized Expenses breakdown if available
            if (trip.expenseItems.isNotEmpty) ...[
              SizedBox(height: 10.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      title: 'تفاصيل المصروفات:',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      fontColor: const Color(0xFF6B7280),
                    ),
                    SizedBox(height: 6.h),
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 6.h,
                      children: trip.expenseItems.map((item) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(
                              color: const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: CustomText(
                            title:
                                '${item.title}: ${item.amount.toStringAsFixed(0)} ج.م',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                            fontColor: const Color(0xFF374151),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],

            // Trip details if present
            if (trip.details.trim().isNotEmpty) ...[
              SizedBox(height: 10.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.notes_rounded,
                      size: 15.sp,
                      color: const Color(0xFF64748B),
                    ),
                    SizedBox(width: 6.w),
                    CustomText(
                      title: isNight ? 'تفاصيل السهرة: ' : 'تفاصيل الرحلة: ',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      fontColor: const Color(0xFF64748B),
                    ),
                    Expanded(
                      child: CustomText(
                        title: trip.details,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        fontColor: const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Legacy Sahra Section for old documents containing embedded sahra fields
            if (trip.hasLegacySahra && !trip.isNightOuting) ...[
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.green.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.nights_stay_rounded,
                          size: 16.sp,
                          color: AppColors.green,
                        ),
                        SizedBox(width: 6.w),
                        CustomText(
                          title: 'بيانات السهرة الملحقة',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          fontColor: AppColors.green,
                        ),
                      ],
                    ),

                    if (trip.sahraDetails != null &&
                        trip.sahraDetails!.trim().isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            title: 'التفاصيل: ',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            fontColor: const Color(0xFF666666),
                          ),
                          Expanded(
                            child: CustomText(
                              title: trip.sahraDetails!,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (trip.sahraDriverName != null &&
                        trip.sahraDriverName!.trim().isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          CustomText(
                            title: 'السائق: ',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            fontColor: const Color(0xFF666666),
                          ),
                          CustomText(
                            title: trip.sahraDriverName!,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            fontColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ],

                    if ((trip.sahraRevenue != null && trip.sahraRevenue! > 0) ||
                        (trip.sahraExpense != null &&
                            trip.sahraExpense! > 0)) ...[
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          if (trip.sahraRevenue != null &&
                              trip.sahraRevenue! > 0)
                            Expanded(
                              child: Row(
                                children: [
                                  CustomText(
                                    title: 'الإيراد: ',
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    fontColor: const Color(0xFF666666),
                                  ),
                                  CustomText(
                                    title:
                                        '${trip.sahraRevenue!.toStringAsFixed(0)} ج.م',
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                    fontColor: AppColors.green,
                                  ),
                                ],
                              ),
                            ),
                          if (trip.sahraExpense != null &&
                              trip.sahraExpense! > 0)
                            Expanded(
                              child: Row(
                                children: [
                                  CustomText(
                                    title: 'المصروف: ',
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    fontColor: const Color(0xFF666666),
                                  ),
                                  CustomText(
                                    title:
                                        '${trip.sahraExpense!.toStringAsFixed(0)} ج.م',
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                    fontColor: AppColors.red,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}