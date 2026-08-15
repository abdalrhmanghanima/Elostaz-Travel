import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:flutter/material.dart';

class BusActionsBottomSheet extends StatelessWidget {
  const BusActionsBottomSheet({super.key});

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
            InkWell(
              onTap: () {
                Navigator.pop(context);

                // NavigatorHandler.push(AddTripScreen());
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
                    title: "إضافة رحلة",
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w600,
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
                      Icons.add_rounded,
                      color: AppColors.primary,
                      size: 25.sp,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 20.h),
            InkWell(
              onTap: () {
                Navigator.pop(context);
                // NavigatorHandler.push(EditBusScreen());
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
                    title: "تعديل بيانات الأتوبيس",
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w600,
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
                      Icons.edit_outlined,
                      color: AppColors.primary,
                      size: 23.sp,
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