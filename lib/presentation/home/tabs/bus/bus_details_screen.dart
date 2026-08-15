import 'package:elostaz_travel/core/dimens/dimens.dart';
import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/navigator/navigator.dart';
import 'package:elostaz_travel/core/utils/app_assets.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_icons.dart';
import 'package:elostaz_travel/core/utils/custom_loading.dart';
import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/presentation/components/custom_app_bar/custom_app_bar.dart';
import 'package:elostaz_travel/presentation/components/custom_asset_image/custom_asset_image.dart';
import 'package:elostaz_travel/presentation/components/custom_svg/custom_svg_icon.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/home/tabs/widgets/bus_action_bottom_sheet.dart';
import 'package:elostaz_travel/presentation/home/tabs/widgets/custom_valid_text_container.dart';
import 'package:elostaz_travel/presentation/trip/provider/trip_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BusDetailsScreen extends ConsumerWidget {
  final BusEntity bus;

  const BusDetailsScreen({super.key, required this.bus});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsState = ref.watch(busTripsProvider(bus.id!));
    final bool isLicenseValid = bus.licenseExpiryDate.isAfter(DateTime.now());
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        showToolBar: true,
        bgColor: AppColors.primary,
        centerTitle: true,
        title: "بيانات الأتوبيس",
        fontColor: AppColors.white,
        fontSize: 24.sp,
        iconPath: AppIcons.arrowLeft,
        onPressed: () {
          NavigatorHandler.pop();
        },
        actions: [
          InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24.r),
                  ),
                ),
                builder: (_) => const BusActionsBottomSheet(),
              );
            },
            child: Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: CustomSvgIcon(
                assetName: AppIcons.more,
                width: 20.w,
                height: 20.w,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 16.h),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundGray,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              CustomText(title: bus.busName, fontSize: 18.sp),
                              CustomText(
                                title: " :اسم العربية",
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              CustomText(
                                title: bus.plateNumber,
                                fontSize: 18.sp,
                              ),
                              CustomText(
                                title: " :نمرة العربية",
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: CustomAssetImage(
                        assetName: AppAssets.defaultBus,
                        width: 180.w,
                        height: 160.h,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 18.h),
            Padding(
              padding: EdgeInsets.only(left: 16.w, right: 16.w),
              child: Container(
                width: Dimens.width,
                decoration: BoxDecoration(
                  color: AppColors.backgroundGray,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CustomText(
                            title: "بيانات العربية",
                            fontWeight: FontWeight.w600,
                            fontSize: 18.sp,
                          ),
                          SizedBox(width: 6.w),
                          CustomSvgIcon(
                            assetName: AppIcons.info,
                            width: 16.w,
                            height: 16.w,
                          ),
                        ],
                      ),

                      Divider(color: AppColors.primary),

                      Padding(
                        padding: EdgeInsets.only(right: 8.w, bottom: 12.h),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  CustomText(title: "الموديل", fontSize: 18.sp),
                                  SizedBox(height: 4.h),
                                  CustomText(
                                    title: "${bus.modelYear} :${bus.brand}",
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  CustomText(
                                    title: "نمرة العربية",
                                    fontSize: 18.sp,
                                  ),
                                  SizedBox(height: 4.h),
                                  CustomText(
                                    title: bus.plateNumber,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.only(right: 8.w, bottom: 12.h),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  CustomText(title: "الموتور", fontSize: 18.sp),
                                  SizedBox(height: 4.h),
                                  CustomText(
                                    title: bus.engineNumber,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  CustomText(title: "الشاسية", fontSize: 18.sp),
                                  SizedBox(height: 4.h),
                                  CustomText(
                                    title: bus.chassisNumber,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.only(right: 8.w, bottom: 12.h),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  CustomText(title: "السعة", fontSize: 18.sp),
                                  SizedBox(height: 4.h),
                                  CustomText(
                                    title: "${bus.passengerCount}",
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  CustomText(title: "النوع", fontSize: 18.sp),
                                  SizedBox(height: 4.h),
                                  CustomText(
                                    title: bus.vehicleType,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.only(right: 8.w, bottom: 12.h),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  CustomText(
                                    title: "حالة التأمين",
                                    fontSize: 18.sp,
                                  ),
                                  SizedBox(height: 4.h),
                                  CustomText(
                                    title: bus.insuranceType,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  CustomText(
                                    title: "اشتراطات خاصة",
                                    fontSize: 18.sp,
                                  ),
                                  SizedBox(height: 4.h),
                                  CustomText(
                                    title: bus.specialConditions,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 18.h),
            Padding(
              padding: EdgeInsets.only(left: 16.w, right: 16.w),
              child: Container(
                width: Dimens.width,
                decoration: BoxDecoration(
                  color: AppColors.backgroundGray,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CustomText(
                            title: "الرخصة",
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                          ),
                          SizedBox(width: 8.w),
                          CustomSvgIcon(
                            assetName: AppIcons.plate,
                            width: 16.w,
                            height: 16.w,
                          ),
                        ],
                      ),
                      Divider(color: AppColors.primary),
                      Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  barrierDismissible: true,
                                  barrierColor: Colors.black.withOpacity(.7),
                                  builder: (context) {
                                    final imagePath =
                                        AppAssets.plate.startsWith('assets')
                                        ? AppAssets.plate
                                        : 'assets/images/icons/${AppAssets.plate}.png';

                                    return Dialog(
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      insetPadding: EdgeInsets.all(20.w),
                                      child: InteractiveViewer(
                                        minScale: 1.0,
                                        maxScale: 6.0,
                                        panEnabled: true,
                                        scaleEnabled: true,
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth: 350.w,
                                            maxHeight: 650.h,
                                          ),
                                          child: Image.asset(
                                            imagePath,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16.r),
                                child: CustomAssetImage(
                                  assetName: AppAssets.plate,
                                  width: 80.w,
                                  height: 64.h,
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                CustomText(
                                  title: "تاريخ الانتهاء",
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w400,
                                ),
                                SizedBox(height: 4.h),
                                CustomText(
                                  title:
                                      '${bus.licenseExpiryDate.year}-${bus.licenseExpiryDate.month.toString().padLeft(2, '0')}-${bus.licenseExpiryDate.day.toString().padLeft(2, '0')}',
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                                SizedBox(height: 10.h),
                                CustomValidTextContainer(
                                  text: isLicenseValid ? "ساري" : "منتهي",
                                  fontColor: isLicenseValid
                                      ? AppColors.black
                                      : AppColors.red,
                                  backgroundColor: isLicenseValid
                                      ? AppColors.lightGreen
                                      : AppColors.lightRed,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.only(right: 28.w, left: 24.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CustomText(
                    title: "عرض الكل؟",
                    fontWeight: FontWeight.w700,
                    fontSize: 16.sp,
                    fontColor: AppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                  Spacer(),
                  CustomText(
                    title: "رحلات العربية",
                    fontWeight: FontWeight.w700,
                    fontSize: 16.sp,
                  ),
                  SizedBox(width: 4.w),
                  CustomSvgIcon(
                    assetName: AppIcons.trip,
                    width: 15.w,
                    height: 15.w,
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.only(left: 16.w, right: 16.w),
              child: Container(
                width: Dimens.width,
                decoration: BoxDecoration(
                  color: AppColors.backgroundGray,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: tripsState.when(
                  loading: () => const CustomLoading(),
                  error: (error, stackTrace) =>
                      const Center(child: Text('حدث خطأ في تحميل الرحلات')),
                  data: (trips) {
                    if (trips.isEmpty) {
                      return const Center(
                        child: Text('لا توجد رحلات لهذا الأتوبيس'),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: trips.length,
                      itemBuilder: (context, index) {
                        final trip = trips[index];

                        return Container(
                          width: double.infinity,
                          margin: EdgeInsets.only(bottom: 14.h),
                          padding: EdgeInsets.symmetric(
                            horizontal: 18.w,
                            vertical: 16.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CustomText(
                                          title: "التاريخ",
                                          fontSize: 17.sp,
                                          fontWeight: FontWeight.w400,
                                        ),

                                        SizedBox(height: 6.h),

                                        CustomText(
                                          title:
                                              '${trip.createdAt.day}-'
                                              '${trip.createdAt.month}-'
                                              '${trip.createdAt.year}',
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(width: 20.w),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        CustomText(
                                          title: "السائق",
                                          fontSize: 17.sp,
                                          fontWeight: FontWeight.w400,
                                        ),

                                        SizedBox(height: 6.h),

                                        CustomText(
                                          title: trip.driverName,
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.w600,
                                          textAlign: TextAlign.right,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 14.h),

                              Divider(
                                height: 1,
                                thickness: 1,
                                color: Colors.grey.shade300,
                              ),

                              SizedBox(height: 14.h),

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CustomText(
                                          title: "الإيراد",
                                          fontSize: 17.sp,
                                          fontWeight: FontWeight.w400,
                                        ),

                                        SizedBox(height: 6.h),

                                        CustomText(
                                          title: '${trip.revenue} ج.م',
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(width: 20.w),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        CustomText(
                                          title: "التفاصيل",
                                          fontSize: 17.sp,
                                          fontWeight: FontWeight.w400,
                                        ),

                                        SizedBox(height: 6.h),

                                        CustomText(
                                          title: trip.details,
                                          fontSize: 17.sp,
                                          fontWeight: FontWeight.w500,
                                          textAlign: TextAlign.right,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
