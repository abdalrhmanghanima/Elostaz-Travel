import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:flutter/material.dart';

enum FactoryActionType {
  addTrip,
  editFactory,
  printReport,
  deleteFactory,
}

class FactoryActionsBottomSheet extends StatelessWidget {
  const FactoryActionsBottomSheet({super.key});

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

            // =====================================================
            // ADD TRIP
            // =====================================================
            InkWell(
              onTap: () {
                Navigator.pop(context, FactoryActionType.addTrip);
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
                    title: "إضافة رحلة / وردية",
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w600,
                  ),

                  SizedBox(width: 16.w),

                  Container(
                    width: 45.w,
                    height: 45.w,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: .1),
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

            // =====================================================
            // EDIT FACTORY
            // =====================================================
            InkWell(
              onTap: () {
                Navigator.pop(context, FactoryActionType.editFactory);
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
                    title: "تعديل بيانات المصنع",
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w600,
                  ),

                  SizedBox(width: 16.w),

                  Container(
                    width: 45.w,
                    height: 45.w,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: .1),
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

            Divider(height: 20.h),


            // =====================================================
            // DELETE FACTORY
            // =====================================================
            InkWell(
              onTap: () {
                Navigator.pop(context, FactoryActionType.deleteFactory);
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
                    title: "حذف المصنع",
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w600,
                    fontColor: AppColors.red,
                  ),

                  SizedBox(width: 16.w),

                  Container(
                    width: 45.w,
                    height: 45.w,
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.red,
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
