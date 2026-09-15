import 'package:elostaz_travel/core/dimens/dimens.dart';
import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_icons.dart';
import 'package:elostaz_travel/presentation/components/custom_svg/custom_svg_icon.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/home/tabs/home/provider/home_stats_provider.dart';
import 'package:flutter/material.dart';

class FinancialSummaryCard extends StatelessWidget {
  const FinancialSummaryCard({super.key, required this.stats});

  final HomeStats stats;

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Dimens.width,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─────────────────────────────────────────────
          // Header
          // ─────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.only(
              left: 12.w,
              right: 12.w,
              top: 16.h,
              bottom: 12.h,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(
                  Icons.chevron_left,
                  color: AppColors.darkGray,
                  size: 22,
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: CustomText(
                        title: "الملخص المالي (الشهر الحالي)",
                        fontSize: 16.sp,
                        maxLines: 1,
                        textAlign: TextAlign.right,
                      ),
                    ),

                    SizedBox(width: 8.w),

                    const Icon(Icons.wallet),
                  ],
                ),
              ],
            ),
          ),

          Divider(color: AppColors.backgroundGray, height: 3, thickness: 2),

          // ─────────────────────────────────────────────
          // Expenses + Revenue
          // ─────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.only(left: 12.w, right: 12.w, top: 16.h),
            child: Row(
              children: [
                // Expenses
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: CustomText(
                              title: "إجمالي المصروفات",
                              fontSize: 13.sp,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                            ),
                          ),

                          SizedBox(width: 4.w),

                          CustomSvgIcon(
                            assetName: AppIcons.down,
                            height: 10.h,
                            width: 13.w,
                          ),
                        ],
                      ),

                      SizedBox(height: 4.h),

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomText(title: "ج.م", fontSize: 18.sp),

                          SizedBox(width: 4.w),

                          Flexible(
                            child: CustomText(
                              title: _fmt(stats.currentMonthExpenses),
                              fontSize: 18.sp,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 12.w),

                // Revenue
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: CustomText(
                              title: "إجمالي الإيرادات",
                              fontSize: 13.sp,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                            ),
                          ),

                          SizedBox(width: 4.w),

                          CustomSvgIcon(
                            assetName: AppIcons.up,
                            height: 10.h,
                            width: 13.w,
                          ),
                        ],
                      ),

                      SizedBox(height: 4.h),

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomText(title: "ج.م", fontSize: 18.sp),

                          SizedBox(width: 4.w),

                          Flexible(
                            child: CustomText(
                              title: _fmt(stats.currentMonthRevenue),
                              fontSize: 18.sp,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          Divider(color: AppColors.backgroundGray, height: 3, thickness: 2),

          // ─────────────────────────────────────────────
          // Net Revenue + Trips
          // ─────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.only(left: 12.w, right: 12.w, top: 16.h),
            child: Row(
              children: [
                // Net Revenue
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomText(
                        title: "صافي الإيرادات",
                        fontSize: 13.sp,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 4.h),

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomText(title: "ج.م", fontSize: 18.sp),

                          SizedBox(width: 4.w),

                          Flexible(
                            child: CustomText(
                              title: _fmt(stats.currentMonthNetRevenue),
                              fontSize: 18.sp,
                              fontColor: stats.currentMonthNetRevenue >= 0
                                  ? AppColors.green
                                  : AppColors.red,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 12.w),

                // Month Trips
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomText(
                        title: "رحلات الشهر",
                        fontSize: 13.sp,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 4.h),

                      CustomText(
                        title: stats.currentMonthTripCount.toString(),
                        fontSize: 18.sp,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}
