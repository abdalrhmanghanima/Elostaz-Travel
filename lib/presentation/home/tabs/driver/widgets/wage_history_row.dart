import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_date_picker.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:flutter/material.dart';

class WageHistoryRow extends StatelessWidget {
  final DateTime date;
  final double amount;
  final String notes;

  const WageHistoryRow({
    super.key,
    required this.date,
    required this.amount,
    required this.notes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE7E8EC)),
      ),
      child: Row(
        children: [
          CustomText(
            title: '${amount.toStringAsFixed(0)} ج.م',
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
            fontColor: AppColors.primary,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: CustomText(
              title: notes.isEmpty ? '-' : notes,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              fontColor: const Color(0xFF666A73),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(width: 10.w),
          CustomText(
            title: AppDateFormatter.format(date),
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            fontColor: const Color(0xFF444444),
          ),
        ],
      ),
    );
  }
}
