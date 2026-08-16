import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/presentation/components/custom_button/custom_button.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/provider/bus_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeleteBusBottomSheet extends ConsumerWidget {
  const DeleteBusBottomSheet({super.key, required this.onDelete});

  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busState = ref.watch(busProvider);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
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
              title: 'حذف العربية',
              fontSize: 19.sp,
              fontWeight: FontWeight.w700,
              fontColor: AppColors.primary,
            ),

            SizedBox(height: 10.h),

            CustomText(
              title: 'هل أنت متأكد أنك تريد حذف هذه العربية؟',
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              textAlign: TextAlign.center,
              fontColor: const Color(0xFF666A73),
            ),

            SizedBox(height: 24.h),

            CustomButton(
              isLoading: busState.isLoading,
              title: 'حذف العربية',
              onTap: onDelete,
              width: double.infinity,
              height: 52.h,
              bg: AppColors.red,
              fontColor: AppColors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              radius: 12.r,
            ),

            SizedBox(height: 10.h),

            CustomButton(
              title: 'إلغاء',
              onTap: () {
                Navigator.pop(context);
              },
              width: double.infinity,
              height: 52.h,
              bg: AppColors.backgroundGray,
              fontColor: AppColors.primary,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              radius: 12.r,
            ),

            SizedBox(height: 5.h),
          ],
        ),
      ),
    );
  }
}
