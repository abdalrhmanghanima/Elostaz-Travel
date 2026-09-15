import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:flutter/material.dart';

class FactoryStatItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const FactoryStatItem({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 4.w,
        vertical: 8.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundGray,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14.sp,
            color: iconColor,
          ),
          SizedBox(height: 3.h),
          CustomText(
            title: title,
            fontSize: 9.5.sp,
            fontWeight: FontWeight.w600,
            fontColor: const Color(0xFF666A73),
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
          SizedBox(height: 3.h),
          CustomText(
            title: value,
            fontSize: 12.5.sp,
            fontWeight: FontWeight.w800,
            fontColor: AppColors.black,
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
