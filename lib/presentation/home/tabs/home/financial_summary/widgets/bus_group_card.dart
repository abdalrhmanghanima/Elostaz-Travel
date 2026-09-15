import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_icons.dart';
import 'package:elostaz_travel/presentation/components/custom_svg/custom_svg_icon.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/home/tabs/home/financial_summary/provider/company_financial_summary_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/home/financial_summary/widgets/trip_financial_item.dart';
import 'package:flutter/material.dart';

class BusGroupCard extends StatelessWidget {
  final BusFinancialGroup group;
  final String Function(double) fmt;
  final String Function(DateTime) formatDate;

  const BusGroupCard({
    super.key,
    required this.group,
    required this.fmt,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Bus Header ──────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'لوحة: ${group.plateNumber}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      group.busName,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    CustomSvgIcon(
                      assetName: AppIcons.bus,
                      height: 18.h,
                      width: 18.w,
                      color: AppColors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Trips List for this Bus ─────────────────────────────────────
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: group.trips.length,
            separatorBuilder: (_, __) => Divider(
              color: AppColors.backgroundGray,
              height: 1,
              thickness: 1,
            ),
            itemBuilder: (context, idx) {
              final trip = group.trips[idx];
              final tripNet = trip.revenue - trip.expenses;

              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 10.h,
                ),
                child: Column(
                  children: [
                    // Driver + Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText(
                          title: formatDate(trip.createdAt),
                          fontSize: 12.sp,
                          fontColor: AppColors.darkGray,
                        ),

                        Row(
                          children: [
                            CustomText(
                              title: trip.driverName,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              fontColor: AppColors.black,
                            ),
                            SizedBox(width: 6.w),
                            Icon(
                              Icons.person_outline,
                              size: 16.sp,
                              color: AppColors.gray,
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Trip Details
                    if (trip.details.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Align(
                        alignment: Alignment.centerRight,
                        child: CustomText(
                          title: trip.details,
                          fontSize: 12.sp,
                          fontColor: AppColors.gray,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],

                    SizedBox(height: 8.h),

                    // Financial Information
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        children: [
                          // الإيراد - ناحية اليمين
                          Expanded(
                            child: TripFinancialItem(
                              label: ':الإيراد',
                              value: fmt(trip.revenue),
                              valueColor: AppColors.black,
                            ),
                          ),

                          // المصروف - في المنتصف
                          Expanded(
                            child: TripFinancialItem(
                              label: 'المصروف',
                              value: fmt(trip.expenses),
                              valueColor: AppColors.red,
                            ),
                          ),

                          SizedBox(width: 8.w),

                          // الصافي - ناحية الشمال
                          Expanded(
                            child: TripFinancialItem(
                              label: ':الصافي',
                              value: fmt(tripNet),
                              valueColor: tripNet >= 0
                                  ? AppColors.green
                                  : AppColors.red,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Driver Wage if entered
                    if (trip.driverWage != null && trip.driverWage! > 0) ...[
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(color: const Color(0xFFFDE68A), width: 0.8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${fmt(trip.driverWage!)} ج.م',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  'أجر السائق (مستحق)',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF92400E),
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Icon(
                                  Icons.badge_outlined,
                                  size: 13.sp,
                                  color: const Color(0xFFD97706),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),

          // ── Bus Subtotals Bar ───────────────────────────────────────────
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 10.h,
            ),
            decoration: BoxDecoration(
              color: AppColors.backgroundGray,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16.r),
                bottomRight: Radius.circular(16.r),
              ),
              border: Border(
                top: BorderSide(
                  color: AppColors.borderGray,
                  width: 0.8,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // صافي الأتوبيس
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'صافي الأتوبيس',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkGray,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${fmt(group.busNet)} ج.م',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: group.busNet >= 0
                                  ? AppColors.green
                                  : AppColors.red,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 8.w),

                    // المصروف
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'المصروف',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.darkGray,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${fmt(group.busExpenses)} ج.م',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.red,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 8.w),

                    // الإيراد
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'الإيراد',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.darkGray,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${fmt(group.busRevenue)} ج.م',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (group.busDriverWages > 0) ...[
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${fmt(group.busDriverWages)} ج.م',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'أجور السائقين للأتوبيس:',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          )
        ],
      ),
    );
  }
}
