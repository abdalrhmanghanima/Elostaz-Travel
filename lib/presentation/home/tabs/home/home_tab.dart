import 'package:elostaz_travel/core/dimens/dimens.dart';
import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_icons.dart';
import 'package:elostaz_travel/presentation/components/custom_app_bar/custom_app_bar.dart';
import 'package:elostaz_travel/presentation/components/custom_svg/custom_svg_icon.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/home/tabs/widgets/custom_valid_container.dart';
import 'package:flutter/material.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: CustomAppBar(
        bgColor: AppColors.primary,
        showToolBar: true,
        title: "Elostaz Travel",
        titlePadding: 12.w,
        fontColor: AppColors.white,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 14.r),
            child: CustomSvgIcon(assetName: AppIcons.notificationWhite),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 12.w,
            right: 12.w,
            top: 20.h,
            bottom: 10.h,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 120.h,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CustomText(
                                  title: "12",
                                  fontSize: 26.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                                CustomValidContainer(
                                  icon: AppIcons.valid,
                                  iconBackgroundColor: AppColors.lightGreen,
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                CustomText(
                                  title: "التراخيص السارية",
                                  fontWeight: FontWeight.w700,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Container(
                      height: 120.h,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CustomText(
                                  title: "15",
                                  fontSize: 26.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                                CustomValidContainer(
                                  icon: AppIcons.bus,
                                  iconBackgroundColor: AppColors.lightGray,
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                CustomText(
                                  title: "إجمالي الأتوبيسات",
                                  fontWeight: FontWeight.w700,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 120.h,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CustomText(
                                  title: "3",
                                  fontSize: 26.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                                CustomValidContainer(
                                  icon: AppIcons.unValid,
                                  iconBackgroundColor: AppColors.lightRed,
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                CustomText(
                                  title: "التراخيص المنتهية",
                                  fontWeight: FontWeight.w700,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Container(
                      height: 120.h,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CustomText(
                                  title: "3",
                                  fontSize: 26.sp,
                                  fontWeight: FontWeight.w700,
                                ),

                                CustomValidContainer(
                                  icon: AppIcons.warning,
                                  iconBackgroundColor: AppColors.lightYellow,
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                CustomText(
                                  title: "تراخيص تنتهي قريبًا",
                                  fontWeight: FontWeight.w700,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18.h),
              Container(
                height: 350.h,
                width: Dimens.width,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Padding(
                  padding: EdgeInsets.only(left: 12.w, right: 12.w, top: 16.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText(
                            title: "عرض الكل",
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            fontColor: AppColors.primary,
                          ),
                          CustomText(
                            title: "يحتاج إجراء",
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      Expanded(
                        child: ListView.builder(
                          itemCount: 4,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: EdgeInsets.only(bottom: 12.h),
                              width: Dimens.width,
                              padding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 14.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.red,
                                    ),
                                  ),

                                  SizedBox(width: 12),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'رخصة السيارة • BUS-014',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          'تنتهي خلال 3 أيام',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: AppColors.red,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 18.h),
              Container(
                width: Dimens.width,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        left: 12.w,
                        right: 12.w,
                        top: 16.h,
                        bottom: 12.h,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CustomText(title: "الملخص المالي", fontSize: 18.sp),
                          SizedBox(width: 8.w),
                          Icon(Icons.wallet),
                        ],
                      ),
                    ),
                    Divider(
                      color: AppColors.backgroundGray,
                      height: 3,
                      thickness: 2,
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: 12.w,
                        right: 12.w,
                        top: 16.h,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              Row(
                                children: [
                                  CustomText(title: "إجمالي أجور السائقين"),
                                  SizedBox(width: 4.w),
                                  CustomSvgIcon(
                                    assetName: AppIcons.down,
                                    height: 10.h,
                                    width: 13.w,
                                  ),
                                ],
                              ),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  CustomText(title: "ج.م", fontSize: 18.sp),
                                  SizedBox(width: 4.w),
                                  CustomText(title: "800", fontSize: 18.sp),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Row(
                                children: [
                                  CustomText(title: "إجمالي إيرادات اليوم"),
                                  SizedBox(width: 4.w),
                                  CustomSvgIcon(
                                    assetName: AppIcons.up,
                                    height: 10.h,
                                    width: 13.w,
                                  ),
                                ],
                              ),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  CustomText(title: "ج.م", fontSize: 18.sp),
                                  SizedBox(width: 4.w),
                                  CustomText(title: "2000", fontSize: 18.sp),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      color: AppColors.backgroundGray,
                      height: 3,
                      thickness: 2,
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: 12.w,
                        right: 12.w,
                        top: 16.h,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              CustomText(title: "إجمالي إيرادات الشهر"),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  CustomText(title: "ج.م", fontSize: 18.sp),
                                  SizedBox(width: 4.w),
                                  CustomText(title: "12,500", fontSize: 18.sp),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              CustomText(title: "صافي إيرادات اليوم"),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  CustomText(title: "ج.م", fontSize: 18.sp),
                                  SizedBox(width: 4.w),
                                  CustomText(title: "1200", fontSize: 18.sp),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
