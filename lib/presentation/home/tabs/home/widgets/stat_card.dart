import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/home/tabs/widgets/custom_valid_container.dart';
import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.iconAsset,
    required this.iconBgColor,
    this.onTap,
  });

  final String value;
  final String label;
  final String iconAsset;
  final Color iconBgColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: CustomText(
                    title: value,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    maxLines: 1,
                  ),
                ),

                SizedBox(width: 8.w),

                CustomValidContainer(
                  icon: iconAsset,
                  iconBackgroundColor: iconBgColor,
                ),
              ],
            ),

            SizedBox(height: 10.h),

            Align(
              alignment: Alignment.center,
              child: CustomText(
                title: label,
                fontWeight: FontWeight.w700,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
