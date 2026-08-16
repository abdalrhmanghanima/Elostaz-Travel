import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:flutter/material.dart';

class DeleteDriverBottomSheet extends StatelessWidget {
  const DeleteDriverBottomSheet({super.key, required this.driverName});

  final String driverName;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
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

            SizedBox(height: 24.h),

            Container(
              width: 64.w,
              height: 64.w,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.red,
                size: 32.sp,
              ),
            ),

            SizedBox(height: 16.h),

            CustomText(
              title: 'حذف السواق',
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              fontColor: AppColors.primary,
            ),

            SizedBox(height: 8.h),

            CustomText(
              title: 'هل أنت متأكد أنك تريد حذف السواق $driverName؟',
              fontSize: 14.sp,
              fontColor: const Color(0xFF666A73),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 24.h),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50.h,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context, false);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      child: CustomText(
                        title: 'إلغاء',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        fontColor: AppColors.primary,
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 12.w),

                Expanded(
                  child: SizedBox(
                    height: 50.h,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      child: CustomText(
                        title: 'حذف',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        fontColor: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
