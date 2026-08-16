import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:flutter/material.dart';

class TripActionsBottomSheet extends StatelessWidget {
  const TripActionsBottomSheet({
    super.key,
    required this.onDelete,
  });

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 20.w,
          vertical: 20.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 45.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),

            SizedBox(height: 20.h),

            CustomText(
              title: 'إجراءات الرحلة',
              fontSize: 19.sp,
              fontWeight: FontWeight.w700,
              fontColor: AppColors.primary,
            ),

            SizedBox(height: 20.h),

            InkWell(
              onTap: onDelete,
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20.sp,
                    color: Colors.grey,
                  ),
                  const Spacer(),
                  CustomText(
                    title: 'حذف الرحلة',
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w600,
                    fontColor: AppColors.red,
                  ),
                  SizedBox(width: 16.w),
                  Container(
                    width: 45.w,
                    height: 45.w,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.red,
                      size: 24.sp,
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 24.h),

            InkWell(
              onTap: () {
                Navigator.pop(context);
              },
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20.sp,
                    color: Colors.grey,
                  ),
                  const Spacer(),
                  CustomText(
                    title: 'إلغاء',
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w600,
                    fontColor: AppColors.primary,
                  ),
                  SizedBox(width: 16.w),
                  Container(
                    width: 45.w,
                    height: 45.w,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: AppColors.primary,
                      size: 24.sp,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }
}