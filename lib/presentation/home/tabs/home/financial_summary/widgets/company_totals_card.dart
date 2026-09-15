import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_icons.dart';
import 'package:elostaz_travel/presentation/components/custom_svg/custom_svg_icon.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/home/tabs/home/financial_summary/provider/company_financial_summary_provider.dart';
import 'package:flutter/material.dart';

class CompanyTotalsCard extends StatelessWidget {
  final CompanyFinancialSummary summary;
  final String Function(double) fmt;

  const CompanyTotalsCard({
    super.key,
    required this.summary,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 14.w, right: 14.w, top: 14.h, bottom: 10.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    'رحلة ${summary.totalTrips}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.green,
                    ),
                  ),
                ),
                Row(
                  children: [
                    CustomText(
                      title: "إجمالي أداء الشركة",
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    SizedBox(width: 8.w),
                    const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: AppColors.backgroundGray, height: 2, thickness: 1.5),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              children: [
                // Total Expenses
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomText(title: "المصروفات", fontSize: 13.sp, fontColor: AppColors.gray),
                          SizedBox(width: 4.w),
                          CustomSvgIcon(assetName: AppIcons.down, height: 10.h, width: 10.w),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomText(title: "ج.م", fontSize: 14.sp),
                          SizedBox(width: 4.w),
                          CustomText(
                            title: fmt(summary.totalExpenses),
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            fontColor: AppColors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(height: 40.h, width: 1, color: AppColors.borderGray),
                // Total Revenue
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomText(title: "الإيرادات", fontSize: 13.sp, fontColor: AppColors.gray),
                          SizedBox(width: 4.w),
                          CustomSvgIcon(assetName: AppIcons.up, height: 10.h, width: 10.w),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomText(title: "ج.م", fontSize: 14.sp),
                          SizedBox(width: 4.w),
                          CustomText(
                            title: fmt(summary.totalRevenue),
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            fontColor: AppColors.black,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (summary.totalDriverWages > 0) ...[
            Divider(color: AppColors.backgroundGray, height: 2, thickness: 1.5),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CustomText(title: "ج.م", fontSize: 13.sp, fontColor: const Color(0xFFB45309)),
                      SizedBox(width: 4.w),
                      CustomText(
                        title: fmt(summary.totalDriverWages),
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        fontColor: const Color(0xFFB45309),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      CustomText(
                        title: "إجمالي أجور السائقين المستحقة",
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        fontColor: const Color(0xFF92400E),
                      ),
                      SizedBox(width: 6.w),
                      Icon(
                        Icons.badge_outlined,
                        size: 16.sp,
                        color: const Color(0xFFD97706),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (summary.totalDriverWagesPaid > 0) ...[
            Divider(color: AppColors.backgroundGray, height: 2, thickness: 1.5),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CustomText(title: "ج.م", fontSize: 13.sp, fontColor: AppColors.red),
                      SizedBox(width: 4.w),
                      CustomText(
                        title: fmt(summary.totalDriverWagesPaid),
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        fontColor: AppColors.red,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      CustomText(
                        title: "أجور السائقين المسددة (المدفوعة)",
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        fontColor: AppColors.red,
                      ),
                      SizedBox(width: 6.w),
                      Icon(
                        Icons.payments_outlined,
                        size: 16.sp,
                        color: AppColors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          Divider(color: AppColors.backgroundGray, height: 2, thickness: 1.5),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CustomText(title: "ج.م", fontSize: 14.sp),
                    SizedBox(width: 4.w),
                    CustomText(
                      title: fmt(summary.totalNetRevenue),
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      fontColor: summary.totalNetRevenue >= 0 ? AppColors.green : AppColors.red,
                    ),
                  ],
                ),
                CustomText(
                  title: "صافي أرباح الشركة",
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
