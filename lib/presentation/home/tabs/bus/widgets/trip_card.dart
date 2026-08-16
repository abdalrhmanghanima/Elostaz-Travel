import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/domain/trip/entity/trip_entity.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/widgets/trip_actions_bottom_sheet.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/provider/driver_provider.dart';
import 'package:elostaz_travel/presentation/trip/provider/trip_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TripCard extends ConsumerWidget {
  const TripCard({
    super.key,
    required this.trip,
    this.busId,
  });

  final TripEntity trip;
  final String? busId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final netRevenue = trip.revenue - trip.expenses;

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
                  }

                  ref.invalidate(
                    driverTripsProvider(trip.driverId),
                  );

                  ref.invalidate(
                    driversProvider,
                  );
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
            color: Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        title: 'التاريخ',
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w400,
                      ),
                      SizedBox(height: 6.h),
                      CustomText(
                        title:
                        '${trip.createdAt.day}-'
                            '${trip.createdAt.month}-'
                            '${trip.createdAt.year}',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 20.w),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.end,
                    children: [
                      CustomText(
                        title: 'السائق',
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w400,
                      ),
                      SizedBox(height: 6.h),
                      CustomText(
                        title: trip.driverName,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 14.h),

            Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey.shade300,
            ),

            SizedBox(height: 14.h),

            Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        title: 'الإيراد',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w400,
                      ),
                      SizedBox(height: 5.h),
                      CustomText(
                        title:
                        '${trip.revenue.toStringAsFixed(0)} ج.م',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 8.w),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.center,
                    children: [
                      CustomText(
                        title: 'المصروفات',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w400,
                      ),
                      SizedBox(height: 5.h),
                      CustomText(
                        title:
                        '${trip.expenses.toStringAsFixed(0)} ج.م',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 8.w),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.end,
                    children: [
                      CustomText(
                        title: 'الصافي',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      SizedBox(height: 5.h),
                      CustomText(
                        title:
                        '${netRevenue.toStringAsFixed(0)} ج.م',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        fontColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 14.h),

            Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey.shade300,
            ),

            SizedBox(height: 14.h),

            Column(
              crossAxisAlignment:
              CrossAxisAlignment.center,
              children: [
                CustomText(
                  title: 'التفاصيل',
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w400,
                ),
                SizedBox(height: 6.h),
                CustomText(
                  title: trip.details,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w500,
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}