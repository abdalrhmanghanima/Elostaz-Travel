import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:flutter/material.dart';

class EmptyWageBox extends StatelessWidget {
  final String title;

  const EmptyWageBox({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 20.h),
      decoration: BoxDecoration(
        color: AppColors.backgroundGray,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Center(
        child: CustomText(
          title: title,
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          fontColor: const Color(0xFF999999),
        ),
      ),
    );
  }
}
