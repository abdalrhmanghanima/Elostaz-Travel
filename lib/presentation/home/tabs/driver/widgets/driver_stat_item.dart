import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:flutter/material.dart';

class DriverStatItem extends StatelessWidget {
  final String title;
  final String value;

  const DriverStatItem({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 8.w,
        vertical: 10.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundGray,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomText(
            title: title,
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            fontColor: const Color(0xFF666A73),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 5.h),
          CustomText(
            title: value,
            fontSize: 17.sp,
            fontWeight: FontWeight.w800,
            fontColor: AppColors.primary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
