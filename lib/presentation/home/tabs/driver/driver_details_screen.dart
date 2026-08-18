import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:elostaz_travel/core/navigator/navigator.dart';
import 'package:elostaz_travel/core/utils/app_colors.dart';
import 'package:elostaz_travel/core/utils/app_icons.dart';
import 'package:elostaz_travel/core/utils/custom_loading.dart';
import 'package:elostaz_travel/domain/driver/entity/driver_entity.dart';
import 'package:elostaz_travel/presentation/components/custom_app_bar/custom_app_bar.dart';
import 'package:elostaz_travel/presentation/components/custom_text/custom_text.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/widgets/trip_card.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/provider/driver_provider.dart';
import 'package:elostaz_travel/presentation/home/tabs/driver/widgets/driver_monthly_report_service.dart';
import 'package:elostaz_travel/presentation/trip/provider/trip_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DriverDetailsScreen extends ConsumerWidget {
  final DriverEntity driver;

  const DriverDetailsScreen({
    super.key,
    required this.driver,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsState = ref.watch(
      driverTripsProvider(driver.id),
    );

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        showToolBar: true,
        bgColor: AppColors.primary,
        centerTitle: true,
        title: 'بيانات السواق',
        fontColor: AppColors.white,
        fontSize: 22.sp,
        iconPath: AppIcons.arrowLeft,
        onPressed: () {
          NavigatorHandler.pop();
        },
        actions: [
          IconButton(
            onPressed: tripsState.hasValue
                ? () async {
              await DriverMonthlyReportService.shareCurrentMonthReport(
                driver: driver,
                trips: tripsState.value!,
              );
            }
                : null,
            icon: Icon(
              Icons.print_outlined,
              color: AppColors.white,
              size: 24.sp,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.white,
        onRefresh: () async {
          await Future.wait([
            ref.read(driversProvider.notifier).getDrivers(),
            ref.refresh(driverTripsProvider(driver.id).future),
          ]);
        },
        child: tripsState.when(
          loading: () => const Center(
            child: CustomLoading(),
          ),

          error: (error, stackTrace) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: 150.h),
              Center(
                child: CustomText(
                  title: 'حدث خطأ في تحميل الرحلات',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          data: (trips) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                top: 24.h,
                right: 20.w,
                left: 20.w,
                bottom: 24.h,
              ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 18.w,
                    vertical: 18.h,
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
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 82.w,
                        height: 82.w,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F2F6),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE3E6EC),
                            width: 3.w,
                          ),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          size: 43.sp,
                          color: AppColors.primary,
                        ),
                      ),

                      SizedBox(height: 12.h),

                      CustomText(
                        title: driver.name,
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w700,
                        fontColor: AppColors.primary,
                      ),

                      SizedBox(height: 6.h),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomText(
                            title: driver.phone,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            fontColor: const Color(0xFF666A73),
                          ),
                          SizedBox(width: 5.w),
                          Icon(
                            Icons.phone_outlined,
                            size: 16.sp,
                            color: const Color(0xFF666A73),
                          ),
                        ],
                      ),

                      SizedBox(height: 18.h),

                      Row(
                        children: [
                          Expanded(
                            child: _DriverStatItem(
                              title: 'إجمالي الإيرادات',
                              value:
                              '${driver.totalRevenue.toStringAsFixed(0)} ج.م',
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _DriverStatItem(
                              title: 'الرحلات المكتملة',
                              value: '${driver.tripsCount}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                Align(
                  alignment: Alignment.centerRight,
                  child: CustomText(
                    title: 'رحلات السواق',
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w700,
                    fontColor: AppColors.primary,
                  ),
                ),

                SizedBox(height: 12.h),

                if (trips.isEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 40.h),
                    child: CustomText(
                      title: 'لا توجد رحلات لهذا السواق',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      fontColor: const Color(0xFF777B85),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: trips.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      final trip = trips[index];

                      return TripCard(
                        trip: trip,
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
      )
    );
  }
}
class _DriverStatItem extends StatelessWidget {
  final String title;
  final String value;

  const _DriverStatItem({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 8.w,
        vertical: 10.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundGray,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomText(
            title: title,
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            fontColor: const Color(0xFF666A73),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 5.h),
          CustomText(
            title: value,
            fontSize: 17.sp,
            fontWeight: FontWeight.w800,
            fontColor: AppColors.primary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
