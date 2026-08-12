import 'package:elostaz_travel/core/dimens/dimens.dart';
import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/utils/app_assets.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_icons.dart';
import 'package:elostaz_travel/presentation/components/custom_app_bar/custom_app_bar.dart';
import 'package:elostaz_travel/presentation/components/custom_asset_image/custom_asset_image.dart';
import 'package:elostaz_travel/presentation/components/custom_svg/custom_svg_icon.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/home/tabs/widgets/custom_valid_text_container.dart';
import 'package:flutter/material.dart';

class BusTab extends StatelessWidget {
  const BusTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        showToolBar: true,
        bgColor: AppColors.primary,
        centerTitle: true,
        title: "الأتوبيسات",
        fontColor: AppColors.white,
        fontSize: 24.sp,
        iconPath: AppIcons.add,
        leadingHeight: 19.h,
      ),
      body: Padding(
        padding: EdgeInsets.only(top: 24.h,left: 16.w,right: 16.w),
        child: ListView.builder(
          itemCount: 5,
          itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            width: Dimens.width,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.only(left: 12.w,top: 8.h,right: 8.h,bottom: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CustomSvgIcon(assetName: AppIcons.arrowBack),
                  SizedBox(width: 20.w,),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomValidTextContainer(text: "ساري", backgroundColor: AppColors.lightGreen),
                            CustomText(title: "BUS-014",fontSize: 20.sp,)
                          ],
                        ),
                        CustomText(title: "Mercedes - 2022",textAlign: TextAlign.end,),
                        CustomText(title: "XYZ 987",textAlign: TextAlign.end,)
                      ],
                    ),
                  ),
                  SizedBox(width: 16.w,),
                  ClipRRect(
                      borderRadius: BorderRadiusGeometry.circular(8.r),
                      child: CustomAssetImage(assetName: AppAssets.bus,width: 80.w,height: 80.w,))
                ],
              ),
            ),
          );
        },),
      ),
    );
  }
}