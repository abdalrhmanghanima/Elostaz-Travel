import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:flutter/material.dart';

class BusInfoItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const BusInfoItem({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomText(
                title: title,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                fontColor: AppColors.darkGray,
              ),
              SizedBox(height: 4.h),
              CustomText(
                title: value,
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),

        SizedBox(width: 8.w),

        Container(
          width: 34.w,
          height: 34.w,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            icon,
            size: 19.sp,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
