import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:flutter/material.dart';

class BusInfoCard extends StatelessWidget {
  const BusInfoCard({
    super.key,
    required this.bus,
  });

  final BusEntity bus;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(
        16.w,
        16.h,
        16.w,
        12.h,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 18.w,
        vertical: 16.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: const Color(0xFFE7E8EC),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(.1),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(
              Icons.directions_bus_rounded,
              color: AppColors.primary,
              size: 28.sp,
            ),
          ),

          SizedBox(width: 14.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CustomText(
                  title: bus.busName,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  fontColor: AppColors.primary,
                  textAlign: TextAlign.right,
                ),

                SizedBox(height: 6.h),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CustomText(
                      title: bus.plateNumber,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      fontColor: const Color(0xFF666A73),
                    ),

                    SizedBox(width: 5.w),

                    Icon(
                      Icons.badge_outlined,
                      size: 17.sp,
                      color: const Color(0xFF777B85),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}