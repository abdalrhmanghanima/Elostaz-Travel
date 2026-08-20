import 'dart:io';

import 'package:elostaz_travel/core/dimens/dimens.dart';
import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/navigator/navigator.dart';
import 'package:elostaz_travel/core/services/bus_local_image_service.dart';
import 'package:elostaz_travel/core/services/license_notification_service.dart';
import 'package:elostaz_travel/core/utils/app_assets.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_icons.dart';
import 'package:elostaz_travel/core/utils/custom_loading.dart';
import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/presentation/components/custom_app_bar/custom_app_bar.dart';
import 'package:elostaz_travel/presentation/components/custom_asset_image/custom_asset_image.dart';
import 'package:elostaz_travel/presentation/components/custom_button/custom_button.dart';
import 'package:elostaz_travel/presentation/components/custom_svg/custom_svg_icon.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/bus_trips_screen.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/provider/bus_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/widgets/add_trip_bottom_sheet.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/widgets/bus_action_bottom_sheet.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/widgets/bus_monthly_report_service.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/widgets/delete_bus_bottom_sheet.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/widgets/edit_bus_bottom_sheet.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/widgets/trip_card.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/provider/driver_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/widgets/custom_valid_text_container.dart';
import 'package:elostaz_travel/presentation/trip/provider/trip_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BusDetailsScreen extends ConsumerWidget {
  final BusEntity bus;

  const BusDetailsScreen({super.key, required this.bus});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buses = ref.watch(busProvider).valueOrNull;

    BusEntity currentBus = bus;

    if (buses != null) {
      final index = buses.indexWhere((b) => b.id == bus.id);

      if (index != -1) {
        currentBus = buses[index];
      }
    }
    final localImagesAsync =
        ref.watch(busLocalImagesProvider(currentBus.id!));
    final localBusImage = localImagesAsync.valueOrNull?.busImage;
    final localLicenseImage = localImagesAsync.valueOrNull?.licenseImage;

    final tripsState = ref.watch(busTripsProvider(currentBus.id!));
    final bool isLicenseValid =
        currentBus.licenseExpiryDate.isAfter(DateTime.now());
    final driversState = ref.watch(driversProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        showToolBar: true,
        bgColor: AppColors.primary,
        centerTitle: true,
        title: "بيانات العربية",
        fontColor: AppColors.white,
        fontSize: 24.sp,
        iconPath: AppIcons.arrowLeft,
        onPressed: () {
          NavigatorHandler.pop();
        },
        actions: [
          IconButton(
            onPressed: () {
              tripsState.whenData(
                    (trips) {
                  BusMonthlyReportService
                      .shareCurrentMonthReport(
                    bus: currentBus,
                    trips: trips,
                  );
                },
              );
            },
            icon: Icon(
              Icons.print_outlined,
              color: AppColors.white,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 2.w),
          Padding(
            padding: EdgeInsets.only(right: 4.w),
            child: InkWell(
              borderRadius: BorderRadius.circular(22.r),
              onTap: () async {
                final drivers = driversState.when(
                  loading: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('جاري تحميل السواقين...')),
                    );
                    return null;
                  },
                  error: (error, stackTrace) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('حدث خطأ أثناء تحميل السواقين'),
                      ),
                    );
                    return null;
                  },
                  data: (drivers) => drivers,
                );

                if (drivers == null || !context.mounted) return;

                final action = await showModalBottomSheet<BusActionType>(
                  context: context,
                  backgroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24.r),
                    ),
                  ),
                  builder: (_) => BusActionsBottomSheet(
                    drivers: drivers,
                    bus: currentBus,
                  ),
                );

                if (action == null || !context.mounted) return;

                if (action == BusActionType.addTrip) {
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => AddTripBottomSheet(
                      drivers: drivers,
                      bus: currentBus,
                    )
                  );
                  } else if (action == BusActionType.editBus) {
                    final busNotifier = ref.read(busProvider.notifier);

                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24.r),
                        ),
                      ),
                      builder: (_) => EditBusBottomSheet(
                        bus: currentBus,
                        onSave: ({
                          required String busName,
                          required DateTime licenseExpiryDate,
                          File? busImage,
                          File? licenseImage,
                        }) async {
                          try {
                            final updatedBus = BusEntity(
                              id: currentBus.id,
                              busName: busName,
                              plateNumber: currentBus.plateNumber,
                              brand: currentBus.brand,
                              modelYear: currentBus.modelYear,
                              chassisNumber: currentBus.chassisNumber,
                              engineNumber: currentBus.engineNumber,
                              passengerCount: currentBus.passengerCount,
                              vehicleType: currentBus.vehicleType,
                              licenseExpiryDate: licenseExpiryDate,
                              licenseImageUrl: currentBus.licenseImageUrl,
                              busImageUrl: currentBus.busImageUrl,
                              specialConditions: currentBus.specialConditions,
                              insuranceType: currentBus.insuranceType,
                            );

                            await busNotifier.updateBus(bus: updatedBus);

                            if (currentBus.id != null) {
                              if (busImage != null) {
                                await BusLocalImageService.instance
                                    .saveBusImage(currentBus.id!, busImage);
                              }
                              if (licenseImage != null) {
                                await BusLocalImageService.instance
                                    .saveLicenseImage(currentBus.id!, licenseImage);
                              }
                            }

                            await LicenseNotificationService.instance
                                .rescheduleBusLicenseNotifications(updatedBus);

                            return true;
                          } catch (e) {
                            return false;
                          }
                        },
                      ),
                    );
                  }
                },
                child: SizedBox(
                  width: 44.w,
                  height: 44.h,
                  child: Center(
                    child: CustomSvgIcon(
                      assetName: AppIcons.more,
                      width: 20.w,
                      height: 20.w,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.white,
        onRefresh: () async {
          await Future.wait([
            ref.read(busProvider.notifier).refreshBuses(),
            if (currentBus.id != null)
              ref.refresh(busTripsProvider(currentBus.id!).future),
            if (currentBus.id != null)
              ref.refresh(busLocalImagesProvider(currentBus.id!).future),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 10.h,
              ),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppColors.backgroundGray,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  children: [
                    // =========================
                    // البيانات
                    // =========================
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 6.h,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // اسم العربية
                            _BusInfoItem(
                              title: 'اسم العربية',
                              value: currentBus.busName,
                              icon: Icons.directions_bus_rounded,
                            ),

                            SizedBox(height: 18.h),

                            // نمرة العربية
                            _BusInfoItem(
                              title: 'نمرة العربية',
                              value: currentBus.plateNumber,
                              icon: Icons.confirmation_number_rounded,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // فاصل
                    Container(
                      width: 1.w,
                      height: 90.h,
                      color: AppColors.darkGray.withOpacity(.15),
                    ),

                    SizedBox(width: 10.w),

                    // =========================
                    // صورة الأتوبيس
                    // =========================
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: localBusImage != null
                          ? Image.file(
                        localBusImage,
                        width: 125.w,
                        height: 115.h,
                        fit: BoxFit.cover,
                      )
                          : currentBus.busImageUrl != null &&
                          currentBus.busImageUrl!.isNotEmpty
                          ? Image.network(
                        currentBus.busImageUrl!,
                        width: 125.w,
                        height: 115.h,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return CustomAssetImage(
                            assetName: AppAssets.defaultBus,
                            width: 125.w,
                            height: 115.h,
                          );
                        },
                      )
                          : CustomAssetImage(
                        assetName: AppAssets.defaultBus,
                        width: 125.w,
                        height: 115.h,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 14.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.backgroundGray,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Column(
                    children: [
                      // ================= Header =================
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

                      SizedBox(height: 8.h),

                      Divider(
                        color: AppColors.primary,
                        height: 1,
                      ),

                      SizedBox(height: 16.h),

                      // ================= رقم الشاسية =================
                      Row(
                        textDirection: TextDirection.rtl,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: CustomText(
                                title: "الشاسية",
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: CustomText(
                                title: currentBus.chassisNumber,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                maxLines: 2,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16.h),

                      // ================= رقم الموتور =================
                      Row(
                        textDirection: TextDirection.rtl,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: CustomText(
                                title: "الموتور",
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: CustomText(
                                title: currentBus.engineNumber,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                maxLines: 2,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16.h),

                      // ================= نمرة العربية =================
                      Row(
                        textDirection: TextDirection.rtl,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: CustomText(
                                title: "نمرة العربية",
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: CustomText(
                                title: currentBus.plateNumber,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                maxLines: 2,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16.h),

                      // ================= الموديل =================
                      Row(
                        textDirection: TextDirection.rtl,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: CustomText(
                                title: "الموديل",
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: CustomText(
                                title: "${currentBus.brand} :${currentBus.modelYear}",
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                maxLines: 2,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16.h),

                      // ================= السعة =================
                      Row(
                        textDirection: TextDirection.rtl,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: CustomText(
                                title: "السعة",
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: CustomText(
                                title: "${currentBus.passengerCount}",
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16.h),

                      // ================= النوع =================
                      Row(
                        textDirection: TextDirection.rtl,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: CustomText(
                                title: "النوع",
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: CustomText(
                                title: currentBus.vehicleType,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                maxLines: 2,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16.h),

                      // ================= حالة التأمين =================
                      Row(
                        textDirection: TextDirection.rtl,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: CustomText(
                                title: "حالة التأمين",
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: CustomText(
                                title: currentBus.insuranceType,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                maxLines: 2,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16.h),

                      // ================= اشتراطات خاصة =================
                      Row(
                        textDirection: TextDirection.rtl,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: CustomText(
                                title: "اشتراطات خاصة",
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: CustomText(
                                title: currentBus.specialConditions,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                maxLines: 3,
                              ),
                            ),
                          ),
                        ],
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
                                          child: localLicenseImage != null
                                              ? Image.file(
                                                  localLicenseImage,
                                                  fit: BoxFit.contain,
                                                )
                                              : currentBus.licenseImageUrl != null &&
                                                      currentBus.licenseImageUrl!.isNotEmpty
                                                  ? Image.network(
                                                      currentBus.licenseImageUrl!,
                                                      fit: BoxFit.contain,
                                                      errorBuilder: (_, __, ___) => Image.asset(
                                                        imagePath,
                                                        fit: BoxFit.contain,
                                                      ),
                                                    )
                                                  : Image.asset(
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
                                child: localLicenseImage != null
                                    ? Image.file(
                                        localLicenseImage,
                                        width: 80.w,
                                        height: 64.h,
                                        fit: BoxFit.cover,
                                      )
                                    : currentBus.licenseImageUrl != null &&
                                            currentBus.licenseImageUrl!.isNotEmpty
                                        ? Image.network(
                                            currentBus.licenseImageUrl!,
                                            width: 80.w,
                                            height: 64.h,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => CustomAssetImage(
                                              assetName: AppAssets.plate,
                                              width: 80.w,
                                              height: 64.h,
                                            ),
                                          )
                                        : CustomAssetImage(
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
                                      '${currentBus.licenseExpiryDate.year}-${currentBus.licenseExpiryDate.month.toString().padLeft(2, '0')}-${currentBus.licenseExpiryDate.day.toString().padLeft(2, '0')}',
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
                  InkWell(
                    onTap: (){
                      NavigatorHandler.push(BusTripsScreen(bus: currentBus));
                    },
                    child: CustomText(
                      title: "عرض الكل؟",
                      fontWeight: FontWeight.w700,
                      fontSize: 16.sp,
                      fontColor: AppColors.primary,
                      decoration: TextDecoration.underline,
                    ),
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

                    final displayedTrips = trips.take(3).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: displayedTrips.length,
                          itemBuilder: (context, index) {
                            final trip = displayedTrips[index];

                            return TripCard(
                              trip: trip,
                              busId: currentBus.id!,
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: 16.w,
                right: 16.w,
                bottom: 20.h,
              ),
              child: CustomButton(
                title: "حذف العربية",
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24.r),
                      ),
                    ),
                    builder: (_) {
                      return DeleteBusBottomSheet(
                        onDelete: () async {
                          Navigator.pop(context);

                          if (currentBus.id != null) {
                            await BusLocalImageService.instance
                                .deleteBusImages(currentBus.id!);
                            await LicenseNotificationService.instance
                                .cancelBusLicenseNotifications(currentBus.id!);
                          }

                          final success = await ref
                              .read(busProvider.notifier)
                              .deleteBus(
                            busId: currentBus.id!,
                          );

                          if (!context.mounted) return;

                          if (success) {
                            NavigatorHandler.pop();
                          }
                        },
                      );
                    },
                  );
                },
                bg: AppColors.red,
                fontColor: AppColors.white,
                fontSize: 18.sp,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
class _BusInfoItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _BusInfoItem({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomText(
                title: title,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                fontColor: AppColors.darkGray,
              ),
              SizedBox(height: 4.h),
              CustomText(
                title: value,
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),

        SizedBox(width: 8.w),

        Container(
          width: 34.w,
          height: 34.w,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            icon,
            size: 19.sp,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}