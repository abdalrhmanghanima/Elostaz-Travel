import 'package:elostaz_travel/core/dimens/dimens.dart';
import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/navigator/navigator.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_icons.dart';
import 'package:elostaz_travel/domain/factory/entity/factory_entity.dart';
import 'package:elostaz_travel/presentation/components/custom_svg/custom_svg_icon.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/home/tabs/factory/factory_details_screen.dart';
import 'package:flutter/material.dart';

class FactoryCard extends StatelessWidget {
  final FactoryEntity factory;

  const FactoryCard({
    super.key,
    required this.factory,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => NavigatorHandler.push(
        FactoryDetailsScreen(factory: factory),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        width: Dimens.width,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 14.h,
          ),
          child: Row(
            children: [
              // Arrow
              CustomSvgIcon(
                assetName: AppIcons.arrowBack,
              ),

              SizedBox(width: 12.w),

              // Factory details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CustomText(
                      title: factory.name,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      textAlign: TextAlign.right,
                    ),

                    SizedBox(height: 4.h),

                    if (factory.details.trim().isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: CustomText(
                              title: factory.details,
                              fontSize: 13.sp,
                              fontColor: const Color(0xFF6B7280),
                              maxLines: 1,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.location_on_outlined,
                            size: 14.sp,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                    ],

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(
                              color: const Color(0xFFDCFCE7),
                            ),
                          ),
                          child: CustomText(
                            title:
                                '${factory.totalRevenue.toStringAsFixed(0)} ج.م',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            fontColor: AppColors.green,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(
                              color: const Color(0xFFDBEAFE),
                            ),
                          ),
                          child: CustomText(
                            title: '${factory.tripsCount} رحلة',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            fontColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(width: 14.w),

              // Factory Avatar/Icon
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: const Color(0xFFD0DCFF),
                  ),
                ),
                child: Icon(
                  Icons.factory_outlined,
                  size: 30.sp,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
